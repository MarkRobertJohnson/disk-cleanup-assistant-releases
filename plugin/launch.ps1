# Runs the plugin's dca.exe, the build whose SHA-256 release.json pins.
# When bin\dca.exe is missing or is not that build, it is fetched from the
# GitHub release first; a download that does not match the pin is deleted
# and never run. `just plugin-dev` puts a local build in bin\ with a .dev
# marker, which is used as it is.
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Rest)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$bin = Join-Path $root 'bin'
$exe = Join-Path $bin 'dca.exe'
$pin = Get-Content -Raw (Join-Path $root 'release.json') | ConvertFrom-Json

function Get-Sha256([string] $path) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
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
        $dir = Split-Path $to
        & gh release download $tag --repo $pin.repo --pattern dca.exe --dir $dir --clobber 2>$null
        if ($LASTEXITCODE -eq 0) {
            Move-Item -Force -LiteralPath (Join-Path $dir 'dca.exe') -Destination $to
            return
        }
    }
    Fail "could not download dca.exe $tag from github.com/$($pin.repo). Check the internet connection; for a private repository, sign in with ``gh auth login``."
}

$dev = Test-Path (Join-Path $bin '.dev')
$ready = $dev -or ((Test-Path -LiteralPath $exe) -and ((Get-Sha256 $exe) -eq $pin.sha256))
if (-not $ready) {
    New-Item -ItemType Directory -Force $bin | Out-Null
    $download = Join-Path $bin 'dca.exe.download'
    Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $download
    Get-Release $download
    $got = Get-Sha256 $download
    if ($got -ne $pin.sha256) {
        Remove-Item -Force -LiteralPath $download
        Fail "the downloaded dca.exe does not match the plugin's pin (got $got, expected $($pin.sha256)); it was deleted, not run."
    }
    Move-Item -Force -LiteralPath $download -Destination $exe
}

& $exe @Rest
exit $LASTEXITCODE
