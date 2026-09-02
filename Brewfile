# Homebrew packages the dotfiles depend on -- nothing else. This is the
# installable form of install.sh's prerequisite check; keep the two in sync.
# Project toolchains (compilers, python versions, media codecs) live in the
# projects that need them, not here.
#
#   brew bundle --file ~/dotfiles/Brewfile        install
#   brew bundle check --file ~/dotfiles/Brewfile  verify

tap "nikitabobko/tap"
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae"

# --- terminal stack: WM + emulator + multiplexer (CLAUDE.md layering) ---
cask "nikitabobko/tap/aerospace", trusted: true
brew "felixkratz/formulae/borders", trusted: true   # JankyBorders, aerospace.toml after-startup
cask "ghostty"
brew "herdr"
brew "bun"                                          # herdr-annotate plugin runtime
cask "alt-tab"                                      # owns cmd+tab (CLAUDE.md)

# --- editors (vim/vimrc, nvim/init.lua) ---
brew "vim"                                          # /usr/bin/vim lacks +clipboard
brew "neovim"
brew "tree-sitter-cli"
brew "pyright"
brew "black"
brew "clang-format"
brew "uv"                                           # ~/.virtualenvs/debugpy for nvim-dap

# --- shell (zsh/zshrc, bash/aliases) ---
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf"
brew "zoxide"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"
brew "tree"
brew "htop"
brew "btop"
brew "tmux"                                         # remote VMs; herdr owns local

# --- git (git/gitconfig) ---
brew "git-delta"
brew "gh"                                           # credential helper, hardcoded path
brew "lazygit"                                      # herdr popup binding
