# Runs the plugin's dca.exe, the build whose SHA-256 release.json pins.
# When bin\dca.exe is missing or is not that build, it is fetched from the
# GitHub release first; a download that does not match the pin is deleted
# and never run. `just plugin-dev` puts a local build in bin\ with a .dev
# marker, which is used as it is.
#
# Several Claude sessions may start the plugin at once, so each launch
# downloads to a file of its own and only a verified copy is moved into
# place; a launch that finds the pinned exe already there (or in use by
# another session) runs that one.
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Rest)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$bin = Join-Path $root 'bin'
$exe = Join-Path $bin 'dca.exe'
$pin = Get-Content -Raw (Join-Path $root 'release.json') | ConvertFrom-Json

# .NET directly rather than Get-FileHash, which lives in a script module
# that Windows PowerShell cannot load when started from PowerShell 7.
function Get-Sha256([string] $path) {
    $stream = [IO.File]::OpenRead($path)
    try {
        $sha = [Security.Cryptography.SHA256]::Create()
        -join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') })
    } finally { $stream.Dispose() }
}

function Test-Running([int] $id) {
    try { $null = [Diagnostics.Process]::GetProcessById($id); $true } catch { $false }
}

function Fail([string] $message) {
    [Console]::Error.WriteLine("Disk Cleanup Assistant: $message")
    exit 1
}

function Get-Release([string] $to) {
    $tag = "v$($pin.version)"
    if ($env:DCA_RELEASE_DIR) {
        # Tests fetch from a folder instead of GitHub.
        Copy-Item -LiteralPath (Join-Path $env:DCA_RELEASE_DIR 'dca.exe') -Destination $to
        return
    }
    $url = "https://github.com/$($pin.repo)/releases/download/$tag/dca.exe"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $to
        return
    } catch {
        # A private repository needs the signed-in GitHub CLI.
    }
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        # gh names the file dca.exe, so it gets a folder of its own rather
        # than bin\, where another session may be running dca.exe.
        $dir = "$to.gh"
        & gh release download $tag --repo $pin.repo --pattern dca.exe --dir $dir --clobber 2>$null
        if ($LASTEXITCODE -eq 0) {
            Move-Item -Force -LiteralPath (Join-Path $dir 'dca.exe') -Destination $to
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -LiteralPath $dir
            return
        }
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -LiteralPath $dir
    }
    Fail "could not download dca.exe $tag from github.com/$($pin.repo). Check the internet connection; for a private repository, sign in with ``gh auth login``."
}

function Test-Pinned { (Test-Path -LiteralPath $exe) -and ((Get-Sha256 $exe) -eq $pin.sha256) }

$dev = Test-Path (Join-Path $bin '.dev')
if (-not ($dev -or (Test-Pinned))) {
    New-Item -ItemType Directory -Force $bin | Out-Null
    # Downloads left by launches that were stopped part way: each is named
    # for its launch's process, and one whose process still runs is in use.
    Get-ChildItem -LiteralPath $bin -Filter 'dca.exe.*.download*' |
        Where-Object { $_.Name -match '^dca\.exe\.(\d+)\.download' -and -not (Test-Running $Matches[1]) } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $download = Join-Path $bin "dca.exe.$PID.download"
    Get-Release $download
    $got = Get-Sha256 $download
    if ($got -ne $pin.sha256) {
        Remove-Item -Force -LiteralPath $download
        Fail "the downloaded dca.exe does not match the plugin's pin (got $got, expected $($pin.sha256)); it was deleted, not run."
    }
    try {
        Move-Item -Force -LiteralPath $download -Destination $exe
    } catch {
        # Another session put the pinned exe there first and is running it.
        Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $download
        if (-not (Test-Pinned)) { Fail "could not put the downloaded dca.exe in $bin`: $_" }
    }
}

& $exe @Rest
exit $LASTEXITCODE
