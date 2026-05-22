local wezterm = require('wezterm')
local gpu_adapters = require('utils.gpu_adapter')
local platform = require('utils.platform')
local font_size_config = require('config.font_size')
-- local colors = require('colors.custom')
local scheme = wezterm.get_builtin_color_schemes()['Monokai Soda']

-- 使用统一的字体大小
local base_font_size = font_size_config.base_font_size
local titlebar_font_size = font_size_config.titlebar_font_size or base_font_size

-- 根据字体大小计算其他尺寸
local function calculate_tab_width(font_size)
   -- Tab 宽度约为字体大小的 14-16 倍
   -- hover 时展开内容需要足够空间
   return math.floor(font_size * 15)
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

-- GPU 适配器：缓存到 GLOBAL 避免每次 reload 重复枚举和打日志
local picked_gpu = wezterm.GLOBAL.picked_gpu
if not picked_gpu then
   local preferred_backend = platform().is_win and 'Dx12' or 'Gl'
   picked_gpu = gpu_adapters:pick_manual(preferred_backend, 'DiscreteGpu')
   wezterm.GLOBAL.picked_gpu = picked_gpu
   if picked_gpu then
      wezterm.log_info('WezTerm GPU: ', picked_gpu.name, ' (', picked_gpu.device_type, ', ', picked_gpu.backend, ')')
   else
      wezterm.log_info('WezTerm GPU: Using default (no specific adapter selected)')
   end
end

return {
   animation_fps = 60,
   max_fps = 60,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = picked_gpu,

   -- color scheme
   color_scheme = 'MaterialDesignColors',
   -- color_scheme_dirs = { os.getenv("HOME") .. ',
   -- color_scheme_dirs = { os.getenv("HOME") .. "\\.config\\wezterm\\colors" },
   -- colors = colors,
   colors = {
      foreground = '#F0F0F0',
      tab_bar = {
         background = '#2A2A2A',
         active_tab = {
            bg_color = '#FBB829',
            fg_color = '#000000',
         },
         inactive_tab = {
            bg_color = '#3A3A3A',
            fg_color = '#AAAAAA',
         },
         inactive_tab_hover = {
            bg_color = '#FF8700',
            fg_color = '#000000',
         },
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
         opacity = 0.97,
      },
   },

   -- scrollbar
   enable_scroll_bar = true,

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = true,
   use_fancy_tab_bar = false, -- 非 fancy 模式：tab 渲染和点击热区完全一致
   tab_bar_at_bottom = false,
   tab_max_width = calculate_tab_width(base_font_size),
   show_new_tab_button_in_tab_bar = true,
   switch_to_last_active_tab_when_closing_tab = true,

   -- window decoration
   window_decorations = 'RESIZE',

   -- window
   window_padding = calculate_padding(base_font_size),
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      font = wezterm.font('Google Sans Code', { weight = 'Bold' }), -- 若遇 font 加载警告见 config/fonts.lua 顶部排查文档
      font_size = titlebar_font_size,
   },
   inactive_pane_hsb = {
      saturation = 0.5,  -- 更明显的去色效果（非激活 pane 变灰）
      brightness = 0.4,  -- 更明显的变暗效果（非激活 pane 变暗）
   },
}
