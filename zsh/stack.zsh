# terminal-stack shell glue. Sourced from ~/.zshrc (install.sh adds the line).

# Free ctrl+s from XOFF flow control -- it is the herdr prefix.
# Guarded: stty errors in non-interactive shells.
[[ -t 0 ]] && stty -ixon

# herdr's prefix+e opens scrollback in $EDITOR.
export EDITOR=vim
