# terminal-stack

AeroSpace + Ghostty + herdr (+ vim) configuration for macOS, maintained as a
Claude Code project. `CLAUDE.md` is the canonical state: the layering
contract, hard constraints, and the debugging doctrine. Read it first;
everything else is an artifact of it.

    ./install.sh    # symlink configs into place (backs up real files)
    ./verify.sh     # automated checks + manual keystroke checklist

Layout: one directory per tool, `zsh/stack.zsh` for the two lines of shell
glue (ctrl+s XOFF release, $EDITOR). Edit here, apply, verify, commit.
