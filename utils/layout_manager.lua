local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function get_layout_dir()
   return wezterm.config_dir .. '/layouts'
end

local function ensure_layout_dir()
   local dir = get_layout_dir()
   wezterm.mkdir(dir)
   return dir
end

local function extract_cwd(pane)
   local cwd = pane:get_current_working_dir()
   if not cwd then
      return nil
   end
   -- cwd 是 Url userdata，用 file_path 字段获取解码后的路径
   -- Windows 上 file_path 返回 "/C:/Users/..." 格式
   local path = cwd.file_path
   if not path then
      return nil
   end
   path = tostring(path)
   -- Windows 上 file_path 返回 "/C:/Users/..." 格式，去掉开头斜杠
   if wezterm.target_triple:find('windows') and path:match('^/[A-Za-z]:') then
      path = path:sub(2)
   end
   return path
end

---------------------------------------------------------------------------
-- save
---------------------------------------------------------------------------

local function capture_current_layout(window)
   local tab = window:active_tab()
   if not tab then
      return nil, '无法获取当前 tab'
   end

   local panes_info = tab:panes_with_info()
   if not panes_info or #panes_info == 0 then
      return nil, '没有找到任何 pane'
   end

   -- 获取 tab 总尺寸，用于将单元格坐标转为比例
   local tab_size = tab:get_size()
   local total_cols = tab_size.cols
   local total_rows = tab_size.rows

   local layout = {
      name = '',
      saved_at = os.time(),
      panes = {},
   }

   for i, info in ipairs(panes_info) do
      local cwd = extract_cwd(info.pane)
      table.insert(layout.panes, {
         left = info.left / total_cols,
         top = info.top / total_rows,
         width = info.width / total_cols,
         height = info.height / total_rows,
         cwd = cwd or '',
      })
   end

   return layout
end

