#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# OpenClaw 官网一键部署到 GitHub Pages 脚本
# 用法：./deploy-to-github.sh
# ═══════════════════════════════════════════════════════════════════════

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OpenClaw 官网一键部署到 GitHub Pages                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查是否输入仓库名
if [ -z "$1" ]; then
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  ./deploy-to-github.sh <你的 GitHub 用户名>"
    echo ""
    echo "例如：./deploy-to-github.sh Alexshy"
    echo ""
    exit 1
fi

GITHUB_USERNAME="$1"
REPO_NAME="openclaw-installer"
WEBSITE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${GREEN}✓${NC} 网站目录：$WEBSITE_DIR"
echo -e "${GREEN}✓${NC} GitHub 用户名：$GITHUB_USERNAME"
echo -e "${GREEN}✓${NC} 仓库名称：$REPO_NAME"
echo ""

# 进入网站目录
cd "$WEBSITE_DIR"

# 检查是否存在 .git 目录
if [ -d ".git" ]; then
    echo -e "${YELLOW}⚠ 检测到已存在的 Git 仓库${NC}"
    read -p "是否要重新初始化？(y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf .git
        echo -e "${GREEN}✓${NC} 已删除旧的 Git 仓库"
    else
        echo "使用现有的 Git 仓库..."
    fi
fi

# 初始化 Git 仓库（如果不存在）
if [ ! -d ".git" ]; then
    echo -e "${BLUE}📦 正在初始化 Git 仓库...${NC}"
    git init
    echo -e "${GREEN}✓${NC} Git 仓库初始化完成"
fi

# 添加所有文件
echo ""
echo -e "${BLUE}📝 添加网站文件...${NC}"
git add .
echo -e "${GREEN}✓${NC} 文件已添加到暂存区"

# 创建提交
echo ""
echo -e "${BLUE}💾 创建提交...${NC}"
git commit -m "Initial commit: OpenClaw 官网页面" || {
    echo -e "${YELLOW}⚠ 没有需要提交的文件变更${NC}"
}

# 检查是否已设置远程仓库
REMOTE_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
if git remote | grep -q "^origin$"; then
    echo ""
    echo -e "${YELLOW}⚠ 已存在远程仓库${NC}"
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "当前远程地址：$CURRENT_REMOTE"
    read -p "是否要修改为 $REMOTE_URL ? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git remote set-url origin "$REMOTE_URL"
        echo -e "${GREEN}✓${NC} 远程仓库地址已更新"
    fi
else
    echo ""
    echo -e "${BLUE}🔗 添加远程仓库...${NC}"
    git remote add origin "$REMOTE_URL"
    echo -e "${GREEN}✓${NC} 远程仓库已添加：$REMOTE_URL"
fi

# 重命名分支为 main
echo ""
echo -e "${BLUE}🌿 设置主分支...${NC}"
git branch -M main
echo -e "${GREEN}✓${NC} 主分支已设置为 main"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ 本地 Git 配置完成！${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 接下来请手动完成以下步骤：${NC}"
echo ""
echo "1️⃣  在 GitHub 上创建新仓库："
echo "   访问：https://github.com/new"
echo "   仓库名：${REPO_NAME}"
echo "   描述：OpenClaw One-Click Installer Website"
echo "   ✅ 设为 Public（公开）"
echo "   ❌ 不要初始化 README、.gitignore 或 License"
echo ""
echo "2️⃣  推送代码到 GitHub："
echo -e "   ${BLUE}git push -u origin main${NC}"
echo ""
echo "3️⃣  启用 GitHub Pages："
echo "   进入仓库 → Settings → Pages"
echo "   Source: Deploy from a branch"
echo "   Branch: main / root"
echo "   点击 Save"
echo ""
echo "4️⃣  等待部署完成（约 1-2 分钟）"
echo "   访问地址：https://${GITHUB_USERNAME}.github.io/${REPO_NAME}/"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
