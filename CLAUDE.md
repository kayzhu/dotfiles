# dotfiles

Personal dotfiles: one directory per tool, symlinked into `$HOME` by
`./install.sh` (idempotent, per-file links only, backs up real files;
`--minimal` installs just bash/git/vim for remote Linux VMs). Edit in the
repo, apply, verify, commit — the repo file IS the live file.

The bulk of this repo is **terminal-stack**: a three-layer macOS terminal
environment on an M5 Max — AeroSpace (tiling WM) + Ghostty (emulator) +
herdr (agent-aware multiplexer), plus the vimrc that lives inside it. This
file is the canonical project state; it encodes conclusions from the
debugging campaign that produced those configs, so read it before proposing
changes. The rest (`bash/`, `git/`) predates the stack and mostly stays
stable.

## The layering contract (the core invariant)

| Layer     | Owns                | Keys                                  |
|-----------|---------------------|---------------------------------------|
| AeroSpace | windows between apps| `alt+*` (Carbon global hotkeys)       |
| herdr     | tabs/panes/sessions | everything behind `ctrl+s` (prefix)   |
| Ghostty   | the frame only      | `cmd+*` (quit, config, clipboard, font)|
| vim       | text                | bare keys; `hjkl` cursor motion       |

**No key may ever have two claimants.** Every bug in the original campaign
was two layers claiming one keystroke. Before adding ANY binding anywhere,
enumerate claimants across: aerospace.toml, ghostty config, herdr
config.toml, vimrc, AND readline/zle (the alt+letter Meta keys: f, b, d, t,
u, period are reserved for word motion, and alt+c for fzf's cd widget — all
deliberately unbound in AeroSpace).

Ghostty's `cmd+*` keybinds are pure conveniences that re-encode chords as
prefix bytes (`text:\x13...`); herdr only ever sees bytes, which is why the
prefix works identically over SSH and the cmd chords only exist locally.

## File map

| Repo path              | Installs to                  | Apply                       | Verify                          |
|------------------------|------------------------------|-----------------------------|---------------------------------|
| aerospace/aerospace.toml | ~/.aerospace.toml          | `aerospace reload-config`   | `aerospace list-modes`          |
| ghostty/config         | ~/.config/ghostty/config     | cmd+shift+comma in Ghostty  | `ghostty +list-keybinds`        |
| herdr/config.toml      | ~/.config/herdr/config.toml  | `herdr server reload-config`| `prefix+?` inside herdr         |
| vim/vimrc              | ~/.vimrc                     | restart vim / `:so %`       | `:checkhealth`-style manual     |
| zsh/zshrc              | ~/.zshrc                     | new shell                   | `stty -a \| grep ixon`; `bindkey -lL main` → emacs |
| bash/bashrc            | ~/.bash_profile              | new login shell             | `bash --login -i -c 'type la'`  |
| git/gitconfig          | ~/.gitconfig                 | immediate                   | `git config core.excludesfile`  |
| git/gitignore_global   | ~/.gitignore_global          | immediate                   | `.DS_Store` invisible to status |

`install.sh` creates symlinks (with backup of real files). Edit in the repo,
apply, verify, commit. Never leave changes uncommitted.

## Hard constraints (violating these reintroduces solved bugs)

1. **Ghostty config: NO inline comments, ever.** Everything after `=` is
   value. A trailing comment on a `keybind = ...=text:...` line gets typed
   into herdr as literal text. All comments on their own lines.
2. **Never map `<C-s>` in vim or any TUI config.** herdr consumes the prefix
   before the PTY; the key cannot reach any application inside it.
3. **`stty -ixon` must stay in shell init** (zsh/zshrc for zsh, bash/env for
   bash — one definition per shell). ctrl+s is XOFF at the tty layer without
   it; symptom is a frozen pane, cure is ctrl+q.
4. **AeroSpace: reconcile against `aerospace --version`, not against
   documentation.** The docs site tracks the newest release; the installed
   binary may lag. `auto-reload-config`, `focus-follows-mouse`, and the
   string `test` form of on-window-detected are version-gated (older
   binaries reject them, and AeroSpace refuses the WHOLE file on any unknown
   key). The live config keeps all three active — verified accepted by the
   installed binary (2026-08). On a downgrade or a second machine, fall back
   to the tolerant forms: `if.app-id` table form, both gated keys commented.
5. **herdr: source of truth is `herdr --default-config` and `prefix+?`,
   never web docs or blog posts.** herdr is pre-1.0; the template's lists
   are illustrative, not schemas (bracket keys ARE valid despite not being
   listed; underscore is NOT). Single-string binding values are the verified
   form; the live tab bindings use array form (`previous_tab = ["prefix+[",
   "cmd+shift+["]`) by deliberate choice — kept because it works on this
   build, but unverified upstream. Invalid bindings fail SILENTLY (herdr
   keeps the old binding) — always confirm with `prefix+?` after reload.
