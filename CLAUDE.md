# dotfiles

Personal dotfiles: one directory per tool, symlinked into `$HOME` by
`./install.sh` (idempotent, per-file links only, backs up real files;
`--minimal` installs just bash/git/vim/tmux for remote Linux VMs). Edit in the
repo, apply, verify, commit — the repo file IS the live file.

The bulk of this repo is **the terminal stack**: a three-layer macOS
terminal environment on an M5 Max — AeroSpace (tiling WM) + Ghostty
(emulator) + herdr (agent-aware multiplexer), plus the vimrc that lives
inside it. (It began life as a separate "terminal-stack" project directory,
long since dissolved into the per-tool dirs here — aerospace/, ghostty/,
herdr/, vim/, zsh/.) This file is the canonical project state; it encodes
conclusions from the debugging campaign that produced those configs, so
read it before proposing changes. The rest (`bash/`, `git/`) predates the
stack and mostly stays stable.

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
One documented non-cmd exception: `alt+shift+backspace` is re-encoded as
`ESC ctrl+h` (legacy encoding drops shift on backspace, so the shell could
never distinguish it from alt+backspace) — zsh/bash bind those bytes to
whole-argument kill. The zle word plane itself runs `select-word-style
bash` (readline alphanumeric-only words), so alt+f/b/d, alt+backspace, and
ctrl+w all stop at `/` like bash.

`cmd+tab` is claimed by AltTab (2026-08, `brew install --cask alt-tab`),
not the native switcher: macOS app activation raises ALL of an app's
windows on EVERY display (no setting changes this, and AeroSpace never
sees the chord — it owns only alt), which shuffled the other monitor's
stack whenever an app had windows on both. AltTab switches single
windows, filtered to the active screen, so the other monitor stays
untouched. Non-default prefs (domain `com.lwouis.alt-tab-macos`):
`screensToShow = "1"` (screen showing AltTab only), `startAtLogin =
"true"`, and Shortcut 1's hold key ⌥→⌘ set in the GUI — shortcut prefs
are NSKeyedArchiver blobs, not `defaults`-scriptable (plain strings get
silently discarded). The hold key MUST be ⌘: on its default ⌥, AltTab's
event tap would race AeroSpace's Carbon hotkey for alt+tab.

## File map

| Repo path              | Installs to                  | Apply                       | Verify                          |
|------------------------|------------------------------|-----------------------------|---------------------------------|
| aerospace/aerospace.toml | ~/.aerospace.toml          | `aerospace reload-config`   | `aerospace list-modes`          |
| ghostty/config         | ~/.config/ghostty/config     | cmd+shift+comma in Ghostty  | `ghostty +list-keybinds`        |
| herdr/config.toml      | ~/.config/herdr/config.toml  | `herdr server reload-config`| `prefix+?` inside herdr         |
| vim/vimrc              | ~/.vimrc                     | restart vim / `:so %`       | `:checkhealth`-style manual     |
| nvim/init.lua          | ~/.config/nvim/init.lua      | restart nvim                | `:checkhealth`; full vim parity + DAP; vim stays canonical |
| zsh/zshrc              | ~/.zshrc                     | new shell                   | `stty -a \| grep ixon`; `bindkey -lL main` → emacs |
| bash/bashrc            | ~/.bash_profile + ~/.bashrc  | new shell                   | `bash --login -i -c 'type la'`  |
| git/gitconfig          | ~/.gitconfig                 | immediate                   | `git config core.excludesfile`  |
| git/gitignore_global   | ~/.gitignore_global          | immediate                   | `.DS_Store` invisible to status |
| tmux/tmux.conf(.local) | ~/.tmux.conf(.local)         | `tmux source ~/.tmux.conf`  | remote-VM use; herdr owns local |
| DefaultKeyBinding.dict | ~/Library/KeyBindings/…      | app relaunch                | Cocoa text fields only          |

Not in the table: `bash/env`, `bash/config`, `bash/aliases` are sourced by
bash/bashrc (and `bash/aliases` also by zsh/zshrc — keep it bash-AND-zsh
compatible); `i3/config` is installed nowhere — a modernized reference for
a future Linux desktop, unverifiable until one exists.

