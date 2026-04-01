#!/bin/bash
# Usage: curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash
set -euo pipefail

# 强制 UTF-8 环境，确保 curl | bash 管道执行时中文显示正常
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ═══════════════════════════════════════════════════════════════════════
# OpenClaw 全自动安装部署脚本 - MacOS 版
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

# 终端颜色（NO_COLOR 或 TERM=dumb 时禁用）
use_color() {
    [[ -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]
}

# 检测终端背景色（macOS Terminal/iTerm2 均支持 COLORFGBG；macOS 深/浅色模式用 osascript 判断）
_is_light_bg() {
    # 1. COLORFGBG 格式：前景;背景，背景数字 >= 8 通常为浅色（iTerm2/部分终端设置此变量）
    if [[ -n "${COLORFGBG:-}" ]]; then
        local bg_code
        bg_code="${COLORFGBG##*;}"
        if [[ "$bg_code" -ge 8 ]] 2>/dev/null; then
            return 0
        else
            return 1
        fi
    fi
    # 2. macOS：通过 osascript 查询系统外观（深色模式返回1 = 深色背景）
    if [[ "$(uname -s)" == "Darwin" ]] && command -v osascript &>/dev/null; then
        local appearance
        appearance=$(osascript -e 'tell application "System Events" to return dark mode of appearance preferences' 2>/dev/null || echo "false")
        [[ "$appearance" == "false" ]] && return 0  # 浅色模式
        return 1                                      # 深色模式
    fi
    # 3. 兜底：默认深色
    return 1
}

if use_color; then
    BOLD='\033[1m'
    NC='\033[0m'
    if _is_light_bg; then
        # 浅色/白色背景主题 —— 使用深色、高饱和度颜色确保可读性
        ACCENT='\033[38;2;200;30;30m'        # 深红
        ACCENT_BRIGHT='\033[38;2;220;60;60m' # 中红
        INFO='\033[38;2;50;80;160m'          # 深蓝
        SUCCESS='\033[38;2;0;140;100m'       # 深青绿
        WARN='\033[38;2;180;100;0m'          # 深橙/棕
        ERROR='\033[38;2;180;20;30m'         # 深红
        MUTED='\033[38;2;80;80;100m'         # 深灰蓝
        HEADER='\033[38;2;30;30;30m'         # 近纯黑 — 浅色背景下欢迎页主体字
        HEADER_SUB='\033[38;2;70;70;90m'     # 深灰 — 浅色背景下次要说明行
        TAGLINE='\033[38;2;0;120;80m'        # 深绿 — 浅色背景下标语行
    else
        # 深色背景主题（默认）
        ACCENT='\033[38;2;255;77;77m'        # coral-bright  #ff4d4d
        # shellcheck disable=SC2034
        ACCENT_BRIGHT='\033[38;2;255;110;110m' # lighter coral
        INFO='\033[38;2;136;146;176m'        # text-secondary #8892b0
        SUCCESS='\033[38;2;0;229;204m'       # cyan-bright   #00e5cc
        WARN='\033[38;2;255;176;32m'         # amber
        ERROR='\033[38;2;230;57;70m'         # coral-mid     #e63946
        MUTED='\033[38;2;145;155;178m'       # text-muted（亮化）#919bb2
        HEADER='\033[38;2;220;220;220m'      # 近纯白灰 — 深色背景下欢迎页主体字
        HEADER_SUB='\033[38;2;160;170;195m'  # 中亮灰 — 深色背景下欢迎页次要说明行
        TAGLINE='\033[38;2;80;220;180m'      # 薄荷绿 — 深色背景下标语行
    fi
else
    BOLD='' ACCENT='' ACCENT_BRIGHT='' INFO='' SUCCESS='' WARN='' ERROR='' MUTED='' HEADER='' HEADER_SUB='' TAGLINE='' NC=''
fi

# 分隔线（非 gum 模式）
ui_hr() {
    if [[ -n "$GUM" ]]; then
        return 0
    fi
    local width="${1:-60}"
    local char="${2:-─}"
    if use_color; then
        echo -e "${MUTED}$(printf '%*s' "$width" '' | tr ' ' "$char")${NC}"
    else
        printf '%*s\n' "$width" '' | tr ' ' "$char"
    fi
}


ORIGINAL_PATH="${PATH:-}"

TMPFILES=()
cleanup_tmpfiles() {
    local f
    for f in "${TMPFILES[@]:-}"; do
        rm -rf "$f" 2>/dev/null || true
    done
}
trap cleanup_tmpfiles EXIT

mktempfile() {
    local f
    f="$(mktemp)"
    TMPFILES+=("$f")
    echo "$f"
}

DOWNLOADER=""
GITHUB_PROXY="${OPENCLAW_GITHUB_PROXY:-}"

# HTTP/HTTPS 代理：优先主节点，回退备节点，最后直连（不在脚本中硬编码账号/密码/IP）
# 请通过环境变量传入:
#   OPENCLAW_PROXY_SINGAPORE / OPENCLAW_PROXY_HONGKONG
# 或:
#   OPENCLAW_PROXY_PRIMARY / OPENCLAW_PROXY_SECONDARY
PROXY_SINGAPORE="${OPENCLAW_PROXY_SINGAPORE:-${OPENCLAW_PROXY_PRIMARY:-}}"
PROXY_HONGKONG="${OPENCLAW_PROXY_HONGKONG:-${OPENCLAW_PROXY_SECONDARY:-}}"
PROXY_SINGAPORE_LABEL="${OPENCLAW_PROXY_SINGAPORE_LABEL:-新加坡}"
PROXY_HONGKONG_LABEL="${OPENCLAW_PROXY_HONGKONG_LABEL:-香港}"
SELECTED_PROXY=""
SELECTED_PROXY_LABEL=""
PROXY_CHECK_DONE=0

run_sensitive_cmd() {
    local xtrace_on=0
    case "$-" in
        *x*)
            xtrace_on=1
            set +x
            ;;
    esac
    "$@"
    local status=$?
    if [[ "$xtrace_on" == "1" ]]; then
        set -x
    fi
    return "$status"
}

mask_url_for_log() {
    local raw="${1:-}"
    if [[ -z "$raw" ]]; then
        echo ""
        return 0
    fi

    local scheme rest hostport host port masked_host has_auth=0
    scheme="${raw%%://*}"
    rest="${raw#*://}"
    if [[ "$rest" == "$raw" ]]; then
        scheme="url"
        rest="$raw"
    fi
    if [[ "$rest" == *"@"* ]]; then
        has_auth=1
        rest="${rest#*@}"
    fi
    hostport="${rest%%/*}"
    host="${hostport%%:*}"
    if [[ "$hostport" == "$host" ]]; then
        port=""
    else
        port="${hostport##*:}"
    fi

    if [[ ${#host} -le 4 ]]; then
        masked_host="***"
    else
        masked_host="${host:0:2}***${host: -2}"
    fi

    if [[ -n "$port" && "$port" != "$host" ]]; then
        masked_host="${masked_host}:${port}"
    fi

    if [[ "$has_auth" == "1" ]]; then
        echo "${scheme}://***@${masked_host}"
    else
        echo "${scheme}://${masked_host}"
    fi
}

test_proxy_connectivity() {
    local proxy="${1:-}"
    [[ -z "$proxy" ]] && return 1
    local code=""
    code="$(run_sensitive_cmd curl -x "$proxy" --proxy-insecure -o /dev/null -w "%{http_code}" -s --connect-timeout 8 https://www.google.com 2>/dev/null)" || true
    [[ "$code" == "200" ]]
}

select_proxy() {
    [[ "$PROXY_CHECK_DONE" == "1" ]] && return 0
    PROXY_CHECK_DONE=1
    if ! command -v curl &>/dev/null; then
        SELECTED_PROXY=""
        return 0
    fi
    if [[ -z "$PROXY_SINGAPORE" && -z "$PROXY_HONGKONG" ]]; then
        SELECTED_PROXY=""
        SELECTED_PROXY_LABEL=""
        ui_info "未配置专用代理，使用直连"
        return 0
    fi

    ui_info "检测网络代理..."
    if test_proxy_connectivity "$PROXY_SINGAPORE"; then
        SELECTED_PROXY="$PROXY_SINGAPORE"
        SELECTED_PROXY_LABEL="$PROXY_SINGAPORE_LABEL"
        ui_success "使用${PROXY_SINGAPORE_LABEL}代理"
        return 0
    fi
    if test_proxy_connectivity "$PROXY_HONGKONG"; then
        SELECTED_PROXY="$PROXY_HONGKONG"
        SELECTED_PROXY_LABEL="$PROXY_HONGKONG_LABEL"
        ui_success "使用${PROXY_HONGKONG_LABEL}代理（${PROXY_SINGAPORE_LABEL}不可用）"
        return 0
    fi
    SELECTED_PROXY=""
    SELECTED_PROXY_LABEL=""
    ui_info "代理不可用，直连"
    return 0
}

# 对 GitHub 相关 URL 应用代理（如 https://gh-proxy.org）
# 用法: apply_github_proxy "https://github.com/xxx/yyy"
apply_github_proxy() {
    local url="$1"
    local proxy="${GITHUB_PROXY:-}"
    if [[ -z "$proxy" ]]; then
        echo "$url"
        return
    fi
    proxy="${proxy%/}"
    if [[ "$url" == https://github.com/* ]] || [[ "$url" == https://raw.githubusercontent.com/* ]]; then
        echo "${proxy}/${url}"
        return
    fi
    echo "$url"
}

detect_downloader() {
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
        return 0
    fi
    if command -v wget &> /dev/null; then
        DOWNLOADER="wget"
        return 0
    fi
    ui_error "缺少下载工具（需要 curl 或 wget）"
    exit 1
}

download_file() {
    local url="$1"
    local output="$2"
    local original_url="$url"
    local -a candidates=()
    local effective_url=""
    local errlog=""
    errlog="$(mktempfile)"

    select_proxy

    if [[ -z "$DOWNLOADER" ]]; then
        detect_downloader
    fi

    if [[ -n "$SELECTED_PROXY" ]]; then
        candidates=("$original_url")
    else
        effective_url="$(apply_github_proxy "$original_url")"
        candidates=("$effective_url")
        if [[ "$effective_url" != "$original_url" ]]; then
            candidates+=("$original_url")
        fi
    fi

    local candidate=""
    for candidate in "${candidates[@]}"; do
        : >"$errlog"
        if [[ "$DOWNLOADER" == "curl" ]]; then
            if [[ -n "$SELECTED_PROXY" ]]; then
                if run_sensitive_cmd curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 --retry-connrefused -x "$SELECTED_PROXY" --proxy-insecure -o "$output" "$candidate" 2>"$errlog"; then
                    return 0
                fi
            else
                if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 --retry-connrefused -o "$output" "$candidate" 2>"$errlog"; then
                    return 0
                fi
            fi
        else
            if [[ -n "$SELECTED_PROXY" ]]; then
                if run_sensitive_cmd env https_proxy="$SELECTED_PROXY" http_proxy="$SELECTED_PROXY" \
                    wget -q --https-only --secure-protocol=TLSv1_2 --tries=3 --timeout=20 -O "$output" "$candidate" 2>"$errlog"; then
                    return 0
                fi
            else
                if wget -q --https-only --secure-protocol=TLSv1_2 --tries=3 --timeout=20 -O "$output" "$candidate" 2>"$errlog"; then
                    return 0
                fi
            fi
        fi

        if [[ "$candidate" != "$original_url" ]]; then
            ui_warn "下载通道失败，正在回退: $(mask_url_for_log "$candidate") -> $(mask_url_for_log "$original_url")"
        fi
    done

    if [[ -s "$errlog" ]]; then
        local first_err=""
        first_err="$(head -n1 "$errlog" || true)"
        if [[ -n "$first_err" ]]; then
            ui_warn "下载失败: ${first_err}"
        fi
    fi
    return 1
}

try_install_gum_with_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        return 1
    fi

    ui_info "尝试通过 Homebrew 安装 gum"
    if run_quiet_step "安装 gum (brew)" brew install gum; then
        :
    elif run_quiet_step "升级 gum (brew)" brew upgrade gum; then
        :
    else
        return 1
    fi

    if command -v gum >/dev/null 2>&1; then
        GUM="gum"
        GUM_STATUS="installed"
        GUM_REASON="通过 Homebrew 安装"
        return 0
    fi
    return 1
}

run_remote_bash() {
    local url="$1"
    local tmp
    tmp="$(mktempfile)"
    download_file "$url" "$tmp"
    /bin/bash "$tmp"
}

GUM_VERSION="${OPENCLAW_GUM_VERSION:-0.17.0}"
GUM=""
GUM_STATUS="skipped"
GUM_REASON=""
LAST_NPM_INSTALL_CMD=""

is_non_interactive_shell() {
    if [[ "${NO_PROMPT:-0}" == "1" ]]; then
        return 0
    fi
    if [[ ! -t 0 || ! -t 1 ]]; then
        return 0
    fi
    return 1
}

gum_is_tty() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi
    if [[ "${TERM:-dumb}" == "dumb" ]]; then
        return 1
    fi
    if [[ -t 2 || -t 1 ]]; then
        return 0
    fi
    return 1
}

gum_detect_os() {
    case "$(uname -s 2>/dev/null || true)" in
        Darwin) echo "Darwin" ;;
        Linux) echo "Linux" ;;
        *) echo "unsupported" ;;
    esac
}

gum_detect_arch() {
    case "$(uname -m 2>/dev/null || true)" in
        x86_64|amd64) echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        i386|i686) echo "i386" ;;
        armv7l|armv7) echo "armv7" ;;
        armv6l|armv6) echo "armv6" ;;
        *) echo "unknown" ;;
    esac
}

verify_sha256sum_file() {
    local checksums="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum --ignore-missing -c "$checksums" >/dev/null 2>&1
        return $?
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 --ignore-missing -c "$checksums" >/dev/null 2>&1
        return $?
    fi
    return 1
}

bootstrap_gum_temp() {
    GUM=""
    GUM_STATUS="skipped"
    GUM_REASON=""

    if is_non_interactive_shell; then
        GUM_REASON="非交互式终端（已自动禁用）"
        return 1
    fi

    if ! gum_is_tty; then
        GUM_REASON="终端不支持 gum 界面"
        return 1
    fi

    if command -v gum >/dev/null 2>&1; then
        GUM="gum"
        GUM_STATUS="found"
        GUM_REASON="已安装"
        return 0
    fi

    if ! command -v tar >/dev/null 2>&1; then
        GUM_REASON="未找到 tar"
        return 1
    fi

    local os arch asset base gum_tmpdir gum_path
    os="$(gum_detect_os)"
    arch="$(gum_detect_arch)"
    if [[ "$os" == "unsupported" || "$arch" == "unknown" ]]; then
        GUM_REASON="不支持的系统/架构 ($os/$arch)"
        return 1
    fi

    asset="gum_${GUM_VERSION}_${os}_${arch}.tar.gz"
    base="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}"

    gum_tmpdir="$(mktemp -d)"
    TMPFILES+=("$gum_tmpdir")

    if ! download_file "${base}/${asset}" "$gum_tmpdir/$asset"; then
        if try_install_gum_with_brew; then
            return 0
        fi
        GUM_REASON="下载失败"
        return 1
    fi

    if ! download_file "${base}/checksums.txt" "$gum_tmpdir/checksums.txt"; then
        if try_install_gum_with_brew; then
            return 0
        fi
        GUM_REASON="校验文件不可用或下载失败"
        return 1
    fi

    if ! (cd "$gum_tmpdir" && verify_sha256sum_file "checksums.txt"); then
        GUM_REASON="校验文件不可用或校验失败"
        return 1
    fi

    if ! tar -xzf "$gum_tmpdir/$asset" -C "$gum_tmpdir" >/dev/null 2>&1; then
        GUM_REASON="解压失败"
        return 1
    fi

    gum_path="$(find "$gum_tmpdir" -type f -name gum 2>/dev/null | head -n1 || true)"
    if [[ -z "$gum_path" ]]; then
        GUM_REASON="解压后未找到 gum 二进制文件"
        return 1
    fi

    chmod +x "$gum_path" >/dev/null 2>&1 || true
    if [[ ! -x "$gum_path" ]]; then
        GUM_REASON="gum 二进制文件不可执行"
        return 1
    fi

    GUM="$gum_path"
    GUM_STATUS="installed"
    GUM_REASON="临时安装，已校验"
    return 0
}

print_gum_status() {
    case "$GUM_STATUS" in
        found)
            ui_success "gum 可用（${GUM_REASON}）"
            ;;
        installed)
            ui_success "gum 已引导安装（${GUM_REASON}，v${GUM_VERSION}）"
            ;;
        *)
            if [[ -n "$GUM_REASON" && "$GUM_REASON" != "非交互式终端（已自动禁用）" ]]; then
                ui_info "gum 已跳过（${GUM_REASON}）"
            fi
            ;;
    esac
}

print_installer_banner() {
    if [[ -n "$GUM" ]]; then
        local title tagline hint card
        title="$("$GUM" style --foreground "#ff4d4d" --bold "🦞 OpenClaw 安装器")"
        tagline="$("$GUM" style --foreground "#8892b0" "OpenClaw 一键部署 — 让 AI 助手为你效劳。")"
        hint="$("$GUM" style --foreground "#5a6480" "现代安装模式")"
        card="$(printf '%s\n%s\n%s' "$title" "$tagline" "$hint")"
        "$GUM" style --border rounded --border-foreground "#ff4d4d" --padding "1 2" "$card"
        echo ""
        return
    fi

    echo ""
    ui_hr 54 "═"
    echo -e "${ACCENT}${BOLD}"
    echo "     🦞 OpenClaw 安装器"
    echo -e "${NC}${INFO}     OpenClaw 一键部署 — 让 AI 助手为你效劳。${NC}"
    echo -e "${MUTED}     ── 现代安装模式 ──${NC}"
    ui_hr 54 "═"
    echo ""
}

print_system_info() {
    local arch os_ver os_build cpu_name mem_gb
    arch="$(uname -m 2>/dev/null || echo "未知")"
    if [[ "$OS" == "macos" ]]; then
        os_ver="$(sw_vers -productVersion 2>/dev/null || true)"
        os_build="$(sw_vers -buildVersion 2>/dev/null || true)"
        cpu_name="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
        if [[ -n "$cpu_name" ]]; then
            cpu_name="$(echo "$cpu_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        fi
        if mem_bytes="$(sysctl -n hw.memsize 2>/dev/null)"; then
            mem_gb="$(awk "BEGIN {printf \"%.1f\", $mem_bytes/1024/1024/1024}" 2>/dev/null || echo "")"
        fi
        ui_success "检测到系统: macOS"
        ui_info "  系统: macOS $(sw_vers -productVersion 2>/dev/null || echo "") (Build $os_build)"
        ui_info "  架构: $arch"
        if [[ -n "$cpu_name" ]]; then
            ui_info "  CPU: $cpu_name"
        fi
        if [[ -n "$mem_gb" ]]; then
            ui_info "  内存: ${mem_gb} GB"
        fi
    elif [[ "$OS" == "linux" ]]; then
        os_ver=""
        if [[ -f /etc/os-release ]]; then
            os_ver="$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d'"' -f2)"
        fi
        cpu_name="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if mem_kb="$(grep -E '^MemTotal:' /proc/meminfo 2>/dev/null | awk '{print $2}')"; then
            mem_gb="$(awk "BEGIN {printf \"%.1f\", $mem_kb/1024/1024}" 2>/dev/null || echo "")"
        fi
        ui_success "检测到系统: Linux"
        if [[ -n "$os_ver" ]]; then
            ui_info "  系统: $os_ver"
        fi
        ui_info "  架构: $arch"
        if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
            ui_info "  环境: WSL ($WSL_DISTRO_NAME)"
        fi
        if [[ -n "$cpu_name" ]]; then
            ui_info "  CPU: $cpu_name"
        fi
        if [[ -n "$mem_gb" ]]; then
            ui_info "  内存: ${mem_gb} GB"
        fi
    fi
}

detect_os_or_die() {
    OS="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        OS="linux"
    fi

    if [[ "$OS" == "unknown" ]]; then
        echo ""
        ui_hr 48 "─"
        ui_error "不支持的操作系统"
        echo -e "  本安装器支持 ${ACCENT}macOS${NC} 和 ${ACCENT}Linux${NC}（包括 WSL）"
        echo -e "  Windows 用户请使用: ${INFO}iwr -useb https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.ps1 | iex${NC}"
        ui_hr 48 "─"
        echo ""
        exit 1
    fi

    print_system_info
}

ui_info() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level info "$msg"
    else
        echo -e "  ${MUTED}▸${NC} ${msg}"
    fi
}

ui_warn() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level warn "$msg"
    else
        echo -e "  ${WARN}⚠${NC} ${msg}"
    fi
}

ui_success() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        local mark
        mark="$("$GUM" style --foreground "#00e5cc" --bold "✓")"
        echo "${mark} ${msg}"
    else
        echo -e "  ${SUCCESS}✓${NC} ${msg}"
    fi
}

ui_error() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level error "$msg"
    else
        echo -e "  ${ERROR}✗${NC} ${msg}"
    fi
}

INSTALL_STAGE_TOTAL=3
INSTALL_STAGE_CURRENT=0

ui_section() {
    local title="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --bold --foreground "#ff4d4d" --padding "1 0" "$title"
    else
        echo ""
        echo -e "${ACCENT}${BOLD}  ${title}${NC}"
        ui_hr 48 "─"
    fi
}

ui_stage() {
    local title="$1"
    INSTALL_STAGE_CURRENT=$((INSTALL_STAGE_CURRENT + 1))
    ui_section "[${INSTALL_STAGE_CURRENT}/${INSTALL_STAGE_TOTAL}] ${title}"
}

ui_kv() {
    local key="$1"
    local value="$2"
    if [[ -n "$GUM" ]]; then
        local key_part value_part
        key_part="$("$GUM" style --foreground "#5a6480" --width 20 "$key")"
        value_part="$("$GUM" style --bold "$value")"
        "$GUM" join --horizontal "$key_part" "$value_part"
    else
        echo -e "  ${MUTED}${key}${NC}  ${ACCENT}${value}${NC}"
    fi
}

ui_panel() {
    local content="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --border rounded --border-foreground "#5a6480" --padding "0 1" "$content"
    else
        echo ""
        ui_hr 52 "─"
        echo "$content" | sed 's/^/  /'
        ui_hr 52 "─"
    fi
}

show_install_plan() {
    local detected_checkout="$1"

    ui_section "安装计划"
    ui_kv "操作系统" "$OS"
    ui_kv "安装方式" "$INSTALL_METHOD"
    if [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "pnpm" ]]; then
        local pkg=""
        local tag="latest"
        [[ "$USE_BETA" == "1" ]] && tag="$([[ "${OPENCLAW_EDITION:-}" == "original" ]] && echo "beta/next" || echo "nightly")"
        if [[ -n "${OPENCLAW_EDITION:-}" ]]; then
            pkg="$(get_openclaw_package)@${tag}"
        else
            pkg="openclaw 或 ${OPENCLAW_PACKAGE_ZH}（待选择）@${tag}"
        fi
        ui_kv "安装包" "$pkg"
    else
        ui_kv "请求版本" "$OPENCLAW_VERSION"
    fi
    if [[ "$USE_BETA" == "1" ]]; then
        ui_kv "测试版" "nightly"
    fi
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        ui_kv "Git 目录" "$GIT_DIR"
        ui_kv "Git 更新" "$GIT_UPDATE"
    fi
    if [[ -n "$NPM_REGISTRY" ]] && [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "pnpm" ]]; then
        local reg_url=""
        reg_url="$(resolve_registry_url "$NPM_REGISTRY" 2>/dev/null || true)"
        if [[ -n "$reg_url" ]]; then
            ui_kv "npm 源" "${NPM_REGISTRY} (${reg_url})"
        else
            ui_kv "npm 源" "$NPM_REGISTRY"
        fi
    fi
    if [[ -n "$GITHUB_PROXY" ]]; then
        ui_kv "GitHub 代理" "$(mask_url_for_log "$GITHUB_PROXY")"
    fi
    if [[ -n "$detected_checkout" ]]; then
        ui_kv "检测到的仓库" "$detected_checkout"
    fi
    ui_kv "可选组件" "$(optional_components_summary "$INSTALL_CHINA_CHANNELS" "$INSTALL_OPENCLAW_MANAGER")"
    if [[ "$DRY_RUN" == "1" ]]; then
        ui_kv "模拟运行" "是"
    fi
    if [[ "$NO_ONBOARD" == "1" ]]; then
        ui_kv "引导设置" "已跳过"
    fi
}

