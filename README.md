# dotfiles

Personal configuration, one directory per tool, symlinked into `$HOME`.
Useful for setting up a new Mac, getting basics onto a remote Linux VM, or
sharing config snippets.

    ./install.sh            # full install (backs up real files, idempotent)
    ./install.sh --minimal  # bash/git/vim only, for remote VMs
    ./verify.sh             # automated checks + manual keystroke checklist

The macOS terminal stack (AeroSpace + Ghostty + herdr + vim) is maintained
as a Claude Code project; `CLAUDE.md` is the canonical state — the layering
contract, hard constraints, and the debugging doctrine. Read it before
changing any of those configs. Edit here, apply, verify, commit.
