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
   color_scheme = 'Material (terminal.sexy)',
   -- color_scheme_dirs = { os.getenv("HOME") .. "\\.config\\wezterm\\colors" },
   -- colors = colors,
   colors = {
      tab_bar = {
         background = scheme.background,
         new_tab = {
            bg_color = scheme.background,
            fg_color = scheme.foreground,
            intensity = 'Bold',
         },
         new_tab_hover = {
            bg_color = scheme.ansi[1],
            fg_color = scheme.brights[8],
            intensity = 'Bold',
         },
         -- format-tab-title
         -- active_tab = { bg_color = "#121212", fg_color = "#FCE8C3" },
         -- inactive_tab = { bg_color = scheme.background, fg_color = "#FCE8C3" },
         -- inactive_tab_hover = { bg_color = scheme.ansi[1], fg_color = "#FCE8C3" },
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
   hide_tab_bar_if_only_one_tab = false,
   use_fancy_tab_bar = false,
   tab_max_width = 45,
   show_tab_index_in_tab_bar = false,
   switch_to_last_active_tab_when_closing_tab = true,

   -- window decoration
   window_decorations = 'INTEGRATED_BUTTONS|RESIZE',

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
