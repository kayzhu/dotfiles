#!/usr/bin/env bash
# Idempotent symlink installer for the dotfiles repo.
# Real files are backed up to <name>.bak.<timestamp>; symlinks are replaced.
# Per-file links only, never directory links (config dirs hold runtime state).
#
# Usage:
#   ./install.sh            full install (macOS: terminal stack + shell + git)
#   ./install.sh --minimal  bash/git/vim/tmux (remote Linux VM basics)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

# The shell configs hardcode ~/dotfiles (bashrc/zshrc source paths); links
# from another clone location would verify green but load nothing.
if [ "$REPO" != "$HOME/dotfiles" ]; then
  echo "WARNING: repo is at $REPO, but the shell configs expect ~/dotfiles."
  echo "         Clone to ~/dotfiles (or symlink it) before installing."
fi

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
# bashrc doubles as .bashrc so non-login bash (ssh host cmd) is configured too.
link bash/bashrc          "$HOME/.bash_profile"
link bash/bashrc          "$HOME/.bashrc"
link git/gitconfig        "$HOME/.gitconfig"
link git/gitignore_global "$HOME/.gitignore_global"
link vim/vimrc            "$HOME/.vimrc"
# tmux is for remote VMs (session persistence over ssh); linked everywhere
# for consistency -- herdr remains the local multiplexer (CLAUDE.md).
link tmux/tmux.conf       "$HOME/.tmux.conf"
link tmux/tmux.conf.local "$HOME/.tmux.conf.local"

if [ "$MINIMAL" -eq 1 ]; then
  echo
  echo "Minimal install done (bash/git/vim/tmux). Open a new shell."
  exit 0
fi

# macOS terminal stack.
link aerospace/aerospace.toml "$HOME/.aerospace.toml"
link ghostty/config           "$HOME/.config/ghostty/config"
link herdr/config.toml        "$HOME/.config/herdr/config.toml"

# macOS Cocoa text-system keybindings; apps read it at launch.
link DefaultKeyBinding.dict   "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

# Neovim: debug-first config (nvim-dap); vim remains the daily editor.
link nvim/init.lua            "$HOME/.config/nvim/init.lua"

# Interactive shell config (login shell is zsh; bash configs serve VMs).
link zsh/zshrc                "$HOME/.zshrc"

echo
echo "--- prerequisite check (informational) ---"
for c in aerospace herdr vim tmux fzf rg fd bat eza zoxide tree htop btop \
         trash delta lazygit gh borders black clang-format; do
  if command -v "$c" >/dev/null 2>&1; then echo "ok:       $c"
  else echo "MISSING:  $c"; fi
done
open -Ra Ghostty 2>/dev/null && echo "ok:       Ghostty.app" || echo "MISSING:  Ghostty.app"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ -f "/opt/homebrew/share/$p/$p.zsh" ]; then echo "ok:       $p"
  else echo "MISSING:  $p (brew install $p)"; fi
done
if vim --version 2>/dev/null | grep -q '+clipboard'; then
  echo "ok:       vim +clipboard"
else
  echo "WARNING:  vim lacks +clipboard (use brew vim, not /usr/bin/vim)"
fi

echo
echo "Apply: aerospace reload-config; herdr server reload-config;"
echo "       cmd+shift+comma in Ghostty; open a new shell."
