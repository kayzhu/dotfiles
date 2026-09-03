# dotfiles

Personal dotfiles: one directory per tool, symlinked into `$HOME` by
`./install.sh` (idempotent, per-file links only, backs up real files;
`--minimal` installs just bash/git/vim/tmux for remote Linux VMs). Edit in the
repo, apply, verify, commit — the repo file IS the live file.

The bulk of this repo is **the terminal stack**: a four-layer macOS
terminal environment on an M5 Max — AeroSpace (tiling WM) + Ghostty
(emulator) + herdr (agent-aware multiplexer) + the vim that lives
inside it. This file is the canonical project state; it encodes
conclusions from the debugging campaign that produced those configs, not
preferences. The rest (`bash/`, `git/`) predates the stack and mostly
stays stable.

## The layering contract (the core invariant)

| Layer     | Owns                | Keys                                  |
|-----------|---------------------|---------------------------------------|
| AeroSpace | windows between apps| `alt+*` (Carbon global hotkeys)       |
| herdr     | tabs/panes/sessions | everything behind `ctrl+s` (prefix)   |
| Ghostty   | the frame; re-encodes cmd chords into prefix bytes | `cmd+*` (quit, config, clipboard, font)|
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
One documented non-cmd exception: `alt+shift+backspace` is re-encoded as
`ESC ctrl+h` (legacy encoding drops shift on backspace, so the bytes would
collide with alt+backspace); zsh/bash bind it to whole-argument kill. The
zle/readline word plane runs `select-word-style bash`, so alt+f/b/d,
alt+backspace, and ctrl+w stop at `/` like bash.

`cmd+tab` is claimed by AltTab (2026-08, cask `alt-tab`), not the native
switcher: macOS app activation raises ALL of an app's windows on every
display, shuffling the other monitor whenever an app spans both; AltTab
raises only the window you pick, filtered to the active screen.
Non-default prefs: `screensToShow = "1"`, `startAtLogin = "true"`, hold
key set to ⌘ in its GUI (shortcut prefs aren't `defaults`-scriptable).
The hold key MUST be ⌘: on the default ⌥ it races AeroSpace's alt+tab.

## File map

| Repo path              | Installs to                  | Apply                       | Verify                          |
|------------------------|------------------------------|-----------------------------|---------------------------------|
| aerospace/aerospace.toml | ~/.aerospace.toml          | `aerospace reload-config`   | `aerospace list-modes`          |
| ghostty/config         | ~/.config/ghostty/config     | cmd+shift+comma in Ghostty  | `ghostty +list-keybinds`        |
| herdr/config.toml      | ~/.config/herdr/config.toml  | `herdr server reload-config`| `prefix+?` inside herdr         |
| vim/vimrc              | ~/.vimrc                     | restart vim / `:so %`       | `:checkhealth`-style manual     |
| nvim/init.lua          | ~/.config/nvim/init.lua      | restart nvim                | `:checkhealth`; muscle-memory parity + DAP; vim stays canonical |
| zsh/zshrc              | ~/.zshrc                     | new shell                   | `stty -a \| grep ixon`; `bindkey -lL main` → emacs |
| bash/bashrc            | ~/.bash_profile + ~/.bashrc  | new shell                   | `bash --login -i -c 'type la'`  |
| git/gitconfig          | ~/.gitconfig                 | immediate                   | `git config core.excludesfile`  |
| git/gitignore_global   | ~/.gitignore_global          | immediate                   | `.DS_Store` invisible to status |
| tmux/tmux.conf(.local) | ~/.tmux.conf(.local)         | `tmux source ~/.tmux.conf`  | remote-VM use; herdr owns local |
| DefaultKeyBinding.dict | ~/Library/KeyBindings/… (COPY) | `./install.sh` + app relaunch | Cocoa fields; `cmp` in verify.sh |
| Brewfile               | (not installed; macOS only)  | `brew bundle --file Brewfile` | `brew bundle check --file Brewfile` |

Not in the table: `bash/env`, `bash/config`, `bash/aliases` are sourced by
bash/bashrc (and `bash/aliases` also by zsh/zshrc — keep it bash-AND-zsh
compatible); `i3/config` is installed nowhere — a modernized reference for
a future Linux desktop, unverifiable until one exists. `Brewfile` is the
installable form of install.sh's prerequisite check and nothing more (no
project toolchains); keep the two lists in sync. It is macOS-only and
independent of `install.sh --minimal`.

