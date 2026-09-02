# dotfiles

Personal configuration, one directory per tool, symlinked into `$HOME`.
Useful for setting up a new Mac, getting basics onto a remote Linux VM, or
sharing config snippets. Clone to `~/dotfiles` — the shell configs expect
that path.

    ./install.sh            # full install (backs up real files, idempotent)
    ./install.sh --minimal  # bash/git/vim/tmux, for remote VMs
    ./verify.sh             # automated checks + manual keystroke checklist

The macOS terminal stack (AeroSpace + Ghostty + herdr + vim) is maintained
as a Claude Code project; `CLAUDE.md` is the canonical state — the layering
contract, hard constraints, and the debugging doctrine. Read it before
changing any of those configs. Edit here, apply, verify, commit.

---

# Cheatsheet

The mental model first:

> **One key plane per layer.** `alt+*` moves **windows** (AeroSpace).
> Everything behind the `ctrl+s` prefix runs **tabs/panes/workspaces**
> (herdr). `cmd+*` is frame conveniences (Ghostty re-encodes them into
> prefix bytes). Bare keys belong to whatever runs in the pane (vim, shell).
> No key ever has two owners; `alt+f/b/d/t/u/./c` are reserved for the
> shell's word motion and fzf.

Ghostty has no native tabs: tabs, splits, and projects all live inside
herdr, one herdr session per Ghostty window (`alt+enter` opens another).
`ctrl+s` then a key = "prefix+key" below. Lost? `ctrl+s ?` shows all
live herdr bindings; a frozen pane is XOFF — press `ctrl+q`.

## Windows & workspaces — AeroSpace (`alt`)

| Keys | Action |
|---|---|
| `alt+h/j/k/l` | focus window left/down/up/right (h/l cross monitors) |
| `alt+shift+h/j/k/l` | move window |
| `alt+1..9,0` | go to workspace (2/4/6/8 pinned to Studio Display) |
| `alt+shift+1..9,0` | send window to workspace |
| `alt+tab` | last workspace (back-and-forth) |
| `alt+enter` | new (plain) Ghostty window |
| `alt+shift+enter` | fullscreen |
| `alt+r` | resize mode: `h/j/k/l`, `b` balance, `esc` done |
| `alt+s / alt+w / alt+e` | v-accordion / h-accordion / tiles layout |
| `alt+shift+;` | service mode (`esc` reload, `r` flatten, `f` float) |
| `cmd+tab` | AltTab window switcher — current screen only, raises one window |

## Tabs, panes, projects — herdr (`ctrl+s` prefix)

| Keys | Action | cmd mirror (local only) |
|---|---|---|
| `prefix c` | new tab | `cmd+t` |
| `prefix [` / `]` | previous / next tab | `cmd+[` / `cmd+]` |
| `prefix 1..9` | tab by number | `cmd+1..9` |
| `prefix h/j/k/l` | focus pane | |
| `prefix shift+h/j/k/l` | swap pane left/down/up/right | |
| `prefix v` / `-` | split side-by-side / stacked | `cmd+d` / `cmd+shift+d` |
| `prefix x` | close pane | `cmd+w` |
| `prefix +` | zoom pane | `cmd+enter` |
| `prefix tab` | last pane | |
| `prefix ctrl+c` | **new workspace (= new project)** | |
| `prefix ctrl+k` / `ctrl+j` | previous / next workspace | `cmd+ctrl+[` / `]` |
| `prefix ctrl+f` | find workspace | |
| `prefix enter` | copy mode (vi keys; `v` select, `y` yank) | |
| `prefix e` | open scrollback in vim | |
| `prefix g` | lazygit popup | |
| `prefix a` / `shift+a` | annotate selected text / copy annotations as context | |
| `prefix m` | manage annotations | |
| `prefix o` / `shift+o` | review documents here / the agent's last reply | |
| `prefix r` / `shift+r` | resize mode / reload config | |
| `prefix w` / `b` / `q` | workspace picker / sidebar / detach | |
| `prefix ?` | **help — every live binding** | |

Convention: one workspace per project/worktree. Don't `cd` a tab to another
project — make a workspace (`prefix ctrl+c`); the agents sidebar attributes
panes by workspace.

## Shell (zsh; same aliases in bash)

