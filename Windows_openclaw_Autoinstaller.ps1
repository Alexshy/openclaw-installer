# ═══════════════════════════════════════════════════════════════════════
# OpenClaw 全自动安装部署脚本 - Windows 版
# 涵盖 OpenClaw环境安装 + OpenClaw最新官方稳定版 + 模型/网关/项目空间全自动部署
# 无后门 | 无病毒 | 全自动 | 全免费 | 零技术门槛 
# Created by:Mr_Hou 致力于技术平权降低门槛 让人人都有机会拥抱Ai世界 
# Wechat_id：qiyuan_hou，欢迎一起讨论 共同进化！
# **严禁恶意篡改或将本免费脚本商业化售卖**
# ═══════════════════════════════════════════════════════════════════════
# 功能菜单:
#   《安装与部署 OpenClaw 篇》
#   1. 安装 OpenClaw 并自动化部署（推荐新用户）
#   2. 仅自动化安装 OpenClaw
#   3. 仅部署 OpenClaw 模型/网关/项目空间
#   《使用 OpenClaw 篇》
#   4. 更换 OpenClaw 模型（配置 AI 模型提供商 / API Key）
#   5. 添加 Channels（微信 / 飞书 / 企微 / QQ 等即时通讯渠道）
#   6. OpenClaw 自检并尝试修复
#   7. 进入 OpenClaw 配置页面
#   8. 打开 OpenClaw 主页面
#   《卸载 OpenClaw 篇》
#   9. 完全卸载 OpenClaw
# ═══════════════════════════════════════════════════════════════════════

param(
    # ─── 安装参数 ───
    [string]$Tag = "latest",
    [ValidateSet("npm", "pnpm", "git")]
    [string]$InstallMethod = "pnpm",
    [string]$GitDir,
    [string]$Registry = "auto",
    [string]$GitHubProxy = "https://gh-proxy.org",
    [switch]$NoGitUpdate,
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$TestProxy,
    # ─── 部署参数 ───
    [int]$ProviderChoice,
    [string]$ApiKey,
    [string]$Workspace,
    [switch]$SkipDoctor,
    [switch]$SkipDashboard,
    [switch]$SkipGatewayRestart
)

$ErrorActionPreference = "Stop"

# ─── UTF-8 编码强制设置（iwr|iex 远程执行时防止中文乱码）───
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    if ([Console]::OutputEncoding.CodePage -ne 65001) {
        & chcp 65001 2>$null | Out-Null
    }
} catch { }

# ═══════════════════════════════════════════════════════════════════════
#                         终端美化
# ═══════════════════════════════════════════════════════════════════════
$script:UI_LINE      = "────────────────────────────────────────────────────────"
$script:UI_LINE_WIDE = "══════════════════════════════════════════════════════════════"
$script:UI_ICON_OK   = "[OK]"
$script:UI_ICON_INFO = "[*]"
$script:UI_ICON_WARN = "[!]"
$script:UI_ICON_ARROW = "[>]"

function Write-UILine { param([string]$Char = "-"); Write-Host ("$Char" * 60) -ForegroundColor Blue }
function Write-UISection {
    param([string]$Title, [string]$Step = "")
    Write-Host ""
    if ($Step) {
        Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
        Write-Host "  $script:UI_ICON_ARROW $Title  " -NoNewline -ForegroundColor Cyan
        Write-Host "($Step)" -ForegroundColor Blue
        Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    } else {
        Write-Host "  $script:UI_LINE" -ForegroundColor Blue
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    }
}
function Write-UIInfo { param([string]$Msg); Write-Host "  $script:UI_ICON_INFO $Msg" -ForegroundColor Cyan }
function Write-UIOk   { param([string]$Msg); Write-Host "  $script:UI_ICON_OK $Msg" -ForegroundColor Green }
function Write-UIWarn { param([string]$Msg); Write-Host "  $script:UI_ICON_WARN $Msg" -ForegroundColor Yellow }

# ═══════════════════════════════════════════════════════════════════════
#                    模型提供商配置数据
#        基于 OpenClaw 2026.3.28 官方源码 extensions/ 目录
# ═══════════════════════════════════════════════════════════════════════
$script:ProviderList = @(
    # ═══ 国内 Coding Plan（包月订阅制）═══
    @{
        Index        = 1
        Name         = "火山方舟 Coding Plan"
        NameEn       = "Volcano Engine"
        Category     = "china-plan"
        CategoryName = "国内 Coding Plan（包月订阅制，推荐国内用户）"
        AuthChoice   = "volcengine-api-key"
        CliFlag      = "--volcengine-api-key"
        EnvVar       = "VOLCANO_ENGINE_API_KEY"
        DefaultModel = "volcengine-plan/ark-code-latest"
        ApiKeyUrl    = "https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey"
        Emoji        = "火山"
    },
    @{
        Index        = 2
        Name         = "阿里百炼 Coding Plan"
        NameEn       = "Alibaba Cloud Model Studio"
        Category     = "china-plan"
        CategoryName = "国内 Coding Plan（包月订阅制，推荐国内用户）"
        AuthChoice   = "modelstudio-api-key-cn"
        CliFlag      = "--modelstudio-api-key-cn"
        EnvVar       = "MODELSTUDIO_API_KEY"
        DefaultModel = "modelstudio/qwen3.5-plus"
        ApiKeyUrl    = "https://bailian.console.aliyun.com/cn-beijing?tab=coding-plan#/efm/coding-plan-detail"
        Emoji        = "百炼"
    },
    # ═══ 国内直连模型（按量付费）═══
    @{
        Index        = 3
        Name         = "Kimi (Moonshot AI)"
        NameEn       = "Moonshot AI (Kimi K2.5)"
        Category     = "china-direct"
        CategoryName = "国内直连模型（按量付费）"
        AuthChoice   = "moonshot-api-key-cn"
        CliFlag      = "--moonshot-api-key"
        EnvVar       = "MOONSHOT_API_KEY"
        DefaultModel = "moonshot/kimi-k2.5"
        ApiKeyUrl    = "https://platform.moonshot.cn/console/api-keys"
        Emoji        = "Kimi"
    },
    @{
        Index        = 4
        Name         = "MiniMax"
        NameEn       = "MiniMax (M2.7)"
        Category     = "china-direct"
        CategoryName = "国内直连模型（按量付费）"
        AuthChoice   = "minimax-cn-api"
        CliFlag      = "--minimax-api-key"
        EnvVar       = "MINIMAX_API_KEY"
        DefaultModel = "minimax/MiniMax-M2.7"
        ApiKeyUrl    = "https://platform.minimaxi.com/user-center/basic-information/interface-key"
        Emoji        = "MM"
    },
    @{
        Index        = 5
        Name         = "DeepSeek"
        NameEn       = "DeepSeek"
        Category     = "china-direct"
        CategoryName = "国内直连模型（按量付费）"
        AuthChoice   = "deepseek-api-key"
        CliFlag      = "--deepseek-api-key"
        EnvVar       = "DEEPSEEK_API_KEY"
        DefaultModel = "deepseek/deepseek-chat"
        ApiKeyUrl    = "https://platform.deepseek.com/api_keys"
        Emoji        = "DS"
    },
    @{
        Index        = 6
        Name         = "百度千帆"
        NameEn       = "Qianfan (Baidu)"
        Category     = "china-direct"
        CategoryName = "国内直连模型（按量付费）"
        AuthChoice   = "qianfan-api-key"
        CliFlag      = "--qianfan-api-key"
        EnvVar       = "QIANFAN_API_KEY"
        DefaultModel = "qianfan/deepseek-v3.2"
        ApiKeyUrl    = "https://console.bce.baidu.com/qianfan/ais/console/onlineService"
        Emoji        = "千帆"
    },
    # ═══ 国际模型 ═══
    @{
        Index        = 7
        Name         = "OpenAI (ChatGPT)"
        NameEn       = "OpenAI"
        Category     = "international"
        CategoryName = "国际模型（需海外网络）"
        AuthChoice   = "openai-api-key"
        CliFlag      = "--openai-api-key"
        EnvVar       = "OPENAI_API_KEY"
        DefaultModel = "openai/gpt-5.4"
        ApiKeyUrl    = "https://platform.openai.com/api-keys"
        Emoji        = "GPT"
    },
    @{
        Index        = 8
        Name         = "Google (Gemini)"
        NameEn       = "Google"
        Category     = "international"
        CategoryName = "国际模型（需海外网络）"
        AuthChoice   = "gemini-api-key"
        CliFlag      = "--gemini-api-key"
        EnvVar       = "GEMINI_API_KEY"
        DefaultModel = "google/gemini-3.1-pro-preview"
        ApiKeyUrl    = "https://aistudio.google.com/app/apikey"
        Emoji        = "Gem"
    },
    @{
        Index        = 9
        Name         = "Anthropic (Claude)"
        NameEn       = "Anthropic"
        Category     = "international"
        CategoryName = "国际模型（需海外网络）"
        AuthChoice   = "apiKey"
        CliFlag      = "--anthropic-api-key"
        EnvVar       = "ANTHROPIC_API_KEY"
        DefaultModel = "anthropic/claude-sonnet-4-6"
        ApiKeyUrl    = "https://console.anthropic.com/settings/keys"
        Emoji        = "Claude"
    }
)

# ═══════════════════════════════════════════════════════════════════════
#                      部署相关函数
# ═══════════════════════════════════════════════════════════════════════

function Test-OpenClawInstalled {
    try {
        $null = Get-Command openclaw -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Select-Provider {
    if ($ProviderChoice -ge 1 -and $ProviderChoice -le 9) {
        $selected = $script:ProviderList | Where-Object { $_.Index -eq $ProviderChoice }
        Write-UIInfo "已通过参数选择: $($selected.Name) ($($selected.NameEn))"
        return $selected
    }

    Write-UISection -Title "选择模型提供商" -Step "Model Provider"

    Write-Host ""
    Write-Host "    Boss，请选择要使用的 AI 模型提供商（输入序号即可）：" -ForegroundColor White
    Write-Host ""

    $lastCategory = ""
    foreach ($p in $script:ProviderList) {
        if ($p.Category -ne $lastCategory) {
            $lastCategory = $p.Category
            Write-Host ""
            $categoryLabel = switch ($p.Category) {
                "china-plan"   { "  ══ 国内 Coding Plan（包月订阅制，推荐国内用户）══" }
                "china-direct" { "  ══ 国内直连模型（按量付费）══" }
                "international" { "  ══ 国际模型（需海外网络环境）══" }
            }
            Write-Host $categoryLabel -ForegroundColor Yellow
        }
        $indexStr = "$($p.Index)".PadLeft(4)
        $nameStr  = "[$($p.Emoji)] $($p.Name)".PadRight(32)
        Write-Host "$indexStr) " -NoNewline -ForegroundColor Cyan
        Write-Host $nameStr -NoNewline -ForegroundColor White
        Write-Host "  默认模型：$($p.DefaultModel)" -ForegroundColor Blue
    }

    Write-Host ""
    Write-Host "    提示：国内用户推荐选 1（火山方舟）或 2（阿里百炼），包月订阅更划算。" -ForegroundColor Blue
    Write-Host ""

    while ($true) {
        $userInput = Read-Host "    请输入序号（1-9）"
        $num = 0
        if ([int]::TryParse($userInput, [ref]$num) -and $num -ge 1 -and $num -le 9) {
            $selected = $script:ProviderList | Where-Object { $_.Index -eq $num }
            Write-Host ""
            Write-UIOk "已选择：$($selected.Name)（$($selected.NameEn)）"
            Write-Host "    默认模型：" -NoNewline -ForegroundColor Blue
            Write-Host $selected.DefaultModel -ForegroundColor Cyan
            return $selected
        }
        Write-Host "    输入无效，请输入 1 到 9 之间的数字" -ForegroundColor Red
    }
}

function Read-ApiKey {
    param([hashtable]$Provider)

    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-UIInfo "已通过参数传入 API Key"
        return $ApiKey
    }

    Write-UISection -Title "输入 API Key" -Step "$($Provider.Name)"

    Write-Host ""
    Write-Host "    Boss，请输入你的 $($Provider.Name) API Key：" -ForegroundColor White
    Write-Host ""
    Write-Host "    还没有 API Key？前往以下地址获取：" -ForegroundColor Blue
    Write-Host "    $($Provider.ApiKeyUrl)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    环境变量名：" -NoNewline -ForegroundColor Blue
    Write-Host $Provider.EnvVar -ForegroundColor Yellow
    Write-Host ""

    while ($true) {
        $key = Read-Host "    请粘贴你的 API Key"
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $maskedKey = if ($key.Length -gt 8) {
                $key.Substring(0, 4) + ("*" * ($key.Length - 8)) + $key.Substring($key.Length - 4)
            } else {
                "****"
            }
            Write-Host ""
            Write-UIOk "API Key 已录入！（$maskedKey）"
            return $key.Trim()
        }
        Write-Host "    API Key 不能为空，请重新输入" -ForegroundColor Red
    }
}

function Read-Workspace {
    if (-not [string]::IsNullOrWhiteSpace($Workspace)) {
        Write-UIInfo "已通过参数指定工作目录: $Workspace"
        return $Workspace
    }

    Write-UISection -Title "设置项目文件夹" -Step "Workspace"

    $defaultPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "openclaw"

    Write-Host ""
    Write-Host "    Boss，请指定 OpenClaw 项目文件夹路径：" -ForegroundColor White
    Write-Host "    后续工作文件均存放于此目录。" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    默认路径：" -NoNewline -ForegroundColor Blue
    Write-Host $defaultPath -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    直接按 Enter 使用默认路径，或输入自定义路径：" -ForegroundColor Blue

    $userInput = Read-Host "    工作目录"

    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $finalPath = $defaultPath
    } else {
        $finalPath = $userInput.Trim()
        if ($finalPath.StartsWith("~")) {
            $finalPath = $finalPath.Replace("~", $env:USERPROFILE)
        }
    }

    if (-not (Test-Path $finalPath)) {
        try {
            New-Item -ItemType Directory -Force -Path $finalPath | Out-Null
            Write-UIOk "新文件夹创建成功！路径：$finalPath"
        } catch {
            Write-UIWarn "目录创建失败，已回退到默认路径。"
            $finalPath = $defaultPath
            if (-not (Test-Path $finalPath)) {
                New-Item -ItemType Directory -Force -Path $finalPath | Out-Null
            }
        }
    } else {
        Write-UIOk "目录已存在，直接使用！路径：$finalPath"
    }

    return $finalPath
}

