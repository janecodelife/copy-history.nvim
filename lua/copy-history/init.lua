local M = {}

-- Default configuration options
M.config = {
	max_history = 10, -- Maximum number of copied items to remember
	keymap = "<leader>ch", -- Default keymap to open the copy history window
	border = "rounded", -- Floating window border style
	max_payload_size = 10 * 1024 * 1024, -- Maximum payload size in bytes (10 MB)
	syntax_highlight = false, -- Disable syntax parsing by default for pure plain-text speed
	close_on_q = true, -- Map 'q' to close history window (in addition to <Esc>)
	keymaps = {
		edit = { "e", "i" }, -- Keys to enter edit mode in preview
		save_and_paste = "<C-s>", -- Key to save and paste from edit mode (works in Normal & Insert modes)
		paste = "<CR>", -- Key to paste selected item after cursor (also 'p')
		paste_before = "P", -- Key to paste selected item before cursor
		delete = { "d", "<Del>" }, -- Keys to delete item from history
		yank = "y", -- Key to yank selected item to register
		close = "<Esc>", -- Key to close history window
	},
	window = {
		width = 0.88, -- Overall width ratio (0.0 to 1.0) or fixed integer column width
		height = 0.60, -- Overall height ratio (0.0 to 1.0) or fixed integer row height
		preview_ratio = 0.55, -- Portion of width allocated to preview window (default 55%)
		min_height = 8, -- Minimum height in rows
	},
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

-- Computes the deterministic JSON storage file path for the current working directory
function M.get_storage_path()
	local storage_dir = M.config.storage_dir or (vim.fn.stdpath("data") .. "/copy-history")
	local cwd = vim.fs.normalize(vim.fn.getcwd())
	local safe_name = cwd:gsub("[/\\]", "%%"):gsub(":", "%%") .. ".json"
	return storage_dir, storage_dir .. "/" .. safe_name
end

-- Loads persisted history from disk for the active working directory
function M.load_history()
	local _, file_path = M.get_storage_path()
	if vim.fn.filereadable(file_path) == 1 then
		local lines = vim.fn.readfile(file_path)
		if lines and #lines > 0 then
			local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
			if ok and type(data) == "table" then
				M.history = data
				return
			end
		end
	end
	M.history = {}
end

-- Persists the active history list to disk for the current working directory
function M.save_history()
	local storage_dir, file_path = M.get_storage_path()
	if vim.fn.isdirectory(storage_dir) == 0 then
		vim.fn.mkdir(storage_dir, "p")
	end
	local ok, json_str = pcall(vim.json.encode, M.history)
	if ok and json_str then
		vim.fn.writefile({ json_str }, file_path)
	end
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

	-- Automatically persist updated history to disk
	M.save_history()
end

-- Generates and displays the visual history list in a centered floating window
function M.open_history_window()
	if #M.history == 0 then
		vim.notify("Copy History: History is currently empty.", vim.log.levels.INFO)
		return
	end

	-- Helper function to resolve dynamic dimensions from ratio (0-1) or fixed columns/rows (>1)
	local function resolve_dim(val, max_avail, fallback_ratio)
		local v = val or fallback_ratio
		if type(v) == "number" then
			if v > 0 and v <= 1 then
				return math.max(1, math.floor(max_avail * v))
			elseif v > 1 then
				return math.min(math.floor(v), max_avail)
			end
		end
		return math.max(1, math.floor(max_avail * fallback_ratio))
	end

	-- 1. Calculate responsive window dimensions based on user configuration
	local total_cols = vim.o.columns
	local total_lines = vim.o.lines
	local win_cfg = M.config.window or {}

	local target_width = resolve_dim(win_cfg.width, total_cols, 0.88)
	local target_height = resolve_dim(win_cfg.height, total_lines, 0.60)
	local min_height = math.max(1, win_cfg.min_height or 8)
	local height = math.min(math.max(1, total_lines - 4), math.max(min_height, target_height))
	local row = math.max(0, math.floor((total_lines - height) / 2))

	-- Adaptive dual-pane threshold (only split into two panes if screen is wide enough)
	local show_preview = (win_cfg.preview ~= false) and (total_cols >= 75) and (target_width >= 65)
	local preview_ratio = (win_cfg.preview_ratio and win_cfg.preview_ratio > 0 and win_cfg.preview_ratio < 1)
			and win_cfg.preview_ratio
		or 0.55
	local preview_width = show_preview and math.floor((target_width - 2) * preview_ratio) or 0
	local list_width = show_preview and (target_width - preview_width - 2) or target_width

	local list_col = math.max(0, math.floor((total_cols - target_width) / 2))
	local preview_col = list_col + list_width + 2

	-- 2. Create scratch buffers
	local list_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[list_buf].buftype = "nofile"
	vim.bo[list_buf].bufhidden = "wipe"

	local preview_buf = nil
	local preview_win = nil
	if show_preview then
		preview_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[preview_buf].buftype = "nofile"
		vim.bo[preview_buf].bufhidden = "wipe"
	end

	-- Helper function to generate responsive titles based on window width
	local function get_list_title(w)
		if w >= 60 then
			return " 󰅍 Copy History (Enter: Paste | e: Edit | d: Del | y: Yank) "
		elseif w >= 42 then
			return " 󰅍 Copy History (Enter/e/d/y) "
		elseif w >= 22 then
			return " 󰅍 Copy History "
		else
			return " 󰅍 "
		end
	end

	local function get_preview_title(file, line, w)
		local short_file = vim.fn.fnamemodify(file or "Snippet", ":t")
		local full_title = string.format(" 󰈈 Preview: %s:%d ", file or "Snippet", line or 1)
		local short_title = string.format(" 󰈈 Preview: %s:%d ", short_file, line or 1)
		local min_title = " 󰈈 Preview "
		if #full_title <= (w - 4) then
			return full_title
		elseif #short_title <= (w - 4) then
			return short_title
		elseif #min_title <= (w - 4) then
			return min_title
		else
			return " 󰈈 "
		end
	end

	-- Helper function to format lines for the list picker adaptively
	local function render_display_lines()
		local display_lines = {}
		for i, item in ipairs(M.history) do
			local text = M.get_entry_text(item)
			local file = (type(item) == "table" and item.file) or "[No Name]"
			local line = (type(item) == "table" and item.line) or 1
			local line_count = (type(item) == "table" and item.line_count) or #vim.split(text, "\n")
			local preview = text:gsub("\n", " ")

			local prefix
			if list_width >= 45 then
				prefix = string.format(" [%d] %s:%d (%dL) · ", i, file, line, line_count)
			elseif list_width >= 28 then
				local short_file = vim.fn.fnamemodify(file, ":t")
				prefix = string.format(" [%d] %s:%d · ", i, short_file, line)
			else
				prefix = string.format(" [%d] ", i)
			end

			local avail_len = math.max(5, list_width - #prefix - 2)
			if #preview > avail_len then
				preview = preview:sub(1, avail_len) .. "..."
			end
			table.insert(display_lines, prefix .. preview)
		end
		return display_lines
	end

	vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, render_display_lines())
	vim.bo[list_buf].modifiable = false

	-- 3. Open Floating Windows with responsive titles
	local list_opts = {
		relative = "editor",
		width = list_width,
		height = height,
		row = row,
		col = list_col,
		style = "minimal",
		border = M.config.border,
		title = get_list_title(list_width),
		title_pos = "center",
	}
	local list_win = vim.api.nvim_open_win(list_buf, true, list_opts)

	if show_preview and preview_buf then
		local preview_opts = {
			relative = "editor",
			width = preview_width,
			height = height,
			row = row,
			col = preview_col,
			style = "minimal",
			border = M.config.border,
			title = get_preview_title(nil, nil, preview_width),
			title_pos = "center",
		}
		preview_win = vim.api.nvim_open_win(preview_buf, false, preview_opts)
	end

	-- Safe window closer function
	local function close_all_windows()
		if vim.api.nvim_win_is_valid(list_win) then
			vim.api.nvim_win_close(list_win, true)
		end
		if preview_win and vim.api.nvim_win_is_valid(preview_win) then
			vim.api.nvim_win_close(preview_win, true)
		end
	end

	-- Synchronize preview window with active cursor selection
	local function update_preview(idx)
		if not show_preview or not preview_buf or not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
			return
		end
		local entry = M.history[idx]
		if not entry then
			vim.bo[preview_buf].modifiable = true
			vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "-- No preview available --" })
			vim.bo[preview_buf].modifiable = false
			return
		end

		local text = M.get_entry_text(entry)
		local lines = vim.split(text, "\n")
		vim.bo[preview_buf].modifiable = true
		vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
		vim.bo[preview_buf].modifiable = false

		if M.config.syntax_highlight and type(entry) == "table" and entry.filetype and entry.filetype ~= "" then
			pcall(function()
				vim.bo[preview_buf].filetype = entry.filetype
			end)
		else
			pcall(function()
				vim.bo[preview_buf].filetype = ""
			end)
		end

		local title_file = (type(entry) == "table" and entry.file) or "Snippet"
		local title_line = (type(entry) == "table" and entry.line) or 1
		orig_preview_title = get_preview_title(title_file, title_line, preview_width)
		pcall(vim.api.nvim_win_set_config, preview_win, {
			title = orig_preview_title,
			title_pos = "center",
		})
	end

	local cur_edit_idx = nil

	-- Synchronize preview buffer contents back into M.history
	local function sync_preview_to_history()
		if not show_preview or not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
			return
		end
		local idx = cur_edit_idx
		if not idx or not M.history[idx] then
			if vim.api.nvim_win_is_valid(list_win) then
				idx = vim.api.nvim_win_get_cursor(list_win)[1]
			else
				idx = 1
			end
		end
		if not M.history[idx] then
			return
		end

		local modified_lines = vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false)
		local modified_text = table.concat(modified_lines, "\n")
		if type(M.history[idx]) == "table" then
			M.history[idx].text = modified_text
			M.history[idx].line_count = #modified_lines
		else
			M.history[idx] = modified_text
		end
		M.save_history()

		-- Refresh list window display so the edited snippet is immediately reflected
		if vim.api.nvim_buf_is_valid(list_buf) then
			vim.bo[list_buf].modifiable = true
			vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, render_display_lines())
			vim.bo[list_buf].modifiable = false
		end
	end

	-- Initial preview update
	update_preview(1)

	-- Update preview on cursor movement in list window
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = list_buf,
		callback = function()
			if vim.api.nvim_win_is_valid(list_win) then
				local cur_line = vim.api.nvim_win_get_cursor(list_win)[1]
				if show_preview and preview_buf and vim.bo[preview_buf].modifiable then
					sync_preview_to_history()
					vim.bo[preview_buf].modifiable = false
				end
				update_preview(cur_line)
			end
		end,
	})

	-- Refresh list and preview after deletion or edits
	local function refresh_list_and_preview()
		if #M.history == 0 then
			close_all_windows()
			vim.notify("Copy History: History is now empty.", vim.log.levels.INFO)
			return
		end
		vim.bo[list_buf].modifiable = true
		vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, render_display_lines())
		vim.bo[list_buf].modifiable = false

		if vim.api.nvim_win_is_valid(list_win) then
			local cur = vim.api.nvim_win_get_cursor(list_win)[1]
			if cur > #M.history then
				cur = #M.history
				vim.api.nvim_win_set_cursor(list_win, { cur, 0 })
			end
			update_preview(cur)
		end
	end

	-- Defocus autocommand: close when focus leaves both picker and preview windows
	local function on_leave()
		vim.schedule(function()
			local cur_win = vim.api.nvim_get_current_win()
			if cur_win ~= list_win and (not preview_win or cur_win ~= preview_win) then
				close_all_windows()
			end
		end)
	end

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = list_buf,
		callback = on_leave,
	})

	if preview_buf then
		vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
			buffer = preview_buf,
			callback = function()
				if vim.bo[preview_buf].modifiable then
					sync_preview_to_history()
					vim.bo[preview_buf].modifiable = false
					if orig_preview_title and vim.api.nvim_win_is_valid(preview_win) then
						pcall(vim.api.nvim_win_set_config, preview_win, {
							title = orig_preview_title,
							title_pos = "center",
						})
					end
				end
				on_leave()
			end,
		})
	end

	-- Helper function to map single key or list of keys
	local function map_keys(mode, keys, callback, buf)
		if type(keys) == "table" then
			for _, k in ipairs(keys) do
				vim.keymap.set(mode, k, callback, { buffer = buf, silent = true, nowait = true })
			end
		elseif type(keys) == "string" and keys ~= "" then
			vim.keymap.set(mode, keys, callback, { buffer = buf, silent = true, nowait = true })
		end
	end

	local cfg_keys = M.config.keymaps or {}

	-- Dismiss / Close window mappings
	local close_keys = cfg_keys.close or "<Esc>"
	map_keys("n", close_keys, close_all_windows, list_buf)

	-- Configurable 'q' dismissal
	if M.config.close_on_q ~= false then
		map_keys("n", "q", close_all_windows, list_buf)
	end

	-- Delete selected item
	local function delete_item()
		if #M.history == 0 then
			return
		end
		local cur = vim.api.nvim_win_get_cursor(list_win)[1]
		table.remove(M.history, cur)
		M.save_history()
		refresh_list_and_preview()
	end
	map_keys("n", cfg_keys.delete or { "d", "<Del>" }, delete_item, list_buf)

	-- Yank selected item to register without closing
	map_keys("n", cfg_keys.yank or "y", function()
		if #M.history == 0 then
			return
		end
		local cur = vim.api.nvim_win_get_cursor(list_win)[1]
		local text = M.get_entry_text(M.history[cur])
		if text and text ~= "" then
			vim.fn.setreg('"', text)
			pcall(vim.fn.setreg, "+", text)
			vim.notify("Copy History: Yanked entry to clipboard!", vim.log.levels.INFO)
		end
	end, list_buf)

	-- Paste handler helper (character-wise insertion)
	local function paste_selected(paste_after)
		if #M.history == 0 then
			return
		end
		if show_preview and preview_buf and vim.bo[preview_buf].modifiable then
			sync_preview_to_history()
		end
		local cur = vim.api.nvim_win_get_cursor(list_win)[1]
		local text = M.get_entry_text(M.history[cur])
		close_all_windows()
		if text and text ~= "" then
			vim.api.nvim_put(vim.split(text, "\n"), "c", paste_after, true)
		end
	end

	-- Paste keymaps in list window
	map_keys("n", cfg_keys.paste or "<CR>", function()
		paste_selected(true)
	end, list_buf)
	if cfg_keys.paste ~= "p" then
		map_keys("n", "p", function()
			paste_selected(true)
		end, list_buf)
	end

	map_keys("n", cfg_keys.paste_before or "P", function()
		paste_selected(false)
	end, list_buf)

	-- Mouse interactions in list window: single click selects, double click pastes
	vim.keymap.set("n", "<LeftMouse>", function()
		local mouse = vim.fn.getmousepos()
		if mouse and mouse.winid == list_win and mouse.line <= #M.history and mouse.line >= 1 then
			pcall(vim.api.nvim_win_set_cursor, list_win, { mouse.line, 0 })
			if show_preview and preview_buf and vim.bo[preview_buf].modifiable then
				sync_preview_to_history()
				vim.bo[preview_buf].modifiable = false
			end
			update_preview(mouse.line)
		end
	end, { buffer = list_buf, silent = true, nowait = true })

	vim.keymap.set("n", "<2-LeftMouse>", function()
		local mouse = vim.fn.getmousepos()
		if mouse and mouse.winid == list_win and mouse.line <= #M.history and mouse.line >= 1 then
			pcall(vim.api.nvim_win_set_cursor, list_win, { mouse.line, 0 })
			paste_selected(true)
		end
	end, { buffer = list_buf, silent = true, nowait = true })

	-- Edit Mode in preview window
	if show_preview and preview_buf and preview_win then
		local function enter_edit_mode()
			if #M.history == 0 then
				return
			end
			local cur_idx = cur_edit_idx
			if vim.api.nvim_win_is_valid(list_win) then
				cur_idx = vim.api.nvim_win_get_cursor(list_win)[1]
			end
			if not cur_idx or cur_idx > #M.history or cur_idx < 1 then
				cur_idx = 1
			end
			cur_edit_idx = cur_idx
			if vim.api.nvim_win_is_valid(preview_win) and vim.api.nvim_get_current_win() ~= preview_win then
				vim.api.nvim_set_current_win(preview_win)
			end
			vim.bo[preview_buf].modifiable = true

			orig_preview_title = get_preview_title(
				(type(M.history[cur_idx]) == "table" and M.history[cur_idx].file) or "Snippet",
				(type(M.history[cur_idx]) == "table" and M.history[cur_idx].line) or 1,
				preview_width
			)

			-- Display responsive edit mode indicator in preview border
			pcall(vim.api.nvim_win_set_config, preview_win, {
				title = preview_width >= 40 and " 󰏫 Edit Mode (<C-s>: Save & Paste | <Esc>: Done) "
					or " 󰏫 Edit Mode ",
				title_pos = "center",
			})

			-- In edit mode: save modifications and paste directly into buffer
			local function save_and_paste()
				sync_preview_to_history()
				local cur = cur_edit_idx or vim.api.nvim_win_get_cursor(list_win)[1]
				local text = M.get_entry_text(M.history[cur])
				close_all_windows()
				if text and text ~= "" then
					vim.api.nvim_put(vim.split(text, "\n"), "c", true, true)
				end
			end

			-- Auto-sync changes back into history and return focus to list window
			local function sync_and_return()
				sync_preview_to_history()
				vim.bo[preview_buf].modifiable = false
				pcall(vim.api.nvim_win_set_config, preview_win, {
					title = orig_preview_title,
					title_pos = "center",
				})

				if vim.api.nvim_win_is_valid(list_win) then
					vim.api.nvim_set_current_win(list_win)
				end
			end

			-- Bind save_and_paste in BOTH Normal mode and Insert mode!
			local save_keys = cfg_keys.save_and_paste or "<C-s>"
			map_keys("n", save_keys, save_and_paste, preview_buf)
			map_keys("i", save_keys, save_and_paste, preview_buf)
			-- Also map <CR> in normal mode to save & paste
			vim.keymap.set("n", "<CR>", save_and_paste, { buffer = preview_buf, silent = true, nowait = true })

			-- <Esc> in Normal mode syncs edits and returns focus to list window
			vim.keymap.set("n", "<Esc>", sync_and_return, { buffer = preview_buf, silent = true, nowait = true })

			-- 'q' in Normal mode returns focus back to list window (if close_on_q enabled)
			if M.config.close_on_q ~= false then
				vim.keymap.set("n", "q", sync_and_return, { buffer = preview_buf, silent = true, nowait = true })
			end
		end

		-- Map edit keys in list window (default 'e' and 'i')
		map_keys("n", cfg_keys.edit or { "e", "i" }, enter_edit_mode, list_buf)

		-- Protect preview buffer when focused in read-only mode:
		-- Pressing any editing key enters edit mode automatically without triggering E21
		local function on_preview_input(action)
			return function()
				if not vim.bo[preview_buf].modifiable then
					enter_edit_mode()
				end
				if action == "i" then
					vim.cmd("startinsert")
				elseif action == "a" then
					vim.cmd("startinsert!")
				elseif action == "I" then
					vim.cmd("startinsert")
					vim.cmd("normal! ^")
				elseif action == "A" then
					vim.cmd("startinsert!")
				elseif action == "o" then
					vim.api.nvim_feedkeys("o", "n", false)
				elseif action == "O" then
					vim.api.nvim_feedkeys("O", "n", false)
				elseif action == "c" or action == "C" or action == "s" or action == "S" then
					vim.api.nvim_feedkeys(action, "n", false)
				end
			end
		end

		local edit_keys = { "i", "a", "o", "O", "c", "C", "s", "S", "I", "A", "e" }
		for _, k in ipairs(edit_keys) do
			vim.keymap.set("n", k, on_preview_input(k), { buffer = preview_buf, silent = true, nowait = true })
		end

		-- Mouse click on preview buffer enters edit mode and positions cursor
		vim.keymap.set("n", "<LeftMouse>", function()
			if not vim.bo[preview_buf].modifiable then
				enter_edit_mode()
			end
			local mouse = vim.fn.getmousepos()
			if mouse and mouse.winid == preview_win then
				pcall(vim.api.nvim_win_set_cursor, preview_win, { mouse.line, math.max(0, mouse.column - 1) })
			end
		end, { buffer = preview_buf, silent = true, nowait = true })

		-- Auto-promote to modifiable on WinEnter
		vim.api.nvim_create_autocmd("WinEnter", {
			buffer = preview_buf,
			callback = function()
				if vim.api.nvim_win_is_valid(list_win) and not vim.bo[preview_buf].modifiable then
					enter_edit_mode()
				end
			end,
		})
	end
end

-- Standard configuration setup framework entry-point
function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Automatically load persisted history for current working directory
	M.load_history()

	-- Initialize automated autocommand listener group
	local group = vim.api.nvim_create_augroup("CopyHistoryGroup", { clear = true })
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = group,
		callback = function()
			M.on_text_copy()
		end,
	})

	-- Reload directory-specific history when working directory changes
	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			M.load_history()
		end,
	})

	-- Ensure latest history is flushed to disk before quitting Neovim
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			M.save_history()
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
