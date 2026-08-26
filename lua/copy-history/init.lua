local M = {}

-- Default configuration options
M.config = {
	max_history = 10, -- Maximum number of copied items to remember
	keymap = "<leader>ch", -- Default keymap to open the copy history window
	border = "rounded", -- Floating window border style
	max_payload_size = 10 * 1024 * 1024, -- Maximum payload size in bytes (10 MB)
}

-- Table to store the copied text history items (structured metadata entries)
M.history = {}

-- Safely retrieves raw text snippet from a history item (backward-compatible)
function M.get_entry_text(item)
	if type(item) == "table" then
		return item.text or ""
	elseif type(item) == "string" then
		return item
	end
	return ""
end

-- Core listener function triggered immediately after any text is copied/yanked
function M.on_text_copy()
	-- Get the recently yanked text string from the default register
	local copied_text = table.concat(vim.v.event.regcontents, "\n")

	-- Ignore empty strings or whitespace-only copies
	if copied_text == "" or string.match(copied_text, "^%s*$") then
		return
	end

	-- Enforce maximum payload limit (protects memory and JSON disk I/O)
	if #copied_text > (M.config.max_payload_size or (10 * 1024 * 1024)) then
		return
	end

	-- Check if this exact text already exists in history; remove it to prevent duplicates
	for i, v in ipairs(M.history) do
		if M.get_entry_text(v) == copied_text then
			table.remove(M.history, i)
			break
		end
	end

	-- Capture source context metadata
	local raw_file = vim.api.nvim_buf_get_name(0)
	local display_file = raw_file ~= "" and vim.fn.fnamemodify(raw_file, ":~:.") or "[No Name]"
	local cursor_line = 1
	local ok_cursor, pos = pcall(vim.api.nvim_win_get_cursor, 0)
	if ok_cursor and pos then
		cursor_line = pos[1]
	end
	local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
	local lines = vim.split(copied_text, "\n")

	local entry = {
		text = copied_text,
		file = display_file,
		line = cursor_line,
		filetype = ft,
		line_count = #lines,
		time = os.time(),
	}

	-- Insert the new entry at the very top (index 1) of our history list
	table.insert(M.history, 1, entry)

	-- Cap the history list size based on the user's max_history configuration
	if #M.history > M.config.max_history then
		table.remove(M.history)
	end
end

-- Generates and displays the visual history list in a centered floating window
function M.open_history_window()
	if #M.history == 0 then
		vim.notify("Copy History: History is currently empty! ⎘ ", vim.log.levels.INFO)
		return
	end

	-- 1. Create an isolated scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)

	-- Format the display lines to show a preview snippet of each copied item
	local display_lines = {}
	for i, item in ipairs(M.history) do
		local text = M.get_entry_text(item)
		-- Replace newlines with spaces for cleaner single-line preview display
		local preview = text:gsub("\n", " ")
		-- Truncate long strings to fit perfectly in the window view
		if #preview > 50 then
			preview = preview:sub(1, 50) .. "..."
		end
		table.insert(display_lines, string.format(" [%d] %s", i, preview))
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
	vim.bo[buf].modifiable = false -- Make it read-only so users cannot type in it

	-- 2. Define floating window dimensional layout properties
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.min(#M.history, math.floor(vim.o.lines * 0.5))
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = M.config.border,
		title = " ⎘  Copy Clipboard History ",
		title_pos = "center",
	}

	-- 3. Launch the floating window
	local win = vim.api.nvim_open_win(buf, true, opts)

	local function close_win()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Map 'q' and '<Esc>' to instantly close the history window picker view
	vim.keymap.set("n", "q", close_win, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, silent = true, nowait = true })

	-- Automatically close floating window on focus loss (switching window or leaving buffer)
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = buf,
		once = true,
		callback = close_win,
	})

	-- Map '<CR>' (Enter Key) to select the item, close the view, and paste it under cursor
	vim.keymap.set("n", "<CR>", function()
		-- Get the current line number the cursor is sitting on
		local cursor_pos = vim.api.nvim_win_get_cursor(win)
		local cursor_line = cursor_pos[1]

		-- Safely extract the corresponding text from history
		local selected_entry = M.history[cursor_line]
		local selected_text = M.get_entry_text(selected_entry)

		-- Close the floating window buffer instantly
		close_win()

		-- Safely put/paste the selected text right after the cursor position in main buffer
		if selected_text and selected_text ~= "" then
			-- "c" stands for character-wise insertion (the correct API standard type)
			vim.api.nvim_put(vim.split(selected_text, "\n"), "c", true, true)
		end
	end, { buffer = buf, silent = true, nowait = true })
end

-- Standard configuration setup framework entry-point
function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Initialize automated autocommand listener looking for TextYankPost event
	local group = vim.api.nvim_create_augroup("CopyHistoryGroup", { clear = true })
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = group,
		callback = function()
			M.on_text_copy()
		end,
	})

	-- Map global configuration shortcut to trigger window viewer
	if M.config.keymap then
		vim.keymap.set("n", M.config.keymap, function()
			M.open_history_window()
		end, { desc = "Open copy history clipboard viewer" })
	end
end

return M
