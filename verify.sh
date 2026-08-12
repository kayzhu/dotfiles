#!/usr/bin/env bash
# Smoke tests for the three-layer contract. Checks the checkable, prints a
# manual checklist for the keystroke tests (those need human fingers).
set -uo pipefail
pass() { echo "ok:    $1"; }
fail() { echo "FAIL:  $1"; }

# ctrl+s must be free of XOFF in this shell.
if stty -a 2>/dev/null | grep -q -- '-ixon'; then pass "stty -ixon (ctrl+s free)"
else fail "ixon still on: ctrl+s is XOFF here (source zsh/stack.zsh)"; fi

# Secure input steals all global hotkeys when held by any process.
if [ -z "$(ioreg -l -w 0 2>/dev/null | grep -i SecureInput)" ]; then
  pass "secure input off"
else fail "secure input HELD (find pid via ioreg; AeroSpace hotkeys dead)"; fi

# AeroSpace alive and config loaded.
if command -v aerospace >/dev/null && aerospace list-modes >/dev/null 2>&1; then
  pass "aerospace responding (modes: $(aerospace list-modes | tr '\n' ' '))"
else fail "aerospace CLI not responding"; fi

# Ghostty keybind translations present.
if command -v ghostty >/dev/null; then
  n=$(ghostty +list-keybinds 2>/dev/null | grep -c 'text:' || true)
  [ "${n:-0}" -ge 15 ] && pass "ghostty text: translations loaded ($n)" \
                       || fail "ghostty translations missing ($n found; reload config)"
fi

# herdr server up.
command -v herdr >/dev/null && herdr --version >/dev/null 2>&1 \
  && pass "herdr $(herdr --version 2>/dev/null | head -1)" \
  || fail "herdr not available"

# vim capabilities.
vim --version 2>/dev/null | grep -q '+clipboard' \
  && pass "vim +clipboard" || fail "vim lacks +clipboard"
[ -f "$HOME/.vim/autoload/plug.vim" ] \
  && pass "vim-plug bootstrapped" || echo "note:  vim-plug bootstraps on first vim launch"

cat << 'MANUAL'

--- manual checklist (one keystroke per layer) ---
1. alt+j        window focus moves; `cat -v` shows NOTHING (AeroSpace owns it)
2. ctrl+s j     herdr pane focus moves (herdr owns the prefix plane)
3. cmd+]        herdr tab switches; prefix+? shows previous_tab = prefix+[
4. alt+f        cursor jumps a word at a shell prompt (Option-as-Meta + AeroSpace non-binding)
5. ctrl+s ctrl+j  workspace switches; if COPY MODE opens instead, the build
                  aliases 0x0A/0x0D -- switch bindings to prefix+ctrl+p/n
MANUAL
