# 🚀 OpenClaw 官网快速部署指南

## ✅ 你的仓库信息

- **GitHub 用户名**: Alexshy
- **仓库地址**: https://github.com/Alexshy/openclaw-installer
- **预期访问地址**: https://Alexshy.github.io/openclaw-installer/

---

## 📋 部署步骤（3 步完成）

### 第 1 步：运行部署脚本

打开终端，执行以下命令：

```bash
cd /Users/mac/Desktop/Wukong/Ai\ Auto/openclaw-website
./deploy-to-existing-repo.sh
```

**脚本会自动完成：**
- ✅ 初始化 Git 仓库
- ✅ 添加所有网站文件
- ✅ 提交代码
- ✅ 关联远程仓库
- ✅ 推送到 GitHub

---

### 第 2 步：配置 GitHub Pages

推送完成后，在浏览器中操作：

1. **进入仓库设置**
   - 访问：https://github.com/Alexshy/openclaw-installer/settings/pages
   - 或：点击仓库 → **Settings** → **Pages**

2. **配置 Pages 源**
   - **Source**: Deploy from a branch
   - **Branch**: main
   - **Folder**: /(root)
   - 点击 **Save**

---

### 第 3 步：等待部署完成

- ⏳ GitHub 会在 1-2 分钟内构建并部署你的网站
- 🔄 刷新 Pages 设置页面查看部署状态
- ✅ 显示 "Your site is live" 即表示部署成功

**访问地址：**
```
https://Alexshy.github.io/openclaw-installer/
```

---

## 🔍 验证部署

部署完成后，打开浏览器访问上述地址，你应该能看到：

- ✨ 精美的 Hero 区域
- 🎯 功能特性介绍
- 📖 详细的安装指南
- 🤖 AI 模型支持说明
- ❓ FAQ 常见问题

---

## ⚠️ 常见问题

### 1. 推送时提示认证失败

**解决方案：使用 Personal Access Token**

1. 访问：https://github.com/settings/tokens
2. 点击 **Generate new token (classic)**
3. 勾选权限：`repo`、`workflow`
4. 生成后复制 Token
5. 推送时使用 Token 代替密码

```bash
git push -u origin main
# 用户名：Alexshy
# 密码：[粘贴你的 Token]
```

### 2. 提示 remote origin 已存在

这是正常的，说明仓库已经关联。脚本会自动处理。

### 3. GitHub Pages 页面显示 404

**原因**：Pages 还未配置或正在构建

**解决方案**：
1. 确认已完成第 2 步的 Pages 配置
2. 等待 2-3 分钟让 GitHub 完成构建
3. 检查 Branch 是否选择了 `main`

### 4. 推送时出现冲突

如果远程仓库已有内容，先拉取最新代码：

```bash
git pull origin main --rebase
git push -u origin main
```

---

## 🎨 自定义域名（可选）

如果你想使用自己的域名（如 `openclaw.ai`）：

1. 进入 **Settings** → **Pages** → **Custom domain**
2. 输入你的域名
3. 点击 **Save**
4. 在域名服务商处配置 CNAME 记录

---

## 📊 查看部署日志

在仓库中可以查看自动部署日志：

1. 进入仓库主页
2. 点击 **Actions** 标签
3. 选择 **pages-build-deployment**
4. 查看最近的构建记录

---

## 💡 后续更新

修改网站内容后，只需重新运行部署脚本：

```bash
./deploy-to-existing-repo.sh
```

GitHub Pages 会自动更新网站内容（通常 1-2 分钟生效）。

---

## 📞 需要帮助？

如果遇到其他问题，请告诉我具体的错误信息，我会帮你解决！

**祝你部署顺利！** 🎉
