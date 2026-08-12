#!/usr/bin/env bash
# Idempotent symlink installer for terminal-stack.
# Real files are backed up to <name>.bak.<timestamp>; symlinks are replaced.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

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

link aerospace/aerospace.toml "$HOME/.aerospace.toml"
link ghostty/config           "$HOME/.config/ghostty/config"
link herdr/config.toml        "$HOME/.config/herdr/config.toml"
link vim/vimrc                "$HOME/.vimrc"

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
