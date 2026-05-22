local wezterm = require('wezterm')
local platform = require('utils.platform')
local font_size_config = require('config.font_size')

-- 字体列表（优先级从高到低）
-- 如遇 Google Sans Code 加载警告：其 Variable 版支持 Proportional/Monospaced 双模式，
-- WezTerm 可能误选 Proportional 版本。安装 Static 版可解决，从 googlefonts/googlesans-code 下载 v6.000+。
-- 关联: wezterm#3639 #3944 #3931
local fonts = { -- 主字体
{
    family = 'Google Sans Code',
    weight = 300,
}, {
    family = 'LXGW WenKai Mono GB Screen',
    weight = 'Regular',
}, {
    family = 'Maple Mono NF CN',
    weight = 'ExtraLight'
}, 'MesloLGM Nerd Font', 'JetBrainsMono Nerd Font', -- 跨平台字体回退
{
    family = 'Cascadia Code',
    weight = 'Regular'
}, {
    family = 'Consolas',
    weight = 'Regular'
}, -- Windows
{
    family = 'SF Mono',
    weight = 'Regular'
}, -- macOS
-- 符号和 Emoji
'Nerd Font Symbols', 'Noto Color Emoji', 'Segoe UI Emoji', -- Windows
'Apple Color Emoji' -- macOS
}

-- 使用统一的字体大小配置
local font_size = font_size_config.base_font_size

-- 平台特定调整
if platform().is_mac then
    font_size = font_size - 1 -- macOS 字体渲染通常较大
end

return {
    font = wezterm.font_with_fallback(fonts),
    font_size = font_size,

    -- 禁用连字渲染以提升性能
    harfbuzz_features = {'calt=0', 'clig=0', 'liga=0'},

    -- 当改变字体大小时调整窗口大小以保持行列数
    adjust_window_size_when_changing_font_size = true,

    -- ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
    freetype_load_target = 'Light', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'Light' ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