6. **Shared accent `#00afff`** (tmux heritage, colour_4) appears in TWO
   places that must change together: JankyBorders `active_color` in
   aerospace.toml and `ui.accent` in herdr config.toml. Focus must read
   identically at the window layer and the pane layer. Same coupling class:
   herdr's theme (`name = "terminal"`) inherits Ghostty's `theme` — changing
   the Ghostty theme restyles the pane layer too.
7. **Gaps and border width are coupled** in aerospace.toml: 8px gaps for
   5px borders. Shrinking gaps to 1 requires borders at 2-3 or adjacent
   borders merge and active/inactive stops reading.
8. **`macos-option-as-alt = true` in Ghostty is load-bearing** for readline
   word motion (alt+f/b/d...). It does NOT affect AeroSpace's alt bindings
   (Carbon hotkeys fire before Ghostty sees the key). Do not set to false.
9. **No native Ghostty tabs, ever.** Native macOS tabs are separate
   AXWindows and break AeroSpace focus (the bug that started everything).
   The original design auto-launched herdr via
   `command = /opt/homebrew/bin/herdr`; that line is now DELIBERATELY
   commented out (new Ghostty windows each attached a fresh herdr window to
   the same session — unwanted duplicates). herdr is started manually in
   the primary window instead; plain-shell escape hatch:
   `open -na Ghostty --args -e zsh`.
10. **herdr scrollback is BYTES, not lines** (`scrollback_limit_bytes`).
    tmux's history-limit intuition does not transfer.
11. **`bindkey -e` must stay FIRST in zsh/zshrc.** `EDITOR=vim` makes zsh
    select the vi keymap at startup, which kills alt+f/b/d word motion (the
    reserved readline/zle plane, constraint 8). The login shell is zsh
    (`chsh -s /bin/zsh`); bash/ configs remain canonical for Linux VMs and
    share bash/aliases with zsh — keep that file bash-AND-zsh compatible.

## Debugging doctrine: bisect by layer

When a keystroke misbehaves, find which layer consumed it — never guess:

- `cat -v` in a pane: does the chord produce bytes? Silence = consumed
  above the PTY (AeroSpace, macOS, or Ghostty). Bytes = it reached the app.
- `ghostty +list-keybinds | grep <key>`: does Ghostty claim it?
- `prefix+?` in herdr: what is actually bound (not what the config says).
- `aerospace list-windows --workspace focused`: window-count anomalies
  (this is the test that exposed native-tabs-as-windows).
- `aerospace list-modes --current`: stuck in a non-main binding mode?
- `ioreg -l -w 0 | grep -i SecureInput`: secure input steals ALL global
  hotkeys system-wide; empty output = off. Check while reproducing.
- Config reloads that "do nothing": AeroSpace refuses the whole file on any
  unknown key and keeps the previous config; herdr silently keeps prior
  bindings on invalid values. Both demand post-reload verification.

## Conventions

- herdr: one workspace per project/worktree. `new_cwd = "follow"` is
  predictable ONLY within that convention; for a different project, create
  a workspace (`prefix+ctrl+c`), never cd inside a tab (the agents sidebar
  attributes panes by workspace and stale cwds misattribute).
- Key grammar: vertical containers get j/k (workspaces: prefix+ctrl+j/k),
  horizontal rows get brackets (tabs: prefix+[ / ]). Coarser motion =
  heavier modifier plane.
- Claude Code wiring lives outside these files:
  `herdr integration install claude` (state + session resume) and the herdr
  agent skill (`herdr --skill` to review; installed globally, gated on
  HERDR_ENV=1 and explicit mention).

## Pending verification

- vimrc: `:LspInstallServer` (pyright) in a Python buffer remains unverified
  (vim-plug bootstrap is confirmed done). Also unverified after the 2026-08
  black upgrade (22.8 → 26.x): format-on-save output will follow the newer
  stable style.
- zsh switch (2026-08-12): confirm interactive feel in a real terminal —
  prompt renders, autosuggestions/highlighting show, alt+f/b/d word motion
  works, history shared across panes. Remove this item once a day of use
  passes without surprises.

## Upgrade playbook

- **AeroSpace**: `brew upgrade --cask aerospace`, then uncomment
  `auto-reload-config`, reload once manually. Upgrading restarts the WM and
  briefly un-hides all workspace windows — do it between tasks.
- **herdr** (pre-1.0, highest churn): after upgrade, diff
  `herdr --default-config` against the last known template, re-verify every
  custom binding via `prefix+?`, and re-check integration versions with
  `herdr integration status`.
- **Ghostty**: NOT brew-managed (no cask installed) — updates come from the
  app itself. After updating, reload config, then `ghostty +list-keybinds`
  to confirm the 20 repo-defined text: translations survived (23 total
  including Ghostty's own defaults); watch release notes for keybind
  grammar changes (physical key names arrived in 1.2).
- **vim plugins**: `:PlugUpdate`; `:LspInstallServer --force` if a language
  server misbehaves after a brew python bump.
