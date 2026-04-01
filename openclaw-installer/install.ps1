# OpenClaw Auto-Installer Bootstrap for Windows (PowerShell)
# Usage: iwr -useb https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.ps1 | iex
# This bootstrap downloads the main installer as a UTF-8 file and executes it.

$ErrorActionPreference = "Stop"

$MAIN_URL = "https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/Windows_openclaw_Autoinstaller.ps1"
$MAIN_URL_CDN = "https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/Windows_openclaw_Autoinstaller.ps1"

function Download-And-Run {
    param([string]$Url)
    $tmp = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName() + ".ps1"
    try {
        (New-Object Net.WebClient).DownloadFile($Url, $tmp)
        & $tmp
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    }
}

try {
    Download-And-Run $MAIN_URL
} catch {
    Write-Host "Primary download failed, trying CDN mirror..." -ForegroundColor Yellow
    try {
        Download-And-Run $MAIN_URL_CDN
    } catch {
        Write-Host "ERROR: Failed to download installer. Please check your network." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
