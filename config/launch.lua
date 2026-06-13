local platform = require('utils.platform')()

local options = {
   default_prog = {},
   launch_menu = {},
}

if platform.is_win then
   options.default_prog = { 'wsl.exe', '-d', 'arch' }
   options.launch_menu = {
      { label = 'PowerShell Desktop', args = { 'powershell' } },
      { label = 'Arch', args = { 'wsl.exe', '-d', 'arch' } },
      { label = 'Nushell', args = { 'nu' } },
      {
         label = 'Git Bash',
         args = { 'C:\\Users\\kevin\\scoop\\apps\\git\\current\\bin\\bash.exe' },
      },
      {
         label = 'Alma Linux',
         args = { 'ssh', 'kali@192.168.44.147', '-p', '22' },
      },
   }
elseif platform.is_mac then
   options.default_prog = { '/bin/zsh' }
   options.launch_menu = {
      { label = 'Zsh', args = { 'zsh' } },
   }
end

return options
