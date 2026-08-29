-- Automated test suite for copy-history.nvim
-- Run via: nvim --headless -u NONE -c "luafile tests/copy_history_spec.lua" -c "qall!"

local function run_tests()
	local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h")
	local init_lua = plugin_root .. "/lua/copy-history/init.lua"

	local test_storage = "/tmp/copy_history_test_storage_" .. os.time() .. "_" .. math.random(1000, 9999)
	local test_dir_1 = "/tmp/copy_history_test_dir1_" .. os.time() .. "_" .. math.random(1000, 9999)
	local test_dir_2 = "/tmp/copy_history_test_dir2_" .. os.time() .. "_" .. math.random(1000, 9999)
	vim.fn.mkdir(test_storage, "p")
	vim.fn.mkdir(test_dir_1, "p")
	vim.fn.mkdir(test_dir_2, "p")

	vim.cmd("cd " .. test_dir_1)

	local M = dofile(init_lua)
	M.setup({
		max_history = 5,
		max_payload_size = 10 * 1024 * 1024,
		storage_dir = test_storage,
	})

	print("Running Test 1: Capture yank with structured metadata...")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local a = 1", "local b = 2" })
	vim.bo.filetype = "lua"
	vim.cmd("normal! ggVGy")

	assert(#M.history == 1, "Expected 1 history item, got " .. #M.history)
	local entry1 = M.history[1]
	assert(type(entry1) == "table", "Entry should be a table")
	assert(entry1.text == "local a = 1\nlocal b = 2", "Yanked text should match buffer lines")
	assert(entry1.filetype == "lua", "Filetype should be lua")
	assert(entry1.line_count == 2, "Line count should be 2")
	assert(type(entry1.file) == "string", "File path should be string")
	print("✓ Test 1 passed!")

	print("Running Test 2: Payload limiter (enforcing max_payload_size)...")
	M.config.max_payload_size = 50 -- Temporarily set small limit to test rejection
	local big_text = string.rep("x", 200)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { big_text })
	vim.cmd("normal! ggVGy")
	assert(#M.history == 1, "Large payload above 50 bytes should be ignored")
	M.config.max_payload_size = 10 * 1024 * 1024 -- Reset to 10MB
	print("✓ Test 2 passed!")

	print("Running Test 3: Deduplication of identical copies...")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "item alpha" })
	vim.cmd("normal! ggVGy")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "item beta" })
	vim.cmd("normal! ggVGy")
	assert(#M.history == 3, "Expected 3 distinct items")
	-- Copy alpha again: should move to index 1 without increasing total count
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "item alpha" })
	vim.cmd("normal! ggVGy")
	assert(#M.history == 3, "Deduplication failed; item count increased")
	assert(M.get_entry_text(M.history[1]) == "item alpha", "Alpha should now be at top index 1")
	print("✓ Test 3 passed!")

	print("Running Test 4: Zero-dependency per-directory persistence...")
	local _, storage_file = M.get_storage_path()
	assert(vim.fn.filereadable(storage_file) == 1, "History JSON file must exist on disk: " .. storage_file)

	-- Simulate reload in same working directory
	local M_reloaded = dofile(init_lua)
	M_reloaded.setup({ storage_dir = test_storage })
	assert(#M_reloaded.history == 3, "Persisted history should reload exactly 3 items")
	assert(M_reloaded.get_entry_text(M_reloaded.history[1]) == "item alpha")
	print("✓ Test 4 passed!")

	print("Running Test 5: Working directory isolation...")
	vim.cmd("cd " .. test_dir_2)
	assert(#M_reloaded.history == 0, "Switched directory should start with clean history")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "project 2 secret" })
	vim.cmd("normal! ggVGy")
	assert(#M_reloaded.history == 1, "Project 2 should have 1 item")
	-- Switch back to project 1
	vim.cmd("cd " .. test_dir_1)
	assert(#M_reloaded.history == 3, "Project 1 should restore original 3 items")
	print("✓ Test 5 passed!")

	print("Running Test 6: UI Floating Picker & Synchronized Preview...")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "initial line" })
	M_reloaded.open_history_window()
	local open_windows = vim.api.nvim_list_wins()
	assert(#open_windows >= 2, "Main list and preview floating windows should both be open")

	-- Test delete with 'd'
	local count_before_del = #M_reloaded.history
	vim.api.nvim_feedkeys("d", "xt", false)
	assert(#M_reloaded.history == count_before_del - 1, "Key 'd' should delete the selected entry")

	-- Test yank with 'y'
	vim.api.nvim_feedkeys("y", "xt", false)
	local yanked_reg = vim.fn.getreg('"')
	assert(yanked_reg == M_reloaded.get_entry_text(M_reloaded.history[1]), "Key 'y' should load snippet into register")

	-- Test paste with 'p'
	vim.api.nvim_feedkeys("p", "xt", false)
	assert(#vim.api.nvim_list_wins() == 1, "Windows should close after paste")
	print("✓ Test 6 passed!")

	print("Running Test 7: Preview Live Edit Mode ('e')...")
	M_reloaded.open_history_window()
	vim.api.nvim_feedkeys("e", "xt", false)
	local active_preview_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(active_preview_buf, 0, -1, false, { "edited line 1", "edited line 2" })
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "xt", false)

	assert(M_reloaded.history[1].text == "edited line 1\nedited line 2", "History entry should be updated with edit")
	local pasted_result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	assert(pasted_result[1]:find("edited line 1") ~= nil, "Pasted buffer should contain edited content")
	print("✓ Test 7 passed!")

	print("Running Test 8: Dismissal on Escape & Defocus...")
	M_reloaded.open_history_window()
	assert(#vim.api.nvim_list_wins() >= 2)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
	assert(#vim.api.nvim_list_wins() == 1, "Floating windows should close on <Esc>")
	print("✓ Test 8 passed!")

	print("Running Test 9: Zero-Treesitter / Plain Text Preview Mode...")
	M_reloaded.config.syntax_highlight = false
	M_reloaded.open_history_window()
	local wins = vim.api.nvim_list_wins()
	local preview_win_id = wins[2] or wins[1]
	local prev_buf = vim.api.nvim_win_get_buf(preview_win_id)
	assert(vim.bo[prev_buf].filetype == "", "Preview buffer filetype must remain blank in zero-treesitter mode")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
	assert(#vim.api.nvim_list_wins() == 1, "Windows should close on <Esc>")
	print("✓ Test 9 passed!")

	print("Running Test 10: Configurable 'q' Window Dismissal...")
	-- When close_on_q = false: 'q' should NOT close window
	M_reloaded.config.close_on_q = false
	M_reloaded.open_history_window()
	assert(#vim.api.nvim_list_wins() >= 2)
	vim.api.nvim_feedkeys("q", "xt", false)
	assert(#vim.api.nvim_list_wins() >= 2, "Window must stay open when close_on_q = false")
	-- <Esc> must still close window
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
	assert(#vim.api.nvim_list_wins() == 1, "Window must close on <Esc>")

	-- When close_on_q = true: 'q' SHOULD close window
	M_reloaded.config.close_on_q = true
	M_reloaded.open_history_window()
	assert(#vim.api.nvim_list_wins() >= 2)
	vim.api.nvim_feedkeys("q", "xt", false)
	assert(#vim.api.nvim_list_wins() == 1, "Window must close on 'q' when close_on_q = true")
	print("✓ Test 10 passed!")

	print("=========================================")
	print("🎉 ALL 10 TEST SUITES COMPLETED SUCCESSFULLY!")
	print("=========================================")
end

run_tests()
