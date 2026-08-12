#!/usr/bin/env bash
# Idempotent symlink installer for the dotfiles repo.
# Real files are backed up to <name>.bak.<timestamp>; symlinks are replaced.
# Per-file links only, never directory links (config dirs hold runtime state).
#
# Usage:
#   ./install.sh            full install (macOS: terminal stack + shell + git)
#   ./install.sh --minimal  bash/git/vim only (remote Linux VM basics)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

MINIMAL=0
[ "${1:-}" = "--minimal" ] && MINIMAL=1

link() {
  local src="$REPO/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$TS"
    echo "backed up: $dst -> $dst.bak.$TS"
  fi
  ln -sfn "$src" "$dst"
  echo "linked:    $dst -> $src"
}

# Portable basics (always).
link bash/bashrc          "$HOME/.bash_profile"
link git/gitconfig        "$HOME/.gitconfig"
link git/gitignore_global "$HOME/.gitignore_global"
link vim/vimrc            "$HOME/.vimrc"

if [ "$MINIMAL" -eq 1 ]; then
  echo
  echo "Minimal install done (bash/git/vim). Open a new shell."
  exit 0
fi

# macOS terminal stack.
link aerospace/aerospace.toml "$HOME/.aerospace.toml"
link ghostty/config           "$HOME/.config/ghostty/config"
link herdr/config.toml        "$HOME/.config/herdr/config.toml"

# macOS Cocoa text-system keybindings; apps read it at launch.
link DefaultKeyBinding.dict   "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

# Shell glue: source stack.zsh from .zshrc exactly once.
ZLINE="source $REPO/zsh/stack.zsh"
if ! grep -qF "zsh/stack.zsh" "$HOME/.zshrc" 2>/dev/null; then
  printf '\n# terminal-stack glue (ctrl+s / EDITOR)\n%s\n' "$ZLINE" >> "$HOME/.zshrc"
  echo "appended:  source line to ~/.zshrc"
else
  echo "present:   ~/.zshrc already sources stack.zsh"
fi

echo
echo "--- prerequisite check (informational) ---"
for c in aerospace herdr vim fzf rg borders black clang-format; do
  if command -v "$c" >/dev/null 2>&1; then echo "ok:       $c"
  else echo "MISSING:  $c"; fi
done
open -Ra Ghostty 2>/dev/null && echo "ok:       Ghostty.app" || echo "MISSING:  Ghostty.app"
if vim --version 2>/dev/null | grep -q '+clipboard'; then
  echo "ok:       vim +clipboard"
else
  echo "WARNING:  vim lacks +clipboard (use brew vim, not /usr/bin/vim)"
fi

echo
echo "Apply: aerospace reload-config; herdr server reload-config;"
echo "       cmd+shift+comma in Ghostty; open a new shell."
