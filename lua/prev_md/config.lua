local M = {}

M.defaults = {
	renderer = "glow", -- 'glow' | 'mdcat' | 'bat'
	window = "split", -- currently 'split' only
	split_width = 80,
	auto_update = true,
	debounce_ms = 300,
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- Initialize with defaults
M.options = vim.deepcopy(M.defaults)

return M
