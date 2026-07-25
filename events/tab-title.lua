local wezterm = require('wezterm')

local GLYPH_CIRCLE = '' -- nf.fa_circle
local GLYPH_ADMIN = '󰞀' -- nf.md_shield_half_full
local TAB_WIDTH = 28
local TAB_GAP = 1
local TAB_BAR_BG = '#232a2e'
local FALLBACK_TITLE = 'WSL'

local HIDDEN_PROCESS_NAMES = {
   wslhost = true,
}

local M = {}
local colors = {
   default = { bg = '#343f44', fg = '#859289', intensity = 'Normal', },
   is_active = { bg = '#a7c080', fg = '#2d353b', intensity = 'Bold', },
   hover = { bg = '#4f585e', fg = '#d3c6aa', intensity = 'Bold', },
   unseen = '#dbbc7f',
}

local _safe_string = function(value)
   if value == nil then
      return ''
   end
   return tostring(value)
end

local _basename = function(path)
   return _safe_string(path):gsub('(.*[/\\])(.*)', '%2')
end

local _clean_process_name = function(path)
   local process_name = _basename(path):gsub('%.exe$', '')
   if HIDDEN_PROCESS_NAMES[process_name:lower()] then
      return ''
   end
   return process_name
end

local _clean_title = function(title)
   local cleaned = _safe_string(title)

   -- WezTerm may derive a pane title from the Windows-side WSL host process.
   -- Remove it whether it appears alone or as a prefix such as
   -- "wslhost.exe ~ ..." or "wslhost: ...".
   cleaned = cleaned:gsub('^[Ww][Ss][Ll][Hh][Oo][Ss][Tt]%.?[Ee]?[Xx]?[Ee]?%s*[~:%-]?%s*', '')
   cleaned = cleaned:gsub('^%s+', ''):gsub('%s+$', '')

   return cleaned
end

local _set_title = function(tab)
   local explicit_title = _clean_title(tab.tab_title)
   if explicit_title:len() > 0 then
      return explicit_title
   end

   local pane_title = _clean_title(tab.active_pane and tab.active_pane.title)
   local process_name = _clean_process_name(
      tab.active_pane and tab.active_pane.foreground_process_name
   )

   if process_name:len() > 0 and pane_title:len() > 0 then
      return process_name .. ' ~ ' .. pane_title
   end

   if pane_title:len() > 0 then
      return pane_title
   end

   if process_name:len() > 0 then
      return process_name
   end

   return FALLBACK_TITLE
end

local _check_if_admin = function(title)
   return _safe_string(title):match('^Administrator: ') ~= nil
end

local _has_unseen_output = function(tab)
   for _, pane in ipairs(tab.panes or {}) do
      if pane.has_unseen_output then
         return true
      end
   end
   return false
end

local _push = function(cells, bg, fg, intensity, text)
   table.insert(cells, { Background = { Color = bg } })
   table.insert(cells, { Foreground = { Color = fg } })
   table.insert(cells, { Attribute = { Intensity = intensity } })
   table.insert(cells, { Text = text })
end

local _format_content = function(tab, title, is_admin, has_unseen_output, width)
   local prefix = string.format(' %d ', (tab.tab_index or 0) + 1)
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

local _render_tab = function(tab, hover, max_width)
   local cells = {}
   local tab_width = math.min(TAB_WIDTH, max_width)

   if tab_width < 2 then
      return wezterm.truncate_right(tostring((tab.tab_index or 0) + 1), max_width)
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
   local is_admin = _check_if_admin(tab.active_pane and tab.active_pane.title)
   local has_unseen_output = _has_unseen_output(tab)
   local gap_width = math.min(TAB_GAP, tab_width - 1)
   local content_width = tab_width - gap_width
   local content = _format_content(
      tab,
      title,
      is_admin,
      has_unseen_output,
      content_width
   )

   _push(cells, style.bg, style.fg, style.intensity, content)
   _push(cells, TAB_BAR_BG, TAB_BAR_BG, 'Normal', string.rep(' ', gap_width))

   return cells
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      local ok, result = pcall(_render_tab, tab, hover, max_width)
      if ok then
         return result
      end

      -- Keep the custom geometry even if unexpected pane metadata causes a
      -- rendering error, rather than allowing WezTerm to fall back to its
      -- variable-width default tab title.
      wezterm.log_error('format-tab-title failed: ' .. _safe_string(result))

      local tab_width = math.min(TAB_WIDTH, max_width)
      local gap_width = math.min(TAB_GAP, math.max(0, tab_width - 1))
      local content_width = math.max(1, tab_width - gap_width)
      local fallback = wezterm.pad_right(
         wezterm.truncate_right(
            string.format(' %d %s', (tab.tab_index or 0) + 1, FALLBACK_TITLE),
            content_width
         ),
         content_width
      )
      local cells = {}
      _push(cells, colors.default.bg, colors.default.fg, 'Normal', fallback)
      if gap_width > 0 then
         _push(cells, TAB_BAR_BG, TAB_BAR_BG, 'Normal', string.rep(' ', gap_width))
      end
      return cells
   end)
end

return M