function M.save_layout(window, name)
   if not name or name == '' then
      return false, '没有指定布局名称'
   end

   local layout, err = capture_current_layout(window)
   if not layout then
      return false, 'capture 失败: ' .. tostring(err)
   end

   layout.name = name

   local layout_dir = ensure_layout_dir()
   local layout_file = layout_dir .. '/' .. name .. '.json'

   local file = io.open(layout_file, 'w')
   if not file then
      return false, '无法打开文件: ' .. layout_file
   end

   local ok, json_str = pcall(wezterm.json_encode, layout)
   if not ok then
      file:close()
      return false, 'JSON 编码失败: ' .. tostring(json_str)
   end

   local _, write_err = file:write(json_str)
   file:close()
   if write_err then
      return false, '写入失败: ' .. tostring(write_err)
   end

   wezterm.log_info('布局已保存: ' .. name .. ' (' .. #layout.panes .. ' 个 panes)')
   return true, '布局已保存: ' .. name
end

---------------------------------------------------------------------------
-- list / load
---------------------------------------------------------------------------

function M.list_layouts()
   local layout_dir = get_layout_dir()

   local ok, entries = pcall(wezterm.read_dir, layout_dir)
   if not ok or not entries then
      return {}
   end

   local layouts = {}
   for _, entry in ipairs(entries) do
      if entry:match('%.json$') then
         -- read_dir 返回完整路径，需提取文件名
         local filename = entry:match('([^/\\]+)%.json$')
         table.insert(layouts, {
            label = filename,
            name = filename,
         })
      end
   end

   return layouts
end

function M.load_layout(name)
   if not name or name == '' then
      return nil, '没有指定布局名称'
   end

   local layout_dir = get_layout_dir()
   local layout_file = layout_dir .. '/' .. name .. '.json'

   local file = io.open(layout_file, 'r')
   if not file then
      return nil, '文件无法打开: ' .. layout_file
   end

   local json_str = file:read('*all')
   file:close()

   if not json_str or json_str == '' then
      return nil, '文件为空: ' .. layout_file
   end

   local ok, layout = pcall(wezterm.json_parse, json_str)
   if not ok then
      return nil, 'JSON 解析失败: ' .. tostring(layout)
   end
   if not layout then
      return nil, 'JSON 解析结果为 nil'
   end

   return layout
end

---------------------------------------------------------------------------
-- tree inference: 从 pane 位置/尺寸推断二叉分割树
---------------------------------------------------------------------------

-- 按 pane 在某轴上的位置分组，验证是否可以干净地沿该轴分割
-- key: 'left'(水平分割) 或 'top'(垂直分割)
-- size_key: 'width' 或 'height'
-- 返回排序后的分组列表，或 nil（不可分割）
local function group_by_axis(panes, indices, key, size_key)
   local groups = {}
   for _, idx in ipairs(indices) do
      local pos = panes[idx][key]
      local matched = false
      for _, g in ipairs(groups) do
         if math.abs(g.pos - pos) < 0.03 then
            table.insert(g.indices, idx)
            matched = true
            break
         end
      end
      if not matched then
         table.insert(groups, { pos = pos, indices = { idx } })
      end
   end
   table.sort(groups, function(a, b) return a.pos < b.pos end)

   if #groups < 2 then return nil end

   -- 验证：每组内 pane 的位置和尺寸一致
   for _, g in ipairs(groups) do
      local ref_pos = panes[g.indices[1]][key]
      local ref_size = panes[g.indices[1]][size_key]
      for _, idx in ipairs(g.indices) do
         if math.abs(panes[idx][key] - ref_pos) > 0.03
            or math.abs(panes[idx][size_key] - ref_size) > 0.03
         then
            return nil
         end
      end
   end

   -- 验证连续性：组之间无间隙
   for i = 2, #groups do
      local prev_right = groups[i - 1].pos + panes[groups[i - 1].indices[1]][size_key]
      if math.abs(groups[i].pos - prev_right) > 0.03 then
         return nil
      end
   end

   return groups
end

-- 递归构建分割树
-- panes: 数组，每个元素含 left/top/width/height
-- indices: 当前子集的 pane 索引列表
local function build_tree(panes, indices)
   if #indices <= 1 then
      return { type = 'leaf', pane_index = indices[1] }
   end

   -- --- 尝试水平分割（按 left 分组 → 左右分割） ---
   local h_groups = group_by_axis(panes, indices, 'left', 'width')
   if h_groups then
      local first_group = h_groups[1]
      local last_group = h_groups[#h_groups]
      local left_boundary = first_group.pos + panes[first_group.indices[1]].width
      local right_boundary = last_group.pos + panes[last_group.indices[1]].width
      local total_width = right_boundary - first_group.pos
      local ratio = (left_boundary - first_group.pos) / total_width

      if ratio > 0.05 and ratio < 0.95 then
         local left_indices = first_group.indices
         local right_indices = {}
         for i = 2, #h_groups do
            for _, idx in ipairs(h_groups[i].indices) do
               table.insert(right_indices, idx)
            end
         end
         return {
            type = 'split',
            direction = 'horizontal',
            left_size = ratio,
            left = build_tree(panes, left_indices),
            right = build_tree(panes, right_indices),
         }
      end
   end

   -- --- 尝试垂直分割（按 top 分组 → 上下分割） ---
   local v_groups = group_by_axis(panes, indices, 'top', 'height')
   if v_groups then
      local first_group = v_groups[1]
      local last_group = v_groups[#v_groups]
      local top_boundary = first_group.pos + panes[first_group.indices[1]].height
      local bottom_boundary = last_group.pos + panes[last_group.indices[1]].height
      local total_height = bottom_boundary - first_group.pos
      local ratio = (top_boundary - first_group.pos) / total_height

      if ratio > 0.05 and ratio < 0.95 then
         local top_indices = first_group.indices
         local bottom_indices = {}
         for i = 2, #v_groups do
            for _, idx in ipairs(v_groups[i].indices) do
               table.insert(bottom_indices, idx)
            end
         end
         return {
            type = 'split',
            direction = 'vertical',
            left_size = ratio,
            left = build_tree(panes, top_indices),
            right = build_tree(panes, bottom_indices),
         }
      end
   end

   -- --- 回退：均分水平分割 ---
   local mid = math.ceil(#indices / 2)
   local left_indices = {}
   local right_indices = {}
   for i = 1, mid do table.insert(left_indices, indices[i]) end
   for i = mid + 1, #indices do table.insert(right_indices, indices[i]) end
   return {
      type = 'split',
      direction = 'horizontal',
      left_size = 0.5,
      left = build_tree(panes, left_indices),
      right = build_tree(panes, right_indices),
   }
end

---------------------------------------------------------------------------
-- restore: 在新 tab 中重建布局
---------------------------------------------------------------------------

function M.restore_layout(window, layout_data)
   if not layout_data or not layout_data.panes or #layout_data.panes == 0 then
      wezterm.log_error('布局数据无效')
      return false
   end

   local panes = layout_data.panes

   -- 向后兼容：旧格式没有位置信息，回退为等分水平布局
   local has_position = panes[1].left ~= nil
   local tree
   if has_position then
      local indices = {}
      for i = 1, #panes do table.insert(indices, i) end
      tree = build_tree(panes, indices)
   else
      -- 旧格式：所有 pane 等分宽度
      tree = { type = 'split', direction = 'horizontal', left_size = 1.0 }
      local n = #panes
      local current = tree
      for i = 1, n - 1 do
         local size = (n - i) / (n - i + 1)
         current.left_size = 1.0 - size
         current.left = { type = 'leaf', pane_index = i }
         if i < n - 1 then
            current.right = { type = 'split', direction = 'horizontal' }
            current = current.right
         else
            current.right = { type = 'leaf', pane_index = n }
         end
      end
   end

   -- 创建新 tab
   local active_pane = window:active_pane()
   if not active_pane then
      wezterm.log_error('无法获取活跃 pane，取消布局恢复')
      return false
   end
   window:perform_action(act.SpawnTab('CurrentPaneDomain'), active_pane)
   local tab = window:active_tab()
   if not tab then
      wezterm.log_error('无法创建新 tab')
      return false
   end

   local pane_map = {}

   -- 递归重放分割树
   -- 使用 pane index 而非 pane 对象引用，因为 SplitPane 后原 pane 对象会失效
   local split_count = 0
   local function replay_node(node, pane_idx)
      if node.type == 'leaf' then
         pane_map[node.pane_index] = tab:panes()[pane_idx + 1]
         return
      end

      local direction = node.direction == 'horizontal' and 'Right' or 'Down'
      local new_pane_size = 1.0 - node.left_size
      local pct = math.floor(new_pane_size * 100 + 0.5)

      split_count = split_count + 1

      -- 先激活目标 pane，再拆分（SplitPane 总是作用于活跃 pane）
      local current_pane = tab:active_pane()
      if not current_pane then
         wezterm.log_error('[layout-restore] active_pane 为 nil，跳过 split #' .. split_count)
         return
      end
      window:perform_action(act.ActivatePaneByIndex(pane_idx), current_pane)

      current_pane = tab:active_pane()
      if not current_pane then
         wezterm.log_error('[layout-restore] ActivatePane 后 active_pane 为 nil，跳过 split #' .. split_count)
         return
      end
      window:perform_action(act.SplitPane({
         direction = direction,
         size = { Percent = pct },
      }), current_pane)

      local new_pane = tab:active_pane()
      if not new_pane then
         wezterm.log_error('[layout-restore] SplitPane 后 active_pane 为 nil，跳过后续恢复')
         return
      end
      local new_pane_id = new_pane:pane_id()

      -- 先处理左子树（原 pane 保留在 pane_idx，不受后续 split 影响）
      replay_node(node.left, pane_idx)

      -- 左子树处理完后重新查找右 pane 的 index
      -- （左子树的 split 会插入新 pane，导致之前的 index 偏移）
      local all_panes = tab:panes()
      local new_pane_idx = nil
      for i, p in ipairs(all_panes) do
         if p:pane_id() == new_pane_id then
            new_pane_idx = i - 1
            break
         end
      end

      if new_pane_idx then
         replay_node(node.right, new_pane_idx)
      end
   end

   replay_node(tree, 0)

   -- 根 pane 无法通过 SplitPane 设置 cwd，用 send_text 兜底
   local root_idx = pane_map[1] and 1 or nil
   if root_idx then
      local cwd = panes[root_idx].cwd
      if cwd and cwd ~= '' then
         pane_map[root_idx]:send_text('cd "' .. cwd .. '"\r')
      end
   end

   wezterm.log_info(
      string.format('布局 "%s" 已恢复 (%d 个 panes)', layout_data.name, #panes)
   )
   return true
end

return M
