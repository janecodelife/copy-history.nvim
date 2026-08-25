# copy-history.nvim 📋

[![Follow on X](https://img.shields.io/badge/Follow-@janecodelife-000000?style=for-the-badge&logo=x)](https://x.com/janecodelife)
[![Subscribe on YouTube](https://img.shields.io/badge/Subscribe-@JaneCodeLife-FF0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@JaneCodeLife)

A lightweight, high-performance, and minimalist clipboard history manager for Neovim. It automatically tracks everything you copy (yank) and lets you recall and paste it instantly via a floating window in a blink.

## ✨ Features
- **Zero Dependencies:** Written purely in Lua, running 100% locally with zero external requirements.
- **Duplicate Prevention:** Automatically removes older duplicate text snippets to keep your history clean.

---

## 📦 Installation

### Using Neovim's Built-in Pack (`vim.pack`)
Add the following to your configuration file (e.g., `init.lua`):

```lua
-- Add and load the copy-history plugin directly from GitHub
vim.pack.add({
    source = "janecodelife/copy-history.nvim",
})

-- Initialize and configure the plugin
require("copy-history").setup({
    keymap = "<leader>ch",  -- Hotkey combination to open the viewer window
    max_history = 10,       -- Number of copied text snippets to remember
    border = "rounded",     -- Floating window border style (rounded, single, double, solid)
})
```


## Demo Video 📺

<p align="center">
  <img src="assets/todo-tracker.gif" alt="todo-tracker-video" width="100%">
</p>

---


## 🚀 Usage

1. Go about your normal coding routine and copy text snippets using regular Neovim operators (e.g., `yy`, `yw`, `viw+y`).
2. Whenever you want to paste something from your history, press **`<leader>ch`** (Space + c + h by default) in **Normal Mode**.
3. A centered floating window will open showing your recent copy history snippets.
4. **Navigate** up/down the list, then press **`Enter`** on any line to automatically close the window and paste that text right after your cursor!
5. To close the picker menu without pasting anything, simply press **`q`**.

--- 


## 💝 Support the Project

> _This plugin is built entirely on developer insights gathered over **years of building real-world software** to catch common pain points, combined with **months of dedicated building and rigorous testing** to ensure it operates flawlessly._

If this utility boosts your everyday speed and eliminates annoying file search clutter, please consider buying me a coffee or supporting my continuous maintenance!

You can tip or donate directly to my **TRON (TRX / USDT-TRC20)** crypto wallet address:

## ☕☕☕☕ Support Me By Coffee Via USDT ☕☕☕☕

- **Network:** `TRX Tron (TRC20)`
- **Address:** `TAFFjBP39Z86weL5dDU1A2251VrgPprDUj`

> _Every bit of support fuels the expansion of this ecosystem and helps me write cleaner tools for all of us. Thank you for standing behind independent developers!_ 🙏

---

##  If Have A Question🤝 (Contact Me)

I will be there i am answer to all messages

- **X (Twitter)**: [https://x.com/janecodelife](https://x.com/janecodelife)
- **YouTube**: [https://www.youtube.com/@JaneCodeLife](https://www.youtube.com/@JaneCodeLife)
- **Email**: [janecodelife@gmail.com](janecodelife@gmail.com)

---

## 🔗 My Other Plugins

Check out my other open-source tools to supercharge your Neovim environment from real-world developers use case problem solving:

- **[livewire-secure-properties](https://github.com/janecodelife/livewire-secure-properties)** - Secure livewire app properties by default and void headache.
- **[todo-tracker.nvim](https://github.com/janecodelife/todo-tracker.nvim)** - Assign and list app todos in a blink
- **[folders-bookmark.nvim](https://github.com/janecodelife/folders-bookmark.nvim)** - Bookmark folders and accessing them by keymap in a blink
- **[copy-history.nvim](https://github.com/janecodelife/copy-history.nvim)** - Access your copy (Yank) history and paste it again by 1 click in a blink.

---

# ThankYou

## Upcoming 🚀 (Stay Tuned!)

### The Ultimate Neovim Config for Modern Web & Laravel Devs ⚡

I am currently cooking a comprehensive guide and boilerplate configuration on **How to turn Neovim into a (Powerful) IDE** explicitly optimized for:

- **Backend & Frameworks**: PHP (Intelephense) & Full Laravel & Livewire Integration (With Preformance)
- **Frontend & Tooling**: HTML, CSS, JavaScript, TypeScript, and Livewire SFCs
- **Speed**: Blazing fast autocompletion, lightning-speed code navigation, and fuzzy finding.
