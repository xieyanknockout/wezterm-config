local wezterm = require('wezterm')

local M = {}

local function get_process_name(s)
   local a = string.gsub(s, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

local function get_short_cwd(pane)
   local cwd = pane.current_working_dir
   if not cwd then return '' end
   cwd = tostring(cwd)
   local home = os.getenv('HOME') or os.getenv('USERPROFILE')
   if home and cwd:find(home, 1, true) == 1 then
      cwd = '~' .. cwd:sub(#home + 1)
   end
   local parts = {}
   for part in cwd:gmatch('[/\\]+([^/\\]+)') do
      table.insert(parts, part)
   end
   if #parts > 2 then
      return '…/' .. parts[#parts - 1] .. '/' .. parts[#parts]
   elseif #parts > 0 then
      return table.concat(parts, '/')
   end
   return cwd
end

local function used_width(cells)
   local w = 0
   for _, c in ipairs(cells) do
      if c.Text then w = w + #c.Text end
   end
   return w
end

local function trunc(text, max)
   if max <= 0 then return '' end
   if #text <= max then return text end
   if max <= 1 then return '…' end
   return text:sub(1, max - 1) .. '…'
end

local function push(cells, bg, fg, text, intensity)
   table.insert(cells, { Background = { Color = bg } })
   table.insert(cells, { Foreground = { Color = fg } })
   table.insert(cells, { Attribute = { Intensity = intensity or 'Normal' } })
   table.insert(cells, { Text = text })
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
      local bar_bg = '#2A2A2A'

      local bg, fg
      if tab.is_active then
         bg = '#FBB829'; fg = '#000000'
      elseif hover then
         bg = '#FF8700'; fg = '#000000'
      else
         bg = '#3A3A3A'; fg = '#AAAAAA'
      end

      local process_name = get_process_name(tab.active_pane.foreground_process_name)
      local short_cwd = get_short_cwd(tab.active_pane)
      local tab_index = tab.tab_index
      local pane_count = #tab.panes
      local nf = wezterm.nerdfonts

      local has_unseen_output = false
      for _, p in ipairs(tab.panes) do
         if p.has_unseen_output then has_unseen_output = true; break end
      end

      -- 预算：max_width 减去左右分隔符(2) + 左右padding(2) = 4
      -- 再减去活动 tab 的固定附加元素
      local fixed_overhead = 4  -- 分隔符 + padding
      if pane_count > 1 then fixed_overhead = fixed_overhead + 3 end  -- ' ▶2'
      if has_unseen_output then fixed_overhead = fixed_overhead + 2 end  -- ' ●'
      if tab.is_active then fixed_overhead = fixed_overhead + 7 end  -- ' 🕐HH:MM'

      local budget = max_width - fixed_overhead
      if budget < 8 then budget = 8 end

      local cells = {}

      -- 左分隔符：bar_bg 底 + tab色三角
      table.insert(cells, { Background = { Color = bar_bg } })
      table.insert(cells, { Foreground = { Color = bg } })
      table.insert(cells, { Text = nf.pl_right_hard_divider })

      -- 左padding
      push(cells, bg, fg, ' ')

      -- 索引
      local idx = tostring(tab_index) .. ' '
      push(cells, bg, tab.is_active and '#000000' or '#888888', idx, 'Bold')

      -- 进程名
      local proc_text = ''
      if process_name ~= '' then
         proc_text = trunc(process_name, 12) .. ' '
      end

      -- cwd
      local cwd_text = ''
      if short_cwd ~= '' then
         local used = #idx + #proc_text + 1  -- +1 left padding
         local remain = budget - used
         if remain > 3 then
            cwd_text = trunc(short_cwd, remain)
         end
      end

      push(cells, bg, fg, proc_text .. cwd_text)

      -- pane 数量
      if pane_count > 1 then
         local icon = nf.md_split_horizontal or '|'
         push(cells, bg, '#E67700', ' ' .. icon .. pane_count, 'Bold')
      end

      -- 活动标签：时间
      if tab.is_active then
         local time_str = wezterm.strftime('%H:%M')
         push(cells, bg, '#1C7A0E', ' ' .. nf.md_clock .. time_str, 'Bold')
      end

      -- 未读输出
      if has_unseen_output then
         push(cells, bg, '#E03131', ' ●', 'Bold')
      end

      -- 右padding
      push(cells, bg, fg, ' ')

      -- 右分隔符：bar_bg 底 + tab色三角
      table.insert(cells, { Background = { Color = bar_bg } })
      table.insert(cells, { Foreground = { Color = bg } })
      table.insert(cells, { Text = nf.pl_left_hard_divider })

      return cells
   end)
end

return M