function Invoke-Deployment {
    param(
        [hashtable]$Provider,
        [string]$Key,
        [string]$WorkDir
    )

    Write-UISection -Title "执行自动部署" -Step "openclaw onboard --non-interactive"

    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host "  部署计划" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host "    模型提供商    " -NoNewline -ForegroundColor Blue
    Write-Host "$($Provider.Name) ($($Provider.NameEn))" -ForegroundColor White
    Write-Host "    认证方式 ID   " -NoNewline -ForegroundColor Blue
    Write-Host $Provider.AuthChoice -ForegroundColor White
    Write-Host "    默认模型      " -NoNewline -ForegroundColor Blue
    Write-Host $Provider.DefaultModel -ForegroundColor White
    Write-Host "    工作目录      " -NoNewline -ForegroundColor Blue
    Write-Host $WorkDir -ForegroundColor White
    Write-Host "    安装 Daemon   " -NoNewline -ForegroundColor Blue
    Write-Host "是（后台服务自启动）" -ForegroundColor White
    Write-Host "    跳过通道配置  " -NoNewline -ForegroundColor Blue
    Write-Host "是（稍后可通过 openclaw channels add 添加）" -ForegroundColor White
    Write-Host "    跳过技能配置  " -NoNewline -ForegroundColor Blue
    Write-Host "是（稍后可通过 openclaw skills 配置）" -ForegroundColor White
    Write-Host "    跳过搜索配置  " -NoNewline -ForegroundColor Blue
    Write-Host "是（稍后可通过 openclaw configure --section web 配置）" -ForegroundColor White
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host ""

    Write-UIInfo "正在执行 OpenClaw 自动化部署，请稍候..."
    Write-Host ""

    [Environment]::SetEnvironmentVariable($Provider.EnvVar, $Key, "Process")

    $onboardArgs = @(
        "onboard",
        "--non-interactive",
        "--accept-risk",
        "--auth-choice", $Provider.AuthChoice,
        $Provider.CliFlag, $Key,
        "--workspace", $WorkDir,
        "--install-daemon",
        "--skip-channels",
        "--skip-skills",
        "--skip-search"
    )

    Write-UIInfo "执行命令: openclaw onboard --non-interactive --auth-choice $($Provider.AuthChoice) ..."

    try {
        & openclaw @onboardArgs 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Blue
        }
        $onboardExit = $LASTEXITCODE
    } catch {
        $onboardExit = 1
        Write-Host "    错误: $($_.Exception.Message)" -ForegroundColor Red
    }

    if ($onboardExit -eq 0) {
        Write-Host ""
        Write-UIOk "🦞 OpenClaw 部署配置完成！"
        Write-Host ""
        Write-Host "    已完成以下配置：" -ForegroundColor Blue
        Write-Host "      - 模型提供商: $($Provider.Name)" -ForegroundColor Cyan
        Write-Host "      - 默认模型: $($Provider.DefaultModel)" -ForegroundColor Cyan
        Write-Host "      - API Key: 已配置" -ForegroundColor Cyan
        Write-Host "      - 工作目录: $WorkDir" -ForegroundColor Cyan
        Write-Host "      - Gateway Daemon: 已安装并启动" -ForegroundColor Cyan
        Write-Host "      - 网关端口: 18789（Loopback 绑定 + Token 认证）" -ForegroundColor Cyan
        return $true
    } else {
        Write-Host ""
        Write-UIWarn "部署过程遇到问题（退出码：$onboardExit）"
        Write-Host ""
        Write-Host "    请检查以下可能的原因：" -ForegroundColor Yellow
        Write-Host "      1. API Key 是否正确" -ForegroundColor Cyan
        Write-Host "      2. 网络是否可以访问对应模型提供商" -ForegroundColor Cyan
        Write-Host "      3. 工作目录是否有写入权限" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    你可以稍后手动运行以下命令重试：" -ForegroundColor Blue
        Write-Host "      openclaw onboard --install-daemon" -ForegroundColor Cyan
        Write-Host ""
        return $false
    }
}

function Invoke-DoctorCheck {
    if ($SkipDoctor) {
        Write-UIInfo "已跳过 doctor 自检"
        return
    }
    Write-UISection -Title "部署后健康检查" -Step "openclaw doctor"
    Write-UIInfo "正在运行 OpenClaw 自检（openclaw doctor）..."
    Write-Host ""
    try {
        & openclaw doctor 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Blue
        }
    } catch {
        Write-UIWarn "doctor 运行遇到问题：$($_.Exception.Message)"
    }
    Write-Host ""
    Write-UIInfo "正在尝试自动修复检测到的问题（openclaw doctor --fix）..."
    Write-Host ""
    try {
        & openclaw doctor --fix 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Blue
        }
    } catch { }
    Write-Host ""
    Write-UIOk "自检完成！如有 [!] 标记的项目请参考输出手动处理。"
}

function Invoke-GatewayRestart {
    if ($SkipGatewayRestart) {
        Write-UIInfo "已跳过 Gateway 重启"
        return
    }
    Write-UISection -Title "重启 Gateway 服务" -Step "openclaw gateway restart"
    Write-UIInfo "正在重启 Gateway 后台服务..."
    Write-Host ""
    Write-Host "    小提示：gateway restart 是重启后台 daemon 服务" -ForegroundColor Blue
    Write-Host "    记得不要额外运行 openclaw gateway run 哦，会造成端口冲突的！" -ForegroundColor Blue
    Write-Host ""
    try {
        & openclaw gateway restart 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Blue
        }
        Write-Host ""
        Write-UIOk "🦞 Gateway 服务重启成功！"
    } catch {
        Write-UIWarn "Gateway 重启失败：$($_.Exception.Message)"
        Write-Host "    可稍后手动运行：openclaw gateway restart" -ForegroundColor Blue
    }
}

function Invoke-Dashboard {
    if ($SkipDashboard) {
        Write-UIInfo "已跳过打开 Web UI"
        return
    }
    Write-UISection -Title "打开 Web UI 控制界面" -Step "openclaw dashboard"
    Write-UIInfo "正在打开 OpenClaw 控制面板（Web UI）..."
    Write-Host ""
    try {
        & openclaw dashboard 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Blue
        }
        Write-Host ""
        Write-UIOk "OpenClaw Web UI 已启动！"
    } catch {
        Write-UIWarn "打开 Web UI 失败，请稍后手动运行：openclaw dashboard"

    }
}

function Show-DeploySummary {
    param(
        [hashtable]$Provider,
        [string]$WorkDir,
        [bool]$DeploySuccess
    )
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Green
    Write-Host "  " -NoNewline
    if ($DeploySuccess) {
        Write-Host "  🦞 OpenClaw 部署配置全部完成！" -ForegroundColor Green
    } else {
        Write-Host "  🦞 OpenClaw 部署配置已完成（部分步骤可能需要手动处理）" -ForegroundColor Yellow
    }
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Green
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  部署摘要" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "    模型提供商    " -NoNewline -ForegroundColor Blue
    Write-Host "$($Provider.Name)" -ForegroundColor Cyan
    Write-Host "    默认模型      " -NoNewline -ForegroundColor Blue
    Write-Host $Provider.DefaultModel -ForegroundColor Cyan
    Write-Host "    工作目录      " -NoNewline -ForegroundColor Blue
    Write-Host $WorkDir -ForegroundColor Cyan
    Write-Host "    Gateway 端口  " -NoNewline -ForegroundColor Blue
    Write-Host "18789 (Loopback + Token)" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  常用命令" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "    自检修复      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw doctor --fix" -ForegroundColor Cyan
    Write-Host "    重启服务      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw gateway restart" -ForegroundColor Cyan
    Write-Host "    打开面板      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw dashboard" -ForegroundColor Cyan
    Write-Host "    重新引导      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw onboard --install-daemon" -ForegroundColor Cyan
    Write-Host "    安全审计      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw security audit --deep" -ForegroundColor Cyan
    Write-Host "    添加通道      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw channels add" -ForegroundColor Cyan
    Write-Host "    配置技能      " -NoNewline -ForegroundColor Blue
    Write-Host "openclaw skills" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    $tips = @(
        "🦞 OpenClaw 已就绪，快去探索 AI 世界吧！",
        "一切就绪！打开 Web UI 就可以与 AI 助手对话。",
        "配置完成！试试 openclaw dashboard 打开控制面板。",
        "你的 AI 助手已在后台待命，随时召唤。"
    )
    Write-Host "  " -NoNewline
    Write-Host $tips[(Get-Random -Maximum $tips.Count)] -ForegroundColor Cyan
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
#                        欢迎菜单
# ═══════════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════
#                   使用 / 卸载 OpenClaw 功能函数
# ═══════════════════════════════════════════════════════════════════════

# ————————————————————————————————————————————————————
# 选项4: 更换 OpenClaw 模型
# ————————————————————————————————————————————————————
function Invoke-ConfigureModel {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 更换 OpenClaw 模型  " -NoNewline -ForegroundColor Cyan
    Write-Host "配置向导" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  模型资源与配置参考" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    🔥 火山方舟 Coding Plan（火山引擎 包月订阅）" -ForegroundColor Yellow
    Write-Host "       配置指南： https://www.volcengine.com/docs/82379/2183190?lang=zh" -ForegroundColor Blue
    Write-Host "       API Key 查看： https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    ☁️  阿里百炼 Coding Plan（平行引擎 包月订阅）" -ForegroundColor Yellow
    Write-Host "       配置指南： https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085" -ForegroundColor Blue
    Write-Host "       API Key 查看： https://bailian.console.aliyun.com/cn-beijing?tab=coding-plan#/efm/coding-plan-detail" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    🟦 腾讯 Coding Plan（混元大模型 包月订阅）" -ForegroundColor Yellow
    Write-Host "       配置指南： https://cloud.tencent.com/document/product/1772/128949" -ForegroundColor Blue
    Write-Host "       API Key 查看： https://hunyuan.cloud.tencent.com/#/app/subscription" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  请提前准备好对应模型的 API Key，然后选择操作：" -ForegroundColor White
    Write-Host ""
    Write-Host "    1) " -NoNewline -ForegroundColor Cyan
    Write-Host "继续配置 OpenClaw 模型" -ForegroundColor White
    Write-Host ""
    Write-Host "    2) " -NoNewline -ForegroundColor Cyan
    Write-Host "返回主菜单" -ForegroundColor White
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    while ($true) {
        $subInput = Read-Host "    请输入序号 (1/2)"
        switch ($subInput) {
            "1" {
                Write-Host ""
                Write-UIInfo "正在调起 openclaw configure （Local + Model）..."
                Write-Host ""
                try {
                    & openclaw configure
                } catch {
                    Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： openclaw configure" -ForegroundColor Blue
                }
                return
            }
            "2" { return }
            default { Write-Host "    输入无效，请输入 1 或 2" -ForegroundColor Red }
        }
    }
}

# ————————————————————————————————————————————————————
# 选项5: 添加 Channels
# ————————————————————————————————————————————————————
function Show-WechatChannelMenu {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 连接微信  " -NoNewline -ForegroundColor Cyan
    Write-Host "Wechat Channel" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  接入步骤" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  第一步：升级微信至最新版（≥ 8.0.7）" -ForegroundColor White
    Write-Host "    微信 → 我 → 设置 → 关于微信 → 版本更新" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  第二步：在微信里启用插件" -ForegroundColor White
    Write-Host "    1. 手机微信 → 「我」→ 「设置」→ 「插件」" -ForegroundColor Blue
    Write-Host "    2. 找到「微信 ClawBot」，按提示启用/授权" -ForegroundColor Blue
    Write-Host "    （此步是将微信账号与插件能力绑定）" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  第三步：点击“继续”，将自动安装微信官方插件" -ForegroundColor White
    Write-Host "    执行命令： npx -y @tencent-weixin/openclaw-weixin-cli@latest install" -ForegroundColor Blue
    Write-Host "    执行后自动弹出二维码，用需要绑定的微信扫码并点“连接”确认" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    1) " -NoNewline -ForegroundColor Cyan
    Write-Host "安装微信官方插件（自动执行上述命令）" -ForegroundColor White
    Write-Host ""
    Write-Host "    2) " -NoNewline -ForegroundColor Cyan
    Write-Host "返回主菜单" -ForegroundColor White
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    while ($true) {
        $subInput = Read-Host "    请输入序号 (1/2)"
        switch ($subInput) {
            "1" {
                Write-Host ""
                Write-UIInfo "正在安装微信官方插件..."
                Write-Host ""
                try {
                    & npx -y @tencent-weixin/openclaw-weixin-cli@latest install
                    Write-Host ""
                    Write-UIOk "微信插件安装命令执行完成！请用微信扫码确认连接。"
                } catch {
                    Write-UIWarn "安装失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： npx -y @tencent-weixin/openclaw-weixin-cli@latest install" -ForegroundColor Blue
                }
                return
            }
            "2" { return }
            default { Write-Host "    输入无效，请输入 1 或 2" -ForegroundColor Red }
        }
    }
}

function Show-ChannelsMenu {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 添加 Channels  " -NoNewline -ForegroundColor Cyan
    Write-Host "连接即时通讯渠道" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  请选择要连接的渠道：" -ForegroundColor White
    Write-Host ""
    Write-Host "    1) " -NoNewline -ForegroundColor Cyan
    Write-Host "连接微信" -ForegroundColor White
    Write-Host ""
    Write-Host "    2) " -NoNewline -ForegroundColor Cyan
    Write-Host "连接飞书" -ForegroundColor White
    Write-Host "       参考指南： https://www.feishu.cn/content/article/7613711414611463386" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    3) " -NoNewline -ForegroundColor Cyan
    Write-Host "连接企微" -ForegroundColor White
    Write-Host "       参考指南： https://open.work.weixin.qq.com/help2/pc/cat?doc_id=21657" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    4) " -NoNewline -ForegroundColor Cyan
    Write-Host "连接 QQ" -ForegroundColor White
    Write-Host "       参考指南： https://q.qq.com/qqbot/openclaw/login.html" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    5) " -NoNewline -ForegroundColor Cyan
    Write-Host "连接其他渠道" -ForegroundColor White
    Write-Host "       进入 Channels 配置总入口，手动选择渠道" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    6) " -NoNewline -ForegroundColor Cyan
    Write-Host "返回主菜单" -ForegroundColor White
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    while ($true) {
        $subInput = Read-Host "    请输入序号 (1-6)"
        switch ($subInput) {
            "1" {
                Show-WechatChannelMenu
                # 微信子菜单返回后，继续循环显示渠道菜单
            }
            "2" {
                Write-Host ""
                Write-UIInfo "飞书接入指南： https://www.feishu.cn/content/article/7613711414611463386"
                Write-Host ""
                Write-UIInfo "正在调起 openclaw configure → Channels..."
                Write-Host ""
                try {
                    & openclaw configure --section channels
                } catch {
                    Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： openclaw configure --section channels" -ForegroundColor Blue
                }
            }
            "3" {
                Write-Host ""
                Write-UIInfo "企微接入指南： https://open.work.weixin.qq.com/help2/pc/cat?doc_id=21657"
                Write-Host ""
                Write-UIInfo "正在调起 openclaw configure → Channels..."
                Write-Host ""
                try {
                    & openclaw configure --section channels
                } catch {
                    Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： openclaw configure --section channels" -ForegroundColor Blue
                }
            }
            "4" {
                Show-QQChannelMenu
                # QQ子菜单返回后，继续循环显示渠道菜单
            }
            "5" {
                Write-Host ""
                Write-UIInfo "正在调起 openclaw configure → Channels..."
                Write-Host ""
                try {
                    & openclaw configure --section channels
                } catch {
                    Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： openclaw configure --section channels" -ForegroundColor Blue
                }
            }
            "6" { return }
            default { Write-Host "    输入无效，请输入 1 到 6 之间的序号" -ForegroundColor Red }
        }
    }
}

