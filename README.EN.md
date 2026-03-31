# 🦞 OpenClaw One-Click Installer

> **Zero technical knowledge required · Fully automated · Mac + Windows**

<div align="center">

🇨🇳 [中文文档](./README.md) &nbsp;|&nbsp; 🇺🇸 English

</div>

---

## What is this?

This is a **fully automated** OpenClaw installation and deployment script suite, supporting both **Mac** and **Windows** platforms.

**No technical knowledge required.**  
Open a terminal, paste one command, and let the script handle everything ✅

> [OpenClaw](https://openclaw.ai) is a powerful AI coding assistant that supports DeepSeek, Kimi, ChatGPT, Claude, and other leading AI models — bringing AI-powered coding assistance to your favorite IDE.

---

## ✨ What can the script do for you?

| Feature | Description |
|---------|-------------|
| 🚀 **One-click Install & Deploy** | Auto-installs all dependencies + latest stable OpenClaw + AI model configuration |
| 🔄 **Switch AI Model** | Switch to any AI provider anytime (no reinstall needed) |
| 📱 **Add Chat Channels** | Connect WeChat / Lark / WeCom / QQ and more |
| 🔍 **Self-check & Repair** | Auto-detect and fix common issues |
| ⚙️ **Configuration Page** | Open the OpenClaw graphical configuration UI |
| 🌐 **Open Dashboard** | Launch the OpenClaw Web UI directly |
| 🗑️ **Full Uninstall** | Clean and complete removal of OpenClaw |

---

## 🤖 Supported AI Models

### 🇨🇳 China Users (No VPN Required)

| # | Model | Billing | Notes |
|---|-------|---------|-------|
| 1 | 🔥 **Volcano Engine Coding Plan** (ByteDance) | Monthly subscription | Best value, highly recommended |
| 2 | 🧠 **Alibaba Cloud Model Studio Coding Plan** | Monthly subscription | Qwen series, stable & reliable |
| 3 | 🌙 **Kimi** (Moonshot AI) | Pay-per-use | Outstanding long-context capability |
| 4 | 🎯 **MiniMax** | Pay-per-use | Low latency, direct domestic access |
| 5 | 🔵 **DeepSeek** | Pay-per-use | Strong coding ability, affordable |

### 🌍 International Users (VPN may be required from China)

| # | Model | Notes |
|---|-------|-------|
| 7 | **OpenAI (ChatGPT)** | GPT series, most widely used globally |
| 8 | **Google (Gemini)** | Google's latest flagship model |
| 9 | **Anthropic (Claude)** | Exceptional at coding and reasoning |

---

## 💻 System Requirements

| Platform | Minimum Requirement |
|----------|---------------------|
| **Mac** | macOS 10.15 Catalina or later |
| **Windows** | Windows 10 / 11 (64-bit) |

> The script will **automatically install** all missing dependencies (Node.js, pnpm, etc.) — no manual setup needed!

---

## 🚀 Quick Start

### 🍎 Mac Users

**Step 1**: Open **Terminal** (press `Command + Space`, search "Terminal", and open it)

**Step 2**: Copy the command below, paste it into Terminal, and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.sh | bash
```

> If GitHub is slow in your region, use the jsDelivr mirror:
> ```bash
> curl -fsSL https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/install.sh | bash
> ```

**Step 3**: Follow the on-screen prompts — that's it! 🎉

---

### 🪟 Windows Users

**Step 1**: Right-click the **Start Menu**, select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**

> ⚠️ Must be run as **Administrator**, otherwise software cannot be installed

**Step 2**: Copy the command below, paste it into PowerShell, and press Enter:

```powershell
$r=iwr -useb https://raw.githubusercontent.com/Alexshy/openclaw-installer/main/install.ps1; iex ([System.Text.Encoding]::UTF8.GetString($r.Content))
```

> If GitHub is slow in your region, use the jsDelivr mirror:
> ```powershell
> $r=iwr -useb https://cdn.jsdelivr.net/gh/Alexshy/openclaw-installer@main/install.ps1; iex ([System.Text.Encoding]::UTF8.GetString($r.Content))
> ```

> If you encounter an "execution policy" error, run this first:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> Then run the install command again.

**Step 3**: Follow the on-screen prompts — that's it! 🎉

---

## 📋 Menu Overview

After launching, the script displays an interactive menu with three sections:

```
╔══════════════════════════════════════════╗
║     《 Installation & Deployment 》      ║
║  1. Install + Deploy OpenClaw (Recommended) ║
║  2. Install OpenClaw only               ║
║  3. Deploy model/gateway/workspace only ║
╠══════════════════════════════════════════╣
║        《 Using OpenClaw 》              ║
║  4. Switch AI Model / Provider          ║
║  5. Add Channels (WeChat/Lark/WeCom/QQ) ║
║  6. Self-check & Auto Repair            ║
║  7. Open Configuration Page             ║
║  8. Open OpenClaw Dashboard             ║
╠══════════════════════════════════════════╣
║        《 Uninstall OpenClaw 》          ║
║  9. Fully Uninstall OpenClaw            ║
╚══════════════════════════════════════════╝
```

**New users: just pick `1` and everything is handled automatically!**

---

## ❓ FAQ

**Q: Do I need to install anything beforehand?**  
A: No! The script automatically detects and installs all required dependencies.

**Q: What do I need to input during installation?**  
A: Just your AI model API Key (a credential string from your chosen AI platform) and a folder path for your project workspace.

**Q: Where do I get an API Key?**  
A: After selecting your model, the script provides the direct link to the API key page. Simply register an account on that platform and apply.

**Q: Is it safe? Any viruses or backdoors?**  
A: The script is fully open-source — you can review every line of code right here on this page. No backdoors, no viruses, no data collection of any kind.

**Q: What if the installation fails?**  
A: Re-run the script and select option `6` (Self-check & Repair), or contact WeChat `qiyuan_hou` for support.

---

## 👨‍💻 About the Author

**Created by: Mr_Hou**  
Dedicated to democratizing technology — making AI accessible to everyone 🤝

- 💬 WeChat: `qiyuan_hou` (happy to chat and grow together!)
- 🐙 GitHub: [https://github.com/Alexshy/openclaw-installer](https://github.com/Alexshy/openclaw-installer)

> ⚠️ **Unauthorized modification or commercial resale of this free script is strictly prohibited.**

---

<div align="center">

If this project helped you, please give it a ⭐ **Star**!

</div>
