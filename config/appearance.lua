local wezterm = require('wezterm')
local gpu_adapters = require('utils.gpu_adapter')
-- local colors = require('colors.custom')
local scheme = wezterm.get_builtin_color_schemes()['Monokai Soda']

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
   tab_max_width = 120, -- 限制最大宽度，保持美观
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
   window_padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
   },
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      -- font = fonts.font,
      -- font_size = fonts.font_size,
   },
   inactive_pane_hsb = {
      saturation = 0.9,
      brightness = 0.65,
   },
}
