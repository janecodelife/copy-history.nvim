# copy-history.nvim 📋

A lightweight, high-performance, and minimalist clipboard history manager for Neovim. It automatically tracks everything you copy (yank) and lets you recall and paste it instantly via a centered floating window picker.

## ✨ Features
- **Zero Dependencies:** Written purely in Lua, running 100% locally with zero external requirements.
- **Duplicate Prevention:** Automatically removes older duplicate text snippets to keep your history clean.
- **Smart Truncation:** Provides a beautifully formatted single-line preview inside the picker view.
- **Sleek UX:** Instantly map any hotkey to fire up a clean, rounded floating window, navigate with standard motion keys, and paste with Enter.

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

### Using [lazy.nvim](https://github.com)
```lua
return {
    "janecodelife/copy-history.nvim",
    config = function()
        require("copy-history").setup({
            keymap = "<leader>ch",
            max_history = 10,
            border = "rounded"
        })
    end
}
```

## 🚀 Usage

1. Go about your normal coding routine and copy text snippets using regular Neovim operators (e.g., `yy`, `yw`, `viw+y`).
2. Whenever you want to paste something from your history, press **`<leader>ch`** (Space + c + h by default) in **Normal Mode**.
3. A centered floating window will open showing your recent copy history snippets.
4. **Navigate** up/down the list, then press **`Enter`** on any line to automatically close the window and paste that text right after your cursor!
5. To close the picker menu without pasting anything, simply press **`q`**.

## 📄 License
MIT License. See the [LICENSE](./LICENSE) file for more details.

