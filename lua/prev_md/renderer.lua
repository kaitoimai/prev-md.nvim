local M = {}

-- Each renderer returns a command table for jobstart/termopen
local backends = {
  glow  = function(file, width)
    return {
      'glow',
      '--style',
      vim.o.background,
      '--width',
      tostring(width),
      file,
    }
  end,
  mdcat = function(file)
    return { 'mdcat', file }
  end,
  bat   = function(file)
    return { 'bat', '--language=markdown', '--style=plain', '--color=always', '--paging=never', file }
  end,
}

function M.is_available(name)
  local cmds = { glow = 'glow', mdcat = 'mdcat', bat = 'bat' }
  local cmd = cmds[name]
  return cmd ~= nil and vim.fn.executable(cmd) == 1
end

function M.find_available()
  for _, name in ipairs({ 'glow', 'mdcat', 'bat' }) do
    if M.is_available(name) then
      return name
    end
  end
  return nil
end

function M.get_cmd(name, file, width)
  local backend = backends[name]
  if not backend then
    error('prev-md: unknown renderer: ' .. tostring(name))
  end
  return backend(file, width)
end

function M.get_env(name)
  if name == 'glow' then
    return {
      TERM = 'xterm-256color',
      COLORTERM = 'truecolor',
    }
  end

  return {
    COLORTERM = 'truecolor',
  }
end

return M
