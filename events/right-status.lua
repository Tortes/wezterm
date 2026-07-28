local wezterm = require('wezterm')
local umath = require('utils.math')

local nf = wezterm.nerdfonts
local M = {}

local discharging_icons = {
   nf.md_battery_10,
   nf.md_battery_20,
   nf.md_battery_30,
   nf.md_battery_40,
   nf.md_battery_50,
   nf.md_battery_60,
   nf.md_battery_70,
   nf.md_battery_80,
   nf.md_battery_90,
   nf.md_battery,
}
local charging_icons = {
   nf.md_battery_charging_10,
   nf.md_battery_charging_20,
   nf.md_battery_charging_30,
   nf.md_battery_charging_40,
   nf.md_battery_charging_50,
   nf.md_battery_charging_60,
   nf.md_battery_charging_70,
   nf.md_battery_charging_80,
   nf.md_battery_charging_90,
   nf.md_battery_charging,
}

local colors = {
   bg = '#232a2e',
   workspace = '#83c092',
   date = '#dbbc7f',
   battery = '#a7c080',
   battery_low = '#e69875',
   battery_critical = '#e67e80',
   muted = '#859289',
}

local __cells__ = {}

local _push = function(text, icon, fg)
   table.insert(__cells__, { Foreground = { Color = fg } })
   table.insert(__cells__, { Background = { Color = colors.bg } })
   table.insert(__cells__, { Attribute = { Intensity = 'Bold' } })
   table.insert(__cells__, { Text = ' ' .. icon .. ' ' .. text .. ' ' })
end

local _set_workspace = function(window)
   _push(window:active_workspace(), nf.cod_window, colors.workspace)
end

local _set_date = function()
   local date = wezterm.strftime('%a %H:%M')
   _push(date, nf.md_clock_outline, colors.date)
end

local _set_battery = function()
   for _, b in ipairs(wezterm.battery_info()) do
      local idx = umath.clamp(umath.round(b.state_of_charge * 10), 1, 10)
      local charge = string.format('%.0f%%', b.state_of_charge * 100)
      local icon
      local fg = colors.battery

      if b.state == 'Charging' then
         icon = charging_icons[idx]
      else
         icon = discharging_icons[idx]
      end

      if b.state_of_charge <= 0.15 then
         fg = colors.battery_critical
      elseif b.state_of_charge <= 0.30 then
         fg = colors.battery_low
      end

      _push(charge, icon, fg)
   end
end

M.setup = function()
   wezterm.on('update-status', function(window, _pane)
      __cells__ = {}
      _set_workspace(window)
      _set_date()
      _set_battery()

      window:set_right_status(wezterm.format(__cells__))
   end)
end

return M
