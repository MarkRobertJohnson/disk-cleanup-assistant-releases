@echo off
rem Starts the plugin's dca.exe. Windows PowerShell alone takes a second or
rem two to start, long enough for Claude Code to give up on the new MCP
rem protocol's opener, so a dca.exe already in bin\ is run directly.
rem launch.ps1 put it there only after checking it against the pin, and
rem each plugin version has a folder of its own, so it is the pinned build
rem or a local build that `just plugin-dev` marked as one. Without it,
rem launch.ps1 downloads and checks the pinned build first.
rem No labels: git may check this file out with LF line endings, which
rem cmd reads correctly only without goto.
setlocal
set "exe=%~dp0bin\dca.exe"
if exist "%exe%" ("%exe%" %*) else (powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0launch.ps1" %*)
exit /b %ERRORLEVEL%