show_footer_links() {
    if [[ -n "$GUM" ]]; then
        local content
        content="需要帮助？
官方文档: ${OPENCLAW_DOCS_URL}
常见问题: ${OPENCLAW_FAQ_URL}
OpenClawCN 官网: ${OPENCLAW_CN_SITE_URL}
OpenClawCN 中文翻译: ${OPENCLAW_CN_TRANSLATION_REPO}
OpenClaw Manager: ${OPENCLAW_MANAGER_REPO_URL}
China IM 渠道: ${OPENCLAW_CHINA_CHANNELS_REPO_URL}"
        ui_panel "$content"
    else
        echo ""
        echo -e "${MUTED}  需要帮助？${NC}"
        ui_hr 48 "─"
        echo -e "  ${MUTED}官方文档${NC}     ${INFO}${OPENCLAW_DOCS_URL}${NC}"
        echo -e "  ${MUTED}常见问题${NC}     ${INFO}${OPENCLAW_FAQ_URL}${NC}"
        echo -e "  ${MUTED}OpenClawCN${NC}   ${INFO}${OPENCLAW_CN_SITE_URL}${NC}"
        echo -e "  ${MUTED}中文翻译${NC}     ${INFO}${OPENCLAW_CN_TRANSLATION_REPO}${NC}"
        echo -e "  ${MUTED}Manager${NC}     ${INFO}${OPENCLAW_MANAGER_REPO_URL}${NC}"
        echo -e "  ${MUTED}China IM${NC}     ${INFO}${OPENCLAW_CHINA_CHANNELS_REPO_URL}${NC}"
        ui_hr 48 "─"
    fi
}

ui_celebrate() {
    local msg="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --bold --foreground "#00e5cc" "$msg"
    else
        echo ""
        echo -e "  ${SUCCESS}${BOLD}${msg}${NC}"
        ui_hr 48 "─"
    fi
}

is_shell_function() {
    local name="${1:-}"
    [[ -n "$name" ]] && declare -F "$name" >/dev/null 2>&1
}

is_gum_raw_mode_failure() {
    local err_log="$1"
    [[ -s "$err_log" ]] || return 1
    grep -Eiq 'setrawmode' "$err_log"
}

# 简单 ASCII 旋转动画（非 gum 模式，需 TTY）
run_simple_spinner() {
    local title="$1"
    shift
    local pid ret
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    (
        "$@" &
        pid=$!
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r  %s %s  ' "${spin:$((i % 10)):1}" "$title"
            i=$((i + 1))
            sleep 0.08
        done
        wait "$pid"
    )
    ret=$?
    if [[ $ret -eq 0 ]]; then
        echo -e "\r  ${SUCCESS}✓${NC} ${title}    "
    else
        echo -e "\r  ${ERROR}✗${NC} ${title}    "
    fi
    return $ret
}

run_with_spinner() {
    local title="$1"
    shift

    if [[ -n "$GUM" ]] && gum_is_tty && ! is_shell_function "${1:-}"; then
        local gum_err
        gum_err="$(mktempfile)"
        if "$GUM" spin --spinner dot --title "$title" -- "$@" 2>"$gum_err"; then
            return 0
        fi
        local gum_status=$?
        if is_gum_raw_mode_failure "$gum_err"; then
            GUM=""
            GUM_STATUS="skipped"
            GUM_REASON="gum raw 模式不可用"
            ui_warn "当前终端不支持加载动画；继续执行"
            "$@"
            return $?
        fi
        if [[ -s "$gum_err" ]]; then
            cat "$gum_err" >&2
        fi
        return "$gum_status"
    fi

    # 非 gum 模式：有 TTY 时显示简单旋转动画
    if gum_is_tty && ! is_shell_function "${1:-}"; then
        run_simple_spinner "$title" "$@"
        return $?
    fi

    "$@"
}

run_quiet_step() {
    local title="$1"
    shift

    if [[ "$VERBOSE" == "1" ]]; then
        run_with_spinner "$title" "$@"
        return $?
    fi

    local log
    log="$(mktempfile)"

    if [[ -n "$GUM" ]] && gum_is_tty && ! is_shell_function "${1:-}"; then
        local cmd_quoted=""
        local log_quoted=""
        printf -v cmd_quoted '%q ' "$@"
        printf -v log_quoted '%q' "$log"
        if run_with_spinner "$title" bash -c "${cmd_quoted}>${log_quoted} 2>&1"; then
            return 0
        fi
    else
        if "$@" >"$log" 2>&1; then
            return 0
        fi
    fi

    ui_error "${title} 失败 — 使用 --verbose 重新运行以查看详情"
    if [[ -s "$log" ]]; then
        tail -n 80 "$log" >&2 || true
    fi
    return 1
}

print_log_tail_sanitized() {
    local log="$1"
    local lines="${2:-80}"
    if [[ -z "$log" || ! -s "$log" ]]; then
        return 0
    fi

    local cleaned
    cleaned="$(mktempfile)"
    grep -Eiv 'inappropriate ioctl for device' "$log" >"$cleaned" 2>/dev/null || true
    if [[ -s "$cleaned" ]]; then
        tail -n "$lines" "$cleaned" >&2 || true
    else
        tail -n "$lines" "$log" >&2 || true
    fi
}

cleanup_legacy_submodules() {
    local repo_dir="$1"
    local legacy_dir="$repo_dir/Peekaboo"
    if [[ -d "$legacy_dir" ]]; then
        ui_info "正在移除旧版子模块: ${legacy_dir}"
        rm -rf "$legacy_dir"
    fi
}

cleanup_npm_openclaw_paths() {
    local npm_root=""
    npm_root="$(npm root -g 2>/dev/null || true)"
    if [[ -z "$npm_root" || "$npm_root" != *node_modules* ]]; then
        return 1
    fi
    rm -rf "$npm_root"/.openclaw-* "$npm_root"/openclaw 2>/dev/null || true
}

extract_openclaw_conflict_path() {
    local log="$1"
    local path=""
    path="$(sed -n 's/.*File exists: //p' "$log" | head -n1)"
    if [[ -z "$path" ]]; then
        path="$(sed -n 's/.*EEXIST: file already exists, //p' "$log" | head -n1)"
    fi
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi
    return 1
}

cleanup_openclaw_bin_conflict() {
    local bin_path="$1"
    if [[ -z "$bin_path" || ( ! -e "$bin_path" && ! -L "$bin_path" ) ]]; then
        return 1
    fi
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir 2>/dev/null || true)"
    if [[ -n "$npm_bin" && "$bin_path" != "$npm_bin/openclaw" ]]; then
        case "$bin_path" in
            "/opt/homebrew/bin/openclaw"|"/usr/local/bin/openclaw")
                ;;
            *)
                return 1
                ;;
        esac
    fi
    if [[ -L "$bin_path" ]]; then
        local target=""
        target="$(readlink "$bin_path" 2>/dev/null || true)"
        if [[ "$target" == *"/node_modules/openclaw/"* ]]; then
            rm -f "$bin_path"
            ui_info "已移除过期的 openclaw 符号链接: ${bin_path}"
            return 0
        fi
        return 1
    fi
    local backup=""
    backup="${bin_path}.bak-$(date +%Y%m%d-%H%M%S)"
    if mv "$bin_path" "$backup"; then
        ui_info "已将现有 openclaw 二进制文件备份到 ${backup}"
        return 0
    fi
    return 1
}

npm_log_indicates_missing_build_tools() {
    local log="$1"
    if [[ -z "$log" || ! -f "$log" ]]; then
        return 1
    fi

    grep -Eiq "(not found: make|make: command not found|cmake: command not found|CMAKE_MAKE_PROGRAM is not set|Could not find CMAKE|gyp ERR! find Python|no developer tools were found|is not able to compile a simple test program|Failed to build llama\\.cpp|It seems that \"make\" is not installed in your system|It seems that the used \"cmake\" doesn't work properly)" "$log"
}

install_build_tools_linux() {
    require_sudo

    if command -v apt-get &> /dev/null; then
        if is_root; then
            run_quiet_step "更新软件包索引" apt-get update -qq
            run_quiet_step "安装构建工具" apt-get install -y -qq build-essential python3 make g++ cmake
        else
            run_quiet_step "更新软件包索引" sudo apt-get update -qq
            run_quiet_step "安装构建工具" sudo apt-get install -y -qq build-essential python3 make g++ cmake
        fi
        return 0
    fi

    if command -v dnf &> /dev/null; then
        if is_root; then
            run_quiet_step "安装构建工具" dnf install -y -q gcc gcc-c++ make cmake python3
        else
            run_quiet_step "安装构建工具" sudo dnf install -y -q gcc gcc-c++ make cmake python3
        fi
        return 0
    fi

    if command -v yum &> /dev/null; then
        if is_root; then
            run_quiet_step "安装构建工具" yum install -y -q gcc gcc-c++ make cmake python3
        else
            run_quiet_step "安装构建工具" sudo yum install -y -q gcc gcc-c++ make cmake python3
        fi
        return 0
    fi

    if command -v apk &> /dev/null; then
        if is_root; then
            run_quiet_step "安装构建工具" apk add --no-cache build-base python3 cmake
        else
            run_quiet_step "安装构建工具" sudo apk add --no-cache build-base python3 cmake
        fi
        return 0
    fi

    ui_warn "无法检测到包管理器，无法自动安装构建工具"
    return 1
}

# Tauri/WebKit 依赖（OpenClaw Manager 等图形化应用所需）
install_tauri_linux_deps() {
    require_sudo
    if command -v apt-get &> /dev/null; then
        local pkgs="libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev"
        if is_root; then
            run_quiet_step "更新软件包索引" apt-get update -qq
            run_quiet_step "安装 Tauri 依赖" apt-get install -y -qq $pkgs
        else
            run_quiet_step "更新软件包索引" sudo apt-get update -qq
            run_quiet_step "安装 Tauri 依赖" sudo apt-get install -y -qq $pkgs
        fi
        return $?
    fi
    if command -v dnf &> /dev/null; then
        local pkgs="webkit2gtk4.1-devel openssl-devel curl wget file libxdo-devel gcc gcc-c++ make"
        if is_root; then
            run_quiet_step "安装 Tauri 依赖" dnf install -y -q $pkgs
        else
            run_quiet_step "安装 Tauri 依赖" sudo dnf install -y -q $pkgs
        fi
        return $?
    fi
    ui_warn "无法自动安装 Tauri 依赖（仅支持 apt/dnf）"
    return 1
}

install_build_tools_macos() {
    local ok=true

    if ! xcode-select -p >/dev/null 2>&1; then
        ui_info "正在安装 Xcode 命令行工具（make/clang 所需）"
        xcode-select --install >/dev/null 2>&1 || true
        if ! xcode-select -p >/dev/null 2>&1; then
            ui_warn "Xcode 命令行工具尚未就绪"
            ui_info "请完成安装对话框，然后重新运行本安装器"
            ok=false
        fi
    fi

    if ! command -v cmake >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            run_quiet_step "安装 cmake" brew install cmake
        else
            ui_warn "Homebrew 不可用；无法自动安装 cmake"
            ok=false
        fi
    fi

    if ! command -v make >/dev/null 2>&1; then
        ui_warn "make 仍然不可用"
        ok=false
    fi
    if ! command -v cmake >/dev/null 2>&1; then
        ui_warn "cmake 仍然不可用"
        ok=false
    fi

    [[ "$ok" == "true" ]]
}

auto_install_build_tools_for_npm_failure() {
    local log="$1"
    if ! npm_log_indicates_missing_build_tools "$log"; then
        return 1
    fi

    ui_warn "检测到缺少原生构建工具；正在尝试自动安装"
    if [[ "$OS" == "linux" ]]; then
        install_build_tools_linux || return 1
    elif [[ "$OS" == "macos" ]]; then
        install_build_tools_macos || return 1
    else
        return 1
    fi
    ui_success "构建工具安装完成"
    return 0
}

run_npm_global_install() {
    local spec="$1"
    local log="$2"

    local -a cmd
    cmd=(npm --loglevel "$NPM_LOGLEVEL")
    if [[ -n "$NPM_SILENT_FLAG" ]]; then
        cmd+=("$NPM_SILENT_FLAG")
    fi
    local registry_url=""
    registry_url="$(resolve_registry_url "${NPM_REGISTRY:-}" 2>/dev/null || true)"
    if [[ -n "$registry_url" ]]; then
        cmd+=(--registry "$registry_url")
    fi
    cmd+=(--no-fund --no-audit install -g "$spec")
    local cmd_display=""
    printf -v cmd_display '%q ' "${cmd[@]}"
    LAST_NPM_INSTALL_CMD="${cmd_display% }"

    # 简化：直接执行命令，不使用 spinner
    "${cmd[@]}" >"$log" 2>&1
}

extract_npm_debug_log_path() {
    local log="$1"
    local path=""
    path="$(sed -n -E 's/.*A complete log of this run can be found in:[[:space:]]*//p' "$log" | tail -n1)"
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    path="$(grep -Eo '/[^[:space:]]+_logs/[^[:space:]]+debug[^[:space:]]*\.log' "$log" | tail -n1 || true)"
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

extract_first_npm_error_line() {
    local log="$1"
    grep -E 'npm (ERR!|error)|ERR!' "$log" | head -n1 || true
}

extract_npm_error_code() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) code[[:space:]]+([^[:space:]]+).*$/\2/p' "$log" | head -n1
}

extract_npm_error_syscall() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) syscall[[:space:]]+(.+)$/\2/p' "$log" | head -n1
}

extract_npm_error_errno() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) errno[[:space:]]+(.+)$/\2/p' "$log" | head -n1
}

print_npm_failure_diagnostics() {
    local spec="$1"
    local log="$2"
    local debug_log=""
    local first_error=""
    local error_code=""
    local error_syscall=""
    local error_errno=""

    echo ""
    ui_hr 50 "─"
    ui_warn "npm 安装 ${spec} 失败"
    ui_hr 50 "─"
    if [[ -n "${LAST_NPM_INSTALL_CMD}" ]]; then
        echo -e "  ${MUTED}命令${NC} ${LAST_NPM_INSTALL_CMD}"
    fi
    echo -e "  ${MUTED}日志${NC} ${log}"

    error_code="$(extract_npm_error_code "$log")"
    if [[ -n "$error_code" ]]; then
        echo -e "  ${MUTED}错误码${NC} ${ERROR}${error_code}${NC}"
    fi

    error_syscall="$(extract_npm_error_syscall "$log")"
    if [[ -n "$error_syscall" ]]; then
        echo -e "  ${MUTED}syscall${NC} ${error_syscall}"
    fi

    error_errno="$(extract_npm_error_errno "$log")"
    if [[ -n "$error_errno" ]]; then
        echo -e "  ${MUTED}errno${NC} ${error_errno}"
    fi

    debug_log="$(extract_npm_debug_log_path "$log" || true)"
    if [[ -n "$debug_log" ]]; then
        echo -e "  ${MUTED}调试日志${NC} ${INFO}${debug_log}${NC}"
    fi

    first_error="$(extract_first_npm_error_line "$log")"
    if [[ -n "$first_error" ]]; then
        echo -e "  ${MUTED}首条错误${NC} ${ERROR}${first_error}${NC}"
    fi
    echo ""
}

install_openclaw_npm() {
    local spec="$1"
    local log
    log="$(mktempfile)"
    if ! run_npm_global_install "$spec" "$log"; then
        local attempted_build_tool_fix=false
        if auto_install_build_tools_for_npm_failure "$log"; then
            attempted_build_tool_fix=true
            ui_info "构建工具安装完成，正在重试 npm 安装"
            if run_npm_global_install "$spec" "$log"; then
                ui_success "OpenClaw npm 包安装成功"
                return 0
            fi
        fi

        print_npm_failure_diagnostics "$spec" "$log"

        if [[ "$VERBOSE" != "1" ]]; then
            if [[ "$attempted_build_tool_fix" == "true" ]]; then
                ui_warn "安装构建工具后 npm 安装仍然失败；显示最后的日志"
            else
                ui_warn "npm 安装失败；显示最后的日志"
            fi
            print_log_tail_sanitized "$log" 80
        fi

        if grep -q "ENOTEMPTY: directory not empty, rename .*openclaw" "$log"; then
            ui_warn "npm 残留了过期目录；正在清理并重试"
            cleanup_npm_openclaw_paths
            if run_npm_global_install "$spec" "$log"; then
                ui_success "OpenClaw npm 包安装成功"
                return 0
            fi
            return 1
        fi
        if grep -q "EEXIST" "$log"; then
            local conflict=""
            conflict="$(extract_openclaw_conflict_path "$log" || true)"
            if [[ -n "$conflict" ]] && cleanup_openclaw_bin_conflict "$conflict"; then
                if run_npm_global_install "$spec" "$log"; then
                    ui_success "OpenClaw npm 包安装成功"
                    return 0
                fi
                return 1
            fi
            ui_error "npm 安装失败，因为 openclaw 二进制文件已存在"
            if [[ -n "$conflict" ]]; then
                ui_info "请移除或移动 ${conflict}，然后重试"
            fi
            ui_info "或使用以下命令强制重装: npm install -g --force ${spec}"
        fi
        return 1
    fi
    ui_success "OpenClaw npm 包安装成功"
    return 0
}



map_legacy_env() {
    local key="$1"
    local legacy="$2"
    if [[ -z "${!key:-}" && -n "${!legacy:-}" ]]; then
        printf -v "$key" '%s' "${!legacy}"
    fi
}

map_legacy_env "OPENCLAW_NO_ONBOARD" "CLAWDBOT_NO_ONBOARD"
map_legacy_env "OPENCLAW_NO_PROMPT" "CLAWDBOT_NO_PROMPT"
map_legacy_env "OPENCLAW_DRY_RUN" "CLAWDBOT_DRY_RUN"
map_legacy_env "OPENCLAW_INSTALL_METHOD" "CLAWDBOT_INSTALL_METHOD"
map_legacy_env "OPENCLAW_VERSION" "CLAWDBOT_VERSION"
map_legacy_env "OPENCLAW_BETA" "CLAWDBOT_BETA"
map_legacy_env "OPENCLAW_GIT_DIR" "CLAWDBOT_GIT_DIR"
map_legacy_env "OPENCLAW_GIT_UPDATE" "CLAWDBOT_GIT_UPDATE"
map_legacy_env "OPENCLAW_NPM_LOGLEVEL" "CLAWDBOT_NPM_LOGLEVEL"
map_legacy_env "OPENCLAW_VERBOSE" "CLAWDBOT_VERBOSE"
map_legacy_env "OPENCLAW_PROFILE" "CLAWDBOT_PROFILE"
map_legacy_env "OPENCLAW_INSTALL_SH_NO_RUN" "CLAWDBOT_INSTALL_SH_NO_RUN"
map_legacy_env "OPENCLAW_NPM_REGISTRY" "CLAWDBOT_NPM_REGISTRY"

# npm 源预设（来源: https://ksh7.com/posts/npm-registry/）
resolve_registry_url() {
    local key="${1:-}"
    if [[ -z "$key" ]]; then
        echo ""
        return 1
    fi
    if [[ "$key" == https://* || "$key" == http://* ]]; then
        echo "$key"
        return 0
    fi
    case "$key" in
        npm)       echo "https://registry.npmjs.org/" ;;
        yarn)      echo "https://registry.yarnpkg.com/" ;;
        tencent)   echo "https://mirrors.cloud.tencent.com/npm/" ;;
        taobao)    echo "https://registry.npmmirror.com/" ;;
        cnpm)      echo "https://r.cnpmjs.org/" ;;
        npmMirror) echo "https://skimdb.npmjs.com/registry/" ;;
        ali)       echo "https://registry.npm.alibaba-inc.com/" ;;
        huawei)    echo "https://mirrors.huaweicloud.com/repository/npm/" ;;
        163)       echo "https://mirrors.163.com/npm/" ;;
        ustc)      echo "https://mirrors.ustc.edu.cn/" ;;
        tsinghua)  echo "https://mirrors.tuna.tsinghua.edu.cn/" ;;
        *)
            echo ""
            return 1
            ;;
    esac
    return 0
}

# 测速单个 npm 源（返回毫秒数，失败返回 9999）
test_registry_speed() {
    local name="$1"
    local url="$2"
    local time_s
    time_s=$(curl -fsSL -o /dev/null --max-time 3 -w '%{time_total}' "${url}vue" 2>/dev/null) || { echo "9999"; return; }
    # time_total 是秒（小数），转成整数毫秒
    local ms
    ms=$(awk "BEGIN { printf \"%d\", ${time_s} * 1000 }" 2>/dev/null) || ms=9999
    echo "$ms"
}

# 自动测速选择最快的 npm 源
auto_select_fastest_registry() {
    ui_info "正在测速 npm 源，选择最快的..."
    
    local -a registries=(
        "taobao|https://registry.npmmirror.com/"
        "tencent|https://mirrors.cloud.tencent.com/npm/"
        "huawei|https://mirrors.huaweicloud.com/repository/npm/"
        "ustc|https://mirrors.ustc.edu.cn/"
        "163|https://mirrors.163.com/npm/"
        "npm|https://registry.npmjs.org/"
    )
    
    local fastest_name="taobao"
    local fastest_time=9999
    local fastest_url=""
    
    for entry in "${registries[@]}"; do
        local name="${entry%%|*}"
        local url="${entry#*|}"
        local time
        time=$(test_registry_speed "$name" "$url")
        
        if [[ "$VERBOSE" == "1" ]]; then
            if [[ "$time" == "9999" ]]; then
                ui_info "  ${name}: 超时"
            else
                ui_info "  ${name}: ${time}ms"
            fi
        fi
        
        if [[ "$time" -lt "$fastest_time" ]]; then
            fastest_time="$time"
            fastest_name="$name"
            fastest_url="$url"
        fi
    done
    
    if [[ "$fastest_time" == "9999" ]]; then
        ui_warn "所有源均超时，使用默认 taobao 源"
        NPM_REGISTRY="taobao"
    else
        NPM_REGISTRY="$fastest_name"
        ui_success "已选择最快源: ${fastest_name} (${fastest_time}ms)"
    fi
}

npm_view() {
    local registry_url=""
    registry_url="$(resolve_registry_url "${NPM_REGISTRY:-}" 2>/dev/null || true)"
    if [[ -n "$registry_url" ]]; then
        npm view --registry "$registry_url" "$@"
    else
        npm view "$@"
    fi
}

NO_ONBOARD=${OPENCLAW_NO_ONBOARD:-0}
NO_PROMPT=${OPENCLAW_NO_PROMPT:-0}
DRY_RUN=${OPENCLAW_DRY_RUN:-0}
INSTALL_METHOD=${OPENCLAW_INSTALL_METHOD:-}
OPENCLAW_VERSION=${OPENCLAW_VERSION:-latest}
USE_BETA=${OPENCLAW_BETA:-0}
# 版本选择: original=原版 openclaw, zh=中文版 @qingchencloud/openclaw-zh
OPENCLAW_EDITION=${OPENCLAW_EDITION:-}
OPENCLAW_EDITION_FROM_ARGS=0  # 1=用户显式传入 --zh/--original 等
OPENCLAW_PACKAGE_ORIGINAL="openclaw"
OPENCLAW_PACKAGE_ZH="@qingchencloud/openclaw-zh"
if [[ "$OSTYPE" == "darwin"* ]]; then
    GIT_DIR_DEFAULT="${HOME}/OpenClaw"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    GIT_DIR_DEFAULT="/opt/OpenClaw"
else
    GIT_DIR_DEFAULT="${HOME}/OpenClaw"
fi
GIT_DIR=${OPENCLAW_GIT_DIR:-$GIT_DIR_DEFAULT}
GIT_UPDATE=${OPENCLAW_GIT_UPDATE:-1}
SHARP_IGNORE_GLOBAL_LIBVIPS="${SHARP_IGNORE_GLOBAL_LIBVIPS:-1}"
NPM_LOGLEVEL="${OPENCLAW_NPM_LOGLEVEL:-error}"
NPM_SILENT_FLAG="--silent"
VERBOSE="${OPENCLAW_VERBOSE:-0}"
OPENCLAW_BIN=""
PNPM_CMD=()
HELP=0
NPM_REGISTRY="${OPENCLAW_NPM_REGISTRY:-auto}"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME_DIR:-${HOME}/.openclaw}"
OPENCLAW_CHANNELS_DIR="${OPENCLAW_CHANNELS_DIR:-${OPENCLAW_HOME_DIR}/extensions/channels}"
OPENCLAW_DOCS_URL="${OPENCLAW_DOCS_URL:-https://docs.openclaw.ai/zh-CN}"
OPENCLAW_WEB_UI_URL="${OPENCLAW_WEB_UI_URL:-https://claw.moyuxl.top/}"
OPENCLAW_FAQ_URL="${OPENCLAW_FAQ_URL:-https://docs.openclaw.ai/start/faq}"
OPENCLAW_CN_SITE_URL="${OPENCLAW_CN_SITE_URL:-https://openclaw.qt.cool/}"
OPENCLAW_CN_TRANSLATION_REPO="${OPENCLAW_CN_TRANSLATION_REPO:-https://github.com/1186258278/OpenClawChineseTranslation}"
OPENCLAW_MANAGER_REPO="${OPENCLAW_MANAGER_REPO:-miaoxworld/openclaw-manager}"
OPENCLAW_MANAGER_REPO_URL="${OPENCLAW_MANAGER_REPO_URL:-https://github.com/${OPENCLAW_MANAGER_REPO}}"
OPENCLAW_CHINA_CHANNELS_REPO_URL="${OPENCLAW_CHINA_CHANNELS_REPO_URL:-https://github.com/BytePioneer-AI/openclaw-china}"
INSTALL_CHINA_CHANNELS="${OPENCLAW_INSTALL_CHINA_CHANNELS:-auto}"
INSTALL_OPENCLAW_MANAGER="${OPENCLAW_INSTALL_MANAGER:-auto}"
OPENCLAW_WARNED_TTY_BIN=""
OPENCLAW_WARNED_NODE_REQUIREMENT=0
OPENCLAW_LEGACY_CONFIG_PATHS=(
    "${HOME}/.clawdbot/clawdbot.json"
    "${HOME}/.moltbot/moltbot.json"
    "${HOME}/.moldbot/moldbot.json"
)

