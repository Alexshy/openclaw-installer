#!/bin/bash

# OpenClaw 官网部署脚本 - 上传到现有 GitHub 仓库
# 使用方法：./deploy-to-existing-repo.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   OpenClaw 官网部署到现有 GitHub 仓库${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 Git 是否安装
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ 错误：未检测到 Git，请先安装 Git${NC}"
    exit 1
fi

# 配置项
GITHUB_USERNAME="Alexshy"
REPO_NAME="openclaw-installer"
REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
BRANCH_NAME="main"

echo -e "${YELLOW}📦 目标仓库：${REPO_URL}${NC}"
echo ""

# 进入网站目录
cd "$(dirname "$0")"

# 检查是否已初始化 Git
if [ ! -d ".git" ]; then
    echo -e "${BLUE}🔧 初始化 Git 仓库...${NC}"
    git init
    git branch -M ${BRANCH_NAME}
fi

# 添加所有文件
echo -e "${BLUE}📝 添加网站文件...${NC}"
git add .

# 提交更改
echo -e "${BLUE}💾 提交更改...${NC}"
git commit -m "feat: 添加 OpenClaw 官方网站页面

- Hero 区域展示项目核心价值
- 功能特性介绍（一键安装、模型切换等）
- 详细安装指南（Mac/Windows/Linux）
- AI 模型支持说明
- FAQ 常见问题解答
- 响应式设计，适配各种设备

✨ 简单清晰、对小白用户友好的设计风格"

# 添加远程仓库（如果不存在）
if ! git remote | grep -q "origin"; then
    echo -e "${BLUE}🔗 添加远程仓库...${NC}"
    git remote add origin ${REPO_URL}
else
    echo -e "${GREEN}✅ 远程仓库已配置${NC}"
fi

# 拉取最新代码（避免冲突）
echo -e "${BLUE}📥 拉取远程最新代码...${NC}"
git pull origin ${BRANCH_NAME} --rebase || true

# 推送到 GitHub
echo -e "${BLUE}🚀 推送到 GitHub...${NC}"
echo -e "${YELLOW}💡 提示：如果提示认证失败，请使用 Personal Access Token 代替密码${NC}"
echo -e "${YELLOW}   获取 Token: https://github.com/settings/tokens${NC}"
echo ""

git push -u origin ${BRANCH_NAME}

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   ✅ 部署成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}🌐 访问地址：${NC}"
echo -e "   https://${GITHUB_USERNAME}.github.io/${REPO_NAME}/"
echo ""
echo -e "${YELLOW}⚙️  下一步配置 GitHub Pages：${NC}"
echo "   1. 进入仓库 → Settings → Pages"
echo "   2. Source: Deploy from a branch"
echo "   3. Branch: main / (root)"
echo "   4. 点击 Save"
echo ""
echo -e "${BLUE}📖 详细文档请查看：DEPLOY_GUIDE.md${NC}"
echo ""