# ————————————————————————————————————————————————————
# QQ 渠道三级菜单
# ————————————————————————————————————————————————————
function Show-QQChannelMenu {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 连接 QQ  " -NoNewline -ForegroundColor Cyan
    Write-Host "三步完成 QQ 渠道接入" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📋 连接前请先阅读官方指南：" -ForegroundColor White
    Write-Host "     https://q.qq.com/qqbot/openclaw/login.html" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  接入步骤：" -ForegroundColor White
    Write-Host "    第一步：访问以上官方指南页面，完成 QQ 账号授权" -ForegroundColor Blue
    Write-Host "    第二步：准备好 QQ 机器人的相关凭据（AppID / Token 等）" -ForegroundColor Blue
    Write-Host "    第三步：点击继续，进入 OpenClaw Channels 配置页完成绑定" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    Write-Host "    1) " -NoNewline -ForegroundColor Cyan
    Write-Host "继续连接 QQ（进入 Channels 配置）" -ForegroundColor White
    Write-Host ""
    Write-Host "    2) " -NoNewline -ForegroundColor Cyan
    Write-Host "返回渠道菜单" -ForegroundColor White
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    while ($true) {
        $subInput = Read-Host "    请输入序号 (1-2)"
        switch ($subInput) {
            "1" {
                Write-Host ""
                Write-UIInfo "正在调起 openclaw configure → Channels..."
                Write-Host ""
                try {
                    & openclaw configure --section channels
                } catch {
                    Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
                    Write-Host "    请手动运行： openclaw configure --section channels" -ForegroundColor Blue
                }
                return
            }
            "2" { return }
            default { Write-Host "    输入无效，请输入 1 或 2" -ForegroundColor Red }
        }
    }
}

# ————————————————————————————————————————————————————
# 选项6: 自检并尝试修复
# ————————————————————————————————————————————————————
function Invoke-SelfCheck {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 OpenClaw 自检并尝试修复  " -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  小提示：请将完整自检结果复制粘贴给 豆包 / 千问 / DeepSeek 帮你分析" -ForegroundColor Yellow
    Write-Host ""

    # 第1步: openclaw doctor
    Write-UISection -Title "Step 1 - 健康检查" -Step "openclaw doctor"
    Write-UIInfo "正在运行 OpenClaw 健康检查..."
    Write-Host ""
    try {
        & openclaw doctor 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    } catch {
        Write-UIWarn "doctor 运行遇到问题：$($_.Exception.Message)"
    }
    Write-Host ""

    # 第2步: openclaw doctor --fix
    Write-UISection -Title "Step 2 - 自动修复" -Step "openclaw doctor --fix"
    Write-UIInfo "正在尝试自动修复检测到的问题..."
    Write-Host ""
    try {
        & openclaw doctor --fix 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    } catch {
        Write-UIWarn "doctor --fix 运行遇到问题：$($_.Exception.Message)"
    }
    Write-Host ""

    # 第3步: openclaw gateway restart
    Write-UISection -Title "Step 3 - 重启 Gateway" -Step "openclaw gateway restart"
    Write-UIInfo "正在重启 Gateway 后台服务..."
    Write-Host ""
    try {
        & openclaw gateway restart 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        Write-Host ""
        Write-UIOk "Gateway 服务已重启"
    } catch {
        Write-UIWarn "gateway restart 失败：$($_.Exception.Message)"
        Write-Host "    可手动运行： openclaw gateway restart" -ForegroundColor Blue
    }
    Write-Host ""

    # 第4步: openclaw status --all
    Write-UISection -Title "Step 4 - 查看全量状态" -Step "openclaw status --all"
    Write-UIInfo "正在获取 OpenClaw 全量状态信息..."
    Write-Host ""
    try {
        & openclaw status --all 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    } catch {
        Write-UIWarn "status --all 运行遇到问题：$($_.Exception.Message)"
    }
    Write-Host ""

    # 第5步: openclaw dashboard
    Write-UISection -Title "Step 5 - 打开控制面板" -Step "openclaw dashboard"
    Write-UIInfo "正在打开 OpenClaw Web UI（控制面板）..."
    Write-Host ""
    try {
        & openclaw dashboard 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        Write-Host ""
        Write-UIOk "OpenClaw Web UI 已启动！"
    } catch {
        Write-UIWarn "打开 Web UI 失败，请手动运行： openclaw dashboard"
    }
    Write-Host ""

    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-UIOk "🦞 全部自检流程执行完成！如有输出异常请复制给 AI 助手分析。"
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
}

# ————————————————————————————————————————————————————
# 选项7: 进入 OpenClaw 配置页面
# ————————————————————————————————————————————————————
function Invoke-ConfigureMain {
    Write-Host ""
    Write-UISection -Title "进入 OpenClaw 配置页面" -Step "openclaw configure"
    Write-UIInfo "正在启动 OpenClaw 配置向导（包含模型 / 网关 / 渠道 / 守护进程等）..."
    Write-Host ""
    try {
        & openclaw configure
    } catch {
        Write-UIWarn "configure 启动失败：$($_.Exception.Message)"
        Write-Host "    请手动运行： openclaw configure" -ForegroundColor Blue
    }
    Write-Host ""
}

# ————————————————————————————————————————————————————
# 选项8: 打开 OpenClaw 主页面
# ————————————————————————————————————————————————————
function Invoke-Dashboard {
    Write-Host ""
    Write-UISection -Title "打开 OpenClaw 主页面" -Step "openclaw dashboard"
    Write-UIInfo "正在启动 OpenClaw Web UI..."
    Write-Host ""
    try {
        & openclaw dashboard 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        Write-Host ""
        Write-UIOk "OpenClaw Web UI 已启动！请在浏览器中查看。"
    } catch {
        Write-UIWarn "启动失败：$($_.Exception.Message)"
        Write-Host "    请手动运行： openclaw dashboard" -ForegroundColor Blue
    }
    Write-Host ""
}

# ————————————————————————————————————————————————————
# 选项9: 完全卸载 OpenClaw
# ————————————————————————————————————————————————————
function Invoke-Uninstall {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Red
    Write-Host "  ⚠️  完全卸载 OpenClaw  " -NoNewline -ForegroundColor Red
    Write-Host "本操作不可逆！" -ForegroundColor Red
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Red
    Write-Host ""
    Write-Host "  将依次执行以下操作：" -ForegroundColor White
    Write-Host "    1. openclaw gateway stop" -ForegroundColor Blue
    Write-Host "    2. openclaw gateway uninstall" -ForegroundColor Blue
    Write-Host "    3. openclaw uninstall" -ForegroundColor Blue
    Write-Host "    4. npm uninstall -g openclaw" -ForegroundColor Blue
    Write-Host "    5. pnpm remove -g openclaw" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Red
    Write-Host "  请输入 YES 进行二次确认（输入其它内容取消）" -ForegroundColor Red
    Write-Host ""
    $confirm1 = Read-Host "    请确认：输入 YES 开始卸载"
    if ($confirm1 -ne "YES") {
        Write-UIInfo "已取消卸载操作。"
        return
    }
    Write-Host ""
    $confirm2 = Read-Host "    再次确认：这将彻底卸载 OpenClaw，输入 YES 继续"
    if ($confirm2 -ne "YES") {
        Write-UIInfo "已取消卸载操作。"
        return
    }

    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 开始执行卸载流程..." -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""

    $uninstallResults = @()

    # Step 1: openclaw gateway stop
    Write-UISection -Title "Step 1 - 停止 Gateway 服务" -Step "openclaw gateway stop"
    try {
        & openclaw gateway stop 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        $uninstallResults += "[OK] openclaw gateway stop"
    } catch {
        $uninstallResults += "[!] openclaw gateway stop: $($_.Exception.Message)"
    }
    Write-Host ""

    # Step 2: openclaw gateway uninstall
    Write-UISection -Title "Step 2 - 移除 Gateway 服务" -Step "openclaw gateway uninstall"
    try {
        & openclaw gateway uninstall 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        $uninstallResults += "[OK] openclaw gateway uninstall"
    } catch {
        $uninstallResults += "[!] openclaw gateway uninstall: $($_.Exception.Message)"
    }
    Write-Host ""

    # Step 3: openclaw uninstall
    Write-UISection -Title "Step 3 - 卸载 OpenClaw配置" -Step "openclaw uninstall"
    try {
        & openclaw uninstall 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        $uninstallResults += "[OK] openclaw uninstall"
    } catch {
        $uninstallResults += "[!] openclaw uninstall: $($_.Exception.Message)"
    }
    Write-Host ""

    # Step 4: npm uninstall -g openclaw
    Write-UISection -Title "Step 4 - npm 全局卸载" -Step "npm uninstall -g openclaw"
    try {
        & npm uninstall -g openclaw 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        $uninstallResults += "[OK] npm uninstall -g openclaw"
    } catch {
        $uninstallResults += "[!] npm uninstall -g openclaw: $($_.Exception.Message)"
    }
    Write-Host ""

    # Step 5: pnpm remove -g openclaw
    Write-UISection -Title "Step 5 - pnpm 全局卸载" -Step "pnpm remove -g openclaw"
    try {
        & pnpm remove -g openclaw 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
        $uninstallResults += "[OK] pnpm remove -g openclaw"
    } catch {
        $uninstallResults += "[!] pnpm remove -g openclaw: $($_.Exception.Message)"
    }
    Write-Host ""

    # 卸载结果汇总
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 卸载流程完成 — 执行结果汇总" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""
    foreach ($result in $uninstallResults) {
        if ($result -like "[OK]*") {
            Write-Host "    $result" -ForegroundColor Green
        } else {
            Write-Host "    $result" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-UIInfo "OpenClaw 卸载流程全部执行完成。如有标记 [!] 的步骤请手动处理。"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
#                          欢迎菜单
# ═══════════════════════════════════════════════════════════════════════

function Show-WelcomeMenu {
    Write-Host ""
    Write-Host "  # ═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  # OpenClaw 全自动安装部署脚本 - Windows 版" -ForegroundColor Cyan
    Write-Host "  # 涵盖 OpenClaw环境安装 + OpenClaw最新官方稳定版 + 模型/网关/项目空间全自动部署" -ForegroundColor Blue
    Write-Host "  # 无后门 | 无病毒 | 全自动 | 全免费 | 零技术门槛" -ForegroundColor Green
    Write-Host "  # Created by: Mr_Hou  致力于技术平权降低门槛 让人人都有机会拥抱Ai世界" -ForegroundColor Blue
    Write-Host "  # Wechat_id：qiyuan_hou，欢迎一起讨论 共同进化！" -ForegroundColor Blue
    Write-Host "  # **严禁恶意篡改或将本免费脚本商业化售卖**" -ForegroundColor Yellow
    Write-Host "  # ═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  # 功能菜单:" -ForegroundColor Blue
    Write-Host ""

    # ── 安装部署 OpenClaw 篇 ──
    Write-Host "  ┌─ 《安装与部署 OpenClaw 篇》 ────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "    1) " -NoNewline -ForegroundColor Cyan
    Write-Host "安装 OpenClaw 并自动化部署" -NoNewline -ForegroundColor White
    Write-Host "  （推荐新用户）" -ForegroundColor Blue
    Write-Host "       自动安装 Node.js / Git / OpenClaw，并配置模型、API Key、网关和项目空间" -ForegroundColor Blue
    Write-Host "    2) " -NoNewline -ForegroundColor Cyan
    Write-Host "仅自动化安装 OpenClaw" -ForegroundColor White
    Write-Host "       只安装 OpenClaw CLI 运行环境，模型和网关配置稍后可单独完成" -ForegroundColor Blue
    Write-Host "    3) " -NoNewline -ForegroundColor Cyan
    Write-Host "仅部署 OpenClaw 模型/网关/项目空间" -ForegroundColor White
    Write-Host "       OpenClaw 已安装，仅配置模型提供商、API Key 和工作目录" -ForegroundColor Blue
    Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    # ── 使用 OpenClaw 篇 ──
    Write-Host "  ┌─ 《使用 OpenClaw 篇》（需已安装 OpenClaw）─────────────────────────────┤" -ForegroundColor Yellow
    Write-Host "    4) " -NoNewline -ForegroundColor Yellow
    Write-Host "更换 OpenClaw 模型（配置 AI 模型提供商 / API Key）" -ForegroundColor White
    Write-Host "       支持 DeepSeek / Kimi / 火山方舟 / 阿里百炼 / ChatGPT / Claude 等 9 家提供商" -ForegroundColor Blue
    Write-Host "    5) " -NoNewline -ForegroundColor Yellow
    Write-Host "添加 Channels（微信 / 飞书 / 企微 / QQ 等即时通讯渠道）" -ForegroundColor White
    Write-Host "       连接即时通讯渠道，让 AI 助手在你的聊天 App 里直接回复消息" -ForegroundColor Blue
    Write-Host "    6) " -NoNewline -ForegroundColor Yellow
    Write-Host "OpenClaw 自检并尝试修复" -ForegroundColor White
    Write-Host "       自动运行 doctor 诊断 + doctor --fix 修复 + gateway restart 重启网关" -ForegroundColor Blue
    Write-Host "    7) " -NoNewline -ForegroundColor Yellow
    Write-Host "进入 OpenClaw 配置页面" -ForegroundColor White
    Write-Host "       打开完整的交互式配置向导（模型 / 网关 / 渠道 / 守护进程等）" -ForegroundColor Blue
    Write-Host "    8) " -NoNewline -ForegroundColor Yellow
    Write-Host "打开 OpenClaw 主页面" -ForegroundColor White
    Write-Host "       启动 OpenClaw Web UI 控制面板，可在浏览器中查看全部功能和对话" -ForegroundColor Blue
    Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""

    # ── 卸载 OpenClaw 篇 ──
    Write-Host "  ┌─ 《卸载 OpenClaw 篇》 ──────────────────────────────────────────────────┤" -ForegroundColor Red
    Write-Host "    9) " -NoNewline -ForegroundColor Red
    Write-Host "完全卸载 OpenClaw" -ForegroundColor White
    Write-Host "       停止全部服务并彻底移除 OpenClaw（操作不可逆，执行前需二次确认）" -ForegroundColor Blue
    Write-Host "  └─────────────────────────────────────────────────────────────────────┘" -ForegroundColor Red
    Write-Host ""

    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
    while ($true) {
        $userInput = Read-Host "    请输入序号 (1-9)"
        switch ($userInput) {
            "1" { return "full" }
            "2" { return "install" }
            "3" { return "deploy" }
            "4" { return "configure-model" }
            "5" { return "channels" }
            "6" { return "selfcheck" }
            "7" { return "configure-main" }
            "8" { return "dashboard" }
            "9" { return "uninstall" }
            default { Write-Host "    输入无效，请输入 1 到 9 之间的序号" -ForegroundColor Red }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════
#                    安装相关变量和初始化
# ═══════════════════════════════════════════════════════════════════════
$OPENCLAW_PACKAGE_ORIGINAL = "openclaw"
$OPENCLAW_PACKAGE_ZH = "@qingchencloud/openclaw-zh"
if (-not (Get-Variable -Name OPENCLAW_EDITION -Scope Script -ErrorAction SilentlyContinue)) {
    $script:OPENCLAW_EDITION = ""
}
$env:SHARP_IGNORE_GLOBAL_LIBVIPS = if ($env:SHARP_IGNORE_GLOBAL_LIBVIPS) { $env:SHARP_IGNORE_GLOBAL_LIBVIPS } else { "1" }

if ([string]::IsNullOrWhiteSpace($GitDir)) {
    $GitDir = "C:\OpenClaw"
}

# ─── HTTP/HTTPS 代理初始化 ───
$script:ProxyCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_PROXY_PRIMARY)) { $script:ProxyCandidates += $env:OPENCLAW_PROXY_PRIMARY.Trim() }
if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_PROXY_SECONDARY)) { $script:ProxyCandidates += $env:OPENCLAW_PROXY_SECONDARY.Trim() }
if (-not [string]::IsNullOrWhiteSpace($env:HTTPS_PROXY)) { $script:ProxyCandidates += $env:HTTPS_PROXY.Trim() }
if (-not [string]::IsNullOrWhiteSpace($env:HTTP_PROXY)) { $script:ProxyCandidates += $env:HTTP_PROXY.Trim() }
$script:ProxyCandidates = @($script:ProxyCandidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
$script:SelectedProxy = $null

# ═══════════════════════════════════════════════════════════════════════
#                        代理函数
# ═══════════════════════════════════════════════════════════════════════
function Get-GitHubProxiedUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($GitHubProxy)) { return $Url }
    return "$($GitHubProxy.TrimEnd('/'))/$Url"
}

