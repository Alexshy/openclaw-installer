# 🦞 OpenClaw 一键安装部署脚本

> **零技术门槛 · 全自动 · 双平台支持（Mac + Windows）**
> 
> Created by:Mr_Hou 致力于技术平权降低门槛 让人人都有机会拥抱Ai世界  🌏

<div align="center">

🇨🇳 中文 &nbsp;|&nbsp; 🇺🇸 [English](./README.EN.md)

</div>

---

## 这是什么？

这是一套**全自动**的 OpenClaw 安装部署脚本，同时支持 **Mac** 和 **Windows** 两个系统。

**你不需要懂任何编程知识。**  
打开终端，粘贴一行命令，剩下的全部交给脚本搞定 ✅

> [OpenClaw](https://openclaw.ai) 是一款强大的 AI 编程助手工具，支持接入 DeepSeek、Kimi、ChatGPT、Claude 等主流 AI 模型，帮你在各种 IDE 编辑器中获得 AI 辅助编程能力。

---

## ✨ 脚本能帮你做什么？

| 功能 | 说明 |
|------|------|
| 🚀 **一键安装部署** | 自动安装所有依赖环境 + 安装 OpenClaw 最新稳定版 + 配置 AI 模型 |
| 🔄 **更换 AI 模型** | 随时切换到其他 AI 提供商（无需重装） |
| 📱 **添加聊天渠道** | 接入微信 / 飞书 / 企微 / QQ 等即时通讯工具 |
| 🔍 **自检修复** | 自动检测问题并尝试修复 |
| ⚙️ **配置页面** | 进入 OpenClaw 图形化配置界面 |
| 🌐 **打开主页面** | 直接打开 OpenClaw Web UI |
| 🗑️ **完全卸载** | 干净彻底地卸载 OpenClaw |

---

## 🤖 支持的 AI 模型

### 🇨🇳 国内用户推荐（无需翻墙）

| # | 模型 | 计费方式 | 说明 |
|---|------|----------|------|
| 1 | 🔥 **火山方舟 Coding Plan**（字节跳动）| 包月订阅 | 性价比极高，强烈推荐 |
| 2 | 🧠 **阿里百炼 Coding Plan**（阿里云）| 包月订阅 | Qwen 系列，稳定可靠 |
| 3 | 🌙 **Kimi**（月之暗面）| 按量付费 | 长上下文能力突出 |
| 4 | 🎯 **MiniMax** | 按量付费 | 国内直连，低延迟 |
| 5 | 🔵 **DeepSeek** | 按量付费 | 代码能力强，价格实惠 |

### 🌍 国际用户（需海外网络）

| # | 模型 | 说明 |
|---|------|------|
| 7 | **OpenAI (ChatGPT)** | GPT 系列，全球最广泛使用 |
| 8 | **Google (Gemini)** | Google 最新旗舰模型 |
| 9 | **Anthropic (Claude)** | 代码与推理能力极强 |

---

## 💻 系统要求

| 系统 | 最低要求 |
|------|---------|
| **Mac** | macOS 10.15 Catalina 及以上 |
| **Windows** | Windows 10 / 11（64位） |

> 脚本会自动帮你安装所有缺少的依赖（Node.js、pnpm 等），无需手动安装！

---

## 🚀 快速开始

### 🍎 Mac 用户

**第一步**：打开「终端」（按 `Command + 空格`，搜索「终端」并打开）

**第二步**：复制以下命令，粘贴到终端，按回车：

```bash
curl -fsSL https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash
```

> 国内网络较慢时，可使用 jsDelivr 加速：
> ```bash
> curl -fsSL https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/install.sh | bash
> ```

**第三步**：按照脚本提示操作即可 🎉

---

### 🪟 Windows 用户

**第一步**：右键点击「开始菜单」，选择 **「Windows PowerShell（管理员）」** 或 **「终端（管理员）」**

> ⚠️ 必须以**管理员身份**运行，否则无法安装软件

**第二步**：复制以下命令，粘贴到 PowerShell，按回车：

```powershell
$r=iwr -useb https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.ps1; iex ([System.Text.Encoding]::UTF8.GetString($r.Content))
```

> 国内网络较慢时，可使用 jsDelivr 加速：
> ```powershell
> $r=iwr -useb https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/install.ps1; iex ([System.Text.Encoding]::UTF8.GetString($r.Content))
> ```

> 如遇到「执行策略」报错，请先运行：
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> 然后再重新运行安装命令。

**第三步**：按照脚本提示操作即可 🎉

---

## 📋 功能菜单详解

脚本启动后，会显示交互式菜单，共分三个板块：

```
╔══════════════════════════════════════════╗
║      《安装与部署 OpenClaw 篇》          ║
║   1. 安装 OpenClaw 并自动化部署（推荐）  ║
║   2. 仅自动化安装 OpenClaw              ║
║   3. 仅部署模型/网关/项目空间            ║
╠══════════════════════════════════════════╣
║        《使用 OpenClaw 篇》              ║
║   4. 更换 OpenClaw 模型                 ║
║   5. 添加 Channels（微信/飞书/企微/QQ） ║
║   6. OpenClaw 自检并尝试修复            ║
║   7. 进入 OpenClaw 配置页面             ║
║   8. 打开 OpenClaw 主页面               ║
╠══════════════════════════════════════════╣
║        《卸载 OpenClaw 篇》              ║
║   9. 完全卸载 OpenClaw                  ║
╚══════════════════════════════════════════╝
```

**新用户直接选 `1`，一键搞定所有事情！**

---

## ❓ 常见问题

**Q：我需要先安装什么吗？**  
A：不需要！脚本会自动检测并安装所有必要依赖。

**Q：安装过程中需要输入什么？**  
A：只需要输入你的 AI 模型 API Key（一串密钥，从对应平台申请），以及选择一个存放项目的文件夹路径。

**Q：API Key 从哪里获取？**  
A：选好模型后，脚本会直接提供申请链接，点击进入对应平台注册账号并申请即可。

**Q：安全吗？会不会有病毒？**  
A：脚本完全开源，代码可在本页面直接查看审计。无后门，无病毒，无任何数据收集。

**Q：安装失败了怎么办？**  
A：重新运行脚本，选择菜单 `6`（自检修复）；或添加微信 `qiyuan_hou` 寻求帮助。

---

## 👨‍💻 作者信息

**Created by：Mr_Hou**  
致力于技术平权，降低技术门槛，让人人都有机会拥抱 AI 世界 🤝

- 💬 Wechat：`qiyuan_hou`（欢迎交流，共同进化！）
- 🐙 GitHub：[https://github.com/Alexshy/openclaw-installer](https://github.com/Alexshy/openclaw-installer)

> ⚠️ **严禁恶意篡改或将本免费脚本商业化售卖**

---

<div align="center">

如果这个项目对你有帮助，欢迎点个 ⭐ **Star**！

</div>