`install.sh` creates symlinks (with backup of real files). Edit in the repo,
apply, verify, commit. Never leave changes uncommitted.

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
   build, but unverified upstream. The `cmd+shift+…` array elements are
   DEAD locally (Ghostty consumes all cmd chords and sends prefix bytes);
   they exist only for herdr attached from a non-Ghostty terminal — a
   documented exception to "no key has two claimants," not a live one.
   Invalid bindings fail SILENTLY (herdr keeps the old binding) — always
   confirm with `prefix+?` after reload.
6. **Shared accent `#33467c`** (TokyoNight's selection-background, derived
   from the Ghostty theme 2026-08; the accent originated as tmux colour_4
   `#00afff`) appears in FOUR places that must change together:
   JankyBorders `active_color` in aerospace/aerospace.toml, `ui.accent` in
   herdr/config.toml, `tmux_conf_theme_colour_4` in tmux/tmux.conf.local,
   and `client.focused` in i3/config. Focus must read identically at every
   layer. The accent must be SELECTION-grade: herdr paints whitish text
   over it in active sidebar rows and no text-on-accent override exists
   (verified against theme.custom via reload diagnostics; a Jellybeans
   bright-blue attempt failed exactly here). Light-on-accent counterparts:
   tmux `window_status_current_fg` = colour_7, i3 `client.focused` text.
   Same coupling class: herdr's theme (`name = "terminal"`) inherits
   Ghostty's `theme` — a theme change re-derives the accent from the new
   theme's selection color, and JankyBorders `inactive_color` (#15161e,
   TokyoNight palette 0) from a near-background tone.
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
12. **AeroSpace `move-mouse` callbacks stay disabled.** With
    `on-focus-changed` / `on-focused-monitor-changed = move-mouse …`
    active, alt+h cross-monitor focus intermittently landed on a
    same-monitor window of the target app instead of crossing (found by
    bisection 2026-08-13; suspected mechanism: the mouse warp fires
    mid-focus-change and feeds back into focus resolution). The symptom
    exactly mimics upstream #101 (same-app-on-two-monitors misfocus).
    AltTab was ruled out by bisection; macOS "Displays have separate
    Spaces" stays ENABLED — deliberately untried (AeroSpace guide §4.3
    recommends disabling it, but the side effects — native fullscreen
    blacking the other display, primary-only menu bar — aren't worth it
    while the callbacks-off fix holds). Cost: the pointer no longer
    follows focus; move it by hand. Re-enable only with a repro test.

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
- Remote multiplexing, two tiers: VMs that can take the herdr binary get
  `herdr --remote <ssh-target> --session <name>` (managed ssh: keepalives,
  control-socket reuse; local keybindings by default) — run it from a PLAIN
  Ghostty window (`open -na Ghostty --args -e zsh`), never inside a herdr
  pane: the outer herdr consumes ctrl+s (constraint 2) and the nest guard
  (`allow_nested = false`) refuses herdr-in-herdr. Everything else gets
  tmux via `install.sh --minimal` (prefix C-a for the same reason).
  UNVERIFIED against a real VM — test on first use and drop this note.

## Pending verification

- vimrc: black upgrade (22.8 → 26.x, 2026-08) means format-on-save follows
  the newer stable style — expect small diffs on first save of old Python.
  (pyright verified working 2026-08-12: LspStatus running, hover, go-to-def.
  Note: the servers dir was created by a manual install after vim's own
  `:LspInstallServer` failed once with a stale-environment suspicion; if a
  future server install fails, capture `:messages` before closing vim.)
- zsh switch (2026-08-12): confirm interactive feel in a real terminal —
  prompt renders, autosuggestions/highlighting show, alt+f/b/d word motion
  works, history shared across panes. Remove this item once a day of use
  passes without surprises.

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
  `ghostty +list-keybinds` to confirm the 21 repo-defined text:
  translations survived (24 total including Ghostty's own defaults); watch
  release notes for keybind grammar changes (physical key names arrived
  in 1.2).
- **vim plugins**: `:PlugUpdate`; `:LspInstallServer --force` if a language
  server misbehaves after a brew python bump.