function Test-ProxyConnectivity {
    param([string]$ProxyUrl)
    if ([string]::IsNullOrWhiteSpace($ProxyUrl)) { return $false }
    $curlExe = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
    if (-not $curlExe) { return $false }
    try {
        $code = & $curlExe -x $ProxyUrl --proxy-insecure -o "NUL" -w "%{http_code}" -s --connect-timeout 10 https://www.google.com 2>&1
        $code = ($code | Out-String).Trim()
        return ($code -eq "200")
    } catch { return $false }
}

function Select-Proxy {
    if ($script:SelectedProxy -ne $null) { return $script:SelectedProxy }
    $curlExe = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
    if (-not $curlExe) {
        $curlExe = Join-Path $env:SystemRoot "System32\curl.exe"
        if (-not (Test-Path $curlExe)) {
            $script:SelectedProxy = ""
            return ""
        }
    }
    if ($script:ProxyCandidates.Count -eq 0) {
        $script:SelectedProxy = ""
        Write-Host "  $script:UI_ICON_INFO 未配置代理环境变量，直连" -ForegroundColor Cyan
        return ""
    }
    Write-Host "  $script:UI_ICON_INFO 检测网络代理..." -ForegroundColor Cyan
    foreach ($candidate in $script:ProxyCandidates) {
        if (Test-ProxyConnectivity -ProxyUrl $candidate) {
            $script:SelectedProxy = $candidate
            Write-Host "  $script:UI_ICON_OK 使用已配置代理" -ForegroundColor Green
            return $candidate
        }
    }
    $script:SelectedProxy = ""
    Write-Host "  $script:UI_ICON_INFO 代理不可用，直连" -ForegroundColor Cyan
    return ""
}

function Get-WingetProxyArg {
    $p = Select-Proxy
    if ([string]::IsNullOrWhiteSpace($p)) { return $null }
    return ($p -replace '^https://', 'http://')
}

function Get-ProxyUriForIwr {
    $p = Get-WingetProxyArg
    if ([string]::IsNullOrWhiteSpace($p)) { return $null }
    return [Uri]$p
}

function Get-WebProxyForNet {
    $proxy = Select-Proxy
    if ([string]::IsNullOrWhiteSpace($proxy)) { return $null }
    if ($proxy -match '^https?://([^:]+):([^@]+)@([^:]+):(\d+)$') {
        $hostPort = "$($Matches[3]):$($Matches[4])"
        $proxyUri = [Uri]"http://$hostPort"
        $wp = [Net.WebProxy]::new($proxyUri)
        $wp.Credentials = [Net.NetworkCredential]::new($Matches[1], $Matches[2])
        return $wp
    }
    if ($proxy -match '^https?://([^:]+):(\d+)$') {
        $proxyUri = [Uri]"http://$($Matches[1]):$($Matches[2])"
        return [Net.WebProxy]::new($proxyUri)
    }
    return $null
}

# ═══════════════════════════════════════════════════════════════════════
#                     包名/版本检测函数
# ═══════════════════════════════════════════════════════════════════════
function Get-OpenClawPackage {
    if ($script:OPENCLAW_EDITION -eq "original") {
        return $OPENCLAW_PACKAGE_ORIGINAL
    }
    return $OPENCLAW_PACKAGE_ZH
}

function Detect-InstalledEdition {
    param([string]$Method = $InstallMethod)
    if ($Method -eq "npm") {
        try {
            $json = & (Get-NpmExe) list -g --depth 0 --json 2>$null
            if ([string]::IsNullOrWhiteSpace($json)) { return "" }
            $obj = $json | ConvertFrom-Json
            if ($obj.dependencies) {
                if ($obj.dependencies.PSObject.Properties[$OPENCLAW_PACKAGE_ORIGINAL]) { return "original" }
                if ($obj.dependencies.PSObject.Properties[$OPENCLAW_PACKAGE_ZH]) { return "zh" }
            }
        } catch { }
    } elseif ($Method -eq "pnpm") {
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            try {
                $out = pnpm list -g 2>$null
                if (-not [string]::IsNullOrWhiteSpace($out)) {
                    if ($out -match '\+\s+openclaw\s') { return "original" }
                    if ($out -match '@qingchencloud/openclaw-zh') { return "zh" }
                }
            } catch { }
        }
    }
    return ""
}

function Test-OpenClawCheckout {
    param([string]$Dir = (Get-Location).Path)
    $pkgJson = Join-Path $Dir "package.json"
    $workspace = Join-Path $Dir "pnpm-workspace.yaml"
    if (-not (Test-Path $pkgJson) -or -not (Test-Path $workspace)) { return $false }
    $content = Get-Content $pkgJson -Raw -ErrorAction SilentlyContinue
    return ($content -match '"name"\s*:\s*"openclaw"')
}

function Choose-InstallMethodInteractive {
    param([string]$DetectedCheckout)
    if ([string]::IsNullOrWhiteSpace($DetectedCheckout)) { return }
    if ($PSBoundParameters.ContainsKey("InstallMethod")) { return }
    if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_INSTALL_METHOD)) { return }
    if ($env:OPENCLAW_NO_PROMPT -eq "1") { return }
    Write-Host ""
    Write-Host "  $script:UI_ICON_ARROW 喔！检测到 OpenClaw 源码目录，请选择安装方式：" -ForegroundColor Yellow
    Write-Host "    $DetectedCheckout" -ForegroundColor Cyan
    Write-Host "    1) 更新源码目录（git）并使用"
    Write-Host "    2) 通过 npm 全局安装"
    Write-Host "    3) 通过 pnpm 全局安装"
    $choice = Read-Host "    Boss，请输入 1、2 或 3"
    switch ($choice) {
        "1" { $script:InstallMethod = "git"; $script:GitDir = $DetectedCheckout }
        "2" { $script:InstallMethod = "npm" }
        "3" { $script:InstallMethod = "pnpm" }
        default { Write-Host "    输入无效，已保留默认安装方式：$InstallMethod" -ForegroundColor Yellow }
    }
}

function Choose-RegistryInteractive {
    if ($Registry -eq "auto") {
        Auto-SelectFastestRegistry
        return
    }
    if ($env:OPENCLAW_NO_PROMPT -eq "1") { return }
    if ($PSBoundParameters.ContainsKey("Registry") -or -not [string]::IsNullOrWhiteSpace($env:OPENCLAW_NPM_REGISTRY)) {
        return
    }
    if ($InstallMethod -ne "npm" -and $InstallMethod -ne "pnpm") {
        return
    }
    Write-Host ""
    Write-Host "  $script:UI_ICON_ARROW Boss，请选择 npm 源（国内用户推荐选 2-4）：" -ForegroundColor Yellow
    Write-Host "    1) npm 官方    2) 淘宝 (taobao)   3) 腾讯云 (tencent)"
    Write-Host "    4) 清华 (tsinghua)  5) 中科大 (ustc)  6) 网易 (163)"
    Write-Host "    7) 华为云 (huawei)  8) 跳过（自动测速）"
    $choice = Read-Host "    Boss，请输入 1-8"
    switch ($choice) {
        "1" { $script:Registry = "npm" }
        "2" { $script:Registry = "taobao" }
        "3" { $script:Registry = "tencent" }
        "4" { $script:Registry = "tsinghua" }
        "5" { $script:Registry = "ustc" }
        "6" { $script:Registry = "163" }
        "7" { $script:Registry = "huawei" }
        default {
            Write-Host "    输入无效，已自动测速选择最佳源" -ForegroundColor Yellow
            Auto-SelectFastestRegistry
        }
    }
}

function Choose-EditionInteractive {
    if ($InstallMethod -ne "npm" -and $InstallMethod -ne "pnpm") {
        return
    }
    $script:OPENCLAW_EDITION = "original"
}

function Detect-InstalledChannel {
    param([string]$Method = $InstallMethod)
    $pkg = if ($script:OPENCLAW_EDITION -eq "original") { $OPENCLAW_PACKAGE_ORIGINAL } else { $OPENCLAW_PACKAGE_ZH }
    $version = $null
    if ($Method -eq "npm") {
        try {
            $json = & (Get-NpmExe) list -g --depth 0 --json 2>$null
            if (-not [string]::IsNullOrWhiteSpace($json)) {
                $obj = $json | ConvertFrom-Json
                if ($obj.dependencies -and $obj.dependencies.PSObject.Properties[$pkg]) {
                    $version = $obj.dependencies.$pkg.version
                }
            }
        } catch { }
    } elseif ($Method -eq "pnpm" -and (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        $out = pnpm list -g 2>$null
        if ($pkg -eq "openclaw") {
            if ($out -match '\+\s+openclaw\s+([^\s\r\n]+)') { $version = $Matches[1] }
        } else {
            if ($out -match '\+\s+@qingchencloud/openclaw-zh\s+([^\s\r\n]+)') { $version = $Matches[1] }
        }
    }
    if ([string]::IsNullOrWhiteSpace($version)) { return "" }
    if ($version -match 'nightly|next|beta|rc|alpha|canary|preview') { return "beta" }
    return "stable"
}



function Test-PackageInstalledGlobally {
    param([string]$Package, [string]$Method = $InstallMethod)
    if ($Method -eq "npm") {
        try {
            $json = & (Get-NpmExe) list -g --depth 0 --json 2>$null
            if ([string]::IsNullOrWhiteSpace($json)) { return $false }
            $obj = $json | ConvertFrom-Json
            return $obj.dependencies -and $obj.dependencies.PSObject.Properties[$Package]
        } catch { return $false }
    } elseif ($Method -eq "pnpm") {
        if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) { return $false }
        $out = pnpm list -g 2>$null
        if ($Package -eq "openclaw") { return $out -match '\+\s+openclaw\s' }
        if ($Package -eq "@qingchencloud/openclaw-zh") { return $out -match '@qingchencloud/openclaw-zh' }
        return $out -match [regex]::Escape($Package)
    }
    return $false
}

function Uninstall-Both-And-ClearCache {
    param([string]$Method = $InstallMethod)
    Write-Host "[*] 正在彻底卸载旧版本并清除缓存..." -ForegroundColor Yellow
    if ($Method -eq "npm") {
        if (Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method $Method) { & (Get-NpmExe) uninstall -g $OPENCLAW_PACKAGE_ORIGINAL >$null 2>&1 }
        if (Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method $Method) { & (Get-NpmExe) uninstall -g $OPENCLAW_PACKAGE_ZH >$null 2>&1 }
        try {
            & (Get-NpmExe) cache clean --force 2>$null | Out-Null
            Write-Host "[OK] npm 缓存已清除。" -ForegroundColor Green
        } catch {
            Write-Host "[!] npm 缓存清除失败，不影响安装。" -ForegroundColor Yellow
        }
    } elseif ($Method -eq "pnpm") {
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            if (Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method $Method) { pnpm remove -g $OPENCLAW_PACKAGE_ORIGINAL >$null 2>&1 }
            if (Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method $Method) { pnpm remove -g $OPENCLAW_PACKAGE_ZH >$null 2>&1 }
            try {
                pnpm store prune 2>$null | Out-Null
                Write-Host "[OK] pnpm 存储已清理。" -ForegroundColor Green
            } catch {
                Write-Host "[!] pnpm 存储清理失败，不影响安装。" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "[OK] 旧版本卸载完成，缓存已清空。" -ForegroundColor Green
}

# npm view 带 registry（国内源加速）— 已修复 $args 保留变量
function Invoke-NpmView {
    param([string]$Package, [string]$Field)
    $viewArgs = @("view", $Package, $Field)
    $registryUrl = Get-RegistryUrl $Registry
    if ($registryUrl) {
        $viewArgs += "--registry"; $viewArgs += $registryUrl
    }
    & (Get-NpmExe) @viewArgs 2>$null
}

function Clear-NpmOpenClawPaths {
    $npmRoot = (& (Get-NpmExe) root -g 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($npmRoot) -or $npmRoot -notmatch "node_modules") { return }
    Get-Item (Join-Path $npmRoot ".openclaw-*") -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $openclawDir = Join-Path $npmRoot "openclaw"
    if (Test-Path $openclawDir) { Remove-Item -Recurse -Force $openclawDir -ErrorAction SilentlyContinue }
}

# ═══════════════════════════════════════════════════════════════════════
#                        npm 源函数
# ═══════════════════════════════════════════════════════════════════════
function Get-RegistryUrl {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return $null }
    if ($Key -match "^https?://") { return $Key.TrimEnd("/") + "/" }
    $map = @{
        "npm"      = "https://registry.npmjs.org/"
        "yarn"     = "https://registry.yarnpkg.com/"
        "tencent"  = "https://mirrors.cloud.tencent.com/npm/"
        "taobao"   = "https://registry.npmmirror.com/"
        "cnpm"     = "https://r.cnpmjs.org/"
        "huawei"   = "https://mirrors.huaweicloud.com/repository/npm/"
        "163"      = "https://mirrors.163.com/npm/"
        "ustc"     = "https://mirrors.ustc.edu.cn/"
        "tsinghua" = "https://mirrors.tuna.tsinghua.edu.cn/"
    }
    return $map[$Key.ToLower()]
}

function Test-RegistrySpeed {
    param([string]$Name, [string]$Url)
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Invoke-WebRequest -Uri "${Url}vue" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $sw.Stop()
        return [int]$sw.ElapsedMilliseconds
    } catch {
        return 9999
    }
}

