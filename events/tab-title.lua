local wezterm = require('wezterm')

local M = {}

-- 获取进程名
local function get_process_name(s)
   local a = string.gsub(s, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

-- 获取简短的当前目录
local function get_short_cwd(pane)
   local cwd = pane.current_working_dir
   if not cwd then
      return ''
   end

   -- 修复：转换为字符串，因为 cwd 可能是 WezTerm 的特殊路径对象
   cwd = tostring(cwd)

   -- 替换 HOME 为 ~
   local home = os.getenv('HOME') or os.getenv('USERPROFILE')
   if home and cwd:find(home, 1, true) == 1 then
      cwd = '~' .. cwd:sub(#home + 1)
   end

   -- 只取最后两个目录
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

M.setup = function()
   wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
      local cells = {}

      -- 确定背景色和前景色
      local bg, fg
      if tab.is_active then
         bg = '#FBB829'  -- 活动标签黄色背景
         fg = '#000000'  -- 纯黑前景，增强对比度
      elseif hover then
         bg = '#FF8700'  -- 悬停橙色背景
         fg = '#000000'
      else
         bg = '#3A3A3A'  -- 非活动标签更深的灰色，降低视觉干扰
         fg = '#AAAAAA'  -- 浅灰文字，让活动标签更突出
      end

      -- 获取信息
      local process_name = get_process_name(tab.active_pane.foreground_process_name)
      local short_cwd = get_short_cwd(tab.active_pane)
      local tab_index = tab.tab_index

      -- 检查未读输出
      local has_unseen_output = false
      for _, pane in ipairs(tab.panes) do
         if pane.has_unseen_output then
            has_unseen_output = true
            break
         end
      end

      -- Pane 数量
      local pane_count = #tab.panes
      local nf = wezterm.nerdfonts

      -- 开始构建标签
      -- 左边距
      table.insert(cells, { Background = { Color = bg } })
      table.insert(cells, { Foreground = { Color = fg } })
      table.insert(cells, { Text = ' ' })

      -- 索引号（加粗显示，使用深色提高可读性）
      table.insert(cells, { Background = { Color = bg } })
      table.insert(cells, { Foreground = { Color = tab.is_active and '#000000' or '#888888' } })
      table.insert(cells, { Attribute = { Intensity = 'Bold' } })
      table.insert(cells, { Text = tostring(tab_index) .. ' ' })

      -- 进程名称
      if process_name and process_name ~= '' then
         table.insert(cells, { Background = { Color = bg } })
         table.insert(cells, { Foreground = { Color = fg } })
         table.insert(cells, { Attribute = { Intensity = 'Normal' } })
         table.insert(cells, { Text = process_name })
      end

      -- Pane 数量
      if pane_count > 1 then
         table.insert(cells, { Background = { Color = bg } })
         table.insert(cells, { Foreground = { Color = '#E67700' } })
         table.insert(cells, { Attribute = { Intensity = 'Bold' } })
         table.insert(cells, { Text = ' ' .. nf.md_split_horizontal .. pane_count })
      end

      -- 工作目录（非活动标签降低透明度）
      if short_cwd and short_cwd ~= '' then
         table.insert(cells, { Background = { Color = bg } })
         -- 非活动标签使用更低的透明度
         local cwd_color = tab.is_active and (fg .. '88') or (fg .. '44')
         table.insert(cells, { Foreground = { Color = cwd_color } })
         table.insert(cells, { Attribute = { Intensity = 'Normal' } })
         table.insert(cells, { Text = ' │ ' .. short_cwd })
      end

      -- 时间（仅活动标签）
      if tab.is_active then
         local time_str = wezterm.strftime('%H:%M')
         table.insert(cells, { Background = { Color = bg } })
         table.insert(cells, { Foreground = { Color = '#1C7A0E' } })  -- 更深的绿色
         table.insert(cells, { Attribute = { Intensity = 'Bold' } })
         table.insert(cells, { Text = ' ' .. nf.md_clock .. time_str })
      end

      -- 未读输出指示
      if has_unseen_output then
         table.insert(cells, { Background = { Color = bg } })
         table.insert(cells, { Foreground = { Color = '#E03131' } })
         table.insert(cells, { Attribute = { Intensity = 'Bold' } })
         table.insert(cells, { Text = ' ●' })
      end

      -- 右边距
      table.insert(cells, { Background = { Color = bg } })
      table.insert(cells, { Foreground = { Color = fg } })
      table.insert(cells, { Text = ' ' })

      return cells
   end)
end

return M
