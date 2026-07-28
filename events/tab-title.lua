local wezterm = require('wezterm')

local GLYPH_CIRCLE = '' -- nf.fa_circle
local MAX_TAB_WIDTH = 28
local TAB_GAP = 1
local TAB_BAR_BG = '#232a2e'
local FALLBACK_TITLE = 'WSL'

-- The right status is clipped from its left edge. Reserving enough room for
-- the clock and battery keeps those useful right-most fields visible, while
-- the drag reserve leaves a reliable blank title-bar region for the mouse.
local RIGHT_STATUS_RESERVE = 24
local DRAG_AREA_RESERVE = 10
local NEW_TAB_BUTTON_RESERVE = 3

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

local shells = {
   bash = true,
   fish = true,
   sh = true,
   zsh = true,
}

local codex_spinner_frames = {
   '⠋', '⠙', '⠹', '⠸', '⠼',
   '⠴', '⠦', '⠧', '⠇', '⠏',
}

local function trim(value)
   return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function basename(path)
   return trim(path):gsub('(.*[/\\])(.*)', '%2')
end

local function starts_with(value, prefix)
   return value:sub(1, #prefix) == prefix
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

local function active_program(pane)
   local user_vars = pane and pane.user_vars or {}
   return command_name(user_vars.WEZTERM_TAB_PROG)
      or command_name(user_vars.WEZTERM_PROG)
end

local function codex_activity_icon(pane)
   local title = trim(pane and pane.title)

   if title:find('Action Required', 1, true) then
      return '!'
   end

   for _, frame in ipairs(codex_spinner_frames) do
      if starts_with(title, frame) then
         return frame
      end
   end

   if title:find('Working', 1, true)
      or title:find('Thinking', 1, true)
      or title:find('Waiting', 1, true)
      or title:find('Starting', 1, true)
   then
      return '●'
   end

   return '○'
end

local function activity_icon(pane, program)
   if program == 'codex' then
      return codex_activity_icon(pane)
   end

   if not program or shells[program] then
      return '○'
   end

   return '▶'
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

local function tab_title(tab, program)
   -- Preserve titles explicitly set by Ctrl+Shift+R or wezterm cli.
   if tab.tab_title and #tab.tab_title > 0 then
      return tab.tab_title
   end

   if program then
      return program
   end

   return cwd_basename(tab.active_pane) or FALLBACK_TITLE
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

local function active_window_columns(tabs)
   local active_tab = tabs[1]
   for _, candidate in ipairs(tabs) do
      if candidate.is_active then
         active_tab = candidate
         break
      end
   end

   if not active_tab then
      return 80
   end

   local right_edge = 0
   for _, pane in ipairs(active_tab.panes or {}) do
      right_edge = math.max(
         right_edge,
         (pane.left or 0) + (pane.width or 0)
      )
   end

   if right_edge > 0 then
      return right_edge
   end

   return active_tab.active_pane and active_tab.active_pane.width or 80
end

local function adaptive_tab_width(tabs, max_width)
   local tab_count = math.max(1, #tabs)
   local reserved = RIGHT_STATUS_RESERVE
      + DRAG_AREA_RESERVE
      + NEW_TAB_BUTTON_RESERVE
   local available = math.max(tab_count, active_window_columns(tabs) - reserved)
   local per_tab = math.floor(available / tab_count)

   return math.max(1, math.min(MAX_TAB_WIDTH, max_width, per_tab))
end

local function tab_prefix(index, icon, content_width)
   local candidates = {
      string.format(' %d %s ', index, icon),
      string.format('%d%s ', index, icon),
      string.format('%d ', index),
      tostring(index),
   }

   for _, candidate in ipairs(candidates) do
      if wezterm.column_width(candidate) <= content_width then
         return candidate
      end
   end

   return wezterm.truncate_right(tostring(index), content_width)
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, tabs, _panes, _config, hover, max_width)
      local tab_width = adaptive_tab_width(tabs, max_width)
      if tab_width <= 1 then
         return tostring((tab.tab_index + 1) % 10)
      end

      local style
      if tab.is_active then
         style = colors.is_active
      elseif hover then
         style = colors.hover
      else
         style = colors.default
      end

      local pane = tab.active_pane or {}
      local program = active_program(pane)
      local icon = activity_icon(pane, program)
      local gap_width = math.min(TAB_GAP, tab_width - 1)
      local content_width = tab_width - gap_width
      local prefix = tab_prefix(tab.tab_index + 1, icon, content_width)
      local prefix_width = wezterm.column_width(prefix)

      local suffix = ''
      if has_unseen_output(tab) and content_width - prefix_width >= 2 then
         suffix = ' ' .. GLYPH_CIRCLE
      end

      local available_title_width = math.max(
         0,
         content_width - prefix_width - wezterm.column_width(suffix)
      )

      local content = prefix
         .. wezterm.truncate_right(tab_title(tab, program), available_title_width)
         .. suffix
      content = fit_to_width(content, content_width)

      local cells = {}
      push(cells, style.bg, style.fg, style.intensity, content)
      push(cells, TAB_BAR_BG, TAB_BAR_BG, 'Normal', string.rep(' ', gap_width))
      return cells
   end)
end

return M
