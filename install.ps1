# OpenClaw Auto-Installer Bootstrap for Windows (PowerShell)
# Usage: iwr -useb https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.ps1 | iex
# This bootstrap downloads the main installer as a UTF-8 file and executes it.

$ErrorActionPreference = "Stop"

# ─── 自动升级 TLS 版本（Windows 7/8/旧版 PowerShell 默认 TLS 1.0 会被现代服务器拒绝）───
function Enable-BestTls {
    $protocols = @(
        # 优先尝试 TLS 1.2（现代服务器标配）
        [Net.SecurityProtocolType]::Tls12,
        # 降级备用：TLS 1.2 + TLS 1.1
        ([Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11),
        # 最后兜底：尝试所有可用协议（3072=Tls12, 768=Tls11, 192=Tls）
        [Net.SecurityProtocolType]3072,
        [Net.SecurityProtocolType]768
    )
    foreach ($proto in $protocols) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = $proto
            # 用一个轻量 TCP 连接验证协议是否可用（不依赖 WebClient/iwr）
            $socket = [System.Net.Sockets.TcpClient]::new()
            $ar = $socket.BeginConnect("raw.githubusercontent.com", 443, $null, $null)
            $ok = $ar.AsyncWaitHandle.WaitOne(3000, $false)
            $socket.Close()
            if ($ok) { return $proto }
        } catch { }
    }
    # 如果上述均失败，尝试直接以当前协议继续（让后续下载失败时再报错）
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
    return $null
}

Write-Host "  [*] 正在检测并升级 TLS 版本..." -ForegroundColor Cyan
$tlsResult = Enable-BestTls
if ($tlsResult) {
    Write-Host "  [OK] TLS 已设置为: $tlsResult" -ForegroundColor Green
} else {
    Write-Host "  [!] TLS 自动升级未能验证连通性，将继续尝试..." -ForegroundColor Yellow
}

$MAIN_URL = "https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/Windows_openclaw_Autoinstaller.ps1"
$MAIN_URL_CDN = "https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/Windows_openclaw_Autoinstaller.ps1"

function Download-And-Run {
    param([string]$Url)
    $tmp = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName() + ".ps1"
    $downloaded = $false
    # 下载方式1：Net.WebClient（继承 ServicePointManager 的 TLS 设置）
    try {
        $wc = New-Object Net.WebClient
        $wc.DownloadFile($Url, $tmp)
        if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) { $downloaded = $true }
    } catch { }
    # 下载方式2：Invoke-WebRequest（PowerShell 3.0+，某些版本有独立 TLS 处理）
    if (-not $downloaded) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing -TimeoutSec 60
            if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) { $downloaded = $true }
        } catch { }
    }
    if (-not $downloaded) { throw "无法下载安装文件：$Url" }
    try {
        & $tmp @args
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "  [*] 正在下载 OpenClaw 安装器..." -ForegroundColor Cyan
try {
    Download-And-Run $MAIN_URL
} catch {
    Write-Host ""
    Write-Host "  [!] 主下载源失败，正在切换至 CDN 加速节点重试..." -ForegroundColor Yellow
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