function Auto-SelectFastestRegistry {
    Write-Host "[*] 正在测速各 npm 源，自动选择最快的一个..." -ForegroundColor Yellow
    $registries = @(
        @{ Name = "taobao";   Url = "https://registry.npmmirror.com/" }
        @{ Name = "tencent";  Url = "https://mirrors.cloud.tencent.com/npm/" }
        @{ Name = "huawei";   Url = "https://mirrors.huaweicloud.com/repository/npm/" }
        @{ Name = "ustc";     Url = "https://mirrors.ustc.edu.cn/" }
        @{ Name = "163";      Url = "https://mirrors.163.com/npm/" }
        @{ Name = "npm";      Url = "https://registry.npmjs.org/" }
    )
    $fastestName = "taobao"
    $fastestTime = 9999
    foreach ($r in $registries) {
        $time = Test-RegistrySpeed -Name $r.Name -Url $r.Url
        if ($Verbose) {
            if ($time -eq 9999) {
                Write-Host "    $($r.Name): 超时" -ForegroundColor Cyan
            } else {
                Write-Host "    $($r.Name): ${time}ms" -ForegroundColor Cyan
            }
        }
        if ($time -lt $fastestTime) {
            $fastestTime = $time
            $fastestName = $r.Name
        }
    }
    if ($fastestTime -eq 9999) {
        Write-Host "[!] 所有 npm 源均超时，回退到默认 taobao 源。" -ForegroundColor Yellow
        $script:Registry = "taobao"
    } else {
        $script:Registry = $fastestName
        Write-Host "[OK] 自动选用最快源：$fastestName（${fastestTime}ms）" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════════════════════════════════════
#                      Node.js 函数
# ═══════════════════════════════════════════════════════════════════════
function Preload-NodePaths {
    $dirs = @(
        "$env:ProgramFiles\nodejs",
        "${env:ProgramFiles(x86)}\nodejs",
        "$env:LOCALAPPDATA\Programs\node",
        "$env:APPDATA\npm"
    )
    if ($env:NVM_HOME -and (Test-Path $env:NVM_HOME)) {
        $nvmCurrent = Join-Path $env:NVM_HOME "current"
        if (Test-Path $nvmCurrent) { $dirs += $nvmCurrent }
    }
    if ($env:SCOOP -and (Test-Path $env:SCOOP)) {
        $scoopShims = Join-Path $env:SCOOP "shims"
        $scoopNode = Join-Path $env:SCOOP "apps\nodejs-lts\current"
        if (Test-Path $scoopShims) { $dirs += $scoopShims }
        if (Test-Path $scoopNode) { $dirs += $scoopNode }
    }
    foreach ($d in $dirs) {
        if ($d -and (Test-Path (Join-Path $d "node.exe"))) {
            $env:Path = "$d;$env:Path"
            return
        }
    }
}

function Get-NpmExe {
    if ($script:NpmExe) { return $script:NpmExe }
    $nodeDir = (Get-Command node -ErrorAction SilentlyContinue).Source | Split-Path
    if ($nodeDir) {
        $npmCmd = Join-Path $nodeDir "npm.cmd"
        if (Test-Path $npmCmd) { $script:NpmExe = $npmCmd; return $npmCmd }
    }
    $script:NpmExe = "npm"
    return "npm"
}

function Get-PnpmExe {
    if ($script:PnpmExe -and (Get-Command $script:PnpmExe -ErrorAction SilentlyContinue)) { return $script:PnpmExe }
    $pnpmCmd = Get-Command pnpm.cmd -ErrorAction SilentlyContinue
    if ($pnpmCmd -and $pnpmCmd.Source) {
        $script:PnpmExe = $pnpmCmd.Source
        return $script:PnpmExe
    }
    $pnpmAny = Get-Command pnpm -ErrorAction SilentlyContinue
    if ($pnpmAny -and $pnpmAny.Source) {
        if ($pnpmAny.Source -like "*.ps1") {
            $candidate = [System.IO.Path]::ChangeExtension($pnpmAny.Source, ".cmd")
            if (Test-Path $candidate) {
                $script:PnpmExe = $candidate
                return $script:PnpmExe
            }
        }
        $script:PnpmExe = $pnpmAny.Source
        return $script:PnpmExe
    }
    try {
        $npmPrefix = (& (Get-NpmExe) config get prefix 2>$null).Trim()
        if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
            $candidate = Join-Path $npmPrefix "pnpm.cmd"
            if (Test-Path $candidate) {
                $script:PnpmExe = $candidate
                return $script:PnpmExe
            }
        }
    } catch { }
    $script:PnpmExe = "pnpm"
    return $script:PnpmExe
}

function Check-Node {
    Preload-NodePaths
    try {
        $nodeVersion = (node -v 2>$null)
        if ($nodeVersion) {
            $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($version -ge 24) {
                Write-Host "[OK] Node.js 已就绪 $nodeVersion，无需重复安装。" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] 已安装 Node.js $nodeVersion，但需要 v24+ 才能运行。" -ForegroundColor Yellow
                return $false
            }
        }
    } catch {
        Write-Host "[!] 未检测到 Node.js，即将自动安装。" -ForegroundColor Yellow
        return $false
    }
    return $false
}

function Install-Node {
    Write-Host "[*] 正在安装 Node.js..." -ForegroundColor Yellow

    # 方式 1: winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  正在尝试 winget 安装方式..." -ForegroundColor Cyan
        # 先尝试重置 winget 源以修复常见的 msstore 证书问题
        try { winget source reset --force 2>$null | Out-Null } catch {}
        winget install OpenJS.NodeJS.LTS --source winget --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Preload-NodePaths
            Write-Host "[OK] 通过 winget 安装 Node.js 成功！" -ForegroundColor Green
            return
        }
        Write-Host "[!] winget 安装失败，尝试其他方式..." -ForegroundColor Yellow
    }

    # 方式 2: Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  正在尝试 Chocolatey 安装方式..." -ForegroundColor Cyan
        choco install nodejs-lts -y
        if ($LASTEXITCODE -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Preload-NodePaths
            Write-Host "[OK] 通过 Chocolatey 安装 Node.js 成功！" -ForegroundColor Green
            return
        }
        Write-Host "[!] Chocolatey 安装失败，尝试其他方式..." -ForegroundColor Yellow
    }

    # 方式 3: Scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "  正在尝试 Scoop 安装方式..." -ForegroundColor Cyan
        scoop install nodejs-lts
        if ($LASTEXITCODE -eq 0) {
            Preload-NodePaths
            Write-Host "[OK] 通过 Scoop 安装 Node.js 成功！" -ForegroundColor Green
            return
        }
        Write-Host "[!] Scoop 安装失败，尝试其他方式..." -ForegroundColor Yellow
    }

    # 方式 4: 直接下载 Node.js MSI 安装包
    Write-Host "  所有包管理器均不可用或失败，尝试直接下载安装..." -ForegroundColor Yellow
    try {
        $arch = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $nodeUrl = "https://nodejs.org/dist/v24.0.2/node-v24.0.2-${arch}.msi"
        $mirrorUrl = "https://npmmirror.com/mirrors/node/v24.0.2/node-v24.0.2-${arch}.msi"
        $msiPath = Join-Path $env:TEMP "node-installer.msi"

        Write-Host "  正在下载 Node.js v24 安装包..." -ForegroundColor Cyan
        $downloadOk = $false
        # 优先尝试国内镜像
        try {
            Invoke-WebRequest -Uri $mirrorUrl -OutFile $msiPath -UseBasicParsing -TimeoutSec 60
            $downloadOk = $true
            Write-Host "  国内镜像下载成功！" -ForegroundColor Cyan
        } catch {
            Write-Host "  国内镜像暂时不可用，改用官方源..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri $nodeUrl -OutFile $msiPath -UseBasicParsing -TimeoutSec 120
                $downloadOk = $true
                Write-Host "  官方源下载成功！" -ForegroundColor Cyan
            } catch {
                Write-Host "  下载失败：$_" -ForegroundColor Red
            }
        }

        if ($downloadOk -and (Test-Path $msiPath)) {
            Write-Host "  正在安装 Node.js，就快好了..." -ForegroundColor Cyan
            $proc = Start-Process msiexec -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -PassThru
            Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
            if ($proc.ExitCode -eq 0) {
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                Preload-NodePaths
                Write-Host "[OK] Node.js 通过安装包安装成功！" -ForegroundColor Green
                return
            } else {
                Write-Host "[!] MSI 安装返回错误码: $($proc.ExitCode)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[!] 直接下载安装失败：$_" -ForegroundColor Red
    }

    # 全部失败
    Write-Host "" -ForegroundColor Red
    Write-Host "[X] 所有自动安装方式均失败，请手动安装 Node.js 24+：" -ForegroundColor Red
    Write-Host "    官方下载: https://nodejs.org/zh-cn/download/" -ForegroundColor Cyan
    Write-Host "    国内镜像: https://npmmirror.com/mirrors/node/" -ForegroundColor Cyan
    Write-Host "    安装完成后重新运行本脚本即可。" -ForegroundColor Cyan
    exit 1
}

function Check-ExistingOpenClaw {
    try {
        $null = Get-Command openclaw -ErrorAction Stop
        Write-Host "[*] 检测到已有 OpenClaw 安装，准备升级..." -ForegroundColor Yellow
        return $true
    } catch {
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════
#                         Git 函数
# ═══════════════════════════════════════════════════════════════════════
function Check-Git {
    try {
        $null = Get-Command git -ErrorAction Stop
        Write-Host "[OK] Git 已就绪，无需重复安装。" -ForegroundColor Green
        return $true
    } catch {
        return $false
    }
}

function Require-Git {
    if (Check-Git) { return }
    Write-Host ""  
    Write-Host "错误: --InstallMethod git 需要先安装 Git。" -ForegroundColor Red
    Write-Host "请安装 Git for Windows：" -ForegroundColor Yellow
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "安装完成后重新运行本脚本即可。" -ForegroundColor Yellow
    exit 1
}

function Download-FileWithFallback {
    param([string]$Url, [string]$OutPath, [long]$MinSizeBytes = 1MB)
    Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
    $proxy = Select-Proxy
    $webProxy = Get-WebProxyForNet
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    $testOk = { if (Test-Path $OutPath) { (Get-Item $OutPath).Length -ge $MinSizeBytes } else { $false } }
    $maxAttempts = 3
    $timeoutSec = 300
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            Write-Host "    下载中 (方法1/5 尝试 $attempt/$maxAttempts)..." -ForegroundColor Blue
            Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing -UserAgent $ua -TimeoutSec $timeoutSec
            if (& $testOk) { return $true }
            Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
        } catch {
            if ($attempt -lt $maxAttempts) { Start-Sleep -Seconds 2 }
        }
    }
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
        try {
            Write-Host "    下载中 (方法2/5 尝试 $attempt/$maxAttempts)..." -ForegroundColor Blue
            $wc = [Net.WebClient]::new()
            $wc.Headers.Add("User-Agent", $ua)
            $wc.DownloadFile($Url, $OutPath)
            if (& $testOk) { return $true }
            Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
        } catch {
            if ($attempt -lt $maxAttempts) { Start-Sleep -Seconds 2 }
        }
    }
    if ($webProxy) {
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
            try {
                Write-Host "    下载中 (方法3/5 尝试 $attempt/$maxAttempts，使用代理)..." -ForegroundColor Blue
                $wc = [Net.WebClient]::new()
                $wc.Proxy = $webProxy
                $wc.Headers.Add("User-Agent", $ua)
                $wc.DownloadFile($Url, $OutPath)
                if (& $testOk) { return $true }
                Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
            } catch {
                if ($attempt -lt $maxAttempts) { Start-Sleep -Seconds 2 }
            }
        }
    }
    $curlExe = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
    if (-not $curlExe) { $curlExe = Join-Path $env:SystemRoot "System32\curl.exe" }
    if ($curlExe -and (Test-Path $curlExe)) {
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
            try {
                Write-Host "    下载中 (方法4/5 尝试 $attempt/$maxAttempts)..." -ForegroundColor Blue
                & $curlExe -L -o $OutPath -s -S --connect-timeout 30 --max-time 600 --user-agent $ua $Url 2>$null
                if (& $testOk) { return $true }
                Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
                if ($attempt -lt $maxAttempts) { Start-Sleep -Seconds 2 }
            } catch { }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($proxy)) {
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
            if ($curlExe -and (Test-Path $curlExe)) {
                Write-Host "    下载中 (方法5/5 尝试 $attempt/$maxAttempts，使用代理)..." -ForegroundColor Blue
                & $curlExe -x $proxy --proxy-insecure -L -o $OutPath -s -S --connect-timeout 30 --max-time 600 --user-agent $ua $Url 2>$null
                if (& $testOk) { return $true }
                Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
                if ($attempt -lt $maxAttempts) { Start-Sleep -Seconds 2 }
            }
        }
    }
    Remove-Item $OutPath -Force -ErrorAction SilentlyContinue
    return $false
}

function Get-GitForWindowsDownloadUrl {
    $apiUrlRaw = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $apiUrl = Get-GitHubProxiedUrl $apiUrlRaw
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    $proxyUri = Get-ProxyUriForIwr
    try {
        $irmParams = @{ Uri = $apiUrl; UseBasicParsing = $true; UserAgent = $ua; ErrorAction = "Stop" }
        if ($proxyUri) { $irmParams["Proxy"] = $proxyUri }
        $release = Invoke-RestMethod @irmParams
    } catch {
        try { $release = Invoke-RestMethod -Uri $apiUrlRaw -UseBasicParsing -UserAgent $ua } catch { return $null }
    }
    $asset = $release.assets | Where-Object { $_.name -match '^Git-\d+\.\d+\.\d+-64-bit\.exe$' } | Select-Object -First 1
    $tag = $release.tag_name
    $ver = ($tag -replace '^v(\d+\.\d+\.\d+).*', '$1')
    $downloadRaw = "https://github.com/git-for-windows/git/releases/download/$tag/Git-$ver-64-bit.exe"
    if ($asset) { $downloadRaw = $asset.browser_download_url }
    return (Get-GitHubProxiedUrl $downloadRaw)
}

