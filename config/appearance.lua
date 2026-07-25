local wezterm = require('wezterm')
local colors = require('colors.custom')
local fonts = require('config.fonts')

return {
   term = "xterm-256color",
   animation_fps = 60,
   max_fps = 60,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',

   -- color scheme
   -- colors = colors,
   -- color_scheme = "Gruvbox dark, medium (base16)",
   -- color_scheme = "Everforest Lioght",
   color_scheme = 'Everforest Dark (Gogh)',

   -- background
   window_background_opacity = 0.85,
   win32_system_backdrop = 'Acrylic',
   window_background_gradient = {
      colors = { '#2d353b', '#232a2e' },
      -- Specifices a Linear gradient starting in the top left corner.
      orientation = { Linear = { angle = -45.0 } },
   },
   -- background = {
   --    {
   --       source = { File = wezterm.config_dir .. '/backdrops/space.jpg' },
   --    },
   --    {
   --       source = { Color = '#1A1B26' },
   --       height = '100%',
   --       width = '100%',
   --       opacity = 0.95,
   --    },
   -- },

   -- scrollbar and tab bar
   enable_scroll_bar = true,
   min_scroll_bar_height = "3cell",
   colors = {
      scrollbar_thumb = '#4f585e',
      tab_bar = {
         background = '#232a2e',
         active_tab = {
            bg_color = '#a7c080',
            fg_color = '#2d353b',
            intensity = 'Bold',
         },
         inactive_tab = {
            bg_color = '#343f44',
            fg_color = '#859289',
         },
         inactive_tab_hover = {
            bg_color = '#4f585e',
            fg_color = '#d3c6aa',
            intensity = 'Bold',
         },
         new_tab = {
            bg_color = '#232a2e',
            fg_color = '#859289',
         },
         new_tab_hover = {
            bg_color = '#343f44',
            fg_color = '#d3c6aa',
            intensity = 'Bold',
         },
      },
   },

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = false,
   use_fancy_tab_bar = false,
   tab_max_width = 32,
   show_tab_index_in_tab_bar = true,
   switch_to_last_active_tab_when_closing_tab = true,

   -- cursor
   default_cursor_style = "BlinkingBlock",
   cursor_blink_ease_in = "Constant",
   cursor_blink_ease_out = "Constant",
   cursor_blink_rate = 700,

   -- window
   adjust_window_size_when_changing_font_size = false,
   window_decorations = "INTEGRATED_BUTTONS|RESIZE",
   integrated_title_button_style = "Windows",
   integrated_title_button_color = '#d3c6aa',
   integrated_title_button_alignment = "Right",
   integrated_title_buttons = { 'Hide', 'Maximize', 'Close' },
   initial_cols = 150,
   initial_rows = 40,
   window_padding = {
      left = 10,
      right = 10,
      top = 12,
      bottom = 7,
   },
   window_close_confirmation = 'AlwaysPrompt',
   window_frame = {
      active_titlebar_bg = '#232a2e',
      inactive_titlebar_bg = '#1e2326',
      font = fonts.font,
      font_size = 14,
   },
   inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 },
}