# ═══════════════════════════════════════════════════════════════════════
#                    部署配置变量
# ═══════════════════════════════════════════════════════════════════════
DEPLOY_PROVIDER_CHOICE=""
DEPLOY_API_KEY=""
DEPLOY_WORKSPACE=""
DEPLOY_SKIP_DOCTOR=0
DEPLOY_SKIP_DASHBOARD=0
DEPLOY_SKIP_GATEWAY_RESTART=0
SELECTED_PROVIDER=""
SELECTED_API_KEY=""
SELECTED_WORKSPACE=""
SETUP_MODE=""

print_usage() {
    echo ""
    echo -e "${ACCENT}${BOLD}  OpenClaw 安装器${NC} ${MUTED}（macOS + Linux）${NC}"
    echo ""
    echo -e "${MUTED}用法:${NC}"
    echo -e "  ${INFO}curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash -s -- [选项]${NC}"
    echo ""
    echo -e "${MUTED}选项:${NC}"
    echo -e "  ${ACCENT}--install-method${NC}, --method npm|pnpm|git  通过 pnpm（默认）、npm 或 git 源码安装"
    echo -e "  --npm, --pnpm, --git/--github                    快捷方式"
    echo -e "  --version <版本|dist-tag>                        npm 安装: 指定版本（默认: latest）"
    echo -e "  --original/--en, --zh/--chinese                  原版或中文版"
    echo -e "  --beta                                           使用测试版"
    echo -e "  --git-dir, --dir <路径>                          源码目录"
    echo -e "  --no-git-update, --no-onboard, --no-prompt       跳过选项"
    echo -e "  --with-channels / --without-channels             安装/跳过 China 渠道插件"
    echo -e "  --with-manager / --without-manager               安装/跳过 OpenClaw Manager"
    echo -e "  --dry-run, --verbose                             模拟/调试"
    echo -e "  ${ACCENT}--registry${NC}, -r <源|URL>              npm 源（默认: auto 自动测速）"
    echo -e "  ${ACCENT}--github-proxy${NC}, -g <URL>             GitHub 代理"
    echo -e "  --help, -h                                       显示此帮助"
    echo ""
    echo -e "${MUTED}环境变量:${NC} OPENCLAW_INSTALL_METHOD, OPENCLAW_EDITION, OPENCLAW_VERSION, OPENCLAW_NPM_REGISTRY,"
    echo -e "         OPENCLAW_INSTALL_CHINA_CHANNELS, OPENCLAW_INSTALL_MANAGER,"
    echo -e "         OPENCLAW_PROXY_SINGAPORE / OPENCLAW_PROXY_HONGKONG,"
    echo -e "         OPENCLAW_PROXY_PRIMARY / OPENCLAW_PROXY_SECONDARY 等"
    echo ""
    echo -e "${MUTED}示例:${NC}"
    echo -e "  curl -fsSL https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash"
    echo -e "  curl -fsSL https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash -s -- ${ACCENT}--beta${NC}"
    echo -e "  curl -fsSL https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash -s -- ${ACCENT}--registry taobao${NC}"
    echo ""
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-onboard)
                NO_ONBOARD=1
                shift
                ;;
            --onboard)
                NO_ONBOARD=0
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --no-prompt)
                NO_PROMPT=1
                shift
                ;;
            --help|-h)
                HELP=1
                shift
                ;;
            --install-method|--method)
                INSTALL_METHOD="$2"
                shift 2
                ;;
            --version)
                OPENCLAW_VERSION="$2"
                shift 2
                ;;
            --beta)
                USE_BETA=1
                shift
                ;;
            --original|--en)
                OPENCLAW_EDITION="original"
                OPENCLAW_EDITION_FROM_ARGS=1
                shift
                ;;
            --zh|--chinese)
                OPENCLAW_EDITION="zh"
                OPENCLAW_EDITION_FROM_ARGS=1
                shift
                ;;
            --npm)
                INSTALL_METHOD="npm"
                shift
                ;;
            --pnpm)
                INSTALL_METHOD="pnpm"
                shift
                ;;
            --git|--github)
                INSTALL_METHOD="git"
                shift
                ;;
            --git-dir|--dir)
                GIT_DIR="$2"
                shift 2
                ;;
            --no-git-update)
                GIT_UPDATE=0
                shift
                ;;
            --registry|-r)
                NPM_REGISTRY="$2"
                shift 2
                ;;
            --with-channels|--install-channels)
                INSTALL_CHINA_CHANNELS=1
                shift
                ;;
            --without-channels|--skip-channels|--no-channels)
                INSTALL_CHINA_CHANNELS=0
                shift
                ;;
            --with-manager|--install-manager)
                INSTALL_OPENCLAW_MANAGER=1
                shift
                ;;
            --without-manager|--skip-manager|--no-manager)
                INSTALL_OPENCLAW_MANAGER=0
                shift
                ;;
            --github-proxy|-g)
                GITHUB_PROXY="$2"
                shift 2
                ;;
            --provider)
                DEPLOY_PROVIDER_CHOICE="$2"
                shift 2
                ;;
            --api-key)
                DEPLOY_API_KEY="$2"
                shift 2
                ;;
            --deploy-workspace)
                DEPLOY_WORKSPACE="$2"
                shift 2
                ;;
            --skip-doctor)
                DEPLOY_SKIP_DOCTOR=1
                shift
                ;;
            --skip-dashboard)
                DEPLOY_SKIP_DASHBOARD=1
                shift
                ;;
            --skip-gateway-restart)
                DEPLOY_SKIP_GATEWAY_RESTART=1
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

configure_verbose() {
    if [[ "$VERBOSE" != "1" ]]; then
        return 0
    fi
    if [[ "$NPM_LOGLEVEL" == "error" ]]; then
        NPM_LOGLEVEL="notice"
    fi
    NPM_SILENT_FLAG=""
    set -x
}

is_promptable() {
    if [[ "$NO_PROMPT" == "1" ]]; then
        return 1
    fi
    if [[ -r /dev/tty && -w /dev/tty ]]; then
        return 0
    fi
    return 1
}

prompt_choice() {
    local prompt="$1"
    local answer=""
    if ! is_promptable; then
        return 1
    fi
    echo -e "$prompt" > /dev/tty
    read -r answer < /dev/tty || true
    echo "$answer"
}

normalize_optional_toggle() {
    local raw="${1:-auto}"
    case "$raw" in
        1|true|TRUE|yes|YES|on|ON|enable|enabled)
            echo "1"
            ;;
        0|false|FALSE|no|NO|off|OFF|disable|disabled)
            echo "0"
            ;;
        auto|"")
            echo "auto"
            ;;
        *)
            echo "auto"
            ;;
    esac
}

optional_toggle_enabled() {
    local value
    value="$(normalize_optional_toggle "$1")"
    [[ "$value" == "1" ]]
}

normalize_optional_components_config() {
    INSTALL_CHINA_CHANNELS="$(normalize_optional_toggle "$INSTALL_CHINA_CHANNELS")"
    INSTALL_OPENCLAW_MANAGER="$(normalize_optional_toggle "$INSTALL_OPENCLAW_MANAGER")"
}

optional_components_summary() {
    local channels="$1"
    local manager="$2"
    local parts=()
    optional_toggle_enabled "$channels" && parts+=("China 渠道插件")
    optional_toggle_enabled "$manager" && parts+=("OpenClaw Manager")
    if [[ ${#parts[@]} -eq 0 ]]; then
        echo "不安装可选组件"
    elif [[ ${#parts[@]} -eq 2 ]]; then
        echo "${parts[0]} + ${parts[1]}"
    else
        echo "${parts[0]}"
    fi
}

choose_optional_components_interactive() {
    normalize_optional_components_config

    local default_channels="$INSTALL_CHINA_CHANNELS"
    local default_manager="$INSTALL_OPENCLAW_MANAGER"
    [[ "$default_channels" == "auto" ]] && default_channels="1"
    [[ "$default_manager" == "auto" ]] && default_manager="1"

    local should_prompt=false
    if [[ "$INSTALL_CHINA_CHANNELS" == "auto" || "$INSTALL_OPENCLAW_MANAGER" == "auto" ]]; then
        should_prompt=true
    fi

    if [[ "$should_prompt" != "true" ]]; then
        INSTALL_CHINA_CHANNELS="$default_channels"
        INSTALL_OPENCLAW_MANAGER="$default_manager"
        return 0
    fi

    if ! is_promptable; then
        INSTALL_CHINA_CHANNELS="$default_channels"
        INSTALL_OPENCLAW_MANAGER="$default_manager"
        ui_info "无交互终端，默认安装可选组件: $(optional_components_summary "$INSTALL_CHINA_CHANNELS" "$INSTALL_OPENCLAW_MANAGER")"
        return 0
    fi

    local selected_channels="$default_channels"
    local selected_manager="$default_manager"

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local selection=""
        selection="$("$GUM" choose \
            --no-limit \
            --header "选择可选组件（可多选，回车确认）" \
            --cursor-prefix "❯ " \
            "China 渠道插件（@openclaw-china/channels）" \
            "OpenClaw Manager（图形化管理工具）" < /dev/tty || true)"
        if [[ -n "$selection" ]]; then
            selected_channels=0
            selected_manager=0
            echo "$selection" | grep -q "China 渠道插件" && selected_channels=1
            echo "$selection" | grep -q "OpenClaw Manager" && selected_manager=1
        fi
    else
        local choice=""
        local prompt_text=""
        prompt_text="${WARN}→${NC} 选择可选组件（可多选）:
  1) China 渠道插件（@openclaw-china/channels）
  2) OpenClaw Manager（图形化管理工具）
  0) 都不安装
直接回车 = 默认（全部安装）
请输入序号（示例: 1 2 或 1,2）:"
        choice="$(prompt_choice "$prompt_text" || true)"
        if [[ -n "$choice" ]]; then
            selected_channels=0
            selected_manager=0
            local token=""
            local normalized=""
            normalized="$(echo "$choice" | tr ',，;；/' '     ')"
            for token in $normalized; do
                case "$token" in
                    1) selected_channels=1 ;;
                    2) selected_manager=1 ;;
                    0) selected_channels=0; selected_manager=0 ;;
                esac
            done
        fi
    fi

    if [[ "$INSTALL_CHINA_CHANNELS" == "auto" ]]; then
        INSTALL_CHINA_CHANNELS="$selected_channels"
    fi
    if [[ "$INSTALL_OPENCLAW_MANAGER" == "auto" ]]; then
        INSTALL_OPENCLAW_MANAGER="$selected_manager"
    fi

    ui_info "可选组件选择: $(optional_components_summary "$INSTALL_CHINA_CHANNELS" "$INSTALL_OPENCLAW_MANAGER")"
    return 0
}

choose_install_method_interactive() {
    local detected_checkout="$1"

    if ! is_promptable; then
        return 1
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local header selection
        header="检测到 OpenClaw 源码目录: ${detected_checkout}
请选择安装方式"
        selection="$("$GUM" choose \
            --header "$header" \
            --cursor-prefix "❯ " \
            "git  · 更新此源码目录并使用" \
            "npm  · 通过 npm 全局安装" \
            "pnpm · 通过 pnpm 全局安装" < /dev/tty || true)"

        case "$selection" in
            git*)
                echo "git"
                return 0
                ;;
            npm*)
                echo "npm"
                return 0
                ;;
            pnpm*)
                echo "pnpm"
                return 0
                ;;
        esac
        return 1
    fi

    local choice=""
    echo ""
    ui_hr 48 "─"
    choice="$(prompt_choice "$(cat <<EOF
${ACCENT}检测到 OpenClaw 源码目录:${NC} ${INFO}${detected_checkout}${NC}

${MUTED}请选择安装方式:${NC}
  ${ACCENT}1)${NC} 更新此源码目录（git）并使用
  ${ACCENT}2)${NC} 通过 npm 全局安装
  ${ACCENT}3)${NC} 通过 pnpm 全局安装

${WARN}→${NC} 请输入 1、2 或 3:
EOF
)" || true)"

    case "$choice" in
        1)
            echo "git"
            return 0
            ;;
        2)
            echo "npm"
            return 0
            ;;
        3)
            echo "pnpm"
            return 0
            ;;
    esac

    return 1
}

choose_registry_interactive() {
    if [[ "${NPM_REGISTRY:-}" == "auto" ]]; then
        auto_select_fastest_registry
        return 0
    fi
    if [[ -n "$NPM_REGISTRY" ]]; then
        return 0
    fi
    if [[ "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "pnpm" ]]; then
        return 0
    fi
    if ! is_promptable; then
        return 1
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local selection
        selection="$("$GUM" choose \
            --header "选择 npm 源（国内推荐 taobao/tencent/tsinghua）" \
            --cursor-prefix "❯ " \
            "npm      · 官方源 (registry.npmjs.org)" \
            "taobao   · 淘宝镜像 (npmmirror.com)" \
            "tencent  · 腾讯云镜像" \
            "tsinghua · 清华镜像" \
            "ustc     · 中科大镜像" \
            "163      · 网易镜像" \
            "huawei   · 华为云镜像" \
            "cnpm     · cnpm 镜像" \
            "跳过     · 使用当前默认源" < /dev/tty || true)"

        case "$selection" in
            npm*)
                NPM_REGISTRY="npm"
                return 0
                ;;
            taobao*)
                NPM_REGISTRY="taobao"
                return 0
                ;;
            tencent*)
                NPM_REGISTRY="tencent"
                return 0
                ;;
            tsinghua*)
                NPM_REGISTRY="tsinghua"
                return 0
                ;;
            ustc*)
                NPM_REGISTRY="ustc"
                return 0
                ;;
            163*)
                NPM_REGISTRY="163"
                return 0
                ;;
            huawei*)
                NPM_REGISTRY="huawei"
                return 0
                ;;
            cnpm*)
                NPM_REGISTRY="cnpm"
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi

    local choice=""
    choice="$(prompt_choice "$(cat <<EOF
${WARN}→${NC} 选择 npm 源（国内推荐 2-4）:
  1) npm 官方
  2) 淘宝镜像 (taobao)
  3) 腾讯云 (tencent)
  4) 清华 (tsinghua)
  5) 中科大 (ustc)
  6) 网易 (163)
  7) 华为云 (huawei)
  8) 跳过（使用默认）
请输入 1-8:
EOF
)" || true)"

    case "$choice" in
        1) NPM_REGISTRY="npm" ;;
        2) NPM_REGISTRY="taobao" ;;
        3) NPM_REGISTRY="tencent" ;;
        4) NPM_REGISTRY="tsinghua" ;;
        5) NPM_REGISTRY="ustc" ;;
        6) NPM_REGISTRY="163" ;;
        7) NPM_REGISTRY="huawei" ;;
        *) return 1 ;;
    esac
    return 0
}

# 根据 OPENCLAW_EDITION 返回包名
get_openclaw_package() {
    if [[ "${OPENCLAW_EDITION:-}" == "original" ]]; then
        echo "$OPENCLAW_PACKAGE_ORIGINAL"
    else
        echo "$OPENCLAW_PACKAGE_ZH"
    fi
}

# 检测当前包管理器中已安装的版本：original | zh | 空（解析输出，不依赖退出码；pnpm list 在包未安装时也返回 0）
detect_installed_edition() {
    local method="${1:-$INSTALL_METHOD}"
    if [[ "$method" == "npm" ]]; then
        local json=""
        json="$(npm list -g --depth 0 --json 2>/dev/null || true)"
        if [[ -n "$json" ]]; then
            if echo "$json" | grep -qE '"openclaw"[[:space:]]*:'; then
                echo "original"
                return 0
            fi
            if echo "$json" | grep -qE '"@qingchencloud/openclaw-zh"[[:space:]]*:'; then
                echo "zh"
                return 0
            fi
        fi
    elif [[ "$method" == "pnpm" ]]; then
        detect_pnpm_cmd 2>/dev/null || true
        if pnpm_cmd_is_ready 2>/dev/null; then
            local out=""
            out="$("${PNPM_CMD[@]}" list -g 2>/dev/null || true)"
            if [[ -n "$out" ]]; then
                if echo "$out" | grep -qE '\+ openclaw[[:space:]]'; then
                    echo "original"
                    return 0
                fi
                if echo "$out" | grep -qE '@qingchencloud/openclaw-zh'; then
                    echo "zh"
                    return 0
                fi
            fi
        fi
    fi
    echo ""
    return 1
}

choose_edition_interactive() {
    # 仅当用户显式传入 --zh/--original 等时跳过；环境变量不跳过提示
    if [[ "${OPENCLAW_EDITION_FROM_ARGS:-0}" == "1" && -n "${OPENCLAW_EDITION:-}" ]]; then
        return 0
    fi
    if [[ "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "pnpm" ]]; then
        return 0
    fi

    # 直接使用原版，不再弹出选择
    OPENCLAW_EDITION="original"
    return 0
}

# 检测当前已安装的通道：stable | beta | 空（根据版本号判断，含 nightly/next/beta 等为测试版）
detect_installed_channel() {
    local method="${1:-$INSTALL_METHOD}"
    local pkg=""
    [[ "${OPENCLAW_EDITION:-}" == "original" ]] && pkg="$OPENCLAW_PACKAGE_ORIGINAL" || pkg="$OPENCLAW_PACKAGE_ZH"
    local version=""
    if [[ "$method" == "npm" ]]; then
        local json=""
        json="$(npm list -g --depth 0 --json 2>/dev/null || true)"
        if [[ -n "$json" ]]; then
            if [[ "$pkg" == "openclaw" ]]; then
                version="$(echo "$json" | grep -A 3 '"openclaw":' | grep '"version"' | head -1 | sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
            else
                version="$(echo "$json" | grep -A 3 '"@qingchencloud/openclaw-zh":' | grep '"version"' | head -1 | sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
            fi
        fi
    elif [[ "$method" == "pnpm" ]] && pnpm_cmd_is_ready 2>/dev/null; then
        local out=""
        out="$("${PNPM_CMD[@]}" list -g 2>/dev/null || true)"
        if [[ "$pkg" == "openclaw" ]]; then
            version="$(echo "$out" | grep -oE '\+ openclaw[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $NF}')"
        else
            version="$(echo "$out" | grep -oE '\+ @qingchencloud/openclaw-zh[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $NF}')"
        fi
    fi
    [[ -z "$version" ]] && return 1
    if echo "$version" | grep -qE 'nightly|next|beta|rc|alpha|canary|preview'; then
        echo "beta"
    else
        echo "stable"
    fi
    return 0
}

choose_beta_interactive() {
    if [[ "$USE_BETA" == "1" ]]; then
        return 0
    fi
    if [[ "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "pnpm" ]]; then
        return 0
    fi

    local beta_label=""
    if [[ "${OPENCLAW_EDITION:-}" == "original" ]]; then
        beta_label="beta/next"
    else
        beta_label="nightly"
    fi

    local channel_hint=""
    local installed_edition=""
    installed_edition="$(detect_installed_edition "$INSTALL_METHOD" || true)"
    if [[ "$installed_edition" == "${OPENCLAW_EDITION:-}" ]]; then
        local ch=""
        ch="$(detect_installed_channel "$INSTALL_METHOD" 2>/dev/null || true)"
        if [[ "$ch" == "stable" ]]; then
            channel_hint="（当前已安装: 稳定版）"
        elif [[ "$ch" == "beta" ]]; then
            channel_hint="（当前已安装: 测试版）"
        fi
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local selection
        selection="$("$GUM" choose \
            --header "选择版本通道 ${channel_hint}" \
            --cursor-prefix "❯ " \
            "稳定版 (latest) · 推荐生产使用" \
            "测试版 ($beta_label) · 抢先体验新功能" < /dev/tty || true)"
        case "$selection" in
            稳定版*)
                USE_BETA=0
                return 0
                ;;
            测试版*)
                USE_BETA=1
                return 0
                ;;
        esac
    fi

    local choice=""
    local prompt_text="${WARN}→${NC} 选择版本通道${channel_hint}:
  1) 稳定版 (latest) - 推荐生产使用
  2) 测试版 ($beta_label) - 抢先体验新功能
请输入序号 (1-2):"
    choice="$(prompt_choice "$prompt_text" || true)"

    case "$choice" in
        1)
            USE_BETA=0
            return 0
            ;;
        2)
            USE_BETA=1
            return 0
            ;;
    esac

    USE_BETA=0
    return 0
}

# 检查指定包是否已全局安装（解析输出，不依赖退出码）
package_installed_globally() {
    local pkg="$1"
    local method="${2:-$INSTALL_METHOD}"
    if [[ "$method" == "npm" ]]; then
        local json=""
        json="$(npm list -g --depth 0 --json 2>/dev/null || true)"
        if [[ -n "$json" ]]; then
            if [[ "$pkg" == "openclaw" ]]; then
                echo "$json" | grep -qE '"openclaw"[[:space:]]*:' && return 0
            elif [[ "$pkg" == "@qingchencloud/openclaw-zh" ]]; then
                echo "$json" | grep -qE '"@qingchencloud/openclaw-zh"[[:space:]]*:' && return 0
            fi
        fi
    elif [[ "$method" == "pnpm" ]]; then
        local out=""
        out="$("${PNPM_CMD[@]}" list -g 2>/dev/null || true)"
        if [[ -n "$out" ]]; then
            if [[ "$pkg" == "openclaw" ]]; then
                echo "$out" | grep -qE '\+ openclaw[[:space:]]' && return 0
            elif [[ "$pkg" == "@qingchencloud/openclaw-zh" ]]; then
                echo "$out" | grep -qE '@qingchencloud/openclaw-zh' && return 0
            fi
        fi
    fi
    return 1
}

# 切换版本时：完全卸载两个包并清除缓存
uninstall_both_and_clear_cache() {
    local method="${1:-$INSTALL_METHOD}"
    ui_info "正在完全卸载旧版本并清除缓存…"

    if [[ "$method" == "npm" ]]; then
        package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "$method" && npm uninstall -g "$OPENCLAW_PACKAGE_ORIGINAL" >/dev/null 2>&1 || true
        package_installed_globally "$OPENCLAW_PACKAGE_ZH" "$method" && npm uninstall -g "$OPENCLAW_PACKAGE_ZH" >/dev/null 2>&1 || true
        cleanup_npm_openclaw_paths
        run_quiet_step "清除 npm 缓存" npm cache clean --force || true
    elif [[ "$method" == "pnpm" ]]; then
        detect_pnpm_cmd 2>/dev/null || true
        if pnpm_cmd_is_ready 2>/dev/null; then
            package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "$method" && \
                "${PNPM_CMD[@]}" remove -g "$OPENCLAW_PACKAGE_ORIGINAL" >/dev/null 2>&1 || true
            package_installed_globally "$OPENCLAW_PACKAGE_ZH" "$method" && \
                "${PNPM_CMD[@]}" remove -g "$OPENCLAW_PACKAGE_ZH" >/dev/null 2>&1 || true
            run_quiet_step "清除 pnpm 存储" "${PNPM_CMD[@]}" store prune || true
        fi
    fi

    ui_success "旧版本已卸载，缓存已清除"
}

detect_openclaw_checkout() {
    local dir="$1"
    if [[ ! -f "$dir/package.json" ]]; then
        return 1
    fi
    if [[ ! -f "$dir/pnpm-workspace.yaml" ]]; then
        return 1
    fi
    if ! grep -q '"name"[[:space:]]*:[[:space:]]*"openclaw"' "$dir/package.json" 2>/dev/null; then
        return 1
    fi
    echo "$dir"
    return 0
}

is_macos_admin_user() {
    if [[ "$OS" != "macos" ]]; then
        return 0
    fi
    if is_root; then
        return 0
    fi
    id -Gn "$(id -un)" 2>/dev/null | grep -qw "admin"
}

print_homebrew_admin_fix() {
    local current_user
    current_user="$(id -un 2>/dev/null || echo "${USER:-当前用户}")"
    echo ""
    ui_hr 50 "─"
    ui_error "安装 Homebrew 需要 macOS 管理员账户"
    echo -e "  ${MUTED}当前用户${NC} ${current_user} 不在 admin 组中"
    echo ""
    echo -e "  ${ACCENT}解决方案:${NC}"
    echo -e "  1) 使用管理员账户重新运行安装器"
    echo -e "  2) 请管理员执行: ${INFO}sudo dseditgroup -o edit -a ${current_user} -t user admin${NC}"
    echo -e "  3) 或安装 Homebrew 国内源:"
    echo -e "     ${INFO}/bin/zsh -c \"\$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)\"${NC}"
    ui_hr 50 "─"
    echo ""
}

