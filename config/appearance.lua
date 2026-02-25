local wezterm = require('wezterm')
local gpu_adapters = require('utils.gpu_adapter')
local font_size_config = require('config.font_size')
-- local colors = require('colors.custom')
local scheme = wezterm.get_builtin_color_schemes()['Monokai Soda']

-- 使用统一的字体大小
local base_font_size = font_size_config.base_font_size
local titlebar_font_size = font_size_config.titlebar_font_size or base_font_size

-- 根据字体大小计算其他尺寸
local function calculate_tab_width(font_size)
   -- Tab 宽度约为字体大小的 15-18 倍
   return math.floor(font_size * 16)
end

local function calculate_padding(font_size)
   -- 内边距约为字体大小的 0.25 倍
   local padding = math.floor(font_size * 0.25)
   return {
      left = padding,
      right = padding,
      top = math.floor(padding * 0.5),
      bottom = math.floor(padding * 0.5),
   }
end

return {
   animation_fps = 60,
   max_fps = 60,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = gpu_adapters:pick_best(),

   -- color scheme
   color_scheme = 'MaterialDesignColors',
   -- color_scheme_dirs = { os.getenv("HOME") .. ',
   -- color_scheme_dirs = { os.getenv("HOME") .. "\\.config\\wezterm\\colors" },
   -- colors = colors,
   colors = {
      tab_bar = {
         background = '#2A2A2A', -- 深色背景，与非活动标签融合
         -- 新建标签按钮样式
         new_tab = {
            bg_color = scheme.ansi[2],
            fg_color = scheme.foreground,
            intensity = 'Bold',
         },
         new_tab_hover = {
            bg_color = '#FBB829',
            fg_color = '#000000',
            intensity = 'Bold',
         },
      },
   },

   -- background
   background = {
      {
         source = { File = wezterm.GLOBAL.background },
         horizontal_align = 'Center',
      },
      {
         source = { Color = scheme.background },
         height = '100%',
         width = '100%',
         opacity = 0.95,
      },
   },

   -- scrollbar
   enable_scroll_bar = true,

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = true, -- 单标签时隐藏，节省空间
   use_fancy_tab_bar = true, -- 自定义格式需要启用 fancy tab bar
   tab_max_width = calculate_tab_width(base_font_size), -- 根据字体大小自适应
   show_new_tab_button_in_tab_bar = true, -- 显示新建标签按钮
   -- show_tab_index_in_tab_bar 由自定义 tab-title 处理
   switch_to_last_active_tab_when_closing_tab = true,

   -- window decoration
   window_decorations = 'RESIZE',

   -- integrated buttons
   integrated_title_buttons = { 'Hide', 'Maximize' },
   integrated_title_button_color = 'rgba(0,0,0,0)',
   integrated_title_button_style = 'Windows',
   -- window
   window_padding = calculate_padding(base_font_size),
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      font = wezterm.font('Google Sans Code', { weight = 'Bold' }),
      font_size = titlebar_font_size,
   },
   inactive_pane_hsb = {
      saturation = 0.9,
      brightness = 0.65,
   },
}