| Type | Get |
|---|---|
| `z proj` / `zi` | jump to a frecent directory / pick interactively |
| `ctrl+r` / `ctrl+t` / `alt+c` | fzf: history / files / cd |
| `alt+f` `alt+b` `alt+d` | word forward / back / delete — stops at `/` `.` `-` (bash-style) |
| `alt+backspace` / `alt+shift+backspace` | delete back one word / the whole argument |
| `ls la ll lla l` | eza listings (`l` = newest first) |
| `g PATTERN` | ripgrep, case-insensitive |
| `f NAME` | fd file search |
| `take DIR` | mkdir + cd |
| `rmf FILE` | move to Trash (never `rm`) |
| `tu` / `tm` | htop by cpu / memory; `btop` for the pretty one |
| `..` `...` `c` `o` `tree` | up / up2 / clear / Finder here / tree |
| `systail` | stream the unified log (macOS) |

git: `git st/df/ci/co/br/lg` short aliases; `git lc` = what the last pull
brought in; **`git pull` rebases**; diffs page through delta (`n`/`N` jump
between files).

## vim (leader = `` ` ``)

| Keys | Action |
|---|---|
| `` `p `` / `` `a `` | fzf files / ripgrep — **project-rooted**, not cwd |
| `` `b `` / `` `m `` / `` `t `` | buffers / recent files / workspace symbols |
| `jk` or `kj` | escape insert mode |
| `gcc` / `gc{motion}` / `` `cc `` | toggle comment |
| `` `cu `` | uncomment (no-op on uncommented lines) |
| `` `jd `jt `jr `` / `K` | LSP: definition / type / references / hover |
| `` `rn `` / `[g` `]g` | rename / prev-next diagnostic |
| `` `s `` | substitute word under cursor |
| `\f` | format (python/c++ also format on save) |
| `Enter` | clear search highlight |

## Debugging (nvim + nvim-dap)

nvim is a full parallel editor (same leader, mappings, formatting, and
git signs as vim, plus treesitter) whose reason to exist is the debug
plane — vim remains the canonical daily/VM editor until nvim earns the
title. The debug plane is `` `d* ``:

| Keys | Action |
|---|---|
| `` `db `` / `` `dB `` | toggle / conditional breakpoint |
| `` `dc `` | continue — or start a session (pick a config) |
| `` `do `` / `` `di `` / `` `dO `` | step over / into / out |
| `` `du `` / `` `dr `` / `` `dk `` | UI panels / REPL / eval under cursor |
| `` `dx `` | terminate session |

Robot/VM attach: on the target, run the node under debugpy
(`python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client …`), then
`` `dc `` → "Attach remote (robot/VM)". ROS 2 / bazel nodes: attach is the
primary workflow.

## Remote VMs

- Box you can install herdr on: `herdr --remote user@host --session name`
  — **from a plain Ghostty window** (`open -na Ghostty --args -e zsh`),
  never inside a herdr pane (the outer herdr owns `ctrl+s`).
- Anything else: `git clone` to `~/dotfiles`, `./install.sh --minimal`
  (bash/git/vim/tmux), then `tmux` — prefix is **`C-a`** there, same
  grammar (`Enter` copy-mode, `hjkl` panes, `-`/`_` splits, `Tab`
  last-window).

## First 10 minutes, worked examples

1. **Start a project:** `ctrl+s ctrl+c`, name it. Open an editor pane:
   `ctrl+s v`, then `vim`. Jump back and forth: `ctrl+s h` / `ctrl+s l`.
2. **Find code:** in vim `` `p `` type a filename; `` `a `` type a pattern.
   In the shell: `g "some string"` or `f partialname`.
3. **Hop projects:** `ctrl+s ctrl+k/j` cycles workspaces; `alt+1..9` if the
   thing you want is another *app's* window.
4. **Copy terminal output:** `ctrl+s enter`, move with `hjkl`, `v` select,
   `y` — it's on the clipboard (also works over ssh from remote tmux).
   Long output? `ctrl+s e` opens the whole scrollback in vim.
5. **Commit work:** `ctrl+s g` for lazygit, or `git st`, `git df`, `git ci`.
6. **Something's wrong:** pane frozen → `ctrl+q`. A keystroke misbehaves →
   `./verify.sh`, then the "bisect by layer" doctrine in CLAUDE.md.