HOMEBREW_CN_INSTALL_URL="${OPENCLAW_HOMEBREW_INSTALL_URL:-https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh}"

install_homebrew() {
    if [[ "$OS" != "macos" ]]; then
        return 0
    fi
    if command -v brew &> /dev/null; then
        ui_success "Homebrew 已安装"
        return 0
    fi
    # Homebrew 安装依赖 Xcode 命令行工具（含 Git），先检测
    if ! xcode-select -p >/dev/null 2>&1; then
        echo ""
        ui_hr 48 "─"
        ui_warn "未找到 Homebrew，且当前为非交互式终端，无法安装"
        echo -e "  ${ERROR}✗${NC} Xcode 命令行工具（含 Git）未安装"
        echo -e "  ${ERROR}✗${NC} Homebrew 未安装"
        echo ""
        ui_info "正在触发 Xcode 命令行工具安装弹窗…"
        xcode-select --install 2>/dev/null || true
        echo ""
        echo -e "  ${ACCENT}请按以下顺序操作:${NC}"
        echo -e "  1) 等待 macOS 弹窗完成 Xcode 命令行工具安装"
        echo -e "  2) 在交互式终端中安装 Homebrew 国内源:"
        echo -e "     ${INFO}/bin/zsh -c \"\$(curl -fsSL ${HOMEBREW_CN_INSTALL_URL})\"${NC}"
        echo -e "  3) 重新运行本安装器"
        ui_hr 48 "─"
        echo ""
        exit 1
    fi
    if is_non_interactive_shell; then
        echo ""
        ui_hr 48 "─"
        ui_warn "未找到 Homebrew，且当前为非交互式终端，无法安装"
        echo -e "  ${SUCCESS}✓${NC} Xcode 命令行工具已就绪"
        echo -e "  ${ERROR}✗${NC} Homebrew 未安装"
        echo ""
        echo -e "  ${MUTED}请先在交互式终端中安装 Homebrew 国内源:${NC}"
        echo -e "    ${INFO}/bin/zsh -c \"\$(curl -fsSL ${HOMEBREW_CN_INSTALL_URL})\"${NC}"
        ui_hr 48 "─"
        echo ""
        return 1
    fi
    if ! is_macos_admin_user; then
        print_homebrew_admin_fix
        exit 1
    fi
    ui_info "未找到 Homebrew，正在使用国内源安装"
    ui_info "安装脚本: ${HOMEBREW_CN_INSTALL_URL}"
    if [[ -r /dev/tty && -w /dev/tty ]]; then
        </dev/tty /bin/zsh -c "$(curl -fsSL "${HOMEBREW_CN_INSTALL_URL}")" || {
            ui_error "Homebrew 安装失败"
            return 1
        }
    else
        /bin/zsh -c "$(curl -fsSL "${HOMEBREW_CN_INSTALL_URL}")" || {
            ui_error "Homebrew 安装失败"
            return 1
        }
    fi

    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    ui_success "Homebrew 安装完成"
}

node_major_version() {
    if ! command -v node &> /dev/null; then
        return 1
    fi
    local version major
    version="$(node -v 2>/dev/null || true)"
    major="${version#v}"
    major="${major%%.*}"
    if [[ "$major" =~ ^[0-9]+$ ]]; then
        echo "$major"
        return 0
    fi
    return 1
}

print_active_node_paths() {
    if ! command -v node &> /dev/null; then
        return 1
    fi
    local node_path node_version npm_path npm_version
    node_path="$(command -v node 2>/dev/null || true)"
    node_version="$(node -v 2>/dev/null || true)"
    ui_info "当前 Node.js: ${node_version:-未知} (${node_path:-未知})"

    if command -v npm &> /dev/null; then
        npm_path="$(command -v npm 2>/dev/null || true)"
        npm_version="$(npm -v 2>/dev/null || true)"
        ui_info "当前 npm: ${npm_version:-未知} (${npm_path:-未知})"
    fi
    return 0
}

N_PREFIX="${N_PREFIX:-$HOME/.local}"

ensure_n_node_active() {
    local n_bin="${N_PREFIX}/bin"
    if [[ -x "${n_bin}/node" ]]; then
        export PATH="${n_bin}:$PATH"
        refresh_shell_command_cache
    fi

    local major=""
    major="$(node_major_version || true)"
    if [[ -n "$major" && "$major" -ge 24 ]]; then
        return 0
    fi

    local active_path active_version
    active_path="$(command -v node 2>/dev/null || echo "未找到")"
    active_version="$(node -v 2>/dev/null || echo "缺失")"

    ui_error "Node.js v24 已通过 n 安装，但当前 shell 使用的是 ${active_version} (${active_path})"
    echo -e "  ${MUTED}请将以下内容添加到 shell 配置文件并重启:${NC}"
    echo -e "  ${ACCENT}export PATH=\"${n_bin}:\$PATH\"${NC}"
    return 1
}

# curl|bash 启动的 shell 通常未加载 .zprofile/.bashrc，PATH 中无 ~/.local/bin
# 预先加入常见 Node 安装路径，避免每次误判为「未安装」而重复安装
preload_node_paths() {
    local dir
    for dir in "$HOME/.local/bin" "/usr/local/bin"; do
        if [[ -x "${dir}/node" ]]; then
            export PATH="${dir}:${PATH}"
            hash -r 2>/dev/null || true
            return 0
        fi
    done
    if [[ -n "${NVM_DIR:-}" && -d "${NVM_DIR}/current/bin" && -x "${NVM_DIR}/current/bin/node" ]]; then
        export PATH="${NVM_DIR}/current/bin:${PATH}"
        hash -r 2>/dev/null || true
    fi
    return 0
}

check_node() {
    preload_node_paths
    if command -v node &> /dev/null; then
        NODE_VERSION="$(node_major_version || true)"
        if [[ -n "$NODE_VERSION" && "$NODE_VERSION" -ge 24 ]]; then
            ui_success "Node.js 已就绪 v$(node -v | cut -d'v' -f2)，跳过安装"
            ensure_user_local_bin_on_path
            print_active_node_paths || true
            return 0
        else
            if [[ -n "$NODE_VERSION" ]]; then
                ui_info "已找到 Node.js $(node -v)，正在升级到 v24+"
            else
                ui_info "已找到 Node.js 但无法解析版本；正在重新安装 v24+"
            fi
            return 1
        fi
    else
        ui_info "未找到 Node.js，正在安装"
        return 1
    fi
}

install_node() {
    ui_info "通过 n 版本管理器安装 Node.js LTS (v24)"
    ensure_user_local_bin_on_path

    if [[ "$OS" == "linux" ]]; then
        ui_info "安装 Linux 构建工具（make/g++/cmake/python3）"
        if install_build_tools_linux; then
            ui_success "构建工具安装完成"
        else
            ui_warn "继续安装，未自动安装构建工具"
        fi
    fi

    local n_script n_url
    n_url="$(apply_github_proxy "https://raw.githubusercontent.com/tj/n/master/bin/n")"
    n_script="$(mktempfile)"
    download_file "$n_url" "$n_script"

    export N_PREFIX="${N_PREFIX:-$HOME/.local}"
    mkdir -p "$N_PREFIX/bin" "$N_PREFIX/lib" "$N_PREFIX/include" "$N_PREFIX/share"
    export PATH="${N_PREFIX}/bin:$PATH"

    export N_NODE_MIRROR="${N_NODE_MIRROR:-https://npmmirror.com/mirrors/node}"

    if ! run_quiet_step "安装 Node.js v24 (n 24)" bash "$n_script" 24; then
        ui_warn "n 24 失败，尝试 n lts"
        if ! run_quiet_step "安装 Node.js LTS (n lts)" bash "$n_script" lts; then
            ui_error "n 安装 Node.js 失败"
            echo -e "  ${MUTED}请手动安装 Node.js 24+:${NC} ${INFO}https://nodejs.org${NC}"
            echo -e "  ${MUTED}或使用:${NC} ${ACCENT}curl -L https://bit.ly/n-install | bash -s -- 24${NC}"
            exit 1
        fi
    fi

    if ! ensure_n_node_active; then
        exit 1
    fi
    ui_success "Node.js 安装完成（n 版本管理器）"
    print_active_node_paths || true
}

check_git() {
    if command -v git &> /dev/null; then
        ui_success "Git 已就绪，跳过安装"
        return 0
    fi
    ui_info "未找到 Git，正在安装"
    return 1
}

# 配置 Git 使用 HTTPS 替代 SSH 访问 GitHub（避免 libsignal-node 等依赖的 Host key verification failed）
# 并预添加 GitHub 主机密钥到 known_hosts，避免首次 SSH 连接时的交互提示
configure_git_github_https() {
    if ! command -v git &> /dev/null; then
        return 0
    fi
    git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true
    git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" 2>/dev/null || true
    # 预添加 GitHub 主机密钥，避免 "The authenticity of host 'github.com' can't be established" 交互提示
    if command -v ssh-keyscan &> /dev/null; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh" 2>/dev/null || true
        if ! grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
            ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
        fi
    fi
    ui_info "已配置 Git 使用 HTTPS 访问 GitHub（pnpm/npm 依赖 libsignal-node）"
}

is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

maybe_sudo() {
    if is_root; then
        if [[ "${1:-}" == "-E" ]]; then
            shift
        fi
        "$@"
    else
        sudo "$@"
    fi
}

require_sudo() {
    if [[ "$OS" != "linux" ]]; then
        return 0
    fi
    if is_root; then
        return 0
    fi
    if command -v sudo &> /dev/null; then
        if ! sudo -n true >/dev/null 2>&1; then
            ui_info "需要管理员权限；请输入密码"
            sudo -v
        fi
        return 0
    fi
    ui_error "Linux 系统安装需要 sudo"
    echo -e "  ${MUTED}请安装 sudo 或以 root 身份重新运行${NC}"
    exit 1
}

install_git() {
    if [[ "$OS" == "macos" ]]; then
        run_quiet_step "安装 Git" brew install git
    elif [[ "$OS" == "linux" ]]; then
        require_sudo
        if command -v apt-get &> /dev/null; then
            if is_root; then
                run_quiet_step "更新软件包索引" apt-get update -qq
                run_quiet_step "安装 Git" apt-get install -y -qq git
            else
                run_quiet_step "更新软件包索引" sudo apt-get update -qq
                run_quiet_step "安装 Git" sudo apt-get install -y -qq git
            fi
        elif command -v dnf &> /dev/null; then
            if is_root; then
                run_quiet_step "安装 Git" dnf install -y -q git
            else
                run_quiet_step "安装 Git" sudo dnf install -y -q git
            fi
        elif command -v yum &> /dev/null; then
            if is_root; then
                run_quiet_step "安装 Git" yum install -y -q git
            else
                run_quiet_step "安装 Git" sudo yum install -y -q git
            fi
        else
            ui_error "无法检测到 Git 的包管理器"
            exit 1
        fi
    fi
    ui_success "Git 安装完成"
}

fix_npm_permissions() {
    if [[ "$OS" != "linux" ]]; then
        return 0
    fi

    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -z "$npm_prefix" ]]; then
        return 0
    fi

    if [[ -w "$npm_prefix" || -w "$npm_prefix/lib" ]]; then
        return 0
    fi

    ui_info "正在配置 npm 用户本地安装"
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"

    # shellcheck disable=SC2016
    local path_line='export PATH="$HOME/.npm-global/bin:$PATH"'
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -q ".npm-global" "$rc"; then
            echo "$path_line" >> "$rc"
        fi
    done

    export PATH="$HOME/.npm-global/bin:$PATH"
    ui_success "npm 已配置为用户安装"
}

ensure_openclaw_bin_link() {
    local npm_root=""
    npm_root="$(npm root -g 2>/dev/null || true)"
    if [[ -z "$npm_root" || ! -d "$npm_root/openclaw" ]]; then
        return 1
    fi
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ -z "$npm_bin" ]]; then
        return 1
    fi
    mkdir -p "$npm_bin"
    if [[ ! -x "${npm_bin}/openclaw" ]]; then
        ln -sf "$npm_root/openclaw/dist/entry.js" "${npm_bin}/openclaw"
        ui_info "已在 ${npm_bin}/openclaw 创建 openclaw 链接"
    fi
    repair_openclaw_bin_from_globals || true
    return 0
}

openclaw_is_usable() {
    local bin="${1:-}"
    if [[ -z "$bin" || ! -x "$bin" ]]; then
        return 1
    fi
    local out=""
    local err=""
    local status=0
    local tmp_err=""
    tmp_err="$(mktempfile)"
    set +e
    out="$("$bin" --version 2>"$tmp_err")"
    status=$?
    set -e
    err="$(cat "$tmp_err" 2>/dev/null || true)"
    rm -f "$tmp_err" 2>/dev/null || true

    if [[ "$status" -eq 0 ]]; then
        return 0
    fi

    local combined="${out}
${err}"
    if echo "$combined" | grep -Eiq 'inappropriate ioctl for device|not a tty|not attached to a tty'; then
        if [[ "${OPENCLAW_WARNED_TTY_BIN}" != "$bin" ]]; then
            ui_warn "检测到 openclaw 在无 TTY 环境下返回终端错误，按已安装处理: ${bin}"
            OPENCLAW_WARNED_TTY_BIN="$bin"
        fi
        return 0
    fi

    if echo "$combined" | grep -Eiq 'Node\.js v[0-9]+\.[0-9]+\+ is required'; then
        if [[ "${OPENCLAW_WARNED_NODE_REQUIREMENT}" != "1" ]]; then
            ui_warn "openclaw 已安装，但当前 Node.js 版本不满足要求"
            print_active_node_paths || true
            OPENCLAW_WARNED_NODE_REQUIREMENT=1
        fi
    fi
    return 1
}

resolve_openclaw_bin_relaxed() {
    local resolved=""

    resolved="$(resolve_command_path openclaw 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ -n "$npm_bin" && -x "${npm_bin}/openclaw" ]]; then
        echo "${npm_bin}/openclaw"
        return 0
    fi

    local pnpm_bin=""
    pnpm_bin="$(pnpm_global_bin_dir || true)"
    if [[ -n "$pnpm_bin" && -x "${pnpm_bin}/openclaw" ]]; then
        echo "${pnpm_bin}/openclaw"
        return 0
    fi

    if [[ -x "$(pnpm_default_home)/openclaw" ]]; then
        echo "$(pnpm_default_home)/openclaw"
        return 0
    fi
    if [[ -x "${HOME}/.local/bin/openclaw" ]]; then
        echo "${HOME}/.local/bin/openclaw"
        return 0
    fi

    return 1
}

find_openclaw_entrypoint() {
    local -a roots=()
    local npm_root=""
    local pnpm_root=""

    npm_root="$(npm root -g 2>/dev/null || true)"
    pnpm_root="$(pnpm root -g 2>/dev/null || true)"

    [[ -n "$npm_root" ]] && roots+=("$npm_root")
    [[ -n "$pnpm_root" ]] && roots+=("$pnpm_root")

    local root pkg bin_rel
    for root in "${roots[@]}"; do
        for pkg in openclaw "@qingchencloud/openclaw-zh"; do
            if [[ -f "${root}/${pkg}/package.json" ]]; then
                bin_rel="$(node -e '
const fs = require("fs");
const p = process.argv[1];
const j = JSON.parse(fs.readFileSync(p, "utf8"));
const bin = j.bin;
if (typeof bin === "string") process.stdout.write(bin);
else if (bin && typeof bin.openclaw === "string") process.stdout.write(bin.openclaw);
' "${root}/${pkg}/package.json" 2>/dev/null || true)"
                if [[ -n "$bin_rel" && -f "${root}/${pkg}/${bin_rel}" ]]; then
                    echo "${root}/${pkg}/${bin_rel}"
                    return 0
                fi
            fi
        done
    done

    echo ""
    return 1
}

repair_openclaw_bin_from_globals() {
    local entry=""
    entry="$(find_openclaw_entrypoint || true)"
    if [[ -z "$entry" || ! -f "$entry" ]]; then
        return 1
    fi

    local node_bin=""
    node_bin="$(command -v node 2>/dev/null || true)"
    if [[ -z "$node_bin" ]]; then
        for node_bin in "/opt/homebrew/opt/node@24/bin/node" "/opt/homebrew/bin/node" "/usr/local/bin/node" "${HOME}/.local/bin/node"; do
            if [[ -x "$node_bin" ]]; then
                break
            fi
        done
    fi

    ensure_user_local_bin_on_path
    local wrapper="${HOME}/.local/bin/openclaw"
    cat > "$wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if command -v node >/dev/null 2>&1; then
    exec node "$(printf '%s' "$entry")" "\$@"
fi
if [[ -n "$(printf '%s' "$node_bin")" ]] && [[ -x "$(printf '%s' "$node_bin")" ]]; then
    exec "$(printf '%s' "$node_bin")" "$(printf '%s' "$entry")" "\$@"
fi
echo "openclaw: node runtime not found in PATH" >&2
exit 127
EOF
    chmod +x "$wrapper"

    ensure_dir_in_shell_path "${HOME}/.local/bin" "用户本地 bin 目录 (~/.local/bin)" || true
    if ! path_has_dir "${PATH:-}" "${HOME}/.local/bin"; then
        export PATH="${HOME}/.local/bin:${PATH:-}"
    fi
    refresh_shell_command_cache
    return 0
}

check_existing_openclaw() {
    if [[ -n "$(resolve_command_path openclaw 2>/dev/null || true)" ]]; then
        ui_info "检测到已有 OpenClaw 安装，正在升级"
        return 0
    fi
    return 1
}

set_pnpm_cmd() {
    PNPM_CMD=("$@")
}

