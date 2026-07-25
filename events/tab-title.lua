local wezterm = require('wezterm')

local GLYPH_CIRCLE = '' -- nf.fa_circle
local TAB_WIDTH = 28
local TAB_GAP = 1
local TAB_BAR_BG = '#232a2e'
local FALLBACK_TITLE = 'WSL'

local M = {}

local colors = {
   default = { bg = '#343f44', fg = '#859289', intensity = 'Normal', },
   is_active = { bg = '#a7c080', fg = '#2d353b', intensity = 'Bold', },
   hover = { bg = '#4f585e', fg = '#d3c6aa', intensity = 'Bold', },
}

local wrappers = {
   command = true,
   doas = true,
   env = true,
   nohup = true,
   sudo = true,
   time = true,
}

local function trim(value)
   return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function basename(path)
   return trim(path):gsub('(.*[/\\])(.*)', '%2')
end

local function command_name(command_line)
   local skip_options = false

   for token in trim(command_line):gmatch('%S+') do
      token = token:gsub('^["\'`]+', ''):gsub('["\'`;|&]+$', '')
      local name = basename(token):gsub('%.exe$', '')

      if name:match('^[%w_]+=.+') then
         -- Skip environment assignments such as FOO=bar.
      elseif wrappers[name] then
         skip_options = true
      elseif skip_options and name:sub(1, 1) == '-' then
         -- Skip wrapper flags such as sudo -E.
      elseif name ~= '' then
         return name
      end
   end

   return nil
end

local function has_unseen_output(tab)
   for _, pane in ipairs(tab.panes or {}) do
      if pane.has_unseen_output then
         return true
      end
   end
   return false
end

local function cwd_basename(pane)
   if not pane or not pane.current_working_dir then
      return nil
   end

   local cwd = pane.current_working_dir
   local path = type(cwd) == 'string' and cwd or cwd.file_path
   if not path or path == '' then
      return nil
   end

   path = tostring(path)
      :gsub('^file://[^/]*', '')
      :gsub('%%20', ' ')
      :gsub('[/\\]+$', '')

   local name = path:match('([^/\\]+)$')
   return name and name ~= '' and name or nil
end

local function tab_title(tab)
   -- Preserve titles explicitly set by Ctrl+Shift+R or wezterm cli.
   if tab.tab_title and #tab.tab_title > 0 then
      return tab.tab_title
   end

   local pane = tab.active_pane or {}
   local user_vars = pane.user_vars or {}

   -- The Windows host can only see wslhost.exe. The WSL shell reports the
   -- actual command via OSC 1337 UserVars instead.
   local prog = command_name(user_vars.WEZTERM_TAB_PROG)
      or command_name(user_vars.WEZTERM_PROG)
   if prog then
      return prog
   end

   return cwd_basename(pane) or FALLBACK_TITLE
end

local function fit_to_width(text, width)
   if width <= 0 then
      return ''
   end

   local fitted = wezterm.truncate_right(text, width)
   local padding = math.max(0, width - wezterm.column_width(fitted))
   return fitted .. string.rep(' ', padding)
end

local function push(cells, bg, fg, intensity, text)
   table.insert(cells, { Background = { Color = bg } })
   table.insert(cells, { Foreground = { Color = fg } })
   table.insert(cells, { Attribute = { Intensity = intensity } })
   table.insert(cells, { Text = text })
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      local tab_width = math.min(TAB_WIDTH, max_width)
      if tab_width < 2 then
         return tostring(tab.tab_index + 1)
      end

      local style
      if tab.is_active then
         style = colors.is_active
      elseif hover then
         style = colors.hover
      else
         style = colors.default
      end

      local gap_width = math.min(TAB_GAP, tab_width - 1)
      local content_width = tab_width - gap_width
      local prefix = string.format(' %d ', tab.tab_index + 1)
      local suffix = has_unseen_output(tab) and (' ' .. GLYPH_CIRCLE) or ''
      local available_title_width = math.max(
         0,
         content_width - wezterm.column_width(prefix) - wezterm.column_width(suffix)
      )

      local content = prefix
         .. wezterm.truncate_right(tab_title(tab), available_title_width)
         .. suffix
      content = fit_to_width(content, content_width)

      local cells = {}
      push(cells, style.bg, style.fg, style.intensity, content)
      push(cells, TAB_BAR_BG, TAB_BAR_BG, 'Normal', string.rep(' ', gap_width))
      return cells
   end)
end

return M
