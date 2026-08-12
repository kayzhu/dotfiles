# terminal-stack

Configuration for a three-layer macOS terminal environment on an M5 Max:
AeroSpace (tiling WM) + Ghostty (emulator) + herdr (agent-aware multiplexer),
plus the vimrc that lives inside it. This file is the canonical project
state; it encodes conclusions from the debugging campaign that produced the
configs, so read it before proposing changes.

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
config.toml, vimrc, AND readline (the alt+letter Meta keys: f, b, d, t, u,
period are reserved for word motion and deliberately unbound in AeroSpace).

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
| zsh/stack.zsh          | sourced from ~/.zshrc        | new shell                   | `stty -a \| grep ixon`          |

`install.sh` creates symlinks (with backup of real files). Edit in the repo,
apply, verify, commit. Never leave changes uncommitted.

## Hard constraints (violating these reintroduces solved bugs)

1. **Ghostty config: NO inline comments, ever.** Everything after `=` is
   value. A trailing comment on a `keybind = ...=text:...` line gets typed
   into herdr as literal text. All comments on their own lines.
2. **Never map `<C-s>` in vim or any TUI config.** herdr consumes the prefix
   before the PTY; the key cannot reach any application inside it.
3. **`stty -ixon` must stay in shell init** (zsh/stack.zsh). ctrl+s is XOFF
   at the tty layer without it; symptom is a frozen pane, cure is ctrl+q.
4. **AeroSpace: prefer version-tolerant forms.** The docs site tracks the
   newest release; the installed binary lags. Use `if.app-id` table form in
   on-window-detected (accepted by all versions; string `test` form rejects
   on older binaries). `auto-reload-config` and `focus-follows-mouse` are
   version-gated: the former stays commented until after a brew upgrade.
   Reconcile against `aerospace --version`, not against documentation.
5. **herdr: source of truth is `herdr --default-config` and `prefix+?`,
   never web docs or blog posts.** herdr is pre-1.0; the template's lists
   are illustrative, not schemas (bracket keys ARE valid despite not being
   listed; underscore is NOT). Use single-string binding values; array
   forms are unverified. Invalid bindings fail SILENTLY (herdr keeps the
   old binding) — always confirm with `prefix+?` after reload.
6. **Shared accent `#00afff`** (tmux heritage, colour_4) appears in TWO
   places that must change together: JankyBorders `active_color` in
   aerospace.toml and `ui.accent` in herdr config.toml. Focus must read
   identically at the window layer and the pane layer.
7. **Gaps and border width are coupled** in aerospace.toml: 8px gaps for
   5px borders. Shrinking gaps to 1 requires borders at 2-3 or adjacent
   borders merge and active/inactive stops reading.
8. **`macos-option-as-alt = true` in Ghostty is load-bearing** for readline
   word motion (alt+f/b/d...). It does NOT affect AeroSpace's alt bindings
   (Carbon hotkeys fire before Ghostty sees the key). Do not set to false.
9. **Ghostty runs `command = /opt/homebrew/bin/herdr`** — one window, one
   session layer, no native tabs. Native macOS tabs are separate AXWindows
   and break AeroSpace focus (the bug that started everything). Never
   reintroduce native tabs; escape hatch for a plain shell:
   `open -na Ghostty --args -e zsh`.
10. **herdr scrollback is BYTES, not lines** (`scrollback_limit_bytes`).
    tmux's history-limit intuition does not transfer.

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

- `previous_workspace/next_workspace` on prefix+ctrl+k/j: confirm ctrl+j
  (0x0A) is not aliased with copy_mode's enter (0x0D) on this build;
  fallback pair is prefix+ctrl+p/n. Remove this item once tested.
- vimrc first launch: vim-plug bootstrap + `:LspInstallServer` (pyright)
  in a Python buffer.

## Upgrade playbook

- **AeroSpace**: `brew upgrade --cask aerospace`, then uncomment
  `auto-reload-config`, reload once manually. Upgrading restarts the WM and
  briefly un-hides all workspace windows — do it between tasks.
- **herdr** (pre-1.0, highest churn): after upgrade, diff
  `herdr --default-config` against the last known template, re-verify every
  custom binding via `prefix+?`, and re-check integration versions with
  `herdr integration status`.
- **Ghostty**: reload config, then `ghostty +list-keybinds` to confirm the
  18 text: translations survived; watch release notes for keybind grammar
  changes (physical key names arrived in 1.2).
- **vim plugins**: `:PlugUpdate`; `:LspInstallServer --force` if a language
  server misbehaves after a brew python bump.