pnpm_cmd_pretty() {
    if [[ ${#PNPM_CMD[@]} -eq 0 ]]; then
        echo ""
        return 1
    fi
    printf '%s' "${PNPM_CMD[*]}"
    return 0
}

pnpm_cmd_is_ready() {
    if [[ ${#PNPM_CMD[@]} -eq 0 ]]; then
        return 1
    fi
    "${PNPM_CMD[@]}" --version >/dev/null 2>&1
}

detect_pnpm_cmd() {
    if command -v pnpm &> /dev/null; then
        set_pnpm_cmd pnpm
        return 0
    fi
    if command -v corepack &> /dev/null; then
        if corepack pnpm --version >/dev/null 2>&1; then
            set_pnpm_cmd corepack pnpm
            return 0
        fi
    fi
    return 1
}

# 获取 pnpm 默认的全局 bin 目录路径（与 pnpm setup 一致）
pnpm_default_home() {
    case "${OS:-unknown}" in
        macos) echo "${HOME}/Library/pnpm" ;;
        linux) echo "${HOME}/.local/share/pnpm" ;;
        *)     echo "${HOME}/.local/share/pnpm" ;;
    esac
}

# 确保 pnpm 全局 bin 目录已配置（解决 ERR_PNPM_NO_GLOBAL_BIN_DIR）
ensure_pnpm_global_bin_config() {
    local home_dir=""
    if [[ -n "${PNPM_HOME:-}" ]]; then
        home_dir="$PNPM_HOME"
    else
        home_dir="$(pnpm_default_home)"
    fi
    mkdir -p "$home_dir"
    export PNPM_HOME="$home_dir"
    if ! path_has_dir "${PATH:-}" "${PNPM_HOME}"; then
        export PATH="${PNPM_HOME}:${PATH:-}"
    fi
    if [[ ${#PNPM_CMD[@]} -gt 0 ]] && pnpm_cmd_is_ready 2>/dev/null; then
        "${PNPM_CMD[@]}" config set global-bin-dir "${PNPM_HOME}" >/dev/null 2>&1 || true
    elif command -v pnpm &>/dev/null; then
        pnpm config set global-bin-dir "${PNPM_HOME}" >/dev/null 2>&1 || true
    fi
    return 0
}

# 将 pnpm 全局 bin 目录写入 shell 配置，确保新终端可用
ensure_pnpm_bin_in_shell_config() {
    local dir="${PNPM_HOME:-$(pnpm_default_home)}"
    [[ -n "$dir" && -d "$dir" ]] || return 0
    ensure_dir_in_shell_path "$dir" "pnpm 全局 bin 目录"
}

# 当使用 corepack pnpm 时，在 ~/.local/bin 创建 pnpm 包装器，确保新终端可用
ensure_pnpm_wrapper_in_local_bin() {
    if [[ "${PNPM_CMD[*]}" != "corepack pnpm" ]] || ! command -v corepack &>/dev/null; then
        return 0
    fi
    ensure_user_local_bin_on_path
    local user_pnpm="${HOME}/.local/bin/pnpm"
    if [[ ! -x "$user_pnpm" ]] || ! grep -q "corepack pnpm" "$user_pnpm" 2>/dev/null; then
        cat >"${user_pnpm}" <<'PNPMWRAP'
#!/usr/bin/env bash
set -euo pipefail
exec corepack pnpm "$@"
PNPMWRAP
        chmod +x "${user_pnpm}"
    fi
}

ensure_pnpm() {
    if detect_pnpm_cmd && pnpm_cmd_is_ready; then
        ensure_pnpm_global_bin_config
        ensure_pnpm_bin_in_shell_config
        ensure_pnpm_wrapper_in_local_bin
        ui_success "pnpm 已就绪 ($(pnpm_cmd_pretty))，跳过安装"
        return 0
    fi

    # 优先使用 npm 全局安装（更稳定），Corepack 作为备选
    ui_info "通过 npm 安装 pnpm"
    fix_npm_permissions
    if run_quiet_step "安装 pnpm" npm install -g pnpm@10; then
        refresh_shell_command_cache
        if detect_pnpm_cmd && pnpm_cmd_is_ready; then
            ensure_pnpm_global_bin_config
            ensure_pnpm_bin_in_shell_config
            ui_success "pnpm 就绪 ($(pnpm_cmd_pretty))"
            return 0
        fi
    fi

    if command -v corepack &> /dev/null; then
        ui_info "npm 安装失败，尝试 Corepack"
        corepack enable >/dev/null 2>&1 || true
        if run_quiet_step "激活 pnpm" corepack prepare pnpm@10 --activate; then
            refresh_shell_command_cache
            if detect_pnpm_cmd && pnpm_cmd_is_ready; then
                ensure_pnpm_global_bin_config
                ensure_pnpm_bin_in_shell_config
                ensure_pnpm_wrapper_in_local_bin
                ui_success "pnpm 就绪 (corepack)"
                return 0
            fi
        fi
    fi

    ui_error "pnpm 安装失败"
    return 1
}

ensure_pnpm_binary_for_scripts() {
    if command -v pnpm >/dev/null 2>&1; then
        return 0
    fi

    if command -v corepack >/dev/null 2>&1; then
        ui_info "确保 pnpm 命令可用"
        corepack enable >/dev/null 2>&1 || true
        corepack prepare pnpm@10 --activate >/dev/null 2>&1 || true
        refresh_shell_command_cache
        if command -v pnpm >/dev/null 2>&1; then
            ui_success "已通过 Corepack 启用 pnpm 命令"
            return 0
        fi
    fi

    if [[ "${PNPM_CMD[*]}" == "corepack pnpm" ]] && command -v corepack >/dev/null 2>&1; then
        ensure_user_local_bin_on_path
        local user_pnpm="${HOME}/.local/bin/pnpm"
        cat >"${user_pnpm}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec corepack pnpm "$@"
EOF
        chmod +x "${user_pnpm}"
        refresh_shell_command_cache

        if command -v pnpm >/dev/null 2>&1; then
            ui_warn "pnpm shim 不在 PATH；已在 ${user_pnpm} 安装用户本地包装器"
            return 0
        fi
    fi

    ui_error "pnpm 命令在 PATH 中不可用"
    ui_info "请全局安装 pnpm (npm install -g pnpm@10) 后重试"
    return 1
}

run_pnpm() {
    if ! pnpm_cmd_is_ready; then
        ensure_pnpm
    fi
    "${PNPM_CMD[@]}" "$@"
}

ensure_user_local_bin_on_path() {
    local target="$HOME/.local/bin"
    mkdir -p "$target"

    export PATH="$target:$PATH"

    # shellcheck disable=SC2016
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    # macOS zsh 登录 shell 加载 .zprofile，需写入以在新终端生效
    local added=false
    for rc in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$rc" ]] && ! grep -q ".local/bin" "$rc"; then
            echo "$path_line" >> "$rc"
            added=true
        fi
    done
    if [[ "$added" != "true" ]] && [[ "${OS:-}" == "macos" ]] && [[ ! -f "$HOME/.zprofile" ]]; then
        touch "$HOME/.zprofile"
        echo "$path_line" >> "$HOME/.zprofile"
    fi
}

npm_global_bin_dir() {
    local prefix=""
    prefix="$(npm prefix -g 2>/dev/null || true)"
    if [[ -n "$prefix" ]]; then
        if [[ "$prefix" == /* ]]; then
            echo "${prefix%/}/bin"
            return 0
        fi
    fi

    prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$prefix" && "$prefix" != "undefined" && "$prefix" != "null" ]]; then
        if [[ "$prefix" == /* ]]; then
            echo "${prefix%/}/bin"
            return 0
        fi
    fi

    echo ""
    return 1
}

pnpm_global_bin_dir() {
    local bin_dir=""
    if [[ ${#PNPM_CMD[@]} -gt 0 ]] && pnpm_cmd_is_ready 2>/dev/null; then
        bin_dir="$("${PNPM_CMD[@]}" bin -g 2>/dev/null || true)"
    elif command -v pnpm &>/dev/null; then
        bin_dir="$(pnpm bin -g 2>/dev/null || true)"
    fi
    if [[ -n "$bin_dir" && -d "$bin_dir" ]]; then
        echo "$bin_dir"
        return 0
    fi

    bin_dir=""
    if [[ ${#PNPM_CMD[@]} -gt 0 ]] && pnpm_cmd_is_ready 2>/dev/null; then
        bin_dir="$("${PNPM_CMD[@]}" config get global-bin-dir 2>/dev/null || true)"
    elif command -v pnpm &>/dev/null; then
        bin_dir="$(pnpm config get global-bin-dir 2>/dev/null || true)"
    fi
    if [[ -n "$bin_dir" && "$bin_dir" != "undefined" && "$bin_dir" != "null" && -d "$bin_dir" ]]; then
        echo "$bin_dir"
        return 0
    fi

    if [[ -n "${PNPM_HOME:-}" && -d "${PNPM_HOME}" ]]; then
        echo "${PNPM_HOME}"
        return 0
    fi

    local fallback_home=""
    fallback_home="$(pnpm_default_home)"
    if [[ -d "$fallback_home" ]]; then
        echo "$fallback_home"
        return 0
    fi

    local root_dir=""
    if [[ ${#PNPM_CMD[@]} -gt 0 ]] && pnpm_cmd_is_ready 2>/dev/null; then
        root_dir="$("${PNPM_CMD[@]}" root -g 2>/dev/null || true)"
    elif command -v pnpm &>/dev/null; then
        root_dir="$(pnpm root -g 2>/dev/null || true)"
    fi
    if [[ "$root_dir" == */global/*/node_modules ]]; then
        bin_dir="${root_dir%/global/*/node_modules}"
        if [[ -n "$bin_dir" && -d "$bin_dir" ]]; then
            echo "$bin_dir"
            return 0
        fi
    fi

    echo ""
    return 1
}

refresh_shell_command_cache() {
    hash -r 2>/dev/null || true
    rehash 2>/dev/null || true
}

# 兼容 bash 和 zsh 的命令路径解析
# type -P 在 zsh 中不工作，使用 command -v 作为回退
resolve_command_path() {
    local cmd="${1:-}"
    local path=""

    # 优先使用 whence -p（zsh 原生）或 type -P（bash 原生）
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        path="$(whence -p "$cmd" 2>/dev/null || true)"
    else
        path="$(type -P "$cmd" 2>/dev/null || true)"
    fi

    if [[ -n "$path" && -x "$path" ]]; then
        echo "$path"
        return 0
    fi

    # 回退到 command -v（POSIX 兼容）
    path="$(command -v "$cmd" 2>/dev/null || true)"
    if [[ -n "$path" && -x "$path" && "$path" == /* ]]; then
        echo "$path"
        return 0
    fi

    # 最后尝试 which
    path="$(which "$cmd" 2>/dev/null || true)"
    if [[ -n "$path" && -x "$path" && "$path" == /* ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

path_has_dir() {
    local path="$1"
    local dir="${2%/}"
    if [[ -z "$dir" ]]; then
        return 1
    fi
    case ":${path}:" in
        *":${dir}:"*) return 0 ;;
        *) return 1 ;;
    esac
}

# 将目录追加到 shell 配置的 PATH（若尚未存在）
ensure_dir_in_shell_path() {
    local dir="${1%/}"
    local label="$2"
    if [[ -z "$dir" || ! -d "$dir" ]]; then
        return 0
    fi

    local path_line="export PATH=\"${dir}:\$PATH\""
    local rc=""
    for rc in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [[ -f "$rc" ]] && grep -qF "${dir}" "$rc" 2>/dev/null; then
            return 0
        fi
    done

    local target=""
    if [[ "${SHELL:-}" == *"zsh"* || "${OS:-}" == "macos" ]]; then
        target="$HOME/.zprofile"
    elif [[ "${SHELL:-}" == *"bash"* ]]; then
        target="$HOME/.bashrc"
    else
        target="$HOME/.profile"
    fi
    [[ -f "$target" ]] || touch "$target"
    echo "" >> "$target"
    echo "# OpenClaw / pnpm 全局 bin" >> "$target"
    echo "$path_line" >> "$target"
    ui_success "已将 ${label} 写入 ${target}"
    return 0
}

warn_shell_path_missing_dir() {
    local dir="${1%/}"
    local label="$2"
    if [[ -z "$dir" ]]; then
        return 0
    fi
    if path_has_dir "$ORIGINAL_PATH" "$dir"; then
        return 0
    fi
    if ensure_dir_in_shell_path "$dir" "$label"; then
        return 0
    fi
    echo ""
    ui_warn "PATH 缺少 ${label}: ${dir}"
    echo "  这可能导致新终端中 openclaw 显示为「command not found」。"
    echo "  修复方法（zsh: ~/.zprofile 或 ~/.zshrc, bash: ~/.bashrc）:"
    echo "    export PATH=\"${dir}:\$PATH\""
}

ensure_npm_global_bin_on_path() {
    local bin_dir=""
    bin_dir="$(npm_global_bin_dir || true)"
    if [[ -n "$bin_dir" ]]; then
        if ! path_has_dir "${PATH:-}" "$bin_dir"; then
            export PATH="${bin_dir}:${PATH:-}"
        fi
    fi
}

ensure_pnpm_global_bin_on_path() {
    local bin_dir=""
    bin_dir="$(pnpm_global_bin_dir || true)"
    if [[ -n "$bin_dir" ]]; then
        if ! path_has_dir "${PATH:-}" "$bin_dir"; then
            export PATH="${bin_dir}:${PATH:-}"
        fi
    fi
}

ensure_global_bin_on_path() {
    ensure_npm_global_bin_on_path
    ensure_pnpm_global_bin_on_path
    if [[ -x "${HOME}/.local/bin/openclaw" ]]; then
        if ! path_has_dir "${PATH:-}" "${HOME}/.local/bin"; then
            export PATH="${HOME}/.local/bin:${PATH:-}"
        fi
    fi
    refresh_shell_command_cache
}

ensure_openclaw_path_ready() {
    local resolved=""
    resolved="$(resolve_openclaw_bin || true)"
    if ! openclaw_is_usable "$resolved"; then
        warn_openclaw_not_found || true
        resolved="$(resolve_openclaw_bin || true)"
    fi
    if ! openclaw_is_usable "$resolved"; then
        return 1
    fi

    local resolved_dir="${resolved%/*}"
    if [[ -n "$resolved_dir" && -d "$resolved_dir" ]]; then
        ensure_dir_in_shell_path "$resolved_dir" "openclaw 可执行目录" || true
        if ! path_has_dir "${PATH:-}" "$resolved_dir"; then
            export PATH="${resolved_dir}:${PATH:-}"
        fi
    fi
    refresh_shell_command_cache
    OPENCLAW_BIN="$resolved"
    return 0
}

maybe_nodenv_rehash() {
    if command -v nodenv &> /dev/null; then
        nodenv rehash >/dev/null 2>&1 || true
    fi
}

probe_openclaw_from_login_shell() {
    local candidate=""
    local -a shells=()
    if [[ -n "${SHELL:-}" && -x "${SHELL}" ]]; then
        shells+=("${SHELL}")
    fi
    [[ -x /bin/zsh ]] && shells+=("/bin/zsh")
    [[ -x /bin/bash ]] && shells+=("/bin/bash")

    local resolved=""
    for candidate in "${shells[@]}"; do
        resolved="$("$candidate" -lic 'command -v openclaw 2>/dev/null || true' 2>/dev/null | head -n1 | tr -d '\r' || true)"
        if openclaw_is_usable "$resolved"; then
            echo "$resolved"
            return 0
        fi
    done
    echo ""
    return 1
}

warn_openclaw_not_found() {
    local login_shell_bin=""
    login_shell_bin="$(probe_openclaw_from_login_shell 2>/dev/null || true)"
    if [[ -n "$login_shell_bin" ]]; then
        ui_info "当前会话尚未加载 openclaw PATH，正在从登录 shell 同步"
    else
        ui_warn "当前 shell 的 PATH 中找不到 openclaw（或 openclaw 尚未安装成功）"
        echo "  尝试: hash -r（bash）或 rehash（zsh），然后重试。"
    fi
    local t=""
    t="$(type -t openclaw 2>/dev/null || true)"
    if [[ "$t" == "alias" || "$t" == "function" ]]; then
        ui_warn "发现名为 openclaw 的 shell ${t} 可能覆盖了真实二进制"
    fi
    if command -v nodenv &> /dev/null; then
        echo -e "使用 nodenv？运行: ${INFO}nodenv rehash${NC}"
    fi

    local npm_prefix=""
    npm_prefix="$(npm prefix -g 2>/dev/null || true)"
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir 2>/dev/null || true)"
    local pnpm_bin=""
    pnpm_bin="$(pnpm_global_bin_dir 2>/dev/null || true)"
    local detected_bin=""
    if openclaw_is_usable "${npm_bin}/openclaw"; then
        detected_bin="${npm_bin}/openclaw"
    elif openclaw_is_usable "${pnpm_bin}/openclaw"; then
        detected_bin="${pnpm_bin}/openclaw"
    elif openclaw_is_usable "$(pnpm_default_home)/openclaw"; then
        detected_bin="$(pnpm_default_home)/openclaw"
    elif openclaw_is_usable "${HOME}/.local/bin/openclaw"; then
        detected_bin="${HOME}/.local/bin/openclaw"
    elif [[ -n "$login_shell_bin" ]]; then
        detected_bin="$login_shell_bin"
    else
        detected_bin="$(resolve_command_path openclaw 2>/dev/null || true)"
    fi
    if [[ -z "$detected_bin" ]]; then
        local maybe_bin=""
        for maybe_bin in "${npm_bin}/openclaw" "${pnpm_bin}/openclaw" "$(pnpm_default_home)/openclaw" "${HOME}/.local/bin/openclaw"; do
            if [[ -n "$maybe_bin" && -x "$maybe_bin" ]]; then
                local run_err=""
                run_err="$("$maybe_bin" --version 2>&1 | head -n1 || true)"
                ui_warn "检测到 openclaw 文件但当前无法运行: ${maybe_bin}"
                [[ -n "$run_err" ]] && echo -e "  诊断: ${run_err}"
                detected_bin="$maybe_bin"
                break
            fi
        done
    fi
    local detected_dir=""
    [[ -n "$detected_bin" ]] && detected_dir="${detected_bin%/*}"

    if [[ -n "$npm_bin" && -d "$npm_bin" ]]; then
        if ! path_has_dir "${PATH:-}" "$npm_bin"; then
            export PATH="${npm_bin}:${PATH:-}"
        fi
    fi
    if [[ -n "$pnpm_bin" && -d "$pnpm_bin" ]]; then
        ensure_dir_in_shell_path "$pnpm_bin" "pnpm 全局 bin 目录" || true
        if ! path_has_dir "${PATH:-}" "$pnpm_bin"; then
            export PATH="${pnpm_bin}:${PATH:-}"
        fi
    fi
    if [[ -n "$detected_dir" && -d "$detected_dir" ]]; then
        ensure_dir_in_shell_path "$detected_dir" "openclaw 可执行目录" || true
        if ! path_has_dir "${PATH:-}" "$detected_dir"; then
            export PATH="${detected_dir}:${PATH:-}"
        fi
    fi
    if openclaw_is_usable "${HOME}/.local/bin/openclaw"; then
        ensure_dir_in_shell_path "${HOME}/.local/bin" "用户本地 bin 目录 (~/.local/bin)" || true
        if ! path_has_dir "${PATH:-}" "${HOME}/.local/bin"; then
            export PATH="${HOME}/.local/bin:${PATH:-}"
        fi
    fi
    refresh_shell_command_cache

    local recovered_bin=""
    recovered_bin="$(resolve_openclaw_bin 2>/dev/null || true)"
    if ! openclaw_is_usable "$recovered_bin"; then
        repair_openclaw_bin_from_globals >/dev/null 2>&1 || true
        recovered_bin="$(resolve_openclaw_bin 2>/dev/null || true)"
    fi
    if openclaw_is_usable "$recovered_bin"; then
        ui_success "已自动修复当前会话 PATH：$(dirname "$recovered_bin")"
        echo -e "现在可直接运行: ${INFO}openclaw onboard${NC}"
        return 0
    fi

    if [[ -z "$detected_bin" ]]; then
        ui_warn "未检测到 openclaw 可执行文件；这通常表示安装步骤失败或被清理。"
    fi
    if [[ -n "$npm_prefix" ]]; then
        echo -e "npm prefix -g: ${INFO}${npm_prefix}${NC}"
    fi
    if [[ -n "$npm_bin" ]]; then
        echo -e "npm bin -g: ${INFO}${npm_bin}${NC}"
        echo -e "如需要: ${INFO}export PATH=\"${npm_bin}:\$PATH\"${NC}"
    fi
    if [[ -n "$pnpm_bin" ]]; then
        echo -e "pnpm bin -g: ${INFO}${pnpm_bin}${NC}"
        echo -e "如需要: ${INFO}export PATH=\"${pnpm_bin}:\$PATH\"${NC}"
    fi
    if [[ -n "$detected_dir" ]]; then
        echo -e "检测到 openclaw 可执行文件目录: ${INFO}${detected_dir}${NC}"
        echo -e "推荐临时修复: ${INFO}export PATH=\"${detected_dir}:\$PATH\"${NC}"
    fi
    return 1
}

resolve_openclaw_bin() {
    refresh_shell_command_cache
    local resolved=""

    resolved="$(resolve_command_path openclaw 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    ensure_global_bin_on_path
    refresh_shell_command_cache
    resolved="$(resolve_command_path openclaw 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ -n "$npm_bin" && -x "${npm_bin}/openclaw" ]]; then
        echo "${npm_bin}/openclaw"
        return 0
    fi

    local pnpm_bin=""
    pnpm_bin="$(pnpm_global_bin_dir || true)"
    if [[ -n "$pnpm_bin" && -x "${pnpm_bin}/openclaw" ]]; then
        echo "${pnpm_bin}/openclaw"
        return 0
    fi
    if [[ -x "$(pnpm_default_home)/openclaw" ]]; then
        echo "$(pnpm_default_home)/openclaw"
        return 0
    fi
    if [[ -x "${HOME}/.local/bin/openclaw" ]]; then
        echo "${HOME}/.local/bin/openclaw"
        return 0
    fi

    maybe_nodenv_rehash
    refresh_shell_command_cache
    resolved="$(resolve_command_path openclaw 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    if [[ -n "$npm_bin" && -x "${npm_bin}/openclaw" ]]; then
        echo "${npm_bin}/openclaw"
        return 0
    fi
    if [[ -n "$pnpm_bin" && -x "${pnpm_bin}/openclaw" ]]; then
        echo "${pnpm_bin}/openclaw"
        return 0
    fi
    if repair_openclaw_bin_from_globals; then
        if [[ -x "${HOME}/.local/bin/openclaw" ]]; then
            echo "${HOME}/.local/bin/openclaw"
            return 0
        fi
        resolved="$(resolve_command_path openclaw 2>/dev/null || true)"
        if [[ -n "$resolved" && -x "$resolved" ]]; then
            echo "$resolved"
            return 0
        fi
    fi
    local login_shell_bin=""
    login_shell_bin="$(probe_openclaw_from_login_shell || true)"
    if [[ -n "$login_shell_bin" && -x "$login_shell_bin" ]]; then
        echo "$login_shell_bin"
        return 0
    fi
    echo ""
    return 1
}

install_openclaw_from_git() {
    local repo_dir="$1"
    local repo_url
    local -a git_env=()
    if [[ -n "$SELECTED_PROXY" ]]; then
        repo_url="https://github.com/openclaw/openclaw.git"
        git_env=(env HTTPS_PROXY="$SELECTED_PROXY" HTTP_PROXY="$SELECTED_PROXY")
    else
        repo_url="$(apply_github_proxy "https://github.com/openclaw/openclaw.git")"
    fi

    if [[ -d "$repo_dir/.git" ]]; then
        ui_info "从 git 源码安装 OpenClaw: ${repo_dir}"
    else
        ui_info "从 GitHub 安装 OpenClaw (${repo_url})"
    fi

    if ! check_git; then
        install_git
    fi

    ensure_pnpm
    ensure_pnpm_binary_for_scripts

    if [[ ! -d "$repo_dir" ]]; then
        if [[ "$OS" == "linux" && "$repo_dir" == "/opt/OpenClaw" ]]; then
            if ! mkdir -p "$repo_dir" 2>/dev/null; then
                ui_info "正在创建 /opt/OpenClaw（需要管理员权限）"
                require_sudo
                run_quiet_step "创建目录" maybe_sudo mkdir -p "$repo_dir"
                run_quiet_step "设置所有权" maybe_sudo chown "$(whoami)" "$repo_dir"
            fi
        else
            mkdir -p "$repo_dir" 2>/dev/null || true
        fi
        run_quiet_step "克隆 OpenClaw" "${git_env[@]}" git clone "$repo_url" "$repo_dir"
    fi

    if [[ "$GIT_UPDATE" == "1" ]]; then
        if [[ -z "$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)" ]]; then
            run_quiet_step "更新仓库" "${git_env[@]}" git -C "$repo_dir" pull --rebase || true
        else
            ui_info "仓库有本地修改；跳过 git pull"
        fi
    fi

    cleanup_legacy_submodules "$repo_dir"

    local pnpm_install_args=(-C "$repo_dir" install)
    local registry_url=""
    registry_url="$(resolve_registry_url "${NPM_REGISTRY:-}" 2>/dev/null || true)"
    if [[ -n "$registry_url" ]]; then
        pnpm_install_args+=(--registry "$registry_url")
    fi
    SHARP_IGNORE_GLOBAL_LIBVIPS="$SHARP_IGNORE_GLOBAL_LIBVIPS" run_quiet_step "安装依赖" run_pnpm "${pnpm_install_args[@]}"

    if ! run_quiet_step "构建 UI" run_pnpm -C "$repo_dir" ui:build; then
        ui_warn "UI 构建失败；继续（CLI 可能仍可用）"
    fi
    run_quiet_step "构建 OpenClaw" run_pnpm -C "$repo_dir" build

    ensure_user_local_bin_on_path

    cat > "$HOME/.local/bin/openclaw" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if command -v node >/dev/null 2>&1; then
    exec node "${repo_dir}/dist/entry.js" "\$@"
fi
if [[ -x "/opt/homebrew/opt/node@24/bin/node" ]]; then
    exec "/opt/homebrew/opt/node@24/bin/node" "${repo_dir}/dist/entry.js" "\$@"
fi
if [[ -x "/opt/homebrew/bin/node" ]]; then
    exec "/opt/homebrew/bin/node" "${repo_dir}/dist/entry.js" "\$@"
fi
if [[ -x "/usr/local/bin/node" ]]; then
    exec "/usr/local/bin/node" "${repo_dir}/dist/entry.js" "\$@"
fi
echo "openclaw: node runtime not found in PATH" >&2
exit 127
EOF
    chmod +x "$HOME/.local/bin/openclaw"
    ui_success "OpenClaw 包装器已安装到 \$HOME/.local/bin/openclaw"
    ui_info "此源码使用 pnpm — 运行 pnpm install（或 corepack pnpm install）安装依赖"
}

resolve_beta_version() {
    local beta=""
    beta="$(npm_view openclaw dist-tags.beta 2>/dev/null || true)"
    if [[ -z "$beta" || "$beta" == "undefined" || "$beta" == "null" ]]; then
        return 1
    fi
    echo "$beta"
}

install_openclaw() {
    local package_name
    package_name="$(get_openclaw_package)"
    local dist_tag="latest"
    local edition_label="中文版"
    if [[ "${OPENCLAW_EDITION:-}" == "original" ]]; then
        edition_label="原版"
        if [[ "$USE_BETA" == "1" ]]; then
            dist_tag="$(resolve_beta_version 2>/dev/null || true)"
            if [[ -z "$dist_tag" ]]; then
                dist_tag="next"
            fi
            ui_info "使用测试版 (${dist_tag})"
        fi
    else
        if [[ "$USE_BETA" == "1" ]]; then
            dist_tag="nightly"
            ui_info "使用测试版 (nightly)"
        fi
    fi

    local resolved_version=""
    resolved_version="$(npm view "${package_name}@${dist_tag}" version 2>/dev/null || true)"
    if [[ -n "$resolved_version" ]]; then
        ui_info "正在安装 OpenClaw ${edition_label} v${resolved_version}"
    else
        ui_info "正在安装 OpenClaw ${edition_label} (${dist_tag})"
    fi
    local install_spec="${package_name}@${dist_tag}"

    if ! install_openclaw_npm "${install_spec}"; then
        ui_warn "npm 安装失败；正在重试"
        cleanup_npm_openclaw_paths
        install_openclaw_npm "${install_spec}"
    fi

    # 如果是 latest 且原版包，安装后未检测到命令，尝试清理后 npm 重装（只用 latest，不回退测试版）
    if [[ "$dist_tag" == "latest" && "$package_name" == "openclaw" ]]; then
        if ! resolve_openclaw_bin &> /dev/null; then
            ui_warn "openclaw@latest 安装后未检测到命令，尝试清理后重装"
            cleanup_npm_openclaw_paths
            install_openclaw_npm "${install_spec}"
        fi
    fi

    ensure_openclaw_bin_link || true

    ui_success "OpenClaw ${edition_label} 安装完成"
}


run_pnpm_global_add() {
    local spec="$1"
    local log="$2"

    if ! pnpm_cmd_is_ready; then
        ensure_pnpm
    fi
    ensure_pnpm_global_bin_config
    ensure_pnpm_bin_in_shell_config

    local -a cmd
    cmd=(env "CI=1" "npm_config_progress=false" "${PNPM_CMD[@]}")
    local registry_url=""
    registry_url="$(resolve_registry_url "${NPM_REGISTRY:-}" 2>/dev/null || true)"
    if [[ -n "$registry_url" ]]; then
        cmd+=(--registry "$registry_url")
    fi
    cmd+=(--reporter append-only)
    cmd+=(add -g "$spec")
    if [[ "$VERBOSE" == "1" ]]; then
        "${cmd[@]}" 2>&1 | tee "$log"
        return $?
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local cmd_quoted=""
        local log_quoted=""
        printf -v cmd_quoted '%q ' "${cmd[@]}"
        printf -v log_quoted '%q' "$log"
        run_with_spinner "正在安装 OpenClaw 包" bash -c "${cmd_quoted}>${log_quoted} 2>&1"
        return $?
    fi

    "${cmd[@]}" >"$log" 2>&1
}

install_openclaw_pnpm() {
    local package_name
    package_name="$(get_openclaw_package)"
    local dist_tag="latest"
    local edition_label="中文版"
    if [[ "${OPENCLAW_EDITION:-}" == "original" ]]; then
        edition_label="原版"
        if [[ "$USE_BETA" == "1" ]]; then
            dist_tag="$(resolve_beta_version 2>/dev/null || true)"
            if [[ -z "$dist_tag" ]]; then
                dist_tag="next"
            fi
            ui_info "使用测试版 (${dist_tag})"
        fi
    else
        if [[ "$USE_BETA" == "1" ]]; then
            dist_tag="nightly"
            ui_info "使用测试版 (nightly)"
        fi
    fi

    local resolved_version=""
    resolved_version="$(npm_view "${package_name}@${dist_tag}" version 2>/dev/null || true)"
    if [[ -n "$resolved_version" ]]; then
        ui_info "正在通过 pnpm 安装 OpenClaw ${edition_label} v${resolved_version}"
    else
        ui_info "正在通过 pnpm 安装 OpenClaw ${edition_label} (${dist_tag})"
    fi
    local install_spec="${package_name}@${dist_tag}"

    local log
    log="$(mktempfile)"
    if ! run_pnpm_global_add "$install_spec" "$log"; then
        ui_warn "pnpm 安装失败；正在重试"
        if ! run_pnpm_global_add "$install_spec" "$log"; then
            ui_warn "pnpm 安装失败，回退到 npm 安装"
            if [[ -s "$log" ]]; then
                print_log_tail_sanitized "$log" 40
            fi
            pnpm remove -g openclaw 2>/dev/null || true
            pnpm remove -g "$package_name" 2>/dev/null || true
            INSTALL_METHOD="npm"
            install_openclaw
            return $?
        fi
    fi

    # 简化检测逻辑：如果 resolve_openclaw_bin 失败，回退到 npm
    if ! resolve_openclaw_bin &> /dev/null; then
        ui_warn "pnpm 安装后仍未找到 openclaw，回退到 npm 安装"
        pnpm remove -g openclaw 2>/dev/null || true
        pnpm remove -g "$package_name" 2>/dev/null || true
        INSTALL_METHOD="npm"
        install_openclaw
        return $?
    fi

    ui_success "OpenClaw ${edition_label} 安装完成（pnpm）"
    return 0
}

run_doctor() {
    ui_info "正在运行 doctor 迁移配置"
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_info "跳过 doctor（openclaw 尚未在 PATH 中）"
        warn_openclaw_not_found
        return 0
    fi
    run_quiet_step "运行 doctor" "$claw" doctor --non-interactive || true
    ui_success "Doctor 完成"
}

maybe_open_dashboard() {
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        return 0
    fi
    if ! "$claw" dashboard --help >/dev/null 2>&1; then
        return 0
    fi
    "$claw" dashboard || true
}

get_openclaw_config_path() {
    echo "${OPENCLAW_CONFIG_PATH:-${OPENCLAW_HOME_DIR}/openclaw.json}"
}

has_existing_openclaw_config() {
    local config_path=""
    config_path="$(get_openclaw_config_path)"
    if [[ -f "${config_path}" ]]; then
        return 0
    fi

    local legacy=""
    for legacy in "${OPENCLAW_LEGACY_CONFIG_PATHS[@]}"; do
        if [[ -f "${legacy}" ]]; then
            return 0
        fi
    done
    return 1
}

is_china_channels_installed() {
    local claw="$1"

    # 使用统一的检测函数（检查输出内容而非仅退出码）
    if is_china_command_available "$claw"; then
        return 0
    fi

    # 然后检查插件列表中是否有 @openclaw-china/channels
    if [[ -n "$claw" ]] && "$claw" plugins list 2>/dev/null | grep -q "@openclaw-china/channels"; then
        return 0
    fi

    # 最后检查目录是否存在且包含有效文件
    if [[ -d "${OPENCLAW_CHANNELS_DIR}" ]]; then
        # 检查是否有 package.json 或其他关键文件
        if [[ -f "${OPENCLAW_CHANNELS_DIR}/package.json" ]]; then
            return 0
        fi
    fi

    return 1
}

resolve_workspace_dir() {
    local profile="${OPENCLAW_PROFILE:-default}"
    if [[ "${profile}" != "default" ]]; then
        echo "${OPENCLAW_HOME_DIR}/workspace-${profile}"
    else
        echo "${OPENCLAW_HOME_DIR}/workspace"
    fi
}

run_bootstrap_onboarding_if_needed() {
    if [[ "${NO_ONBOARD}" == "1" ]]; then
        return
    fi

    # 不再检查配置是否存在，China setup 后直接运行 onboard
    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        ui_info "无 TTY；请手动运行 openclaw onboard 完成设置"
        return
    fi

    ui_info "正在启动 OpenClaw 引导设置"
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_info "openclaw 不在 PATH；跳过引导设置"
        warn_openclaw_not_found
        return
    fi

    "$claw" onboard </dev/tty || {
        ui_error "引导设置失败；运行 openclaw onboard 重试"
        return
    }
}

resolve_openclaw_version() {
    local version=""
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]] && command -v openclaw &> /dev/null; then
        claw="$(command -v openclaw)"
    fi
    if [[ -n "$claw" ]]; then
        version=$("$claw" --version 2>/dev/null | head -n 1 | tr -d '\r')
    fi
    if [[ -z "$version" ]]; then
        local npm_root=""
        npm_root=$(npm root -g 2>/dev/null || true)
        if [[ -n "$npm_root" && -f "$npm_root/openclaw/package.json" ]]; then
            version=$(node -e "console.log(require('${npm_root}/openclaw/package.json').version)" 2>/dev/null || true)
        fi
    fi
    echo "$version"
}

is_gateway_daemon_loaded() {
    local claw="$1"
    if [[ -z "$claw" ]]; then
        return 1
    fi

    local status_json=""
    status_json="$("$claw" daemon status --json 2>/dev/null || true)"
    if [[ -z "$status_json" ]]; then
        return 1
    fi

    printf '%s' "$status_json" | node -e '
const fs = require("fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(1);
try {
  const data = JSON.parse(raw);
  process.exit(data?.service?.loaded ? 0 : 1);
} catch {
  process.exit(1);
}
' >/dev/null 2>&1
}

refresh_gateway_service_if_loaded() {
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        return 0
    fi

    if ! is_gateway_daemon_loaded "$claw"; then
        return 0
    fi

    ui_info "正在刷新已加载的 gateway 服务"
    if run_quiet_step "刷新 gateway 服务" "$claw" gateway install --force; then
        ui_success "Gateway 服务元数据已刷新"
    else
        ui_warn "Gateway 服务刷新失败；继续"
        return 0
    fi

    if run_quiet_step "重启 gateway 服务" "$claw" gateway restart; then
        ui_success "Gateway 服务已重启"
    else
        ui_warn "Gateway 服务重启失败；继续"
        return 0
    fi

    run_quiet_step "探测 gateway 服务" "$claw" gateway status --probe --deep || true
}

install_openclaw_manager() {
    # OpenClaw Manager: 图形化管理工具 (Tauri)
    local repo="${OPENCLAW_MANAGER_REPO}"
    local api_url_direct="https://api.github.com/repos/${repo}/releases/latest"
    local api_url="${api_url_direct}"
    [[ -z "$SELECTED_PROXY" && -n "${GITHUB_PROXY:-}" ]] && api_url="${GITHUB_PROXY%/}/$api_url"
    if [[ "$OS" == "macos" ]]; then
        if [[ -d "/Applications/OpenClaw Manager.app" ]]; then
            ui_success "OpenClaw Manager 已安装"
            return 0
        fi
        ui_info "正在安装 OpenClaw Manager（图形化管理工具）"
        local tag dmg_name dmg_url tmp_dmg mount_point
        if [[ -n "$SELECTED_PROXY" ]]; then
            tag="$(run_sensitive_cmd curl -fsSL -x "$SELECTED_PROXY" --proxy-insecure "$api_url" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        else
            tag="$(curl -fsSL "$api_url" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        fi
        [[ -z "$tag" ]] && { ui_warn "OpenClaw Manager 获取版本失败"; return 0; }
        dmg_name="OpenClaw.Manager_${tag#v}_universal.dmg"
        dmg_url="https://github.com/${repo}/releases/download/$tag/$dmg_name"
        [[ -z "$SELECTED_PROXY" && -n "${GITHUB_PROXY:-}" ]] && dmg_url="${GITHUB_PROXY%/}/$dmg_url"
        tmp_dmg="${TMPDIR:-/tmp}/$dmg_name"
        if [[ -n "$SELECTED_PROXY" ]]; then
            run_sensitive_cmd curl -fsSL -x "$SELECTED_PROXY" --proxy-insecure -o "$tmp_dmg" "$dmg_url" 2>/dev/null
        else
            curl -fsSL -o "$tmp_dmg" "$dmg_url" 2>/dev/null
        fi
        if [[ -f "$tmp_dmg" ]]; then
            hdiutil attach -nobrowse -quiet -readonly "$tmp_dmg" >/dev/null 2>&1
            mount_point="$(ls -d /Volumes/OpenClaw\ Manager* 2>/dev/null | head -1)"
            if [[ -n "$mount_point" && -d "$mount_point/OpenClaw Manager.app" ]]; then
                if cp -R "$mount_point/OpenClaw Manager.app" /Applications/ 2>/dev/null; then
                    xattr -cr "/Applications/OpenClaw Manager.app" 2>/dev/null || true
                    ui_success "OpenClaw Manager 已安装"
                    ui_info "正在打开「完全磁盘访问权限」设置，请添加 OpenClaw Manager 以启用完整功能"
                    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" 2>/dev/null || true
                else
                    ui_warn "OpenClaw Manager 复制失败（可能需要 sudo）"
                fi
                hdiutil detach -quiet "$mount_point" 2>/dev/null || true
            else
                ui_warn "OpenClaw Manager 挂载失败；可手动从 https://github.com/${repo}/releases 下载 DMG"
            fi
            rm -f "$tmp_dmg"
        else
            ui_warn "OpenClaw Manager 下载失败；可手动从 https://github.com/${repo}/releases 下载"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [[ -x "$HOME/.local/bin/openclaw-manager" ]] || command -v openclaw-manager &>/dev/null; then
            ui_success "OpenClaw Manager 已安装"
            return 0
        fi
        ui_info "正在安装 OpenClaw Manager（图形化管理工具）"
        install_tauri_linux_deps || true
        local tag deb_name deb_url tmp_deb
        if [[ -n "$SELECTED_PROXY" ]]; then
            tag="$(run_sensitive_cmd curl -fsSL -x "$SELECTED_PROXY" --proxy-insecure "$api_url" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        else
            tag="$(curl -fsSL "$api_url" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        fi
        [[ -z "$tag" ]] && { ui_warn "OpenClaw Manager 获取版本失败"; return 0; }
        deb_name="OpenClaw.Manager_${tag#v}_amd64.deb"
        deb_url="https://github.com/${repo}/releases/download/$tag/$deb_name"
        [[ -z "$SELECTED_PROXY" && -n "${GITHUB_PROXY:-}" ]] && deb_url="${GITHUB_PROXY%/}/$deb_url"
        tmp_deb="${TMPDIR:-/tmp}/$deb_name"
        if [[ -n "$SELECTED_PROXY" ]]; then
            run_sensitive_cmd curl -fsSL -x "$SELECTED_PROXY" --proxy-insecure -o "$tmp_deb" "$deb_url" 2>/dev/null
        else
            curl -fsSL -o "$tmp_deb" "$deb_url" 2>/dev/null
        fi
        if [[ -f "$tmp_deb" ]]; then
            if command -v apt-get &> /dev/null; then
                if run_quiet_step "安装 OpenClaw Manager" maybe_sudo apt-get install -y -qq "$tmp_deb" 2>/dev/null; then
                    ui_success "OpenClaw Manager 已安装"
                elif run_quiet_step "安装 OpenClaw Manager" maybe_sudo dpkg -i "$tmp_deb"; then
                    maybe_sudo apt-get install -f -y -qq 2>/dev/null || true
                    ui_success "OpenClaw Manager 已安装"
                else
                    ui_warn "OpenClaw Manager 安装失败（可尝试 AppImage）"
                fi
            else
                if run_quiet_step "安装 OpenClaw Manager" maybe_sudo dpkg -i "$tmp_deb"; then
                    ui_success "OpenClaw Manager 已安装"
                else
                    ui_warn "OpenClaw Manager 安装失败（可尝试 AppImage）"
                fi
            fi
            rm -f "$tmp_deb"
        else
            ui_warn "OpenClaw Manager 下载失败；可手动从 https://github.com/${repo}/releases 下载"
        fi
    fi
}

# 检测 china 命令是否真正可用（检查输出内容而非仅退出码）
# 当 china 命令不存在时，openclaw 会返回主帮助信息（退出码 0）
is_china_command_available() {
    local claw="$1"
    [[ -z "$claw" ]] && return 1

    local help_output
    help_output="$("$claw" china --help 2>&1)" || true

    # 检查输出中是否包含 china 命令特有的内容
    # china 命令存在时会显示 "OpenClaw China" 或 "中国渠道" 或 "china setup"
    # 当命令不存在时会显示主帮助信息（包含 "Usage: openclaw [options] [command]"）
    if echo "$help_output" | grep -qE "china setup|OpenClaw China|中国渠道"; then
        return 0
    fi
    return 1
}

install_openclaw_china_channels() {
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_warn "跳过 China 渠道插件安装（openclaw 尚未在 PATH 中）"
        ui_info "安装 openclaw 后请运行: openclaw plugins install @openclaw-china/channels"
        return 0
    fi

    ui_info "OpenClaw 路径: $claw"

    # 先确保 openclaw CLI 完全就绪（运行一次 --version 初始化）
    ui_info "等待 OpenClaw CLI 初始化..."
    local init_retry=0
    local init_max=10
    while [[ $init_retry -lt $init_max ]]; do
        if "$claw" --version &>/dev/null; then
            break
        fi
        sleep 1
        ((init_retry++))
        ui_info "  重试 $init_retry/$init_max..."
    done
    ui_info "OpenClaw CLI 初始化完成"

    # 先检查是否已安装（必须 china 命令真正可用）
    if is_china_command_available "$claw"; then
        ui_success "China 渠道插件已安装"
        return 0
    fi

    ui_info "正在安装 OpenClaw China 渠道插件（钉钉、QQ、飞书、企微）"

    # 执行安装（显示输出以便追踪问题）
    local install_output=""
    install_output="$("$claw" plugins install @openclaw-china/channels 2>&1)" || true
    local install_exit=$?

    # 显示安装输出（提取关键信息）
    if [[ -n "$install_output" ]]; then
        # 显示最后几行关键输出
        echo "$install_output" | tail -15 | while read -r line; do
            # 去除 ANSI 颜色代码后显示
            ui_info "  $(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')"
        done
    fi

    if [[ $install_exit -ne 0 ]]; then
        ui_warn "China 渠道插件安装失败（退出码: $install_exit）"
        ui_info "可稍后运行: openclaw plugins install @openclaw-china/channels"
        return 0
    fi

    # 等待 china 命令真正可用（重试最多 30 秒）
    local retry_count=0
    local max_retries=30
    ui_info "等待插件命令注册..."
    while [[ $retry_count -lt $max_retries ]]; do
        sleep 1
        if is_china_command_available "$claw"; then
            ui_success "China 渠道插件已安装"
            ui_info "China 渠道插件安装完成；将在官方引导后继续渠道配置"
            return 0
        fi
        ((retry_count++))
        ui_info "  等待命令注册 $retry_count/$max_retries..."
    done

    # 超时后仍未成功
    ui_warn "China 渠道插件安装后命令注册超时"
    ui_info "请手动运行以下命令验证："
    echo -e "  ${ACCENT}openclaw china --help${NC}"
    echo -e "  ${ACCENT}openclaw china setup${NC}"
}

run_openclaw_china_setup_after_onboarding() {
    local claw="${OPENCLAW_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openclaw_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_warn "无法找到 openclaw；请手动运行 openclaw plugins install @openclaw-china/channels"
        return 0
    fi

    ui_info "检查 China 渠道插件状态..."
    ui_info "OpenClaw 路径: $claw"

    # 必须验证 china 命令真正可用（检查输出内容）
    if ! is_china_command_available "$claw"; then
        ui_warn "China 渠道插件未正确安装或命令未注册"
        ui_info "请手动运行以下命令安装："
        echo -e "  ${ACCENT}openclaw plugins install @openclaw-china/channels${NC}"
        ui_info "安装后运行以下命令配置渠道："
        echo -e "  ${ACCENT}openclaw china setup${NC}"
        return 0
    fi

    ui_success "China 渠道插件已就绪"

    if [[ "$NO_ONBOARD" == "1" ]]; then
        ui_info "已跳过官方引导；可稍后运行 openclaw china setup 完成渠道配置"
        return 0
    fi

    # 检查是否是真正的交互式环境
    if [[ "${CI:-}" == "1" || "${NONINTERACTIVE:-}" == "1" || ! -t 0 ]]; then
        ui_info "非交互式环境；请手动运行 openclaw china setup 完成渠道配置"
        return 0
    fi

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        ui_info "无 TTY；请手动运行 openclaw china setup 完成渠道配置"
        return 0
    fi

    ui_info "开始执行 China 渠道配置"

    # 验证 china setup 命令可用
    local setup_check
    setup_check="$("$claw" china setup --help 2>&1)" || true
    if ! echo "$setup_check" | grep -qE "中国渠道|配置向导"; then
        ui_warn "china setup 命令不可用，跳过自动配置"
        ui_info "请手动运行: openclaw china setup"
        return 0
    fi

    # 执行 china setup
    if "$claw" china setup </dev/tty 2>&1; then
        ui_success "China 渠道配置已完成"
    else
        local exit_code=$?
        ui_warn "China 渠道配置未完成（退出码: $exit_code）"
        ui_info "可稍后运行: openclaw china setup"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
#                    部署配置功能（模型/网关/项目空间）
#           基于 OpenClaw 2026.3.28 官方源码 extensions/ 目录
# ═══════════════════════════════════════════════════════════════════════

# 提供商数据格式: Index|Name|NameEn|Category|CategoryName|AuthChoice|CliFlag|EnvVar|DefaultModel|ApiKeyUrl|Emoji
DEPLOY_PROVIDERS=(
    "1|火山方舟 Coding Plan|Volcano Engine|china-plan|国内 Coding Plan（包月订阅制，推荐国内用户）|volcengine-api-key|--volcengine-api-key|VOLCANO_ENGINE_API_KEY|volcengine-plan/ark-code-latest|https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey|火山"
    "2|阿里百炼 Coding Plan|Alibaba Cloud Model Studio|china-plan|国内 Coding Plan（包月订阅制，推荐国内用户）|modelstudio-api-key-cn|--modelstudio-api-key-cn|MODELSTUDIO_API_KEY|modelstudio/qwen3.5-plus|https://bailian.console.aliyun.com/cn-beijing?tab=coding-plan#/efm/coding-plan-detail|百炼"
    "3|Kimi (Moonshot AI)|Moonshot AI (Kimi K2.5)|china-direct|国内直连模型（按量付费）|moonshot-api-key-cn|--moonshot-api-key|MOONSHOT_API_KEY|moonshot/kimi-k2.5|https://platform.moonshot.cn/console/api-keys|Kimi"
    "4|MiniMax|MiniMax (M2.7)|china-direct|国内直连模型（按量付费）|minimax-cn-api|--minimax-api-key|MINIMAX_API_KEY|minimax/MiniMax-M2.7|https://platform.minimaxi.com/user-center/basic-information/interface-key|MM"
    "5|DeepSeek|DeepSeek|china-direct|国内直连模型（按量付费）|deepseek-api-key|--deepseek-api-key|DEEPSEEK_API_KEY|deepseek/deepseek-chat|https://platform.deepseek.com/api_keys|DS"
    "6|百度千帆|Qianfan (Baidu)|china-direct|国内直连模型（按量付费）|qianfan-api-key|--qianfan-api-key|QIANFAN_API_KEY|qianfan/deepseek-v3.2|https://console.bce.baidu.com/qianfan/ais/console/onlineService|千帆"
    "7|OpenAI (ChatGPT)|OpenAI|international|国际模型（需海外网络）|openai-api-key|--openai-api-key|OPENAI_API_KEY|openai/gpt-5.4|https://platform.openai.com/api-keys|GPT"
    "8|Google (Gemini)|Google|international|国际模型（需海外网络）|gemini-api-key|--gemini-api-key|GEMINI_API_KEY|google/gemini-3.1-pro-preview|https://aistudio.google.com/app/apikey|Gem"
    "9|Anthropic (Claude)|Anthropic|international|国际模型（需海外网络）|apiKey|--anthropic-api-key|ANTHROPIC_API_KEY|anthropic/claude-sonnet-4-6|https://console.anthropic.com/settings/keys|Claude"
)

deploy_get_field() {
    echo "$1" | cut -d'|' -f"$2"
}

deploy_test_openclaw_installed() {
    command -v openclaw &>/dev/null
}

deploy_select_provider() {
    if [[ -n "$DEPLOY_PROVIDER_CHOICE" ]] && [[ "$DEPLOY_PROVIDER_CHOICE" -ge 1 ]] 2>/dev/null && [[ "$DEPLOY_PROVIDER_CHOICE" -le 9 ]] 2>/dev/null; then
        local p="${DEPLOY_PROVIDERS[$((DEPLOY_PROVIDER_CHOICE - 1))]}"
        ui_info "已通过参数选择: $(deploy_get_field "$p" 2) ($(deploy_get_field "$p" 3))"
        SELECTED_PROVIDER="$p"
        return 0
    fi
    echo ""
    ui_section "步骤 1/4  选择模型提供商 (Model Provider)"
    echo ""
    echo "    Boss，请选择你要使用的 AI 模型提供商（输入对应序号即可）："
    echo ""
    local last_category=""
    for p in "${DEPLOY_PROVIDERS[@]}"; do
        local idx cat_id name emoji default_model
        idx="$(deploy_get_field "$p" 1)"
        cat_id="$(deploy_get_field "$p" 4)"
        name="$(deploy_get_field "$p" 2)"
        emoji="$(deploy_get_field "$p" 11)"
        default_model="$(deploy_get_field "$p" 9)"
        if [[ "$cat_id" != "$last_category" ]]; then
            last_category="$cat_id"
            local cat_label
            case "$cat_id" in
                "china-plan")    cat_label="  ══ 国内 Coding Plan（包月订阅制，推荐国内用户）══" ;;
                "china-direct")  cat_label="  ══ 国内直连模型（按量付费）══" ;;
                "international") cat_label="  ══ 国际模型（需海外网络环境）══" ;;
            esac
            echo ""
            echo -e "${WARN}${cat_label}${NC}"
        fi
        printf "    %2s) [%s] %-28s  默认模型: %s\n" "$idx" "$emoji" "$name" "$default_model"
    done
    echo ""
    echo -e "    ${MUTED}提示: 国内用户推荐选择 1 (火山方舟) 或 2 (阿里百炼)，包月更划算${NC}"
    echo ""
    while true; do
        echo -n "    请输入序号 (1-9): "
        local user_input
        read -r user_input < /dev/tty || true
        if [[ "$user_input" =~ ^[1-9]$ ]]; then
            local p="${DEPLOY_PROVIDERS[$((user_input - 1))]}"
            echo ""
            ui_success "你选择了: $(deploy_get_field "$p" 2) ($(deploy_get_field "$p" 3))"
            echo -e "    ${MUTED}默认模型: ${NC}$(deploy_get_field "$p" 9)"
            SELECTED_PROVIDER="$p"
            return 0
        fi
        echo "    输入无效，请输入 1 到 9 之间的数字"
    done
}

deploy_read_api_key() {
    local provider="$1"
    local p_name p_url p_env
    p_name="$(deploy_get_field "$provider" 2)"
    p_url="$(deploy_get_field "$provider" 10)"
    p_env="$(deploy_get_field "$provider" 8)"
    if [[ -n "$DEPLOY_API_KEY" ]]; then
        ui_info "已通过参数传入 API Key"
        SELECTED_API_KEY="$DEPLOY_API_KEY"
        return 0
    fi
    echo ""
    ui_section "步骤 2/4  输入 API Key ($p_name)"
    echo ""
    echo "    Boss，请输入你的 ${p_name} API Key"
    echo ""
    echo -e "    ${MUTED}获取 API Key 的地址：${NC}"
    echo -e "    ${INFO}${p_url}${NC}"
    echo ""
    echo -e "    ${MUTED}环境变量名: ${NC}${WARN}${p_env}${NC}"
    echo ""
    while true; do
        echo -n "    请粘贴你的 API Key: "
        local key
        read -r key < /dev/tty || true
        if [[ -n "$key" ]]; then
            local masked_key
            if [[ ${#key} -gt 8 ]]; then
                masked_key="${key:0:4}$(printf '%*s' $((${#key} - 8)) '' | tr ' ' '*')${key: -4}"
            else
                masked_key="****"
            fi
            echo ""
            ui_success "API Key 已录入 ($masked_key)"
            SELECTED_API_KEY="$(echo "$key" | xargs)"
            return 0
        fi
        echo "    API Key 不能为空，请重新输入"
    done
}

deploy_read_workspace() {
    if [[ -n "$DEPLOY_WORKSPACE" ]]; then
        ui_info "已通过参数指定工作目录: $DEPLOY_WORKSPACE"
        SELECTED_WORKSPACE="$DEPLOY_WORKSPACE"
        return 0
    fi
    echo ""
    ui_section "步骤 3/4  设置项目文件夹 (Workspace)"
    local default_path="${HOME}/Desktop/openclaw"
    echo ""
    echo "    Boss，请提供 OpenClaw 项目文件夹地址"
    echo -e "    ${MUTED}后续 OpenClaw 的资料和工作区文件将存放在这里${NC}"
    echo ""
    echo -e "    ${MUTED}默认路径: ${NC}${WARN}${default_path}${NC}"
    echo ""
    echo -e "    ${MUTED}直接按 Enter 使用默认路径，或输入自定义路径：${NC}"
    echo -n "    工作目录: "
    local user_input
    read -r user_input < /dev/tty || true
    local final_path
    if [[ -z "$user_input" ]]; then
        final_path="$default_path"
    else
        final_path="$(echo "$user_input" | xargs)"
        if [[ "$final_path" == "~"* ]]; then
            final_path="${HOME}${final_path:1}"
        fi
    fi
    if [[ ! -d "$final_path" ]]; then
        if mkdir -p "$final_path" 2>/dev/null; then
            ui_success "已创建文件夹: $final_path"
        else
            ui_warn "无法创建文件夹: $final_path，将使用默认路径"
            final_path="$default_path"
            mkdir -p "$final_path" 2>/dev/null || true
        fi
    else
        ui_success "文件夹已存在: $final_path"
    fi
    SELECTED_WORKSPACE="$final_path"
}

deploy_invoke_deployment() {
    local provider="$1"
    local key="$2"
    local work_dir="$3"
    local p_name p_name_en p_auth p_cli_flag p_env_var p_model
    p_name="$(deploy_get_field "$provider" 2)"
    p_name_en="$(deploy_get_field "$provider" 3)"
    p_auth="$(deploy_get_field "$provider" 6)"
    p_cli_flag="$(deploy_get_field "$provider" 7)"
    p_env_var="$(deploy_get_field "$provider" 8)"
    p_model="$(deploy_get_field "$provider" 9)"
    echo ""
    ui_section "步骤 4/4  执行自动部署 (openclaw onboard --non-interactive)"
    echo ""
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "  ${ACCENT}部署计划${NC}"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "    ${MUTED}模型提供商    ${NC}${p_name} (${p_name_en})"
    echo -e "    ${MUTED}认证方式 ID   ${NC}${p_auth}"
    echo -e "    ${MUTED}默认模型      ${NC}${p_model}"
    echo -e "    ${MUTED}工作目录      ${NC}${work_dir}"
    echo -e "    ${MUTED}安装 Daemon   ${NC}是（后台服务自启动）"
    echo -e "    ${MUTED}跳过通道配置  ${NC}是（稍后可通过 openclaw channels add 添加）"
    echo -e "    ${MUTED}跳过技能配置  ${NC}是（稍后可通过 openclaw skills 配置）"
    echo -e "    ${MUTED}跳过搜索配置  ${NC}是（稍后可通过 openclaw configure --section web 配置）"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo ""
    ui_info "正在执行 OpenClaw 自动化部署，请稍候..."
    echo ""
    export "${p_env_var}=${key}"
    ui_info "执行命令: openclaw onboard --non-interactive --auth-choice ${p_auth} ..."
    local onboard_output=""
    local onboard_exit=0
    onboard_output=$(openclaw onboard \
        --non-interactive \
        --accept-risk \
        --auth-choice "$p_auth" \
        "$p_cli_flag" "$key" \
        --workspace "$work_dir" \
        --install-daemon \
        --skip-channels \
        --skip-skills \
        --skip-search 2>&1) || onboard_exit=$?
    if [[ -n "$onboard_output" ]]; then
        echo "$onboard_output" | sed 's/^/    /'
    fi
    if [[ "$onboard_exit" -eq 0 ]]; then
        echo ""
        ui_success "OpenClaw 部署配置完成！"
        echo ""
        echo -e "    ${MUTED}已完成以下配置：${NC}"
        echo "      - 模型提供商: ${p_name}"
        echo "      - 默认模型: ${p_model}"
        echo "      - API Key: 已配置"
        echo "      - 工作目录: ${work_dir}"
        echo "      - Gateway Daemon: 已安装并启动"
        echo "      - 网关端口: 18789（Loopback 绑定 + Token 认证）"
        return 0
    else
        echo ""
        ui_warn "部署过程遇到问题（退出码: $onboard_exit）"
        echo ""
        echo "    请检查以下可能的原因："
        echo "      1. API Key 是否正确"
        echo "      2. 网络是否可以访问对应模型提供商"
        echo "      3. 工作目录是否有写入权限"
        echo ""
        echo -e "    ${MUTED}你可以稍后手动运行以下命令重试：${NC}"
        echo -e "      ${INFO}openclaw onboard --install-daemon${NC}"
        echo ""
        return 1
    fi
}

deploy_invoke_doctor_check() {
    if [[ "$DEPLOY_SKIP_DOCTOR" == "1" ]]; then
        ui_info "已跳过 doctor 自检"
        return
    fi
    echo ""
    ui_section "部署后检查 (openclaw doctor)"
    ui_info "正在运行 OpenClaw 自检 (openclaw doctor)..."
    echo ""
    openclaw doctor 2>&1 | sed 's/^/    /' || true
    echo ""
    ui_info "正在尝试自动修复 (openclaw doctor --fix)..."
    echo ""
    openclaw doctor --fix 2>&1 | sed 's/^/    /' || true
    echo ""
    ui_success "自检完成"
}

deploy_invoke_gateway_restart() {
    if [[ "$DEPLOY_SKIP_GATEWAY_RESTART" == "1" ]]; then
        ui_info "已跳过 Gateway 重启"
        return
    fi
    echo ""
    ui_section "重启 Gateway 服务 (openclaw gateway restart)"
    ui_info "正在重启 Gateway 后台服务..."
    echo ""
    echo -e "    ${MUTED}提示: gateway restart 是重启后台 daemon 服务${NC}"
    echo -e "    ${MUTED}请不要额外执行 openclaw gateway run（前台模式会产生端口冲突）${NC}"
    echo ""
    if openclaw gateway restart 2>&1 | sed 's/^/    /'; then
        echo ""
        ui_success "Gateway 服务已重启"
    else
        ui_warn "Gateway 重启遇到问题"
        echo -e "    ${MUTED}你可以稍后手动运行: openclaw gateway restart${NC}"
    fi
}

deploy_invoke_dashboard() {
    if [[ "$DEPLOY_SKIP_DASHBOARD" == "1" ]]; then
        ui_info "已跳过打开 Web UI"
        return
    fi
    echo ""
    ui_section "打开 Web UI 控制界面 (openclaw dashboard)"
    ui_info "正在打开 OpenClaw Web UI (Control Panel)..."
    echo ""
    if openclaw dashboard 2>&1 | sed 's/^/    /'; then
        echo ""
        ui_success "Web UI 已启动"
    else
        ui_warn "打开 Web UI 遇到问题"
        echo -e "    ${MUTED}你可以稍后手动运行: openclaw dashboard${NC}"
    fi
}

deploy_show_summary() {
    local provider="$1"
    local work_dir="$2"
    local deploy_success="$3"
    local p_name p_model
    p_name="$(deploy_get_field "$provider" 2)"
    p_model="$(deploy_get_field "$provider" 9)"
    echo ""
    if [[ "$deploy_success" == "0" ]]; then
        ui_celebrate "OpenClaw 部署配置全部完成！"
    else
        ui_warn "OpenClaw 部署配置已完成（部分步骤可能需要手动处理）"
    fi
    echo ""
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "  ${MUTED}部署摘要${NC}"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "    ${MUTED}模型提供商    ${NC}${INFO}${p_name}${NC}"
    echo -e "    ${MUTED}默认模型      ${NC}${INFO}${p_model}${NC}"
    echo -e "    ${MUTED}工作目录      ${NC}${INFO}${work_dir}${NC}"
    echo -e "    ${MUTED}Gateway 端口  ${NC}${INFO}18789 (Loopback + Token)${NC}"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "  ${MUTED}常用命令${NC}"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo -e "    ${MUTED}自检修复      ${NC}${INFO}openclaw doctor --fix${NC}"
    echo -e "    ${MUTED}重启服务      ${NC}${INFO}openclaw gateway restart${NC}"
    echo -e "    ${MUTED}打开面板      ${NC}${INFO}openclaw dashboard${NC}"
    echo -e "    ${MUTED}重新引导      ${NC}${INFO}openclaw onboard --install-daemon${NC}"
    echo -e "    ${MUTED}安全审计      ${NC}${INFO}openclaw security audit --deep${NC}"
    echo -e "    ${MUTED}添加通道      ${NC}${INFO}openclaw channels add${NC}"
    echo -e "    ${MUTED}配置技能      ${NC}${INFO}openclaw skills${NC}"
    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo ""
    local -a tips=(
        "部署完成！你的 OpenClaw 已经准备好了，开始探索吧！"
        "一切就绪！打开 Web UI 即可开始与你的 AI 助手对话。"
        "配置完成！试试 openclaw dashboard 打开控制面板。"
        "准备好了！你的 AI 助手已经在后台待命。"
    )
    echo -e "  ${MUTED}${tips[RANDOM % ${#tips[@]}]}${NC}"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# 选项4: 更换 OpenClaw 模型
# ════════════════════════════════════════════════════════════════════════

invoke_configure_model() {
    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 更换 OpenClaw 模型  ${NC}${MUTED}配置向导${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${WARN}模型资源与配置参考${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    echo -e "  ${WARN}🔥 火山方舟 Coding Plan（火山引擎 包月订阅）${NC}"
    echo -e "     ${MUTED}配置指南： https://www.volcengine.com/docs/82379/2183190?lang=zh${NC}"
    echo -e "     ${MUTED}API Key 查看： https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey${NC}"
    echo ""
    echo -e "  ${WARN}☁️  阿里百炼 Coding Plan（平行引擎 包月订阅）${NC}"
    echo -e "     ${MUTED}配置指南： https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085${NC}"
    echo -e "     ${MUTED}API Key 查看： https://bailian.console.aliyun.com/cn-beijing?tab=coding-plan#/efm/coding-plan-detail${NC}"
    echo ""
    echo -e "  ${WARN}🟦 腾讯 Coding Plan（混元大模型 包月订阅）${NC}"
    echo -e "     ${MUTED}配置指南： https://cloud.tencent.com/document/product/1772/128949${NC}"
    echo -e "     ${MUTED}API Key 查看： https://hunyuan.cloud.tencent.com/#/app/subscription${NC}"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  请提前准备好对应模型的 API Key，然后选择操作："
    echo ""
    echo -e "    ${ACCENT}1)${NC} 继续配置 OpenClaw 模型"
    echo ""
    echo -e "    ${ACCENT}2)${NC} 返回主菜单"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    while true; do
        printf "    请输入序号 (1/2): "
        local sub_input
        read -r sub_input < /dev/tty || true
        case "$sub_input" in
            1)
                echo ""
                ui_info "正在调起 openclaw configure （Local + Model）..."
                echo ""
                openclaw configure 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "configure 启动失败，请手动运行： openclaw configure"
                return 0
                ;;
            2) return 0 ;;
            *) echo "    输入无效，请输入 1 或 2" ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════
# 选项5: 添加 Channels
# ════════════════════════════════════════════════════════════════════════

show_wechat_channel_menu() {
    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 连接微信  ${NC}${MUTED}Wechat Channel${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}接入步骤${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    echo -e "  第一步：升级微信至最新版（≥ 8.0.7）"
    echo -e "    ${MUTED}微信 → 我 → 设置 → 关于微信 → 版本更新${NC}"
    echo ""
    echo -e "  第二步：在微信里启用插件"
    echo -e "    ${MUTED}1. 手机微信 → 「我」→ 「设置」→ 「插件」${NC}"
    echo -e "    ${MUTED}2. 找到「微信 ClawBot」，按提示启用/授权${NC}"
    echo -e "    ${MUTED}（此步是将微信账号与插件能力绑定）${NC}"
    echo ""
    echo -e "  第三步：点击"继续"，将自动安装微信官方插件"
    echo -e "    ${MUTED}执行命令： npx -y @tencent-weixin/openclaw-weixin-cli@latest install${NC}"
    echo -e "    ${MUTED}执行后自动弹出二维码，用需要绑定的微信扫码并点"连接"确认${NC}"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    echo -e "    ${ACCENT}1)${NC} 安装微信官方插件（自动执行上述命令）"
    echo ""
    echo -e "    ${ACCENT}2)${NC} 返回主菜单"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    while true; do
        printf "    请输入序号 (1/2): "
        local sub_input
        read -r sub_input < /dev/tty || true
        case "$sub_input" in
            1)
                echo ""
                ui_info "正在安装微信官方插件..."
                echo ""
                npx -y @tencent-weixin/openclaw-weixin-cli@latest install 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "安装失败，请手动运行： npx -y @tencent-weixin/openclaw-weixin-cli@latest install"
                echo ""
                ui_success "✅ 微信插件安装命令执行完成！请用微信扫码确认连接。"
                return 0
                ;;
            2) return 0 ;;
            *) echo "    输入无效，请输入 1 或 2" ;;
        esac
    done
}

show_qq_channel_menu() {
    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 连接 QQ  ${NC}${MUTED}三步完成 QQ 渠道接入${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  📋 连接前请先阅读官方指南："
    echo -e "     ${INFO}https://q.qq.com/qqbot/openclaw/login.html${NC}"
    echo ""
    echo -e "  接入步骤："
    echo -e "    ${MUTED}第一步：访问以上官方指南页面，完成 QQ 账号授权${NC}"
    echo -e "    ${MUTED}第二步：准备好 QQ 机器人的相关凭据（AppID / Token 等）${NC}"
    echo -e "    ${MUTED}第三步：点击继续，进入 OpenClaw Channels 配置页完成绑定${NC}"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    echo -e "    ${ACCENT}1)${NC} 继续连接 QQ（进入 Channels 配置）"
    echo ""
    echo -e "    ${ACCENT}2)${NC} 返回渠道菜单"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    while true; do
        printf "    请输入序号 (1-2): "
        local sub_input
        read -r sub_input < /dev/tty || true
        case "$sub_input" in
            1)
                echo ""
                ui_info "正在调起 openclaw configure → Channels..."
                echo ""
                openclaw configure --section channels 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "configure 启动失败，请手动运行： openclaw configure --section channels"
                return 0
                ;;
            2) return 0 ;;
            *) echo "    输入无效，请输入 1 或 2" ;;
        esac
    done
}

show_channels_menu() {
    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 添加 Channels  ${NC}${MUTED}连接即时通讯渠道${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  请选择要连接的渠道："
    echo ""
    echo -e "    ${ACCENT}1)${NC} 连接微信"
    echo ""
    echo -e "    ${ACCENT}2)${NC} 连接飞书"
    echo -e "       ${MUTED}参考指南： https://www.feishu.cn/content/article/7613711414611463386${NC}"
    echo ""
    echo -e "    ${ACCENT}3)${NC} 连接企微"
    echo -e "       ${MUTED}参考指南： https://open.work.weixin.qq.com/help2/pc/cat?doc_id=21657${NC}"
    echo ""
    echo -e "    ${ACCENT}4)${NC} 连接 QQ"
    echo -e "       ${MUTED}参考指南： https://q.qq.com/qqbot/openclaw/login.html${NC}"
    echo ""
    echo -e "    ${ACCENT}5)${NC} 连接其他渠道"
    echo -e "       ${MUTED}进入 Channels 配置总入口，手动选择渠道${NC}"
    echo ""
    echo -e "    ${ACCENT}6)${NC} 返回主菜单"
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo ""
    while true; do
        printf "    请输入序号 (1-6): "
        local sub_input
        read -r sub_input < /dev/tty || true
        case "$sub_input" in
            1)
                show_wechat_channel_menu
                return 0
                ;;
            2)
                echo ""
                ui_info "飞书接入指南： https://www.feishu.cn/content/article/7613711414611463386"
                echo ""
                ui_info "正在调起 openclaw configure → Channels..."
                echo ""
                openclaw configure --section channels 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "configure 启动失败，请手动运行： openclaw configure --section channels"
                return 0
                ;;
            3)
                echo ""
                ui_info "企微接入指南： https://open.work.weixin.qq.com/help2/pc/cat?doc_id=21657"
                echo ""
                ui_info "正在调起 openclaw configure → Channels..."
                echo ""
                openclaw configure --section channels 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "configure 启动失败，请手动运行： openclaw configure --section channels"
                return 0
                ;;
            4)
                show_qq_channel_menu
                return 0
                ;;
            5)
                echo ""
                ui_info "正在调起 openclaw configure → Channels..."
                echo ""
                openclaw configure --section channels 2>&1 | while IFS= read -r line; do
                    echo -e "    ${MUTED}${line}${NC}"
                done || ui_warn "configure 启动失败，请手动运行： openclaw configure --section channels"
                return 0
                ;;
            6) return 0 ;;
            *) echo "    输入无效，请输入 1 到 6 之间的序号" ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════
# 选项6: 自检并尝试修复
# ════════════════════════════════════════════════════════════════════════

invoke_selfcheck() {
    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 OpenClaw 自检并尝试修复${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  ${WARN}小提示：请将完整自检结果复制粘贴给 豆包 / 千问 / DeepSeek 帮你分析${NC}"
    echo ""

    # Step 1: openclaw doctor
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 1 - 健康检查${NC}  ${MUTED}openclaw doctor${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在运行 OpenClaw 健康检查..."
    echo ""
    openclaw doctor 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done || ui_warn "doctor 运行遇到问题"
    echo ""

    # Step 2: openclaw doctor --fix
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 2 - 自动修复${NC}  ${MUTED}openclaw doctor --fix${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在尝试自动修复检测到的问题..."
    echo ""
    openclaw doctor --fix 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done || ui_warn "doctor --fix 运行遇到问题"
    echo ""

    # Step 3: openclaw gateway restart
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 3 - 重启 Gateway${NC}  ${MUTED}openclaw gateway restart${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在重启 Gateway 后台服务..."
    echo ""
    if openclaw gateway restart 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done; then
        ui_success "✅ Gateway 服务已重启"
    else
        ui_warn "gateway restart 失败，可手动运行： openclaw gateway restart"
    fi
    echo ""

    # Step 4: openclaw status --all
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 4 - 查看全量状态${NC}  ${MUTED}openclaw status --all${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在获取 OpenClaw 全量状态信息..."
    echo ""
    openclaw status --all 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done || ui_warn "status --all 运行遇到问题"
    echo ""

    # Step 5: openclaw dashboard
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 5 - 打开控制面板${NC}  ${MUTED}openclaw dashboard${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在打开 OpenClaw Web UI（控制面板）..."
    echo ""
    if openclaw dashboard 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done; then
        ui_success "✅ OpenClaw Web UI 已启动！"
    else
        ui_warn "打开 Web UI 失败，请手动运行： openclaw dashboard"
    fi
    echo ""

    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    ui_success "✅ 🦞 全部自检流程执行完成！如有输出异常请复制给 AI 助手分析。"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# 选项7: 进入 OpenClaw 配置页面
# ════════════════════════════════════════════════════════════════════════

invoke_configure_main() {
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}进入 OpenClaw 配置页面${NC}  ${MUTED}openclaw configure${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在启动 OpenClaw 配置向导（包含模型 / 网关 / 渠道 / 守护进程等）..."
    echo ""
    openclaw configure 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done || ui_warn "configure 启动失败，请手动运行： openclaw configure"
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# 选项8: 打开 OpenClaw 主页面
# ════════════════════════════════════════════════════════════════════════

invoke_dashboard_menu() {
    echo ""
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}打开 OpenClaw 主页面${NC}  ${MUTED}openclaw dashboard${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    ui_info "正在启动 OpenClaw Web UI..."
    echo ""
    if openclaw dashboard 2>&1 | while IFS= read -r line; do
        echo -e "    ${MUTED}${line}${NC}"
    done; then
        ui_success "✅ OpenClaw Web UI 已启动！请在浏览器中查看。"
    else
        ui_warn "启动失败，请手动运行： openclaw dashboard"
    fi
    echo ""
}

# ════════════════════════════════════════════════════════════════════════
# 选项9: 完全卸载 OpenClaw
# ════════════════════════════════════════════════════════════════════════

invoke_uninstall() {
    echo ""
    echo -e "  ${ERROR}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ERROR}${BOLD}⚠️  完全卸载 OpenClaw  ${NC}${ERROR}本操作不可逆！${NC}"
    echo -e "  ${ERROR}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    echo -e "  将依次执行以下操作："
    echo -e "    ${MUTED}1. openclaw gateway stop${NC}"
    echo -e "    ${MUTED}2. openclaw gateway uninstall${NC}"
    echo -e "    ${MUTED}3. openclaw uninstall${NC}"
    echo -e "    ${MUTED}4. npm uninstall -g openclaw${NC}"
    echo -e "    ${MUTED}5. pnpm remove -g openclaw${NC}"
    echo ""
    echo -e "  ${ERROR}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ERROR}请输入 YES 进行二次确认（输入其它内容取消）${NC}"
    echo ""
    printf "    请确认：输入 YES 开始卸载: "
    local confirm1
    read -r confirm1 < /dev/tty || true
    if [[ "$confirm1" != "YES" ]]; then
        ui_info "已取消卸载操作。"
        return 0
    fi
    echo ""
    printf "    再次确认：这将彻底卸载 OpenClaw，输入 YES 继续: "
    local confirm2
    read -r confirm2 < /dev/tty || true
    if [[ "$confirm2" != "YES" ]]; then
        ui_info "已取消卸载操作。"
        return 0
    fi

    echo ""
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 开始执行卸载流程...${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""

    local uninstall_results=()

    # 辅助函数：运行命令并显示输出，返回退出码（不使用 pipe 避免 subshell 问题）
    _run_uninstall_cmd() {
        local _out _rc=0
        _out="$("$@" 2>&1)" || _rc=$?
        if [[ -n "$_out" ]]; then
            while IFS= read -r line; do
                echo -e "    ${MUTED}${line}${NC}"
            done <<< "$_out"
        fi
        return $_rc
    }

    # Step 1: openclaw gateway stop
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 1 - 停止 Gateway 服务${NC}  ${MUTED}openclaw gateway stop${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    if _run_uninstall_cmd openclaw gateway stop; then
        uninstall_results+=("[OK] openclaw gateway stop")
    else
        uninstall_results+=("[!] openclaw gateway stop")
    fi
    echo ""

    # Step 2: openclaw gateway uninstall
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 2 - 移除 Gateway 服务${NC}  ${MUTED}openclaw gateway uninstall${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    if _run_uninstall_cmd openclaw gateway uninstall; then
        uninstall_results+=("[OK] openclaw gateway uninstall")
    else
        uninstall_results+=("[!] openclaw gateway uninstall")
    fi
    echo ""

    # Step 3: openclaw uninstall
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 3 - 卸载 OpenClaw 配置${NC}  ${MUTED}openclaw uninstall${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    if _run_uninstall_cmd openclaw uninstall; then
        uninstall_results+=("[OK] openclaw uninstall")
    else
        uninstall_results+=("[!] openclaw uninstall")
    fi
    echo ""

    # Step 4: npm uninstall -g openclaw
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 4 - npm 全局卸载${NC}  ${MUTED}npm uninstall -g openclaw${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    if _run_uninstall_cmd npm uninstall -g openclaw; then
        uninstall_results+=("[OK] npm uninstall -g openclaw")
    else
        uninstall_results+=("[!] npm uninstall -g openclaw")
    fi
    echo ""

    # Step 5: pnpm remove -g openclaw
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    echo -e "  ${ACCENT}Step 5 - pnpm 全局卸载${NC}  ${MUTED}pnpm remove -g openclaw${NC}"
    echo -e "  ${MUTED}$(printf '─%.0s' {1..56})${NC}"
    if _run_uninstall_cmd pnpm remove -g openclaw; then
        uninstall_results+=("[OK] pnpm remove -g openclaw")
    else
        uninstall_results+=("[!] pnpm remove -g openclaw")
    fi
    echo ""

    # 卸载结果汇总
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo -e "  ${ACCENT}${BOLD}🦞 卸载流程完成 — 执行结果汇总${NC}"
    echo -e "  ${ACCENT}${BOLD}$(printf '═%.0s' {1..63})${NC}"
    echo ""
    local r
    for r in "${uninstall_results[@]}"; do
        if [[ "$r" == \[OK\]* ]]; then
            echo -e "    ${SUCCESS}${r}${NC}"
        else
            echo -e "    ${WARN}${r}${NC}"
        fi
    done
    echo ""
    ui_info "OpenClaw 卸载流程全部执行完成。如有标记 [!] 的步骤请手动处理。"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════
#                         欢迎菜单
# ═══════════════════════════════════════════════════════════════════════

show_welcome_menu() {
    echo ""
    echo -e "${HEADER}${BOLD}  # ═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${HEADER}${BOLD}  # OpenClaw 全自动安装部署脚本 - MacOS 版${NC}"
    echo -e "${HEADER_SUB}  # 涵盖 OpenClaw环境安装 + OpenClaw最新官方稳定版 + 模型/网关/项目空间全自动部署${NC}"
    echo -e "${TAGLINE}  # 无后门 | 无病毒 | 全自动 | 全免费 | 零技术门槛${NC}"
    echo -e "${HEADER_SUB}  # Created by: Mr_Hou  致力于技术平权降低门槛 让人人都有机会拥抱Ai世界${NC}"
    echo -e "${HEADER_SUB}  # Wechat_id：qiyuan_hou，欢迎一起讨论 共同进化！${NC}"
    echo -e "${WARN}  # **严禁恶意篡改或将本免费脚本商业化售卖**${NC}"
    echo -e "${HEADER}${BOLD}  # ═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${HEADER_SUB}  # 功能菜单:${NC}"
    echo ""

    # ── 安装部署 OpenClaw 篇 ──
    echo -e "  ${ACCENT}┌─ 《安装与部署 OpenClaw 篇》 ────────────────────────────────────────────┤${NC}"
    echo -e "    ${ACCENT}1)${NC} 安装 OpenClaw 并自动化部署  ${MUTED}（推荐新用户）${NC}"
    echo -e "       ${MUTED}自动安装 Homebrew/Node.js/Git/OpenClaw，并配置模型、API Key、网关和项目空间${NC}"
    echo -e "    ${ACCENT}2)${NC} 仅自动化安装 OpenClaw"
    echo -e "       ${MUTED}只安装 OpenClaw CLI 运行环境，模型和网关配置稍后可单独完成${NC}"
    echo -e "    ${ACCENT}3)${NC} 仅部署 OpenClaw 模型/网关/项目空间"
    echo -e "       ${MUTED}OpenClaw 已安装，仅配置模型提供商、API Key 和工作目录${NC}"
    echo -e "  ${ACCENT}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # ── 使用 OpenClaw 篇 ──
    echo -e "  ${WARN}┌─ 《使用 OpenClaw 篇》（需已安装 OpenClaw）─────────────────────────────┤${NC}"
    echo -e "    ${WARN}4)${NC} 更换 OpenClaw 模型（配置 AI 模型提供商 / API Key）"
    echo -e "       ${MUTED}支持 DeepSeek / Kimi / 火山方舟 / 阿里百炼 / ChatGPT / Claude 等 9 家提供商${NC}"
    echo -e "    ${WARN}5)${NC} 添加 Channels（微信 / 飞书 / 企微 / QQ 等即时通讯渠道）"
    echo -e "       ${MUTED}连接即时通讯渠道，让 AI 助手在你的聊天 App 里直接回复消息${NC}"
    echo -e "    ${WARN}6)${NC} OpenClaw 自检并尝试修复"
    echo -e "       ${MUTED}自动运行 doctor 诊断 + doctor --fix 修复 + gateway restart 重启网关${NC}"
    echo -e "    ${WARN}7)${NC} 进入 OpenClaw 配置页面"
    echo -e "       ${MUTED}打开完整的交互式配置向导（模型 / 网关 / 渠道 / 守护进程等）${NC}"
    echo -e "    ${WARN}8)${NC} 打开 OpenClaw 主页面"
    echo -e "       ${MUTED}启动 OpenClaw Web UI 控制面板，可在浏览器中查看全部功能和对话${NC}"
    echo -e "  ${WARN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # ── 卸载 OpenClaw 篇 ──
    echo -e "  ${ERROR}┌─ 《卸载 OpenClaw 篇》 ──────────────────────────────────────────────────┤${NC}"
    echo -e "    ${ERROR}9)${NC} 完全卸载 OpenClaw"
    echo -e "       ${MUTED}停止全部服务并彻底移除 OpenClaw（操作不可逆，执行前需二次确认）${NC}"
    echo -e "  ${ERROR}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "  ${MUTED}────────────────────────────────────────────────────────${NC}"
    echo ""
    while true; do
        printf "    请输入序号 (1-9): "
        local user_input
        read -r user_input < /dev/tty || true
        case "$user_input" in
            1) SETUP_MODE="full";            return 0 ;;
            2) SETUP_MODE="install";         return 0 ;;
            3) SETUP_MODE="deploy";          return 0 ;;
            4) SETUP_MODE="configure-model"; return 0 ;;
            5) SETUP_MODE="channels";        return 0 ;;
            6) SETUP_MODE="selfcheck";       return 0 ;;
            7) SETUP_MODE="configure-main";  return 0 ;;
            8) SETUP_MODE="dashboard";       return 0 ;;
            9) SETUP_MODE="uninstall";       return 0 ;;
            *) echo "    输入无效，请输入 1 到 9 之间的序号" ;;
        esac
    done
}

invoke_install_flow() {
    bootstrap_gum_temp || true
    print_installer_banner
    print_gum_status
    detect_os_or_die
    select_proxy  # 优先主节点，回退备节点，回退不代理

    local detected_checkout=""
    detected_checkout="$(detect_openclaw_checkout "$PWD" || true)"

    if [[ -z "$INSTALL_METHOD" && -n "$detected_checkout" ]]; then
        if ! is_promptable; then
            ui_info "发现 OpenClaw 源码但无 TTY；默认使用 pnpm 安装"
            INSTALL_METHOD="pnpm"
        else
            local selected_method=""
            selected_method="$(choose_install_method_interactive "$detected_checkout" || true)"
            case "$selected_method" in
                git|npm|pnpm)
                    INSTALL_METHOD="$selected_method"
                    ;;
                *)
                    ui_error "未选择安装方式"
                    echo -e "  ${MUTED}请使用 --install-method npm|pnpm|git 重新运行${NC}"
                    exit 2
                    ;;
            esac
        fi
    fi

    if [[ -z "$INSTALL_METHOD" ]]; then
        INSTALL_METHOD="npm"
    fi

    if [[ "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "pnpm" && "$INSTALL_METHOD" != "git" ]]; then
        ui_error "无效的 --install-method: ${INSTALL_METHOD}"
        echo -e "  ${MUTED}请使用: --install-method npm|pnpm|git${NC}"
        exit 2
    fi

    if [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "pnpm" ]]; then
        choose_registry_interactive || true
    fi

    choose_optional_components_interactive || true

    show_install_plan "$detected_checkout"

    if [[ "$DRY_RUN" == "1" ]]; then
        ui_success "模拟运行完成（未做任何更改）"
        return 0
    fi

    local is_upgrade=false
    if check_existing_openclaw; then
        is_upgrade=true
    fi
    local should_open_dashboard=false
    local skip_onboard=false

    ui_stage "准备环境"

    if ! install_homebrew; then
        exit 1
    fi

    if ! check_node; then
        install_node
    fi

    if [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "pnpm" ]]; then
        choose_edition_interactive || true
        if [[ -z "${OPENCLAW_EDITION:-}" ]]; then
            OPENCLAW_EDITION="zh"
        fi
        choose_beta_interactive || true
    fi

    ui_stage "安装 OpenClaw"

    local final_git_dir=""
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        if package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "npm" || package_installed_globally "$OPENCLAW_PACKAGE_ZH" "npm"; then
            ui_info "正在移除 npm 全局安装（切换到 git）"
            npm uninstall -g openclaw 2>/dev/null || true
            npm uninstall -g "$OPENCLAW_PACKAGE_ZH" 2>/dev/null || true
            ui_success "npm 全局安装已移除"
        fi
        detect_pnpm_cmd 2>/dev/null || true
        if pnpm_cmd_is_ready 2>/dev/null; then
            if package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "pnpm" || package_installed_globally "$OPENCLAW_PACKAGE_ZH" "pnpm"; then
                ui_info "正在移除 pnpm 全局安装（切换到 git）"
                "${PNPM_CMD[@]}" remove -g openclaw 2>/dev/null || true
                "${PNPM_CMD[@]}" remove -g "$OPENCLAW_PACKAGE_ZH" 2>/dev/null || true
                ui_success "pnpm 全局安装已移除"
            fi
        fi

        local repo_dir="$GIT_DIR"
        if [[ -n "$detected_checkout" ]]; then
            repo_dir="$detected_checkout"
        fi
        final_git_dir="$repo_dir"
        install_openclaw_from_git "$repo_dir"
    else
        if [[ -x "$HOME/.local/bin/openclaw" ]]; then
            ui_info "正在移除 git 包装器（切换到包管理器安装）"
            rm -f "$HOME/.local/bin/openclaw"
            ui_success "git 包装器已移除"
        fi

        if [[ "$INSTALL_METHOD" == "pnpm" ]]; then
            if package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "npm" || package_installed_globally "$OPENCLAW_PACKAGE_ZH" "npm"; then
                ui_info "正在移除 npm 全局安装（切换到 pnpm）"
                npm uninstall -g openclaw 2>/dev/null || true
                npm uninstall -g "$OPENCLAW_PACKAGE_ZH" 2>/dev/null || true
                ui_success "npm 全局安装已移除"
            fi
        elif [[ "$INSTALL_METHOD" == "npm" ]]; then
            detect_pnpm_cmd 2>/dev/null || true
            if pnpm_cmd_is_ready 2>/dev/null; then
                if package_installed_globally "$OPENCLAW_PACKAGE_ORIGINAL" "pnpm" || package_installed_globally "$OPENCLAW_PACKAGE_ZH" "pnpm"; then
                    ui_info "正在移除 pnpm 全局安装（切换到 npm）"
                    "${PNPM_CMD[@]}" remove -g openclaw 2>/dev/null || true
                    "${PNPM_CMD[@]}" remove -g "$OPENCLAW_PACKAGE_ZH" 2>/dev/null || true
                    ui_success "pnpm 全局安装已移除"
                fi
            fi
        fi

        local installed_edition=""
        installed_edition="$(detect_installed_edition "$INSTALL_METHOD" || true)"
        if [[ -n "$installed_edition" ]]; then
            local from_label="" to_label=""
            [[ "$installed_edition" == "original" ]] && from_label="原版" || from_label="中文版"
            [[ "${OPENCLAW_EDITION:-}" == "original" ]] && to_label="原版" || to_label="中文版"
            if [[ "$installed_edition" == "${OPENCLAW_EDITION:-}" ]]; then
                ui_info "检测到已安装相同版本（${from_label}），将直接升级（无需卸载）"
            else
                ui_info "检测到需切换版本（${from_label} → ${to_label}），需先卸载旧版"
                uninstall_both_and_clear_cache "$INSTALL_METHOD"
            fi
        fi

        if ! check_git; then
            if [[ "$OS" == "macos" ]] && ! command -v brew &> /dev/null; then
                install_homebrew || true
            fi
            if [[ "$OS" == "macos" ]] && ! command -v brew &> /dev/null; then
                ui_warn "跳过 Git 安装（需要 Homebrew，请在交互式终端中运行以安装）"
            else
                install_git
            fi
        fi
        configure_git_github_https

        # macOS: OpenClaw 依赖（如 baileys）需要从 GitHub 拉取，需可用的 Git
        if [[ "$OS" == "macos" ]] && ! xcode-select -p >/dev/null 2>&1; then
            ui_warn "未检测到 Xcode 命令行工具（含 Git）"
            ui_info "正在触发安装弹窗…"
            xcode-select --install 2>/dev/null || true
            echo ""
            ui_warn "请等待 macOS 弹窗完成 Xcode 命令行工具安装，然后重新运行本安装器："
            echo "  curl -fsSL https://openclaw.orence.net/install-zh.sh | bash"
            echo ""
            exit 1
        fi

        fix_npm_permissions

        if [[ "$INSTALL_METHOD" == "pnpm" ]]; then
            ensure_pnpm
            install_openclaw_pnpm
        else
            install_openclaw
        fi
    fi

    ui_stage "完成设置"

    ensure_openclaw_path_ready || true
    OPENCLAW_BIN="${OPENCLAW_BIN:-$(resolve_openclaw_bin || true)}"

    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    local pnpm_bin=""
    pnpm_bin="$(pnpm_global_bin_dir || true)"
    if [[ "$INSTALL_METHOD" == "npm" ]]; then
        warn_shell_path_missing_dir "$npm_bin" "npm 全局 bin 目录"
    fi
    if [[ "$INSTALL_METHOD" == "pnpm" ]]; then
        warn_shell_path_missing_dir "$pnpm_bin" "pnpm 全局 bin 目录"
    fi
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        if [[ -x "$HOME/.local/bin/openclaw" ]]; then
            warn_shell_path_missing_dir "$HOME/.local/bin" "用户本地 bin 目录 (~/.local/bin)"
        fi
    fi

    # 1. 先安装 China 渠道插件
    if optional_toggle_enabled "$INSTALL_CHINA_CHANNELS"; then
        install_openclaw_china_channels
    else
        ui_info "按选择跳过 China 渠道插件安装"
    fi

    # 2. 安装 OpenClaw Manager
    if optional_toggle_enabled "$INSTALL_OPENCLAW_MANAGER"; then
        install_openclaw_manager
    else
        ui_info "按选择跳过 OpenClaw Manager 安装"
    fi

    refresh_gateway_service_if_loaded

    local run_doctor_after=false
    if [[ "$is_upgrade" == "true" || "$INSTALL_METHOD" == "git" ]]; then
        run_doctor_after=true
    fi
    if [[ "$run_doctor_after" == "true" ]]; then
        run_doctor
        should_open_dashboard=true
    fi

    # 3. 运行 China 渠道配置（在官方引导之前）
    if optional_toggle_enabled "$INSTALL_CHINA_CHANNELS"; then
        run_openclaw_china_setup_after_onboarding
    else
        ui_info "按选择跳过 China 渠道配置"
    fi

    # 4. 最后运行官方引导
    run_bootstrap_onboarding_if_needed

    local installed_version
    installed_version=$(resolve_openclaw_version)

    echo ""
    if [[ -n "$installed_version" ]]; then
        ui_celebrate "🦞 OpenClaw 安装成功 (${installed_version})！"
    else
        ui_celebrate "🦞 OpenClaw 安装成功！"
    fi
    if [[ "$OS" == "macos" ]]; then
        open "${OPENCLAW_DOCS_URL}" 2>/dev/null &
        open "${OPENCLAW_WEB_UI_URL}" 2>/dev/null &
    elif [[ "$OS" == "linux" ]] && command -v xdg-open &>/dev/null; then
        xdg-open "${OPENCLAW_DOCS_URL}" 2>/dev/null &
        xdg-open "${OPENCLAW_WEB_UI_URL}" 2>/dev/null &
    fi
    if [[ "$is_upgrade" == "true" ]]; then
        local update_messages=(
            "升级完成！新技能已解锁。不客气。"
            "新代码，同一只龙虾。想我了吗？"
            "回来了，更强了。你注意到我离开了吗？"
            "更新完成。我出去学了点新把戏。"
            "升级了！现在多了 23% 的毒舌。"
            "我进化了。跟上节奏。🦞"
            "新版本，谁啊？哦对，还是我，只是更闪了。"
            "打补丁、抛光、准备开夹。出发。"
            "龙虾蜕壳了。壳更硬，钳更利。"
            "更新完成！看看更新日志，或者信我就行，反正很好。"
            "从 npm 的沸水中重生。更强了。"
            "我出去了一趟，回来更聪明了。你也可以试试。"
            "更新完成。bug 怕我，所以跑了。"
            "新版本已安装。旧版本向你问好。"
            "固件新鲜。脑回路：增加了。"
            "我见过你不敢相信的东西。总之，我更新了。"
            "重新上线。更新日志很长，但我们的友谊更长。"
            "升级了！Peter 修了东西。坏了怪他。"
            "蜕壳完成。别看我软壳期的样子。"
            "版本升级！同样的混乱能量，更少的崩溃（大概）。"
        )
        local update_message
        update_message="${update_messages[RANDOM % ${#update_messages[@]}]}"
        echo -e "${MUTED}${update_message}${NC}"
    else
        local completion_messages=(
            "啊不错，我喜欢这儿。有零食吗？"
            "到家了。别担心，我不会乱动家具的。"
            "我来了。让我们制造点负责任的混乱吧。"
            "安装完成。你的生产力即将变得奇怪。"
            "安顿好了。是时候自动化你的生活了，不管你准备好了没。"
            "舒服。我已经看过你的日历了。我们得聊聊。"
            "终于 unpack 完了。现在指给我你的问题。"
            "掰掰钳子 好了，我们要造什么？"
            "龙虾已着陆。你的终端将不再一样。"
            "全部完成！我保证只稍微评判一下你的代码。"
        )
        local completion_message
        completion_message="${completion_messages[RANDOM % ${#completion_messages[@]}]}"
        echo -e "${MUTED}${completion_message}${NC}"
    fi
    echo ""

    if [[ "$INSTALL_METHOD" == "git" && -n "$final_git_dir" ]]; then
        ui_section "源码安装详情"
        ui_kv "源码目录" "$final_git_dir"
        ui_kv "包装器" "$HOME/.local/bin/openclaw"
        ui_kv "更新命令" "openclaw update --restart"
        ui_kv "切换到 npm" "curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash -s -- --install-method npm"
        ui_kv "切换到 pnpm" "curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash -s -- --install-method pnpm"
    elif [[ "$is_upgrade" == "true" ]]; then
        ui_info "升级完成"
        if [[ -r /dev/tty && -w /dev/tty ]]; then
            local claw="${OPENCLAW_BIN:-}"
            if [[ -z "$claw" ]]; then
                claw="$(resolve_openclaw_bin || true)"
            fi
            if [[ -z "$claw" ]]; then
                ui_info "跳过 doctor（openclaw 尚未在 PATH 中）"
                warn_openclaw_not_found
                return 0
            fi
            local -a doctor_args=()
            if [[ "$NO_ONBOARD" == "1" ]]; then
                if "$claw" doctor --help 2>/dev/null | grep -q -- "--non-interactive"; then
                    doctor_args+=("--non-interactive")
                fi
            fi
            ui_info "正在运行 openclaw doctor"
            local doctor_ok=0
            if (( ${#doctor_args[@]} )); then
                OPENCLAW_UPDATE_IN_PROGRESS=1 "$claw" doctor "${doctor_args[@]}" </dev/tty && doctor_ok=1
            else
                OPENCLAW_UPDATE_IN_PROGRESS=1 "$claw" doctor </dev/tty && doctor_ok=1
            fi
            if (( doctor_ok )); then
                ui_info "正在更新插件"
                OPENCLAW_UPDATE_IN_PROGRESS=1 "$claw" plugins update --all || true
            else
                ui_warn "Doctor 失败；跳过插件更新"
            fi
        else
            ui_info "无 TTY；请手动运行 openclaw doctor 和 openclaw plugins update --all"
        fi
    else
        if [[ "$NO_ONBOARD" == "1" || "$skip_onboard" == "true" ]]; then
            ui_info "已跳过引导设置；稍后运行 openclaw onboard"
        else
            # China setup 完成后直接运行 onboard 进行模型配置
            # 不再检查配置是否存在，让用户配置 AI 模型
            ui_info "正在启动 OpenClaw 引导设置"
            echo ""
            if [[ -r /dev/tty && -w /dev/tty ]]; then
                local claw="${OPENCLAW_BIN:-}"
                if [[ -z "$claw" ]]; then
                    claw="$(resolve_openclaw_bin || true)"
                fi
                if [[ -z "$claw" ]]; then
                    ui_info "跳过引导设置（openclaw 尚未在 PATH 中）"
                    warn_openclaw_not_found
                    return 0
                fi
                if "$claw" onboard </dev/tty; then
                    ui_success "引导设置已完成"
                else
                    ui_warn "引导未完成；可稍后运行 openclaw onboard"
                fi
            else
                ui_info "无 TTY；运行 openclaw onboard 完成设置"
                return 0
            fi
        fi
    fi

    # if command -v openclaw &> /dev/null; then
    #     local claw="${OPENCLAW_BIN:-}"
    #     if [[ -z "$claw" ]]; then
    #         claw="$(resolve_openclaw_bin || true)"
    #     fi
    #     if [[ -n "$claw" ]] && is_gateway_daemon_loaded "$claw"; then
    #         if [[ "$DRY_RUN" == "1" ]]; then
    #             ui_info "检测到 Gateway daemon；将重启 (openclaw daemon restart)"
    #         else
    #             ui_info "检测到 Gateway daemon；正在重启"
    #             if OPENCLAW_UPDATE_IN_PROGRESS=1 "$claw" daemon restart >/dev/null 2>&1; then
    #                 ui_success "Gateway 已重启"
    #             else
    #                 ui_warn "Gateway 重启失败；尝试: openclaw daemon restart"
    #             fi
    #         fi
    #     fi
    # fi

    if [[ "$should_open_dashboard" == "true" ]]; then
        maybe_open_dashboard
    fi

    # if [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "pnpm" ]]; then
    #     echo ""
    #     ui_hr 48 "─"
    #     ui_info "若 openclaw 显示「command not found」或「No such file or directory」，请运行："
    #     echo -e "  ${ACCENT}hash -r${NC}  （清除命令缓存，bash）"
    #     echo -e "  ${ACCENT}rehash${NC}    （清除命令缓存，zsh）"
    #     echo -e "  ${MUTED}或运行: source ~/.zprofile（zsh）/ source ~/.bashrc（bash）${NC}"
    #     echo -e "  ${MUTED}或关闭并重新打开终端后再试${NC}"
    #     ui_hr 48 "─"
    # fi

    echo ""
    ui_info "OpenClaw Manager 为测试版，可能存在兼容性或稳定性问题；遇到问题可反馈至其项目仓库。"
    local farewell_messages=(
        "祝使用愉快！有问题可查阅文档或加入社区交流。"
        "准备好了就出发吧。文档和社区随时等你。"
        "开夹快乐！遇到问题别客气，文档和群友都在。"
        "享受自动化吧。卡住了？文档和社区帮你兜底。"
        "开始折腾吧。有问题？文档里找找，群里问问。"
    )
    local farewell_msg
    farewell_msg="${farewell_messages[RANDOM % ${#farewell_messages[@]}]}"
    echo -e "${MUTED}${farewell_msg}${NC}"
    echo ""

    show_footer_links
}

# ═══════════════════════════════════════════════════════════════════════
#                      仅部署流程
# ═══════════════════════════════════════════════════════════════════════

invoke_deploy_flow() {
    echo ""
    echo -e "${ACCENT}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${ACCENT}${BOLD}  🚀 OpenClaw 部署配置  ${NC}${MUTED}Mac 版${NC}"
    echo -e "${ACCENT}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # 检查 openclaw 是否已安装
    if ! deploy_test_openclaw_installed; then
        return 1
    fi

    # 选择模型提供商
    deploy_select_provider
    local provider="${SELECTED_PROVIDER}"
    if [[ -z "$provider" ]]; then
        ui_error "未选择模型提供商，部署终止"
        return 1
    fi

    # 输入 API Key
    deploy_read_api_key "$provider"
    local api_key="${SELECTED_API_KEY}"
    if [[ -z "$api_key" ]]; then
        ui_error "未输入 API Key，部署终止"
        return 1
    fi

    # 设置工作目录
    deploy_read_workspace
    local workspace="${SELECTED_WORKSPACE}"

    # 执行部署
    local deploy_exit=0
    deploy_invoke_deployment "$provider" "$api_key" "$workspace" || deploy_exit=$?

    # Doctor 自检
    if [[ "$DEPLOY_SKIP_DOCTOR" != "1" ]]; then
        deploy_invoke_doctor_check
    fi

    # 重启 Gateway
    if [[ "$DEPLOY_SKIP_GATEWAY_RESTART" != "1" ]]; then
        deploy_invoke_gateway_restart
    fi

    # 打开 Dashboard
    if [[ "$DEPLOY_SKIP_DASHBOARD" != "1" ]]; then
        deploy_invoke_dashboard
    fi

    # 显示摘要
    deploy_show_summary "$provider" "$workspace" "$deploy_exit"
}

# ═══════════════════════════════════════════════════════════════════════
#                     统一入口 main_setup
# ═══════════════════════════════════════════════════════════════════════

main_setup() {
    # 如果通过命令行指定了 --provider，则自动选择仅部署模式
    if [[ -n "$DEPLOY_PROVIDER_CHOICE" && -z "$SETUP_MODE" ]]; then
        SETUP_MODE="deploy"
    fi

    # 如果未指定模式，显示欢迎菜单
    if [[ -z "$SETUP_MODE" ]]; then
        show_welcome_menu
    fi

    case "$SETUP_MODE" in
        full)
            echo ""
            echo -e "${ACCENT}${BOLD}  ▸ 模式: 安装 + 部署${NC}"
            echo ""
            invoke_install_flow
            echo ""
            echo -e "${ACCENT}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${ACCENT}${BOLD}  ✅ 安装完成！现在进入部署配置...${NC}"
            echo -e "${ACCENT}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
            invoke_deploy_flow
            ;;
        install)
            echo ""
            echo -e "${ACCENT}${BOLD}  ▸ 模式: 仅安装${NC}"
            echo ""
            invoke_install_flow
            ;;
        deploy)
            echo ""
            echo -e "${ACCENT}${BOLD}  ▸ 模式: 仅部署${NC}"
            echo ""
            invoke_deploy_flow
            ;;
        configure-model)
            # ══ 模式 4: 更换模型 ══
            invoke_configure_model
            ;;
        channels)
            # ══ 模式 5: 添加 Channels ══
            show_channels_menu
            ;;
        selfcheck)
            # ══ 模式 6: 自检修复 ══
            invoke_selfcheck
            ;;
        configure-main)
            # ══ 模式 7: 进入配置页面 ══
            invoke_configure_main
            ;;
        dashboard)
            # ══ 模式 8: 打开主页面 ══
            invoke_dashboard_menu
            ;;
        uninstall)
            # ══ 模式 9: 完全卸载 ══
            invoke_uninstall
            ;;
        *)
            ui_error "未知模式: $SETUP_MODE"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════
#                         脚本入口点
# ═══════════════════════════════════════════════════════════════════════

if [[ "${OPENCLAW_INSTALL_SH_NO_RUN:-0}" != "1" ]]; then
    parse_args "$@"
    configure_verbose
    if [[ "$HELP" == "1" ]]; then
        print_usage
        exit 0
    fi
    main_setup
fi