function Install-Git {
    Write-Host "[*] 正在安装 Git..." -ForegroundColor Yellow
    $refreshPath = {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        foreach ($p in @("$env:ProgramFiles\Git\cmd", "${env:ProgramFiles(x86)}\Git\cmd")) {
            if ($p -and (Test-Path (Join-Path $p "git.exe"))) { $env:Path = "$p;$env:Path"; break }
        }
    }
    $arch = $env:PROCESSOR_ARCHITECTURE
    $gitExeName = if ($arch -eq "ARM64") { "Git-2.53.0-arm64.exe" } else { "Git-2.53.0-64-bit.exe" }
    $annexUrl = "https://annex.orence.net/git-for-windows/$gitExeName"
    $tempExe = Join-Path $env:TEMP $gitExeName
    Write-Host "  正在下载 $gitExeName ..." -ForegroundColor Cyan
    $ok = Download-FileWithFallback -Url $annexUrl -OutPath $tempExe
    if ($ok -and (Test-Path $tempExe)) {
        Write-Host "  正在静默安装..." -ForegroundColor Cyan
        Start-Process -FilePath $tempExe -ArgumentList "/VERYSILENT" -Wait
        Remove-Item $tempExe -Force -ErrorAction SilentlyContinue
        & $refreshPath
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Host "[OK] 已通过直接下载安装 Git（annex）。" -ForegroundColor Green
            return
        }
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  直接下载失败，尝试 winget..." -ForegroundColor Cyan
        winget settings --enable ProxyCommandLineOptions 2>$null | Out-Null
        $wingetProxy = Get-WingetProxyArg
        if (-not [string]::IsNullOrWhiteSpace($wingetProxy)) {
            winget settings set DefaultProxy $wingetProxy 2>$null | Out-Null
            Write-Host "  已配置 winget 代理" -ForegroundColor Cyan
        }
        $wingetArgs = @("install", "Git.Git", "--source", "winget", "--accept-package-agreements", "--accept-source-agreements")
        if (-not [string]::IsNullOrWhiteSpace($wingetProxy)) {
            $wingetArgs += "--proxy"; $wingetArgs += $wingetProxy
        }
        winget @wingetArgs
        if ($LASTEXITCODE -eq 0) {
            & $refreshPath
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Host "[OK] 已通过 winget 安装 Git！" -ForegroundColor Green
                return
            }
        }
        Write-Host "  winget 安装失败，尝试 gh-proxy..." -ForegroundColor Cyan
    }
    $gitExeNameFallback = if ($arch -eq "ARM64") { "Git-2.53.0-arm64.exe" } else { "Git-2.53.0-64-bit.exe" }
    $gitExeUrl = "https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.1/$gitExeNameFallback"
    $ghProxyUrl = Get-GitHubProxiedUrl $gitExeUrl
    $tempExe = Join-Path $env:TEMP $gitExeNameFallback
    $ok = Download-FileWithFallback -Url $ghProxyUrl -OutPath $tempExe
    if (-not $ok) {
        Write-Host "  gh-proxy 失败，尝试直连 GitHub..." -ForegroundColor Cyan
        $ok = Download-FileWithFallback -Url $gitExeUrl -OutPath $tempExe
    }
    if ($ok -and (Test-Path $tempExe)) {
        Write-Host "  正在静默安装..." -ForegroundColor Cyan
        Start-Process -FilePath $tempExe -ArgumentList "/VERYSILENT" -Wait
        Remove-Item $tempExe -Force -ErrorAction SilentlyContinue
        & $refreshPath
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Host "[OK] 已通过 gh-proxy 安装 Git。" -ForegroundColor Green
            return
        }
    }
    if (-not $ok) { Write-Host "[!] 下载失败，尝试其他方式..." -ForegroundColor Yellow }
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  尝试 Chocolatey 安装 Git..." -ForegroundColor Cyan
        choco install git -y
        if ($LASTEXITCODE -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            foreach ($p in @("$env:ProgramFiles\Git\cmd", "${env:ProgramFiles(x86)}\Git\cmd")) {
                if ($p -and (Test-Path (Join-Path $p "git.exe"))) { $env:Path = "$p;$env:Path"; break }
            }
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Host "[OK] 已通过 Chocolatey 安装 Git！" -ForegroundColor Green
                return
            }
            Write-Host "[!] Chocolatey 安装后未检测到 git 命令，继续尝试..." -ForegroundColor Yellow
        } else {
            Write-Host "[!] Chocolatey 安装返回错误码，继续尝试..." -ForegroundColor Yellow
        }
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "  尝试 Scoop 安装 Git..." -ForegroundColor Cyan
        scoop install git
        if ($LASTEXITCODE -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $scoopGit = Join-Path $env:USERPROFILE "scoop\apps\git\current\cmd"
            if (Test-Path (Join-Path $scoopGit "git.exe")) { $env:Path = "$scoopGit;$env:Path" }
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Host "[OK] 已通过 Scoop 安装 Git！" -ForegroundColor Green
                return
            }
            Write-Host "[!] Scoop 安装后未检测到 git 命令，继续尝试..." -ForegroundColor Yellow
        } else {
            Write-Host "[!] Scoop 安装返回错误码，继续尝试..." -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "错误: 所有方式安装 Git 均失败，请手动安装 Git for Windows：" -ForegroundColor Red
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host "安装完成后重新打开 PowerShell，再运行本脚本。" -ForegroundColor Yellow
    exit 1
}

function Configure-GitForGitHubHttps {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }
    git config --global url."https://github.com/".insteadOf "git@github.com:" 2>$null
    git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" 2>$null
    $sshKeyscan = Get-Command ssh-keyscan -ErrorAction SilentlyContinue
    if ($sshKeyscan) {
        $sshDir = Join-Path $env:USERPROFILE ".ssh"
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
        $knownHosts = Join-Path $sshDir "known_hosts"
        if (-not (Test-Path $knownHosts) -or -not (Select-String -Path $knownHosts -Pattern "github.com" -Quiet -ErrorAction SilentlyContinue)) {
            $keys = cmd /c "ssh-keyscan -t ed25519 github.com 2>nul"
            if ($keys) { $keys | Add-Content -Path $knownHosts -ErrorAction SilentlyContinue }
        }
    }
    Write-Host "[*] 已配置 Git 使用 HTTPS 访问 GitHub（pnpm/npm 依赖 libsignal-node 需要哦）" -ForegroundColor Cyan
}

function Ensure-GitForPnpmNpm {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "[OK] Git 已就绪，无需重复安装。" -ForegroundColor Green
        Configure-GitForGitHubHttps
        return
    }
    Install-Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "[!] Git 安装完成后可能需要重启终端才能生效，请重新打开 PowerShell 后再运行。" -ForegroundColor Red
        Write-Host "请关闭此终端，重新打开并再次运行本安装器。" -ForegroundColor Yellow
        exit 1
    }
    Configure-GitForGitHubHttps
}

# ═══════════════════════════════════════════════════════════════════════
#                      PATH 管理函数
# ═══════════════════════════════════════════════════════════════════════
function Add-PathToUserEnv {
    param([string]$Dir, [string]$Label = "bin")
    if ([string]::IsNullOrWhiteSpace($Dir) -or -not (Test-Path $Dir)) { return $false }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $dirNorm = $Dir.TrimEnd("\")
    if ($userPath -split ";" | Where-Object { $_.TrimEnd("\") -ieq $dirNorm }) { return $false }
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$dirNorm", "User")
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "[OK] 已将 $Label 写入用户 PATH。" -ForegroundColor Green
    return $true
}

function Ensure-NodeNpmOnPath {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($nodeCmd) {
        $nodeDir = Split-Path $nodeCmd.Source -Parent
        Add-PathToUserEnv -Dir $nodeDir -Label "Node.js" | Out-Null
    }
    $npmPrefix = $null
    try { $npmPrefix = (& (Get-NpmExe) config get prefix 2>$null).Trim() } catch { }
    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $npmBin = Join-Path $npmPrefix "bin"
        if (Test-Path $npmBin) {
            Add-PathToUserEnv -Dir $npmBin -Label "npm 全局 bin" | Out-Null
        }
    }
}

function Ensure-PnpmBinOnPath {
    $pnpmHome = $env:PNPM_HOME
    if ([string]::IsNullOrWhiteSpace($pnpmHome)) {
        $pnpmHome = Join-Path $env:LOCALAPPDATA "pnpm"
    }
    if (-not (Test-Path $pnpmHome)) {
        New-Item -ItemType Directory -Force -Path $pnpmHome | Out-Null
    }
    $env:PNPM_HOME = $pnpmHome
    [Environment]::SetEnvironmentVariable("PNPM_HOME", $pnpmHome, "User")
    if (-not (($env:Path -split ";") | Where-Object { $_.TrimEnd("\") -ieq $pnpmHome.TrimEnd("\") })) {
        $env:Path = "$pnpmHome;$env:Path"
    }
    Add-PathToUserEnv -Dir $pnpmHome -Label "pnpm 全局 bin" | Out-Null
}

function Ensure-OpenClawOnPath {
    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        return $true
    }
    $npmPrefix = $null
    try { $npmPrefix = (& (Get-NpmExe) config get prefix 2>$null).Trim() } catch { $npmPrefix = $null }
    $pnpmBin = $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        try { $pnpmBin = (pnpm bin -g 2>$null).Trim() } catch { }
    }
    $binDirs = @()
    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $binDirs += Join-Path $npmPrefix "bin"
    }
    if (-not [string]::IsNullOrWhiteSpace($pnpmBin) -and (Test-Path $pnpmBin)) {
        $binDirs += $pnpmBin
    }
    $userBin = Join-Path $env:USERPROFILE ".local\bin"
    if (Test-Path $userBin) { $binDirs += $userBin }
    foreach ($binDir in $binDirs) {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not ($userPath -split ";" | Where-Object { $_ -ieq $binDir })) {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Host "[!] 已将 $binDir 添加到用户 PATH（若命令未找到请重启终端）。" -ForegroundColor Yellow
        }
        if (Test-Path (Join-Path $binDir "openclaw.cmd")) { return $true }
        if (Test-Path (Join-Path $binDir "openclaw")) { return $true }
    }
    Write-Host "[!] openclaw 尚未在 PATH 中，请重启 PowerShell 或手动添加 npm 全局 bin 目录到 PATH。" -ForegroundColor Yellow
    if ($npmPrefix) {
        Write-Host "预期路径: $npmPrefix\bin" -ForegroundColor Cyan
    } else {
        Write-Host "提示: 运行 \"npm config get prefix\" 可查找 npm 全局路径。" -ForegroundColor Cyan
    }
    return $false
}

# ═══════════════════════════════════════════════════════════════════════
#                   pnpm/npm 安装函数
# ═══════════════════════════════════════════════════════════════════════
function Ensure-Pnpm {
    if (Get-Command pnpm -ErrorAction SilentlyContinue -or (Get-Command pnpm.cmd -ErrorAction SilentlyContinue)) {
        Ensure-PnpmBinOnPath
        $pnpmExe = Get-PnpmExe
        try {
            & $pnpmExe --version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] pnpm 已就绪，无需重复安装。" -ForegroundColor Green
                return
            }
        } catch { }
    }
    Write-Host "[*] 正在通过 npm 安装 pnpm..." -ForegroundColor Yellow
    $pnpmInstallArgs = @("install", "-g", "pnpm@10")
    $registryUrl = Get-RegistryUrl $Registry
    if ($registryUrl) { $pnpmInstallArgs += "--registry"; $pnpmInstallArgs += $registryUrl }
    & (Get-NpmExe) @pnpmInstallArgs
    if ($LASTEXITCODE -eq 0 -and (Get-Command pnpm -ErrorAction SilentlyContinue -or (Get-Command pnpm.cmd -ErrorAction SilentlyContinue))) {
        Ensure-PnpmBinOnPath
        $pnpmExe = Get-PnpmExe
        try {
            & $pnpmExe --version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] pnpm 安装完成。" -ForegroundColor Green
                return
            }
        } catch { }
    }
    if (Get-Command corepack -ErrorAction SilentlyContinue) {
        Write-Host "[*] npm 安装失败，尝试 Corepack..." -ForegroundColor Yellow
        try {
            corepack enable | Out-Null
            corepack prepare pnpm@10 --activate | Out-Null
            if (Get-Command pnpm -ErrorAction SilentlyContinue -or (Get-Command pnpm.cmd -ErrorAction SilentlyContinue)) {
                Ensure-PnpmBinOnPath
                Write-Host "[OK] 已通过 Corepack 安装 pnpm。" -ForegroundColor Green
                return
            }
        } catch { }
    }
    Write-Host "[X] pnpm 安装失败，请检查网络后重试。" -ForegroundColor Red
    exit 1
}

function Install-OpenClawNpm {
    param([string]$Spec)
    if ([string]::IsNullOrWhiteSpace($Spec)) {
        $packageName = Get-OpenClawPackage
        $distTag = "latest"
        $Spec = "$packageName@$distTag"
    }
    $editionLabel = if ($script:OPENCLAW_EDITION -eq "original") { "原版" } else { "中文版" }
    Write-Host "[*] 正在安装 OpenClaw $editionLabel ($Spec)..." -ForegroundColor Yellow
    $installArgs = @("install", "-g", "--no-fund", "--no-audit", $Spec)
    $registryUrl = Get-RegistryUrl $Registry
    if ($registryUrl) { $installArgs += "--registry"; $installArgs += $registryUrl }
    $loglevel = if ($env:OPENCLAW_NPM_LOGLEVEL) { $env:OPENCLAW_NPM_LOGLEVEL } elseif ($Verbose) { "notice" } else { "error" }
    $env:NPM_CONFIG_LOGLEVEL = $loglevel
    $env:NPM_CONFIG_UPDATE_NOTIFIER = "false"
    $env:NPM_CONFIG_FUND = "false"
    $env:NPM_CONFIG_AUDIT = "false"
    try {
        $npmOutput = & (Get-NpmExe) @installArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] OpenClaw $editionLabel 安装完成。" -ForegroundColor Green
            return $true
        }
        $npmOutputStr = $npmOutput | Out-String
        if ($npmOutputStr -match "spawn git" -or $npmOutputStr -match "ENOENT.*git") {
            Write-Host "错误: PATH 中未找到 git！" -ForegroundColor Red
            Write-Host "请安装 Git for Windows 并重新打开 PowerShell：" -ForegroundColor Yellow
            Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
            $npmOutput | ForEach-Object { Write-Host $_ }
            return $false
        }
        if ($npmOutputStr -match "ENOTEMPTY.*openclaw") {
            Write-Host "[!] npm 存在过期缓存目录，清理后重试..." -ForegroundColor Yellow
            Clear-NpmOpenClawPaths
            $npmOutput2 = & (Get-NpmExe) @installArgs 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] OpenClaw $editionLabel 安装完成。" -ForegroundColor Green
                return $true
            }
        }
        if ($npmOutputStr -match "EEXIST") {
            Write-Host "[!] npm 安装遇到了已存在的 openclaw 文件冲突，请移除或使用： npm install -g --force $Spec" -ForegroundColor Red
        } else {
            Write-Host "[!] npm 安装失败，可通过 -Verbose 参数重运查看详细错误。" -ForegroundColor Red
        }
        $npmOutput | ForEach-Object { Write-Host $_ }
        return $false
    } finally {
        $env:NPM_CONFIG_LOGLEVEL = $null
    }
}

