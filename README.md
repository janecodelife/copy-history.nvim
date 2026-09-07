# copy-history.nvim 📋

[![Follow on X](https://img.shields.io/badge/Follow-@janecodelife-000000?style=for-the-badge&logo=x)](https://x.com/janecodelife)
[![Subscribe on YouTube](https://img.shields.io/badge/Subscribe-@JaneCodeLife-FF0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@JaneCodeLife)

A lightweight, high-performance, and minimalist clipboard history manager for Neovim. It automatically tracks everything you copy (yank) and lets you recall and paste it instantly via a floating window in a blink That Support Single Lines  And Mutiple Lines.

## ✨ Features
- **Zero Dependencies & Zero-Treesitter Required:** Written purely in Lua and native Neovim C-APIs, running 100% locally. Tree-sitter is strictly optional for syntax colors and never required for previewing or live editing.
- **Side-by-Side Synchronized Preview:** Live preview window updating in real-time as you navigate recent snippets.
- **Live In-Preview Editing:** Edit text snippets directly in the preview window before pasting (`e` or `i`), with `<C-s>` to save & paste in both Normal and Insert modes.
- **Duplicate Prevention:** Automatically removes older duplicate text snippets to keep your history clean.
- **Support Single And Multiple Lines:** Support and working with single and multiple lines.
- **Per-Directory Persistence:** History is stored cleanly per workspace/directory in Neovim data storage.

---

## 📦 Installation

### Using Neovim's Built-in Pack (`vim.pack`)
Add the following to your configuration file (e.g., `init.lua`):

```lua
-- Add and load the copy-history plugin directly from GitHub
vim.pack.add({
	"https://github.com/janecodelife/copy-history.nvim",
})

-- Initialize with minimal zero-treesitter defaults
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

### Full Configuration (Optional)
```lua
require("copy-history").setup({
    keymap = "<leader>ch",              -- Global keymap to open history window
    max_history = 10,                   -- Max copied snippets to store
    syntax_highlight = false,           -- false: fast zero-treesitter plain-text | true: tree-sitter colors
    close_on_q = true,                  -- Map 'q' to close history window (in addition to <Esc>)
    keymaps = {
        edit = { "e", "i" },            -- Enter preview edit mode
        save_and_paste = "<C-s>",       -- Save & paste from edit mode (Normal & Insert mode)
        paste = "<CR>",                 -- Paste after cursor (also 'p')
        paste_before = "P",             -- Paste before cursor
        delete = { "d", "<Del>" },      -- Delete item from history
        yank = "y",                     -- Yank item to clipboard
        close = "<Esc>",                -- Dismiss window
    },
    window = {
        width = 0.88,                   -- Window width ratio (88%)
        height = 0.60,                  -- Window height ratio (60%)
        preview_ratio = 0.55,           -- Preview window width ratio (55%)
    },
})
```

## Demo Video 📺

<p align="center">
  <img src="assets/copy-history.gif" alt="copy-history-video" width="100%">
</p>

---

## 🚀 Usage

1. Go about your normal coding routine and copy text snippets using regular Neovim operators (e.g., `yy`, `yw`, `viw+y`).
2. Whenever you want to paste something from your history, press **`<leader>ch`** (Space + c + h by default) in **Normal Mode**.
3. A centered floating window will open showing your recent copy history snippets alongside a synchronized preview pane.
4. **Interactive Keybindings**:
   - **`Enter`** / **`p`**: Paste the selected snippet after your cursor.
   - **`P`**: Paste the selected snippet before your cursor.
   - **`e`** or **`i`**: Enter **Edit Mode** in the preview window to modify the snippet before pasting.
     - While editing: Press **`<C-s>`** (in either Normal or Insert mode) or **`<CR>`** (Normal mode) to save & paste immediately!
     - Press **`<Esc>`** in Normal mode to auto-sync your edits and return focus to the list.
   - **`y`**: Yank selected snippet to system clipboard without pasting.
   - **`d`** / **`<Del>`**: Remove selected snippet from history.
   - **`q`** / **`<Esc>`**: Dismiss the window without pasting.

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
