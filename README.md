# prev-md.nvim

Realtime Markdown preview for Neovim, powered by [glow](https://github.com/charmbracelet/glow).

![](https://github.com/user-attachments/assets/77c83c8e-030c-4458-9e1b-7d330a5d6323)

## Features

- Renders Markdown in a vertical split using glow (or mdcat / bat)
- Auto-updates as you type with a debounce
- Keeps the source window focused while preview stays open
- Cleans up gracefully when the preview window is closed

## Requirements

- Neovim >= 0.9
- One of the following renderers:
  - [glow](https://github.com/charmbracelet/glow) (recommended)
  - [mdcat](https://github.com/swsnr/mdcat)
  - [bat](https://github.com/sharkdp/bat)

## Installation

### lazy.nvim

```lua
{
  'kaitoimai/prev-md.nvim',
  ft = 'markdown',
  keys = {
    { '<leader>mp', '<cmd>PrevMd<cr>', desc = 'Markdown Preview' },
  },
  opts = {},
}
```

### With full options

```lua
{
  'kaitoimai/prev-md.nvim',
  ft = 'markdown',
  keys = {
    { '<leader>mp', '<cmd>PrevMd<cr>', desc = 'Markdown Preview' },
  },
  opts = {
    renderer    = 'glow',  -- 'glow' | 'mdcat' | 'bat'
    split_width = 80,
    auto_update = true,
    debounce_ms = 300,
  },
}
```

## Usage

| Action | Command / Key |
|--------|---------------|
| Toggle preview | `:PrevMd` |
| Toggle preview (keymap) | `<leader>mp` |

`:PrevMd` opens a vertical split on the first call and closes it on the second.

The preview updates from buffer changes while you edit. Saving does not trigger an extra redraw if the preview is already up to date.

## Configuration

All options and their defaults:

```lua
require('prev_md').setup({
  renderer    = 'glow', -- renderer backend; falls back to the first available one
  split_width = 80,     -- width of the preview split in columns
  auto_update = true,   -- refresh the preview automatically while editing
  debounce_ms = 300,    -- ms to wait after the last buffer change before re-rendering
})
```

## License

MIT