function Install-OpenClawPnpm {
    $packageName = Get-OpenClawPackage
    $editionLabel = if ($script:OPENCLAW_EDITION -eq "original") { "原版" } else { "中文版" }
    $distTag = "latest"
    # 始终使用稳定版 latest，不回退测试版
    Ensure-Pnpm
    Ensure-PnpmBinOnPath
    $pnpmExe = Get-PnpmExe
    $spec = "$packageName@$distTag"
    Write-Host "[*] 正在通过 pnpm 安装 OpenClaw $editionLabel ($spec)..." -ForegroundColor Yellow
    $addArgs = @("add", "-g", $spec)
    $registryUrl = Get-RegistryUrl $Registry
    if ($registryUrl) { $addArgs += "--registry"; $addArgs += $registryUrl }
    $pnpmOutput = & $pnpmExe @addArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($pnpmOutput -match "global bin directory.+not in PATH") {
            Ensure-PnpmBinOnPath
            $pnpmOutput = & $pnpmExe @addArgs 2>&1
        }
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] pnpm 安装失败，正在重试..." -ForegroundColor Yellow
        $pnpmOutput2 = & $pnpmExe @addArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[!] pnpm 安装仍失败，切换到 npm 安装..." -ForegroundColor Yellow
            $pnpmOutput2 | ForEach-Object { Write-Host $_ }
            $removeArgs = @("remove", "-g", "openclaw")
            if ($registryUrl) { $removeArgs += "--registry"; $removeArgs += $registryUrl }
            & $pnpmExe @removeArgs 2>$null
            $removeArgs = @("remove", "-g", $packageName)
            if ($registryUrl) { $removeArgs += "--registry"; $removeArgs += $registryUrl }
            & $pnpmExe @removeArgs 2>$null
            if (-not (Install-OpenClawNpm -Spec $spec)) {
                Write-Host "[!] npm 安装失败，清理缓存后重试..." -ForegroundColor Yellow
                Clear-NpmOpenClawPaths
                if (-not (Install-OpenClawNpm -Spec $spec)) { exit 1 }
            }
            Write-Host "[OK] OpenClaw $editionLabel 安装完成（npm 回退）。" -ForegroundColor Green
            return
        }
    }
    if ($distTag -eq "latest") {
        Ensure-PnpmBinOnPath
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
            Write-Host "[!] pnpm 安装后未检测到 openclaw 命令，尝试 npm 回退..." -ForegroundColor Yellow
            & (Get-NpmExe) @("install", "-g", "--no-fund", "--no-audit", $spec) 2>&1 | Out-Null
        }
    }
    Write-Host "[OK] 🦞 OpenClaw $editionLabel 安装完成（pnpm）。" -ForegroundColor Green
}

function Install-OpenClawFromGit {
    param([string]$RepoDir, [switch]$SkipUpdate)
    Require-Git
    Ensure-Pnpm
    $repoUrlRaw = "https://github.com/openclaw-ai/openclaw.git"
    $repoUrl = if ($script:SelectedProxy) {
        $env:HTTPS_PROXY = $env:HTTP_PROXY = $script:SelectedProxy
        $repoUrlRaw
    } else {
        Get-GitHubProxiedUrl $repoUrlRaw
    }
    Write-Host "[*] 正在从 GitHub 安装 OpenClaw ($repoUrl)..." -ForegroundColor Yellow
    if (-not (Test-Path $RepoDir)) {
        $parentDir = Split-Path $RepoDir -Parent
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
        try {
            New-Item -ItemType Directory -Force -Path $RepoDir -ErrorAction Stop | Out-Null
        } catch {
            Write-Host "[!] 无法创建 $RepoDir，可能需要管理员权限。" -ForegroundColor Yellow
            exit 1
        }
        git clone $repoUrl $RepoDir
    }
    if (-not $SkipUpdate) {
        if (-not (git -C $RepoDir status --porcelain 2>$null)) {
            git -C $RepoDir pull --rebase 2>$null
        } else {
        Write-Host "[!] 仓库有未提交的本地修改，将跳过 git pull。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[!] 已禁用 Git 更新，跳过 git pull。" -ForegroundColor Yellow
    }
    Remove-LegacySubmodule -RepoDir $RepoDir
    $pnpmArgs = @("-C", $RepoDir, "install")
    $registryUrl = Get-RegistryUrl $Registry
    if ($registryUrl) { $pnpmArgs += "--registry"; $pnpmArgs += $registryUrl }
    $env:SHARP_IGNORE_GLOBAL_LIBVIPS = if ($env:SHARP_IGNORE_GLOBAL_LIBVIPS) { $env:SHARP_IGNORE_GLOBAL_LIBVIPS } else { "1" }
    pnpm @pnpmArgs
    if (-not (pnpm -C $RepoDir ui:build)) {
        Write-Host "[!] UI 构建失败，继续安装（CLI 仍可用）。" -ForegroundColor Yellow
    }
    pnpm -C $RepoDir build
    $binDir = Join-Path $env:USERPROFILE ".local\bin"
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Force -Path $binDir | Out-Null }
    $cmdPath = Join-Path $binDir "openclaw.cmd"
    $cmdContents = "@echo off`r`nnode ""$RepoDir\dist\entry.js"" %*`r`n"
    Set-Content -Path $cmdPath -Value $cmdContents -NoNewline
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not ($userPath -split ";" | Where-Object { $_ -ieq $binDir })) {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "[!] 已将 $binDir 添加到用户 PATH（若命令未找到请重启终端）。" -ForegroundColor Yellow
    }
    Write-Host "[OK] OpenClaw 包装器已安装到 $cmdPath。" -ForegroundColor Green
    Write-Host "[i] 本源码使用 pnpm — 运行 pnpm install 安装依赖（请勿在仓库内使用 npm install）。" -ForegroundColor Cyan
}

# ═══════════════════════════════════════════════════════════════════════
#                       辅助函数
# ═══════════════════════════════════════════════════════════════════════
function Run-Doctor {
    Write-Host "[*] 正在运行 doctor 迁移配置..." -ForegroundColor Yellow
    try { openclaw doctor --non-interactive } catch { }
    Write-Host "[OK] 迁移完成。" -ForegroundColor Green
}

function Get-LegacyRepoDir {
    if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_GIT_DIR)) { return $env:OPENCLAW_GIT_DIR }
    return "C:\OpenClaw"
}

function Remove-LegacySubmodule {
    param([string]$RepoDir)
    if ([string]::IsNullOrWhiteSpace($RepoDir)) { $RepoDir = Get-LegacyRepoDir }
    $legacyDir = Join-Path $RepoDir "Peekaboo"
    if (Test-Path $legacyDir) {
        Write-Host "[!] 正在移除旧版子模块: $legacyDir" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $legacyDir
    }
}

