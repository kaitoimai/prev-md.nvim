local M = {}

local config = require("prev_md.config")
local renderer = require("prev_md.renderer")

local state = {
	preview_bufnr = nil,
	preview_winid = nil,
	term_chan = nil,
	source_bufnr = nil,
	source_winid = nil,
	tmpfile = nil,
	renderer_name = nil,
	last_render_tick = nil,
}

local close_cb = nil

function M.on_close(cb)
	close_cb = cb
end

-- Delete old tmpfile and write current buffer contents to a new one
local function write_tmpfile(bufnr)
	if state.tmpfile then vim.fn.delete(state.tmpfile) end
	state.tmpfile = vim.fn.tempname() .. ".md"
	vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), state.tmpfile)
end

local function resolve_renderer()
	local name = config.options.renderer
	if renderer.is_available(name) then return name end
	local fallback = renderer.find_available()
	if fallback then
		vim.notify(("prev-md: %s not found, using %s"):format(name, fallback), vim.log.levels.WARN)
		return fallback
	end
	vim.notify("prev-md: no renderer found. Install glow, mdcat, or bat.", vim.log.levels.ERROR)
	return nil
end

local function get_render_width()
	if M.is_open() then
		return math.max(vim.api.nvim_win_get_width(state.preview_winid), 20)
	end
	return math.max(config.options.split_width, 20)
end

local function cleanup()
	if state.term_chan then pcall(vim.fn.jobstop, state.term_chan) end
	if state.tmpfile then vim.fn.delete(state.tmpfile) end
	state.preview_bufnr = nil
	state.preview_winid = nil
	state.term_chan = nil
	state.source_bufnr = nil
	state.source_winid = nil
	state.tmpfile = nil
	state.renderer_name = nil
	state.last_render_tick = nil
	if close_cb then
		close_cb()
		close_cb = nil
	end
end

local function restore_source_window(fallback_winid)
	local winid = fallback_winid
	if not (winid and vim.api.nvim_win_is_valid(winid)) then
		winid = state.source_winid
	end
	if winid and vim.api.nvim_win_is_valid(winid) then
		vim.api.nvim_set_current_win(winid)
	end
end

local function configure_preview_window(winid)
	vim.api.nvim_win_set_width(winid, config.options.split_width)
	vim.wo[winid].number = false
	vim.wo[winid].relativenumber = false
	vim.wo[winid].signcolumn = "no"
	vim.wo[winid].statuscolumn = ""
	vim.wo[winid].wrap = false
end

local function render(renderer_name, tmpfile)
	if not M.is_open() then return end

	local previous_bufnr = state.preview_bufnr
	local previous_chan = state.term_chan
	local cmd = renderer.get_cmd(renderer_name, tmpfile, get_render_width())
	local shell_cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ") .. " ; exec cat"
	local current_win = vim.api.nvim_get_current_win()

	vim.api.nvim_set_current_win(state.preview_winid)
	vim.cmd("enew")

	local preview_bufnr = vim.api.nvim_get_current_buf()
	state.preview_bufnr = preview_bufnr
	state.term_chan = nil

	configure_preview_window(state.preview_winid)
	vim.bo[preview_bufnr].bufhidden = "wipe"
	vim.bo[preview_bufnr].buflisted = false
	vim.bo[preview_bufnr].swapfile = false
	pcall(vim.api.nvim_buf_set_name, preview_bufnr, "prev-md://preview")

	state.term_chan = vim.fn.termopen({ "/bin/sh", "-c", shell_cmd }, {
		env = renderer.get_env(renderer_name),
	})
	-- termopen renames the buffer; restore our name
	pcall(vim.api.nvim_buf_set_name, preview_bufnr, "prev-md://preview")

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = preview_bufnr,
		once = true,
		callback = function(args)
			if args.buf == state.preview_bufnr then cleanup() end
		end,
	})

	restore_source_window(current_win)

	if previous_chan then pcall(vim.fn.jobstop, previous_chan) end
	if previous_bufnr and previous_bufnr ~= preview_bufnr and vim.api.nvim_buf_is_valid(previous_bufnr) then
		pcall(vim.api.nvim_buf_delete, previous_bufnr, { force = true })
	end

	if state.source_bufnr and vim.api.nvim_buf_is_valid(state.source_bufnr) then
		state.last_render_tick = vim.api.nvim_buf_get_changedtick(state.source_bufnr)
	end
end

function M.is_open()
	return state.preview_winid ~= nil and vim.api.nvim_win_is_valid(state.preview_winid)
end

function M.open()
	local renderer_name = resolve_renderer()
	if not renderer_name then return end

	state.source_bufnr = vim.api.nvim_get_current_buf()
	state.source_winid = vim.api.nvim_get_current_win()
	state.renderer_name = renderer_name

	write_tmpfile(state.source_bufnr)

	vim.cmd("vnew")
	state.preview_winid = vim.api.nvim_get_current_win()

	render(renderer_name, state.tmpfile)
	restore_source_window()
end

function M.refresh(opts)
	if not M.is_open() then return end
	if not (state.source_bufnr and vim.api.nvim_buf_is_valid(state.source_bufnr)) then return end

	local force = opts and opts.force
	if not force and state.last_render_tick == vim.api.nvim_buf_get_changedtick(state.source_bufnr) then
		return
	end

	local renderer_name = state.renderer_name or resolve_renderer()
	if not renderer_name then return end

	write_tmpfile(state.source_bufnr)
	render(renderer_name, state.tmpfile)
end

function M.close()
	if M.is_open() then
		vim.api.nvim_win_close(state.preview_winid, true)
	end
end

function M.toggle()
	if M.is_open() then M.close() else M.open() end
end

function M.get_state()
	return state
end

return M
