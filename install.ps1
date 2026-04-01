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
    Write-Host ""
    Write-Host "  [!] Primary download failed, trying CDN mirror..." -ForegroundColor Yellow
    Write-Host ""
    try {
        Download-And-Run $MAIN_URL_CDN
    } catch {
        Write-Host ""
        Write-Host "  ======================================================" -ForegroundColor Red
        Write-Host "  [ERROR] Failed to download installer." -ForegroundColor Red
        Write-Host "  ======================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Possible causes:" -ForegroundColor Yellow
        Write-Host "    1. Network issue - please check your internet connection" -ForegroundColor Cyan
        Write-Host "    2. File not found (404) - installer may not be uploaded to GitHub yet" -ForegroundColor Cyan
        Write-Host "    3. GitHub / jsDelivr is temporarily unavailable" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Please contact: WeChat qiyuan_hou for support." -ForegroundColor Green
        Write-Host ""
        # 不使用 exit 1，防止 iex 管道模式下关闭 PowerShell 窗口
        Read-Host "  Press Enter to close"
    }
}
