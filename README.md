# dotfiles

Personal configuration, one directory per tool, symlinked into `$HOME`.
Useful for setting up a new Mac, getting basics onto a remote Linux VM, or
sharing config snippets. Clone to `~/dotfiles` — the shell configs expect
that path.

    ./install.sh            # full install (backs up real files, idempotent)
    ./install.sh --minimal  # bash/git/vim/tmux, for remote VMs
    ./verify.sh             # automated checks + manual keystroke checklist

New to this setup? **`CHEATSHEET.md`** is the one-page quickstart: the key
plane per layer, every personalized binding and alias, and worked examples.

The macOS terminal stack (AeroSpace + Ghostty + herdr + vim) is maintained
as a Claude Code project; `CLAUDE.md` is the canonical state — the layering
contract, hard constraints, and the debugging doctrine. Read it before
changing any of those configs. Edit here, apply, verify, commit.