`install.sh` creates symlinks (with backup of real files). Edit in the repo,
apply, verify, commit. Never leave changes uncommitted. The one non-link is
DefaultKeyBinding.dict: sandboxed apps (Safari, Mail, TextEdit) may read
~/Library/KeyBindings but not a symlink target under ~/dotfiles, so a linked
dict is silently ignored — it is copied, and edits need a re-install plus
app relaunch.

## Hard constraints (violating these reintroduces solved bugs)

1. **Ghostty config: NO inline comments, ever.** Everything after `=` is
   value. A trailing comment on a `keybind = ...=text:...` line gets typed
   into herdr as literal text. All comments on their own lines.
2. **Never map `<C-s>` in vim or any TUI config.** herdr consumes the prefix
   before the PTY; the key cannot reach any application inside it. (This is
   why remote tmux's prefix is C-a — its former C-s prefix, the very
   heritage herdr's prefix came from, became unreachable under herdr.)
3. **`stty -ixon` must stay in shell init** (zsh/zshrc for zsh, bash/env for
   bash — one definition per shell). ctrl+s is XOFF at the tty layer without
   it; symptom is a frozen pane, cure is ctrl+q.
4. **AeroSpace: reconcile against `aerospace --version`, not against
   documentation.** The docs site tracks the newest release; the installed
   binary may lag, and AeroSpace refuses the WHOLE file on any unknown key.
   `auto-reload-config`, `focus-follows-mouse`, and the string `test` form
   of on-window-detected are version-gated — verified accepted by the
   installed binary (2026-08); on a downgrade, comment them out.
5. **herdr: source of truth is `herdr --default-config` and `prefix+?`,
   never web docs or blog posts.** herdr is pre-1.0; the template's lists
   are illustrative, not schemas. Invalid bindings fail SILENTLY (herdr
   keeps the old binding) — always confirm with `prefix+?` after reload.
6. **`macos-option-as-alt = true` in Ghostty is load-bearing** for readline
   word motion (alt+f/b/d...). It does NOT affect AeroSpace's alt bindings
   (Carbon hotkeys fire before Ghostty sees the key). Do not set to false.
7. **No native Ghostty tabs, ever.** Native macOS tabs are separate
   AXWindows and break AeroSpace focus (the bug that started everything).
   Ghostty's `command = herdr` stays commented out — it attached a
   duplicate herdr window per new Ghostty window; start herdr manually.
   Plain-shell escape hatch: `open -na Ghostty --args -e zsh`.
8. **`bindkey -e` must stay FIRST in zsh/zshrc.** `EDITOR=vim` makes zsh
   select the vi keymap at startup, which kills alt+f/b/d word motion (the
   reserved readline/zle plane, constraint 6).
9. **AeroSpace `move-mouse` callbacks stay disabled.** With
   `on-focus-changed` / `on-focused-monitor-changed = move-mouse …`
   active, alt+h cross-monitor focus intermittently landed on a
   same-monitor window of the target app (found by bisection 2026-08-13;
   the warp fires mid-focus-change and feeds back into focus resolution).
   Cost: the pointer no longer follows focus. Re-enable only with a repro
   test at hand.
10. **macOS "Displays have separate Spaces" stays DISABLED** (System
   Settings > Desktop & Dock > Mission Control; takes effect after
   logout). Same symptom as 9, second independent cause (2026-09-02):
   with it on, focusing a window of an app that has windows on two
   workspaces lands on the app's most-recently-used window, on ANY
   monitor, and drags that workspace onto its display (upstream
   nikitabobko/AeroSpace#101; app-level `activate` restores the app's
   last key window, draft PR #2179). Deterministic repro: alt+0 (touch
   the ws-10 Ghostty), alt+1, alt+h — jumps to 10 instead of crossing.
   Off, 3/3 CLI runs cross correctly. Cost: native (green-button)
   fullscreen blacks the other display; use alt+shift+enter instead.
   verify.sh checks the pref.

Colors are NOT doctrine: JankyBorders' active/inactive pair
(aerospace.toml), tmux's colour_4, and i3's focused border are plain
per-file cosmetic values — change any of them freely. herdr's accent is
deliberately UNPINNED (`theme "terminal"` derives it from Ghostty's
palette; hand-pinning it hurt sidebar readability twice, 2026-08).

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
- herdr-annotate plugin (`herdr plugin install plannotator/herdr-annotate`,
  Full): in-terminal annotation of pane text and document/agent-reply
  review, fed back to the agent as context. Runtime: bun. Its five
  prefix+a/shift+a/m/o/shift+o bindings live in herdr/config.toml.
- Hand-set macOS defaults (same class as AltTab's prefs):
  `defaults write -g TSMLanguageIndicatorEnabled -bool false` (2026-08)
  removes Sonoma+'s floating input-source/caps-lock capsule at the text
  cursor — no GUI toggle exists. Applies per-app on relaunch.
  `com.apple.spaces spans-displays = true` (constraint 10, set via the
  Mission Control GUI 2026-09-02; logout to apply).
- **Restart the herdr server after every macOS logout** (`herdr server
  stop`, then start herdr from a fresh Ghostty). The server outlives
  logout, and every pane it then spawns inherits a bootstrap port into
  the dead login session: `launchctl print gui/501` fails with "141:
  Reentrancy avoided", `open -a` finds no apps, `defaults read` sees no
  domains, and runtime Metal shader compiles fail with "Unable to reach
  MTLCompilerService". Confirmed 2026-09-02.
- Remote multiplexing, two tiers: VMs that can take the herdr binary get
  `herdr --remote <ssh-target> --session <name>` (managed ssh: keepalives,
  control-socket reuse; local keybindings by default) — run it from a PLAIN
  Ghostty window (`open -na Ghostty --args -e zsh`), never inside a herdr
  pane: the outer herdr consumes ctrl+s (constraint 2) and the nest guard
  (`allow_nested = false`) refuses herdr-in-herdr. Everything else gets
  tmux via `install.sh --minimal` (prefix C-a for the same reason).
  UNVERIFIED against a real VM — test on first use and drop this note.

## Pending verification

- herdr 0.8.2 restart done (2026-08-31): annotate plugin installed +
  enabled, config reloads clean, claude integration hook updated v7→v8,
  pane swaps verified via CLI in a scratch tab. Remaining finger
  test: `prefix+?` shows the five annotate bindings and the four
  prefix+shift+hjkl swaps; press each once.
  Then drop this item.

## Upgrade playbook

- **AeroSpace**: `brew upgrade --cask aerospace`, then verify the config
  still parses (`aerospace reload-config` + `list-modes`): the version-gated
  keys are live in the config (constraint 4) — if the reload is refused,
  comment them per the tolerant-forms fallback. Upgrading restarts the WM
  and briefly un-hides all workspace windows — do it between tasks.
- **herdr** (pre-1.0, highest churn): after upgrade, diff
  `herdr --default-config` against the last known template, re-verify every
  custom binding via `prefix+?`, and re-check integration versions with
  `herdr integration status`.
- **Ghostty**: brew-cask-managed since 2026-08 (adopted at 1.3.1). The cask
  is marked auto_updates, so the app updates itself and plain
  `brew upgrade` skips it; `brew upgrade --cask ghostty --greedy` forces a
  brew-side sync. After updating, reload config, then
  `./verify.sh` to confirm the repo-defined `text:` translations survived
  (the expected count is pinned there, next to the check that enforces it); watch
  release notes for keybind grammar changes (physical key names arrived
  in 1.2).
- **vim plugins**: `:PlugUpdate`; `:LspInstallServer --force` if a language
  server misbehaves after a brew python bump. black is 26.x since 2026-08:
  expect small format-on-save diffs on old Python. If a vim-lsp server
  install fails, capture `:messages` before closing vim (the 2026-08 pyright
  fix was a manual install into ~/.local/share/vim-lsp-settings/servers).
