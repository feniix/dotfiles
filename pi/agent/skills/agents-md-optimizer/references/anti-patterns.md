# Anti-Pattern Catalog

Patterns commonly found in CLAUDE.md files that should be removed or compressed.
Each pattern is illustrated with real examples from the dding-dong project optimization (182 → 90 lines, 51% reduction).

## Anti-Pattern #1: Directory Structure Tree

**Why discoverable:** `ls -la`, `Glob **/*`, or `tree` reveals the entire structure instantly.

**Before (63 lines):**
```
### Directory Structure

hooks/                 # Claude Code hook entry points (.mjs)
  hooks.json           # Hook registration manifest
  _common.mjs          # Shared runHook() utility
  notification.mjs     # Notification hook → input.required
  stop.mjs             # Stop hook → task.complete
skills/
  dd-config/
    SKILL.md           # /dding-dong:dd-config - settings management
    scripts/
      config-get.mjs   # Config key reader
      config-set.mjs   # Config key writer
  ...                  # (50+ more lines)
```

**After:** Entire section deleted. Zero lines.

**Exception:** Keep a directory note only if the structure is *counter-intuitive* or violates convention (e.g., "Tests live in `src/` next to source files, not in `test/`").

## Anti-Pattern #2: Data Flow Diagram

**Why discoverable:** Following `import` chains from entry points reveals the exact flow.

**Before (16 lines):**
```
### Data Flow

Hook event → hooks/*.mjs
  → _common.mjs runHook(eventType, options)
    → stdin parse (JSON event)
    → scripts/notify.mjs notify(eventType, context)
      → loadConfig(cwd)
      → config.enabled check
      → isQuietHours() check
      → loadState()
      → isCoolingDown() check
      → playSound() + sendNotification()
      → saveState()
    → optional stdout response
```

**After:** Entire section deleted. Zero lines.

**Exception:** Keep if the flow has a non-obvious *constraint* (e.g., "playSound and sendNotification must run in parallel via Promise.allSettled, never sequential").

## Anti-Pattern #3: Tech Stack / "X uses Y" Descriptions

**Why discoverable:** Import statements, `package.json`, and file extensions are self-documenting.

**Before:**
```
- `player.mjs` uses `spawn` from `node:child_process` for audio playback
- `notifier.mjs` uses `execFileSync` for OS notifications
- All scripts use ESM with `.mjs` extension
```

**After:** Only the non-obvious rule survives:
```
- **ESM only**: All scripts use `.mjs` extension with `import`/`export` syntax.
```

This survives because it's a *project convention* that could be violated (someone might add a `.js` file), not a description of what exists.

## Anti-Pattern #4: Config Path Listings

**Why discoverable:** Config modules export path constants; reading the module reveals all paths.

**Before (24 lines):**
```
### Config & State Files

Config is loaded via 5-stage merge (later stages override earlier):
1. **Default** — hardcoded `DEFAULT_CONFIG` in `config.mjs`
2. **Global** — `~/.config/dding-dong/config.json`
3. **Project** — `.dding-dong/config.json` (team-shared, committed)
4. **Project Local** — `.dding-dong/config.local.json` (personal override, gitignored)
5. **Env vars** — `DDING_DONG_ENABLED`, `DDING_DONG_VOLUME`, ...

Other paths:
- State: `~/.config/dding-dong/.state.json`
- Project sound packs: `.dding-dong/packs/<pack-name>/manifest.json`
- User sound packs: `~/.config/dding-dong/packs/<pack-name>/manifest.json`
- Backup files: `<config-path>.backup.<YYYYMMDD_HHMMSS>` (max 3)

#### `_meta` field convention
The `_meta` field in the global config stores setup metadata:
{ "_meta": { "setupCompleted": true, ... } }
- Stored in: Global config only
- Merge behavior: Isolated from deepMerge
- Usage: doctor skill checks _meta.setupCompleted
```

**After (6 lines in Gotchas > Config):**
```
### Config
- 5-stage merge (later wins): Default ← Global ← Project ← Local ← env vars
- `_meta`: extracted before deepMerge, re-attached after. Global-only. Cannot be polluted by project config
- `null` in deepMerge = key deletion. `{ "sound": null }` → removes the sound key entirely. To disable, use `{ "sound": { "enabled": false } }`
- Project/Local scopes store diff-only overrides (not full snapshots)
- `saveConfig` runs round-trip `JSON.parse` validation. On failure, auto-restores from backup
- Backups: max 3 per config file, oldest auto-deleted
```

The paths are discoverable; the *behaviors* (null deletion, _meta isolation, diff-only, round-trip validation) are not.

## Anti-Pattern #5: Cross-Platform Table

**Why discoverable:** Platform detection code explicitly lists all platforms and their tools.

**Before (9 lines):**
```
### Cross-Platform Strategy

| Platform | Sound Playback | OS Notification |
|----------|---------------|-----------------|
| macOS    | `afplay`      | `osascript`     |
| Linux    | `pw-play` > `paplay` > `ffplay` > `mpv` > `aplay` | `notify-send` |
| WSL      | PowerShell `MediaPlayer` | `wsl-notify-send` > WinRT Toast > terminal bell |
```

**After (3 lines in Gotchas > Platform):**
```
### Platform
- WSL detection: checks `/proc/version` for "microsoft" (case-insensitive). `process.platform` returns `"linux"` even on WSL
- Linux audio priority: `pw-play` > `paplay` > `ffplay` > `mpv` > `aplay`
- WSL notification priority: `wsl-notify-send` > WinRT PowerShell Toast > terminal bell
```

macOS entries are removed (standard, discoverable). WSL detection gotcha is added (non-obvious). Priority orders are kept (require reading implementation to determine order).

## Anti-Pattern #6: Event Type Enumerations

**Why discoverable:** Grep for event definitions in hooks.json or message files reveals all types.

**Before:**
```
### Event Types

`task.complete`, `task.error`*, `input.required`, `session.start`, `session.end`

> *`task.error` is defined in config/messages but has no triggering hook.
```

**After (1 line in Gotchas > Events):**
```
### Events
- `task.error`: defined in config/messages but has no triggering hook. Only testable via CLI test mode.
```

The enumeration is removed; only the *caveat* (no triggering hook) survives because it requires cross-referencing hooks.json with messages.mjs.

## Decision Flowchart

For each section in CLAUDE.md:

```
Is this information discoverable via ls/Glob/Grep/Read?
├── Yes → DELETE the section
├── No → Is it expressed concisely (≤3 lines)?
│   ├── Yes → KEEP as-is
│   └── No → COMPRESS to essential gotcha bullets
└── Partially (fact exists but implication doesn't)
    → REWRITE as a gotcha (state the non-obvious implication)
```
