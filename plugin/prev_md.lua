if vim.g.loaded_prev_md then return end
vim.g.loaded_prev_md = true

local preview = require('prev_md.preview')
local watcher = require('prev_md.watcher')

vim.api.nvim_create_user_command('PrevMd', function()
  if preview.is_open() then
    watcher.stop()
    preview.close()
  else
    preview.open()
    local source_bufnr = preview.get_state().source_bufnr
    if source_bufnr then
      watcher.start(source_bufnr)
      -- also stop watcher when the user manually closes the preview window
      preview.on_close(function()
        watcher.stop()
      end)
    end
  end
end, { desc = 'Toggle Markdown preview' })
