local M = {}

local config = require("prev_md.config")
local preview = require("prev_md.preview")

local timer = nil
local attach_generation = 0

local function stop_timer()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

local function schedule_refresh()
	local uv = vim.uv or vim.loop
	stop_timer()
	timer = uv.new_timer()
	timer:start(config.options.debounce_ms, 0, vim.schedule_wrap(function()
		timer = nil
		preview.refresh()
	end))
end

function M.start(bufnr)
	M.stop()
	if not config.options.auto_update then return end

	attach_generation = attach_generation + 1
	local generation = attach_generation

	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = function()
			if generation ~= attach_generation then return true end
			schedule_refresh()
		end,
	})
end

function M.stop()
	attach_generation = attach_generation + 1
	stop_timer()
end

return M
