# 🚀 OpenClaw 官网部署指南

本指南将帮助你将 OpenClaw 官网部署到 GitHub Pages，实现远程访问。

---

## 📋 部署方式选择

### 方式一：一键部署脚本（推荐 ⭐）
适合：所有用户，最简单快捷

### 方式二：手动部署
适合：熟悉 Git 操作的用户

---

## 方式一：一键部署脚本

### 步骤 1：打开终端

进入网站目录：
```bash
cd /Users/mac/Desktop/Wukong/Ai\ Auto/openclaw-website
```

### 步骤 2：赋予脚本执行权限
```bash
chmod +x deploy-to-github.sh
```

### 步骤 3：运行部署脚本

将 `<你的 GitHub 用户名>` 替换为你的实际用户名：
```bash
./deploy-to-github.sh <你的 GitHub 用户名>
```

**示例：**
```bash
./deploy-to-github.sh Alexshy
```

### 步骤 4：在 GitHub 创建仓库

1. 访问 [https://github.com/new](https://github.com/new)
2. 填写以下信息：
   - **Repository name**: `openclaw-installer`
   - **Description**: `OpenClaw One-Click Installer Website`
   - ✅ **Public**（必须公开）
   - ❌ **不要**勾选 "Add a README file"
   - ❌ **不要**添加 .gitignore
   - ❌ **不要**添加 License
3. 点击 **Create repository**

### 步骤 5：推送代码到 GitHub

回到终端，执行：
```bash
git push -u origin main
```

系统会提示你输入 GitHub 账号密码：
- **Username**: 你的 GitHub 用户名
- **Password**: 使用 Personal Access Token（不是登录密码）

> 💡 **如何获取 Personal Access Token？**
> 1. 访问 [https://github.com/settings/tokens](https://github.com/settings/tokens)
> 2. 点击 "Generate new token (classic)"
> 3. 填写备注（如：Deploy Token）
> 4. 勾选 `repo` 权限
> 5. 点击 "Generate token"
> 6. **复制并保存 Token**（只显示一次！）

### 步骤 6：启用 GitHub Pages

1. 进入你的仓库页面：`https://github.com/<你的用户名>/openclaw-installer`
2. 点击 **Settings**（设置）
3. 左侧菜单找到并点击 **Pages**
4. 在 "Build and deployment" 部分：
   - **Source**: Deploy from a branch
   - **Branch**: 选择 `main`，文件夹选择 `/ (root)`
5. 点击 **Save**

### 步骤 7：等待部署完成

GitHub 会自动构建并部署你的网站，通常需要 **1-2 分钟**。

你可以在以下地址查看部署状态：
```
https://github.com/<你的用户名>/openclaw-installer/deployments
```

### 步骤 8：访问你的官网

部署完成后，你的官网将在以下地址可访问：
```
https://<你的用户名>.github.io/openclaw-installer/
```

**示例：**
```
https://Alexshy.github.io/openclaw-installer/
```

---

## 方式二：手动部署

如果你更熟悉 Git 命令，可以手动执行以下步骤：

### 1. 初始化 Git 仓库
```bash
cd /Users/mac/Desktop/Wukong/Ai\ Auto/openclaw-website
git init
```

### 2. 添加所有文件
```bash
git add .
git commit -m "Initial commit: OpenClaw 官网页面"
```

### 3. 创建 GitHub 仓库

访问 [https://github.com/new](https://github.com/new)，创建名为 `openclaw-installer` 的公开仓库。

### 4. 关联远程仓库

将 `<你的 GitHub 用户名>` 替换为实际用户名：
```bash
git remote add origin https://github.com/<你的用户名>/openclaw-installer.git
git branch -M main
```

### 5. 推送到 GitHub
```bash
git push -u origin main
```

### 6. 启用 GitHub Pages

同方式一的步骤 6。

---

## 🔧 常见问题

### Q1: 推送时提示认证失败？

**解决方案：** 使用 Personal Access Token 代替密码。

1. 访问 [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. 生成新的 token（勾选 `repo` 权限）
3. 推送时使用 token 作为密码

### Q2: GitHub Pages 显示 404？

**可能原因：**
- 仓库是私有的（GitHub Pages 免费只支持公开仓库）
- 还未完成部署（等待 1-2 分钟）
- 分支设置错误（确保选择 `main` 分支）

**解决方案：**
1. 确认仓库是 Public
2. 等待几分钟后刷新
3. 检查 Settings → Pages 的分支设置

### Q3: 如何自定义域名？

如果你想使用自己的域名（如 `openclaw.ai`）：

1. 在 Settings → Pages → Custom domain 中输入你的域名
2. 在你的域名服务商处添加 CNAME 记录：
   ```
   openclaw.ai CNAME <你的用户名>.github.io
   ```

### Q4: 如何更新网站内容？

修改 `index.html` 后，执行：
```bash
git add .
git commit -m "更新网站内容"
git push
```

GitHub Pages 会自动重新部署，通常 1 分钟内生效。

---

## 📊 部署检查清单

- [ ] 已安装 Git
- [ ] 已有 GitHub 账号
- [ ] 已创建公开仓库 `openclaw-installer`
- [ ] 已推送代码到 GitHub
- [ ] 已启用 GitHub Pages（main 分支）
- [ ] 网站可正常访问

---

## 🎉 完成！

部署成功后，你可以：

✅ 分享官网链接给用户  
✅ 在 README、文档中引用官网地址  
✅ 持续更新优化网站内容  
✅ 通过 GitHub Issues 收集反馈  

---

## 📞 需要帮助？

如果在部署过程中遇到问题：

- 📧 GitHub Issues: [https://github.com/Alexshy/openclaw-installer/issues](https://github.com/Alexshy/openclaw-installer/issues)
- 💬 微信：qiyuan_hou

---

**祝你部署顺利！** 🚀