function Show-InstallPlan {
    param([string]$DetectedCheckout)
    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host "  安装计划" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host "    操作系统    " -NoNewline -ForegroundColor Blue
    Write-Host "Windows" -ForegroundColor White
    Write-Host "    安装方式    " -NoNewline -ForegroundColor Blue
    Write-Host $InstallMethod -ForegroundColor White
    if ($InstallMethod -eq "npm" -or $InstallMethod -eq "pnpm") {
        $pkg = if (-not [string]::IsNullOrWhiteSpace($script:OPENCLAW_EDITION)) {
            Get-OpenClawPackage
        } else {
            "openclaw 或 $OPENCLAW_PACKAGE_ZH（待选择）"
        }
        $distTag = "latest"
        Write-Host "    安装包      " -NoNewline -ForegroundColor Blue
        Write-Host "$pkg@$distTag" -ForegroundColor White
    } else {
        Write-Host "    Git 目录    " -NoNewline -ForegroundColor Blue
        Write-Host $GitDir -ForegroundColor White
        Write-Host "    Git 更新    " -NoNewline -ForegroundColor Blue
        Write-Host $(if ($NoGitUpdate) { "已禁用" } else { "已启用" }) -ForegroundColor White
    }
    if ($Registry) {
        $regUrl = Get-RegistryUrl -Key $Registry
        if ($regUrl) {
            Write-Host "    npm 源      " -NoNewline -ForegroundColor Blue
            Write-Host "$Registry ($regUrl)" -ForegroundColor White
        } else {
            Write-Host "    npm 源      " -NoNewline -ForegroundColor Blue
            Write-Host $Registry -ForegroundColor White
        }
    }
    if ($GitHubProxy) {
        Write-Host "    GitHub 代理  " -NoNewline -ForegroundColor Blue
        Write-Host $GitHubProxy -ForegroundColor White
    }
    if ($DetectedCheckout) {
        Write-Host "    检测仓库    " -NoNewline -ForegroundColor Blue
        Write-Host $DetectedCheckout -ForegroundColor White
    }
    if ($DryRun) {
        Write-Host "    模拟运行    " -NoNewline -ForegroundColor Blue
        Write-Host "是" -ForegroundColor Yellow
    }
    Write-Host "  $script:UI_LINE" -ForegroundColor Cyan
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
#              环境变量覆盖 + 系统信息 + 管理员检查
# ═══════════════════════════════════════════════════════════════════════
function Apply-EnvOverrides {
    if (-not $PSBoundParameters.ContainsKey("InstallMethod")) {
        if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_INSTALL_METHOD)) { $script:InstallMethod = $env:OPENCLAW_INSTALL_METHOD }
    }
    if (-not $PSBoundParameters.ContainsKey("GitDir")) {
        if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_GIT_DIR)) { $script:GitDir = $env:OPENCLAW_GIT_DIR }
    }
    if (-not $PSBoundParameters.ContainsKey("Registry")) {
        if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_NPM_REGISTRY)) { $script:Registry = $env:OPENCLAW_NPM_REGISTRY }
    }
    if (-not $PSBoundParameters.ContainsKey("GitHubProxy")) {
        if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_GITHUB_PROXY)) { $script:GitHubProxy = $env:OPENCLAW_GITHUB_PROXY }
    }
    if (-not $PSBoundParameters.ContainsKey("NoGitUpdate")) {
        if ($env:OPENCLAW_GIT_UPDATE -eq "0") { $script:NoGitUpdate = $true }
    }
    if (-not $PSBoundParameters.ContainsKey("DryRun")) {
        if ($env:OPENCLAW_DRY_RUN -eq "1") { $script:DryRun = $true }
    }
    if (-not $PSBoundParameters.ContainsKey("Verbose")) {
        if ($env:OPENCLAW_VERBOSE -eq "1") { $script:Verbose = $true }
    }
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-AdminExecutionPolicy {
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
        Write-Host "[*] 已设置执行策略 Process=Bypass（当前会话）" -ForegroundColor Cyan
    } catch {
        Write-Host "[!] Process 执行策略设置失败: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    $execPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($execPolicy -eq "Restricted" -or $execPolicy -eq "AllSigned") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "[*] 已设置执行策略 CurrentUser=RemoteSigned（持久）" -ForegroundColor Cyan
        } catch {
            Write-Host "[!] CurrentUser 执行策略设置失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Show-SystemInfo {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "错误: 需要 PowerShell 5 或更高版本才能运行此脚本。" -ForegroundColor Red
        exit 1
    }
    $osInfo = $null; $csInfo = $null; $cpuInfo = $null
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $csInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $cpuInfo = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1)
    } catch { }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ([string]::IsNullOrWhiteSpace($arch)) { $arch = "未知" }
    $osName = if ($osInfo) { $osInfo.Caption.Trim() } else { "Windows" }
    $osVer = if ($osInfo) { $osInfo.Version } else { "" }
    $osBuild = if ($osInfo) { $osInfo.BuildNumber } else { "" }
    $psVer = $PSVersionTable.PSVersion.ToString()
    $cpuName = if ($cpuInfo) { ($cpuInfo.Name -replace '\s+', ' ').Trim() } else { "" }
    $memGB = if ($csInfo -and $csInfo.TotalPhysicalMemory) {
        [math]::Round($csInfo.TotalPhysicalMemory / 1GB, 1)
    } else { $null }
    Write-Host "  $script:UI_ICON_OK 检测到 Windows，开始运行。" -ForegroundColor Green
    Write-Host "    系统      " -NoNewline -ForegroundColor Blue
    Write-Host $osName -ForegroundColor White
    if ($osVer) {
        Write-Host "    版本      " -NoNewline -ForegroundColor Blue
        Write-Host "$osVer (Build $osBuild)" -ForegroundColor White
    }
    Write-Host "    架构      " -NoNewline -ForegroundColor Blue
    Write-Host $arch -ForegroundColor White
    Write-Host "    PowerShell " -NoNewline -ForegroundColor Blue
    Write-Host $psVer -ForegroundColor White
    if ($cpuName) {
        Write-Host "    CPU       " -NoNewline -ForegroundColor Blue
        Write-Host $cpuName -ForegroundColor White
    }
    if ($null -ne $memGB) {
        Write-Host "    内存      " -NoNewline -ForegroundColor Blue
        Write-Host "${memGB} GB" -ForegroundColor White
    }
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
#                   安装主流程（内嵌）
# ═══════════════════════════════════════════════════════════════════════
function Invoke-InstallFlow {
    if ($TestProxy) {
        Write-Host ""
        Write-UISection -Title "代理测试模式"
        $proxy = Select-Proxy
        if ([string]::IsNullOrWhiteSpace($proxy)) {
            Write-Host "  $script:UI_ICON_WARN 代理不可用" -ForegroundColor Yellow
            Write-Host "  手动测试命令：" -ForegroundColor Cyan
            Write-Host '  curl -x "PROXY" --proxy-insecure -w "%{http_code}" -o NUL -s https://www.google.com' -ForegroundColor Cyan
        } else {
            Write-Host "  $script:UI_ICON_OK 当前代理: $proxy" -ForegroundColor Green
        }
        Write-Host ""
        return
    }

    $detectedCheckout = $null
    if (Test-OpenClawCheckout) { $detectedCheckout = (Get-Location).Path }
    if ($detectedCheckout -and -not $PSBoundParameters.ContainsKey("InstallMethod") -and [string]::IsNullOrWhiteSpace($env:OPENCLAW_INSTALL_METHOD)) {
        Choose-InstallMethodInteractive -DetectedCheckout $detectedCheckout
        if ($InstallMethod -eq "git") { $script:GitDir = $detectedCheckout }
    }

    if ($InstallMethod -ne "npm" -and $InstallMethod -ne "pnpm" -and $InstallMethod -ne "git") {
        Write-Host "错误: 无效的 -InstallMethod（请使用 npm、pnpm 或 git）" -ForegroundColor Red
        exit 2
    }

    if ($InstallMethod -eq "npm" -or $InstallMethod -eq "pnpm") {
        Preload-NodePaths
        Choose-RegistryInteractive
        Choose-EditionInteractive
        if ([string]::IsNullOrWhiteSpace($script:OPENCLAW_EDITION)) { $script:OPENCLAW_EDITION = "original" }
    }

    Show-InstallPlan -DetectedCheckout $detectedCheckout

    if ($DryRun) {
        Write-Host "  $script:UI_ICON_OK 模拟运行完成（未做任何更改）" -ForegroundColor Green
        return
    }

    Select-Proxy | Out-Null
    Remove-LegacySubmodule -RepoDir $GitDir
    $isUpgrade = Check-ExistingOpenClaw

    Write-UISection -Title "步骤 1/3  准备环境" -Step "Node.js · Git · PATH"
    if (-not (Check-Node)) {
        Install-Node
        if (-not (Check-Node)) {
            Write-Host "错误: Node.js 安装完成后可能需要重启终端才能生效，请重启后再运行本脚本。" -ForegroundColor Red
            exit 1
        }
    }
    Ensure-NodeNpmOnPath
    if ($InstallMethod -eq "pnpm" -or $InstallMethod -eq "npm") {
        Ensure-GitForPnpmNpm
    }

    Write-UISection -Title "步骤 2/3  安装 OpenClaw" -Step "$InstallMethod"
    $finalGitDir = $null

    if ($InstallMethod -eq "git") {
        $hasNpmOpenclaw = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method "npm"
        $hasNpmZh = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method "npm"
        if ($hasNpmOpenclaw -or $hasNpmZh) {
            Write-Host "[*] 正在移除 npm 全局安装（切换到 git）..." -ForegroundColor Yellow
            & (Get-NpmExe) uninstall -g openclaw 2>$null
            & (Get-NpmExe) uninstall -g $OPENCLAW_PACKAGE_ZH 2>$null
        }
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            $hasPnpmOpenclaw = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method "pnpm"
            $hasPnpmZh = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method "pnpm"
            if ($hasPnpmOpenclaw -or $hasPnpmZh) {
                Write-Host "[*] 正在移除 pnpm 全局安装（切换到 git）..." -ForegroundColor Yellow
                pnpm remove -g openclaw 2>$null
                pnpm remove -g $OPENCLAW_PACKAGE_ZH 2>$null
            }
        }
        $finalGitDir = $GitDir
        Install-OpenClawFromGit -RepoDir $GitDir -SkipUpdate:$NoGitUpdate
    } elseif ($InstallMethod -eq "pnpm") {
        $hasNpmOpenclaw = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method "npm"
        $hasNpmZh = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method "npm"
        if ($hasNpmOpenclaw -or $hasNpmZh) {
            Write-Host "[*] 正在移除 npm 全局安装（切换到 pnpm）..." -ForegroundColor Yellow
            & (Get-NpmExe) uninstall -g openclaw 2>$null
            & (Get-NpmExe) uninstall -g $OPENCLAW_PACKAGE_ZH 2>$null
        }
        $installedEdition = Detect-InstalledEdition -Method "pnpm"
        if (-not [string]::IsNullOrWhiteSpace($installedEdition)) {
            $fromLabel = if ($installedEdition -eq "original") { "原版" } else { "中文版" }
            $toLabel = if ($script:OPENCLAW_EDITION -eq "original") { "原版" } else { "中文版" }
            if ($installedEdition -eq $script:OPENCLAW_EDITION) {
                Write-Host "[*] 检测到已安装相同版本（$fromLabel），将直接升级。" -ForegroundColor Cyan
            } else {
                Write-Host "[*] 检测到需切换版本（$fromLabel → $toLabel），需先卸载旧版。" -ForegroundColor Yellow
                Uninstall-Both-And-ClearCache -Method "pnpm"
            }
        }
        Install-OpenClawPnpm
    } else {
        if (Get-Command pnpm -ErrorAction SilentlyContinue) {
            $hasPnpmOpenclaw = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ORIGINAL -Method "pnpm"
            $hasPnpmZh = Test-PackageInstalledGlobally -Package $OPENCLAW_PACKAGE_ZH -Method "pnpm"
            if ($hasPnpmOpenclaw -or $hasPnpmZh) {
            Write-Host "[*] 正在移除 pnpm 全局安装（切换到 npm）..." -ForegroundColor Yellow
                pnpm remove -g openclaw 2>$null
                pnpm remove -g $OPENCLAW_PACKAGE_ZH 2>$null
            }
        }
        $installedEdition = Detect-InstalledEdition -Method "npm"
        if (-not [string]::IsNullOrWhiteSpace($installedEdition)) {
            $fromLabel = if ($installedEdition -eq "original") { "原版" } else { "中文版" }
            $toLabel = if ($script:OPENCLAW_EDITION -eq "original") { "原版" } else { "中文版" }
            if ($installedEdition -eq $script:OPENCLAW_EDITION) {
                Write-Host "[*] 检测到已安装相同版本（$fromLabel），将直接升级。" -ForegroundColor Cyan
            } else {
                Write-Host "[*] 检测到需切换版本（$fromLabel → $toLabel），需先卸载旧版。" -ForegroundColor Yellow
                Uninstall-Both-And-ClearCache -Method "npm"
            }
        }
        $userOpenClaw = Join-Path $env:USERPROFILE ".local\bin\openclaw.cmd"
        if (Test-Path $userOpenClaw) {
                Write-Host "[*] 正在移除 git 包装器（切换到包管理器安装）..." -ForegroundColor Yellow
            Remove-Item $userOpenClaw -Force
        }
        $pkg = Get-OpenClawPackage
        $distTag = "latest"
        $spec = "$pkg@$distTag"
        if (-not (Install-OpenClawNpm -Spec $spec)) {
            Write-Host "[!] npm 安装失败，清理缓存后重试..." -ForegroundColor Yellow
            Clear-NpmOpenClawPaths
            if (-not (Install-OpenClawNpm -Spec $spec)) { exit 1 }
        }
        if (-not (Ensure-OpenClawOnPath)) {
            Write-Host "[!] $pkg@$distTag 安装后未找到；正在重试 @latest" -ForegroundColor Yellow
            Clear-NpmOpenClawPaths
            Install-OpenClawNpm -Spec "$pkg@latest" | Out-Null
        }
    }

    if (-not (Ensure-OpenClawOnPath)) {
        Write-UIWarn "安装完成，但 openclaw 尚未在 PATH 中"
        Write-Host "  请打开新终端并运行 " -NoNewline -ForegroundColor Cyan
        Write-Host "openclaw doctor" -ForegroundColor Cyan
        return
    }

    if ($isUpgrade -or $InstallMethod -eq "git") { Run-Doctor }

    $installedVersion = $null
    try { $installedVersion = (openclaw --version 2>$null).Trim() } catch { $installedVersion = $null }
    if (-not $installedVersion) {
        try {
            $npmList = & (Get-NpmExe) list -g --depth 0 --json 2>$null | ConvertFrom-Json
            if ($npmList -and $npmList.dependencies) {
                $deps = $npmList.dependencies
                if ($deps.openclaw -and $deps.openclaw.version) { $installedVersion = $deps.openclaw.version }
                elseif ($deps.'@qingchencloud/openclaw-zh' -and $deps.'@qingchencloud/openclaw-zh'.version) { $installedVersion = $deps.'@qingchencloud/openclaw-zh'.version }
            }
        } catch { $installedVersion = $null }
    }

    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Green
    Write-Host "  " -NoNewline
    Write-Host "  🦞 OpenClaw 安装成功！" -NoNewline -ForegroundColor Green
    if ($installedVersion) { Write-Host "  ($installedVersion)" -ForegroundColor White } else { Write-Host "" }
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Green
    Write-Host ""
    if ($isUpgrade) {
        $updateMessages = @(
            "🦞 OpenClaw 升级完成！我变得更强大了！",
            "升级完成！带着全新功能回来啦！",
            "升级完毕！学到了不少新本领！",
            "自我进化完成！感觉状态绝佳！",
            "升级完毕！现在更强劲了！"
        )
        Write-Host (Get-Random -InputObject $updateMessages) -ForegroundColor Cyan
    } else {
        $completionMessages = @(
            "🦞 安装完成！OpenClaw 准备就绪，随时待命！",
            "安装完成！欢迎来到 AI 世界！",
            "初次见面！已准备就绪，开始探索吧！",
            "安装完毕！让我们一起开启智能协作之旅！",
            "🦞 部署完成！AI 助手已在后台待命！"
        )
        Write-Host (Get-Random -InputObject $completionMessages) -ForegroundColor Cyan
    }
    Write-Host ""
    if ($InstallMethod -eq "git") {
        Write-Host "  源码目录  " -NoNewline -ForegroundColor Blue
        Write-Host $finalGitDir -ForegroundColor Cyan
    }
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "  相关链接" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host "    官方文档      " -NoNewline -ForegroundColor Blue
    Write-Host "https://docs.openclaw.ai/zh-CN" -ForegroundColor Cyan
    Write-Host "    OpenClawCN    " -NoNewline -ForegroundColor Blue
    Write-Host "https://openclaw.qt.cool/" -ForegroundColor Cyan
    Write-Host "  $script:UI_LINE" -ForegroundColor Blue
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════
#                   部署主流程（内嵌）
# ═══════════════════════════════════════════════════════════════════════
function Invoke-DeployFlow {
    Write-Host ""
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host "  🦞 OpenClaw 部署配置器  " -NoNewline -ForegroundColor Cyan
    Write-Host "基于官方源码引导流程" -ForegroundColor Blue
    Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-OpenClawInstalled)) {
        Write-UIWarn "未检测到 OpenClaw，请先完成安装。"
        Write-Host "    重新运行脚本，选 1 或 2 安装即可。" -ForegroundColor Cyan
        return
    }

    $openclawVersion = $null
    try { $openclawVersion = (openclaw --version 2>$null).Trim() } catch { }
    if ($openclawVersion) { Write-UIOk "🦞 检测到 OpenClaw 已安装（$openclawVersion）" } else { Write-UIOk "🦞 检测到 OpenClaw 已安装" }

    $provider = Select-Provider
    $apiKeyValue = Read-ApiKey -Provider $provider
    $workDir = Read-Workspace

    Write-Host ""
    Write-Host "  $script:UI_LINE" -ForegroundColor Yellow
    Write-Host "  即将开始部署，请确认以上信息" -ForegroundColor Yellow
    Write-Host "  $script:UI_LINE" -ForegroundColor Yellow
    Write-Host "    提供商: $($provider.Name)  |  模型: $($provider.DefaultModel)  |  目录: $workDir" -ForegroundColor Blue
    Write-Host ""
    $confirm = Read-Host "    确认开始部署？(Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") {
        Write-UIWarn "已取消部署，随时重新运行脚本即可。"
        return
    }

    $deploySuccess = Invoke-Deployment -Provider $provider -Key $apiKeyValue -WorkDir $workDir
    if ($deploySuccess) {
        Invoke-DoctorCheck
        Invoke-GatewayRestart
        Invoke-Dashboard
    }
    Show-DeploySummary -Provider $provider -WorkDir $workDir -DeploySuccess $deploySuccess
}

# ═══════════════════════════════════════════════════════════════════════
#                      统一入口
# ═══════════════════════════════════════════════════════════════════════
function Main-Setup {
    # 如果通过命令行指定了模式，直接进入
    if (-not [string]::IsNullOrWhiteSpace($script:InitialMode)) {
        $mode = $script:InitialMode
    }

    while ($true) {
        $mode = Show-WelcomeMenu

        switch ($mode) {
            "full" {
                # ══ 模式 1: 安装 + 部署（先收集部署信息，再安装，最后部署） ══
                Write-UISection -Title "配置部署信息" -Step "先收集，安装完成后自动部署"

                $provider = Select-Provider
                $apiKeyVal = Read-ApiKey -Provider $provider
                $workDir = Read-Workspace

                Write-Host ""
                Write-Host "  $script:UI_LINE" -ForegroundColor Yellow
                Write-Host "  即将开始 安装 + 部署，Boss 请确认以上信息" -ForegroundColor Yellow
                Write-Host "  $script:UI_LINE" -ForegroundColor Yellow
                Write-Host "    提供商: $($provider.Name)  |  模型: $($provider.DefaultModel)" -ForegroundColor Blue
                Write-Host "    工作目录: $workDir" -ForegroundColor Blue
                Write-Host ""
                $confirm = Read-Host "    确认开始？(Y/n)"
                if ($confirm -eq "n" -or $confirm -eq "N") {
                    Write-UIWarn "已取消，随时重新运行脚本即可。"
                    break
                }

                # 检查管理员权限
                if (-not (Test-IsAdmin)) {
                    Write-Host ""
                    Write-UIWarn "OpenClaw 安装需要管理员权限。"
                    Write-Host "    请右键 PowerShell → 以管理员身份运行，然后重新执行此脚本。" -ForegroundColor Cyan
                    Write-Host "    或双击 'OpenClaw一键安装部署.bat' 自动提权启动" -ForegroundColor Cyan
                    Write-Host ""
                    break
                }
                Set-AdminExecutionPolicy

                Write-Host ""
                Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
                Write-Host "  🦞 OpenClaw 安装器（安装 + 自动部署）  " -NoNewline -ForegroundColor Cyan
                Write-Host "Windows 版" -ForegroundColor Blue
                Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
                Write-Host ""

                Show-SystemInfo
                Apply-EnvOverrides
                Invoke-InstallFlow

                # 安装完成后自动部署
                if (Test-OpenClawInstalled) {
                    Write-UISection -Title "开始自动部署" -Step "配置模型/网关/项目空间"
                    $deploySuccess = Invoke-Deployment -Provider $provider -Key $apiKeyVal -WorkDir $workDir
                    if ($deploySuccess) {
                        Invoke-DoctorCheck
                        Invoke-GatewayRestart
                        Invoke-Dashboard
                    }
                    Show-DeploySummary -Provider $provider -WorkDir $workDir -DeploySuccess $deploySuccess
                } else {
                    Write-UIWarn "OpenClaw 安装未成功，已跳过部署步骤。"
                    Write-Host "    解决安装问题后重新运行本脚本即可。" -ForegroundColor Cyan
                }
                return
            }
            "install" {
                # ══ 模式 2: 仅安装 ══
                if (-not (Test-IsAdmin)) {
                    Write-Host ""
                    Write-UIWarn "OpenClaw 安装需要管理员权限。"
                    Write-Host "    请右键 PowerShell → 以管理员身份运行，然后重新执行此脚本。" -ForegroundColor Cyan
                    Write-Host "    或双击 'OpenClaw一键安装部署.bat' 自动提权启动" -ForegroundColor Cyan
                    Write-Host ""
                    break
                }
                Set-AdminExecutionPolicy

                Write-Host ""
                Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
                Write-Host "  🦞 OpenClaw 安装器（仅安装）  " -NoNewline -ForegroundColor Cyan
                Write-Host "Windows 版" -ForegroundColor Blue
                Write-Host "  $script:UI_LINE_WIDE" -ForegroundColor Cyan
                Write-Host ""

                Show-SystemInfo
                Apply-EnvOverrides
                Invoke-InstallFlow
                return
            }
            "deploy" {
                # ══ 模式 3: 仅部署（无需管理员权限）══
                Invoke-DeployFlow
                return
            }
            "configure-model" {
                # ══ 模式 4: 更换模型 ══
                Invoke-ConfigureModel
                # 执行完回到 while 循环，重新显示主菜单
            }
            "channels" {
                # ══ 模式 5: 添加 Channels ══
                Show-ChannelsMenu
                # 执行完回到 while 循环
            }
            "selfcheck" {
                # ══ 模式 6: 自检并尝试修复 ══
                Invoke-SelfCheck
                # 执行完回到 while 循环
            }
            "configure-main" {
                # ══ 模式 7: 进入配置页面 ══
                Invoke-ConfigureMain
                # 执行完回到 while 循环
            }
            "dashboard" {
                # ══ 模式 8: 打开主页面 ══
                Invoke-Dashboard
                # 执行完回到 while 循环
            }
            "uninstall" {
                # ══ 模式 9: 完全卸载 OpenClaw ══
                Invoke-Uninstall
                return
            }
        }
    }
}

# 运行统一入口
Main-Setup
