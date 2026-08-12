#!/usr/bin/env bash
# Smoke tests for the three-layer contract. Checks the checkable, prints a
# manual checklist for the keystroke tests (those need human fingers).
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILS=0
pass() { echo "ok:    $1"; }
fail() { echo "FAIL:  $1"; FAILS=$((FAILS + 1)); }

# Every managed dotfile must be a symlink into this repo.
check_link() {
  local dst="$1" want="$REPO/$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$want" ]; then
    pass "link $dst"
  else fail "$dst is not a symlink to $want (run ./install.sh)"; fi
}
IS_MAC=0
[ "$(uname)" = Darwin ] && IS_MAC=1

# Portable links (the --minimal set).
check_link "$HOME/.bash_profile"            bash/bashrc
check_link "$HOME/.bashrc"                  bash/bashrc
check_link "$HOME/.gitconfig"               git/gitconfig
check_link "$HOME/.gitignore_global"        git/gitignore_global
check_link "$HOME/.vimrc"                   vim/vimrc
check_link "$HOME/.tmux.conf"               tmux/tmux.conf
check_link "$HOME/.tmux.conf.local"         tmux/tmux.conf.local

# macOS terminal-stack links.
if [ "$IS_MAC" = 1 ]; then
  check_link "$HOME/.aerospace.toml"          aerospace/aerospace.toml
  check_link "$HOME/.config/ghostty/config"   ghostty/config
  check_link "$HOME/.config/herdr/config.toml" herdr/config.toml
  check_link "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" DefaultKeyBinding.dict
  check_link "$HOME/.zshrc"                   zsh/zshrc
fi

# zsh must be on the emacs keymap (EDITOR=vim would otherwise pick viins,
# killing alt+f/b/d word motion) with shared aliases loaded. Mac-only:
# the zshrc link is not part of --minimal, so a VM's stock zsh is not ours.
if [ "$IS_MAC" = 1 ] && command -v zsh >/dev/null; then
  zout=$(zsh -ic 'bindkey -lL main; alias la' 2>/dev/null)
  if echo "$zout" | grep -q emacs && echo "$zout" | grep -q "^la="; then
    pass "zsh emacs keymap + shared aliases"
  else fail "zsh keymap is not emacs or aliases missing (check zsh/zshrc)"; fi
fi

# ctrl+s must be free of XOFF in this shell (tty only; meaningless without one).
if [ ! -t 0 ]; then echo "note:  no tty; skipping stty -ixon check"
elif stty -a 2>/dev/null | grep -q -- '-ixon'; then pass "stty -ixon (ctrl+s free)"
else fail "ixon still on: ctrl+s is XOFF here (zsh/zshrc or bash/env not loaded)"; fi

if [ "$IS_MAC" = 1 ]; then
  # Secure input steals all global hotkeys when held by any process.
  if [ -z "$(ioreg -l -w 0 2>/dev/null | grep -i SecureInput)" ]; then
    pass "secure input off"
  else fail "secure input HELD (find pid via ioreg; AeroSpace hotkeys dead)"; fi

  # AeroSpace alive and config loaded.
  if command -v aerospace >/dev/null && aerospace list-modes >/dev/null 2>&1; then
    pass "aerospace responding (modes: $(aerospace list-modes | tr '\n' ' '))"
  else fail "aerospace CLI not responding"; fi

  # Ghostty keybind translations present: 20 repo-defined (plus Ghostty's
  # own text: defaults, 3 today -- threshold is the repo-owned count).
  if command -v ghostty >/dev/null; then
    n=$(ghostty +list-keybinds 2>/dev/null | grep -c 'text:' || true)
    [ "${n:-0}" -ge 20 ] && pass "ghostty text: translations loaded ($n)" \
                         || fail "ghostty translations missing ($n found; reload config)"
  fi

  # herdr server up.
  command -v herdr >/dev/null && herdr --version >/dev/null 2>&1 \
    && pass "herdr $(herdr --version 2>/dev/null | head -1)" \
    || fail "herdr not available"
fi

# vim capabilities. +clipboard is a macOS-pasteboard concern (vimrc's
# clipboard=unnamed); on headless VMs distro vim lacking it is fine.
if [ "$IS_MAC" = 1 ]; then
  vim --version 2>/dev/null | grep -q '+clipboard' \
    && pass "vim +clipboard" || fail "vim lacks +clipboard (use brew vim)"
else
  vim --version 2>/dev/null | grep -q '+clipboard' \
    && pass "vim +clipboard" || echo "note:  vim lacks +clipboard (ok headless)"
fi
[ -f "$HOME/.vim/autoload/plug.vim" ] \
  && pass "vim-plug bootstrapped" || echo "note:  vim-plug bootstraps on first vim launch"

cat << 'MANUAL'

--- manual checklist (one keystroke per layer) ---
1. alt+j        window focus moves; `cat -v` shows NOTHING (AeroSpace owns it)
2. ctrl+s j     herdr pane focus moves (herdr owns the prefix plane)
3. cmd+]        herdr switches to the NEXT tab; prefix+? shows next_tab = prefix+]
4. alt+f        cursor jumps a word at a shell prompt (Option-as-Meta + AeroSpace non-binding)
5. ctrl+s ctrl+j  workspace switches; if COPY MODE opens instead, the build
                  aliases 0x0A/0x0D -- switch bindings to prefix+ctrl+p/n
MANUAL

if [ "$FAILS" -gt 0 ]; then
  echo
  echo "$FAILS check(s) FAILED"
  exit 1
fi
