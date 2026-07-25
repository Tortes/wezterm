local wezterm = require('wezterm')

local GLYPH_CIRCLE = '' -- nf.fa_circle
local GLYPH_ADMIN = '󰞀' -- nf.md_shield_half_full
local TAB_WIDTH = 28
local TAB_BAR_BG = '#232a2e'

local M = {}
local __cells__ = {}
local colors = {
   default = { bg = '#343f44', fg = '#859289', border = '#56635f', },
   is_active = { bg = '#a7c080', fg = '#2d353b', border = '#dbbc7f', },
   hover = { bg = '#4f585e', fg = '#d3c6aa', border = '#83c092', },
   unseen = '#dbbc7f',
}

local _set_process_name = function(s)
   local a = string.gsub(s, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

local _set_title = function(tab)
   if tab.tab_title and #tab.tab_title > 0 then
      return tab.tab_title
   end

   local process_name = _set_process_name(tab.active_pane.foreground_process_name)
   if process_name:len() > 0 then
      return process_name .. ' ~ ' .. tab.active_pane.title
   end

   return tab.active_pane.title
end

local _check_if_admin = function(p)
   if p:match('^Administrator: ') then
      return true
   end
   return false
end

local _has_unseen_output = function(tab)
   for _, pane in ipairs(tab.panes) do
      if pane.has_unseen_output then
         return true
      end
   end
   return false
end

---@param fg string
---@param bg string
---@param attribute table
---@param text string
local _push = function(bg, fg, attribute, text)
   table.insert(__cells__, { Background = { Color = bg } })
   table.insert(__cells__, { Foreground = { Color = fg } })
   table.insert(__cells__, { Attribute = attribute })
   table.insert(__cells__, { Text = text })
end

local _format_content = function(tab, title, is_admin, has_unseen_output, width)
   local prefix = string.format(' %d ', tab.tab_index + 1)
   if is_admin then
      prefix = prefix .. GLYPH_ADMIN .. ' '
   end

   local suffix = has_unseen_output and (' ' .. GLYPH_CIRCLE) or ''
   local title_width = math.max(
      0,
      width - wezterm.column_width(prefix) - wezterm.column_width(suffix)
   )
   local content = prefix .. wezterm.truncate_right(title, title_width) .. suffix

   return wezterm.pad_right(wezterm.truncate_right(content, width), width)
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      __cells__ = {}

      local tab_width = math.min(TAB_WIDTH, max_width)
      if tab_width < 3 then
         return wezterm.truncate_right(tostring(tab.tab_index + 1), max_width)
      end

      local style
      if tab.is_active then
         style = colors.is_active
      elseif hover then
         style = colors.hover
      else
         style = colors.default
      end

      local title = _set_title(tab)
      local is_admin = _check_if_admin(tab.active_pane.title)
      local has_unseen_output = _has_unseen_output(tab)
      local content_width = tab_width - 2
      local content = _format_content(
         tab,
         title,
         is_admin,
         has_unseen_output,
         content_width
      )

      -- A colored left status rail and a right divider make each fixed-width
      -- tab visually distinct without consuming space with rounded caps.
      _push(TAB_BAR_BG, style.border, { Intensity = 'Bold' }, tab.is_active and '▌' or '▏')
      _push(style.bg, style.fg, { Intensity = 'Bold' }, content)
      _push(TAB_BAR_BG, style.border, { Intensity = 'Bold' }, '│')

      return __cells__
   end)
end

return M
