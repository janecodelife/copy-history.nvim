# copy-history.nvim 📋

[![Follow on X](https://img.shields.io/badge/Follow-@janecodelife-000000?style=for-the-badge&logo=x)](https://x.com/janecodelife)
[![Subscribe on YouTube](https://img.shields.io/badge/Subscribe-@JaneCodeLife-FF0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@JaneCodeLife)

A lightweight, high-performance, and minimalist clipboard history manager for Neovim. It automatically tracks everything you copy (yank) and lets you recall and paste it instantly via a floating window in a blink That Support Single Lines  And Mutiple Lines.

## ✨ Features
- **Zero Dependencies:** Written purely in Lua, running 100% locally with zero external requirements.
- **Duplicate Prevention:** Automatically removes older duplicate text snippets to keep your history clean.
- **Support Single And Mutiple Lines:** Support And Working with single and multiple lines
- **Support Previews And File Names And Line Numbers :** Thank You frtzhahn
- **Support Tree-sitter Toggling :** Enable or disable Tree-sitter support if you got limited cpus and ram
- **Support Edit Before Paste :** edit already saved history before paste them again
- **Support Not Losing History After Close Neovim :** History will be saved


---

## 📦 Installation

### Using Neovim's Built-in Pack (`vim.pack`)
Add the following to your configuration file (e.g., `init.lua`):

```lua
-- Add and load the copy-history plugin directly from GitHub
vim.pack.add({
	"https://github.com/janecodelife/copy-history.nvim",
})


-- Initialize and configure the plugin
require("copy-history").setup({
	keymap = "<leader>ch", -- Keymap to open the copy history floating window
	max_history = 10, -- Maximum number of copied snippets to store
	border = "rounded", -- Border style: "rounded", "single", "double", "solid"
	max_payload_size = 10 * 1024 * 1024, -- Safety limiter: 10 MB payload ceiling
	syntax_highlight = true, -- true: Tree-sitter colors | false: plain text (0ms CPU)
	close_on_q = true, -- Map 'q' to dismiss window (alongside <Esc>) default is <ESC>
	storage_dir = nil, -- Directory for history JSON (nil = stdpath('data'))
	window = {
		width = 0.88, -- Total width ratio (0.0 - 1.0) or fixed column count
		height = 0.60, -- Total height ratio (0.0 - 1.0) or fixed row count
		preview_ratio = 0.55, -- Width fraction for preview pane (55%)
		min_height = 8, -- Minimum window height in terminal rows
		preview = true, -- Set to false to disable side-by-side preview
	},
})

```

-- Full Core configs 

```
require("copy-history").setup({
    -- Core Options
    keymap = "<leader>ch",                 -- Keymap to toggle the history picker
    max_history = 10,                      -- Maximum number of copied items to retain
    border = "rounded",                    -- Floating border ("single", "double", "rounded", "solid", "shadow")
    max_payload_size = 10 * 1024 * 1024,   -- 10 MB payload safety limit
    storage_dir = nil,                     -- Defaults to stdpath('data') .. '/copy-history'
    
    -- UI & Behavior Options
    syntax_highlight = false,              -- Set true if you want optional syntax highlighting
    close_on_q = true,                     -- Map 'q' to close picker (in addition to <Esc>)
    
    -- Customizable In-Picker Keymaps
    keymaps = {
        edit = { "e", "i" },               -- Keys to unlock and edit snippet in preview
        save = "<C-s>",                    -- Pure Save: updates history & disk without closing (Normal & Insert)
        paste = "<CR>",                    -- Paste & Exit: pastes snippet at cursor and dismisses picker (also 'p')
        paste_before = "P",                -- Multi-Paste: pastes at cursor while leaving picker open
        delete = { "d", "<Del>" },         -- Delete selected item from history
        yank = "y",                        -- Yank selected item to system register
        close = "<Esc>",                   -- Dismiss picker
    },
    
    -- Sizing & Layout Options
    window = {
        width = 0.88,                      -- Width ratio (0.0 to 1.0) or fixed columns
        height = 0.60,                     -- Height ratio (0.0 to 1.0) or fixed rows
        preview_ratio = 0.55,              -- Portion allocated to preview (55%)
        min_height = 8,                    -- Minimum vertical rows
        preview = true,                    -- Enable or disable preview window
    },
})
```
## Interactive Keybindings Reference

| Context | Keymap | Action |
|---------|--------|--------|
| **List Picker** | `<CR>` / `p` | **Paste & Exit:** Pastes selected snippet at cursor and closes picker |
| **List Picker** | `P` | **Multi-Paste:** Pastes snippet at cursor while keeping picker window open |
| **List Picker** | `e` / `i` | **Enter Edit Mode** in preview buffer (or single‑pane buffer swap) |
| **List Picker** | `d` / `<Del>` | Delete selected entry from history and disk |
| **List Picker** | `y` | Yank selected entry to system clipboard (`"` and `+` registers) |
| **List Picker** | `<Esc>` / `q` | Dismiss picker immediately |
| **Preview / Edit** | `<C-s>` | **Pure Save:** Saves edits to history & disk, stays open in Normal & Insert modes |
| **Preview / Edit** | `<CR>` | **Paste & Exit:** Saves edits, closes window, and pastes into code buffer |
| **Preview / Edit** | `P` | **Multi-Paste:** Saves edits and pastes into buffer while keeping preview open |
| **Preview / Edit** | `u` | **Undo:** Undoes edits back to original snippet baseline without deleting content |
| **Preview / Edit** | `<Esc>` | Return focus to snippet list (or swap back to list on small screens) |
| **Global** | Defocus / Mouse | Dismisses window automatically when navigating away; auto‑promotes on mouse click |

## Demo Video 📺

<p align="center">
  <img src="assets/copy-history.gif" alt="copy-history-video" width="100%">
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

You can tip or donate directly to my **TRON (TRX / USDT-TRC20)**  wallet address:

## ☕☕☕☕ Support My Work. Buy Me Coffee Via USDT (Help Me Buy Dev Laptop)☕☕☕☕

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
frtzhahn (aldrin)
## Upcoming 🚀 (Stay Tuned!)

### The Ultimate Neovim Config for Modern Web & Laravel Devs ⚡

I am currently cooking a comprehensive guide and boilerplate configuration on **How to turn Neovim into a (Powerful) IDE** explicitly optimized for:

- **Backend & Frameworks**: PHP (Intelephense) & Full Laravel & Livewire Integration (With Preformance)
- **Frontend & Tooling**: HTML, CSS, JavaScript, TypeScript, and Livewire SFCs
- **Speed**: Blazing fast autocompletion, lightning-speed code navigation, and fuzzy finding.
