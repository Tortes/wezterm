# Report the current WSL command to WezTerm using an OSC 1337 UserVar.
# Source this file from ~/.zshrc:
#   source /path/to/wezterm/shell/wezterm-tab-title.zsh
#
# For recent Codex versions, Codex itself writes an OSC terminal title with an
# activity spinner and an Action Required state. The WezTerm tab formatter uses
# that title only after this hook identifies the active program as `codex`.

if [[ -o interactive ]] && [[ -n "$WEZTERM_PANE" || "$TERM_PROGRAM" == "WezTerm" ]]; then
   autoload -Uz add-zsh-hook

   function _wezterm_tab_set_user_var() {
      local name="$1"
      local value="$2"

      # Reuse WezTerm's official shell-integration helper when available.
      if (( $+functions[__wezterm_set_user_var] )); then
         __wezterm_set_user_var "$name" "$value"
         return
      fi

      (( $+commands[base64] )) || return

      local encoded
      encoded="$(printf '%s' "$value" | base64 | tr -d '\r\n')"

      if [[ -n "$TMUX" ]]; then
         # tmux also requires: set -g allow-passthrough on
         printf '\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\' "$name" "$encoded"
      else
         printf '\033]1337;SetUserVar=%s=%s\007' "$name" "$encoded"
      fi
   }

   function _wezterm_tab_precmd() {
      _wezterm_tab_set_user_var WEZTERM_TAB_PROG "${ZSH_NAME:-zsh}"
   }

   function _wezterm_tab_preexec() {
      _wezterm_tab_set_user_var WEZTERM_TAB_PROG "$1"
   }

   add-zsh-hook precmd _wezterm_tab_precmd
   add-zsh-hook preexec _wezterm_tab_preexec

   _wezterm_tab_precmd
fi
