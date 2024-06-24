local wezterm = require('wezterm')

local M = {}

M.setup = function()
   wezterm.time.call_after(60, function()
      wezterm.reload_configuration()
    end)
end

return M
