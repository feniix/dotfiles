# Gotcha Mining Checklist

Systematic process for discovering non-obvious operational knowledge hidden in source code. Each category includes what to look for, Grep patterns, and examples from the dding-dong project.

## Mining Process

1. Identify the project's core modules (entry points, config, platform abstraction)
2. For each module, scan using the category checklists below
3. For each finding, ask: "Is this already in CLAUDE.md?" and "Would an agent get this wrong without being told?"
4. Document findings with source file and line reference

## Category 1: Timing & Ordering Constraints

Hidden time budgets, sequencing requirements, and race conditions.

**Grep patterns:**
```
setTimeout|setInterval|deadline|timeout|budget
Promise\.race|Promise\.allSettled
```

**What to look for:**
- Nested timeouts that create a timing budget (outer timeout minus inner timeout = remaining budget)
- Operations that must complete within a time window
- Specific ordering of async operations

**dding-dong example:**
- `hooks/_common.mjs`: hooks.json 5s timeout → internal safety timer 4s → stdin read 2s → only ~2s left for notify()
- This timing *budget* is invisible from any single line of code — it emerges from the interaction of three separate timeouts

## Category 2: Implicit Semantics

Values that mean something unexpected, special-cased behavior.

**Grep patterns:**
```
=== null|== null|delete .+\[|delete result
deepMerge|Object\.assign|structuredClone
```

**What to look for:**
- `null` used as a sentinel (deletion, reset, bypass)
- Merge functions with special handling for specific values
- Default values that override or get overridden unexpectedly

**dding-dong example:**
- `config.mjs:157`: `null` in deepMerge triggers `delete result[key]` — setting `{ "sound": null }` doesn't set sound to null, it *removes* the sound key entirely
- Trap: a developer trying to "clear" a config value with null accidentally deletes the entire subtree

## Category 3: Platform Detection Gotchas

Cases where platform detection behaves non-obviously.

**Grep patterns:**
```
process\.platform|os\.platform|/proc/version
wsl|microsoft|darwin|win32
```

**What to look for:**
- WSL reporting as "linux" in `process.platform`
- Platform-specific paths or commands that differ from expectations
- Detection methods that use file contents instead of standard APIs

**dding-dong example:**
- `platform.mjs:14`: WSL detected via `/proc/version` containing "microsoft" (case-insensitive), because `process.platform` returns `"linux"` on WSL
- Without this gotcha, an agent would treat WSL as standard Linux and use wrong audio/notification tools

## Category 4: Mandatory Response Contracts

Entry points that MUST produce specific output or the system blocks.

**Grep patterns:**
```
stdout\.write|process\.stdout|respond|response
MUST|must write|must respond|required.*output
```

**What to look for:**
- Hook handlers that must write to stdout (blocking callers await the response)
- API endpoints with mandatory response shapes
- IPC protocols requiring acknowledgment

**dding-dong example:**
- `hooks/_common.mjs`: stop hook MUST write `{}` to stdout — Claude Code waits for this response. Missing it halts execution
- Safety net: `uncaughtException` handler writes the response before exiting, ensuring Claude never blocks

## Category 5: Error Exit Policies

Non-standard error handling where errors are intentionally swallowed.

**Grep patterns:**
```
catch.*exit\(0\)|catch.*\{\s*\}|process\.exit\(0\)
// ignore|// silent|// swallow
```

**What to look for:**
- `exit(0)` in catch blocks (errors intentionally don't propagate)
- Empty catch blocks with comments explaining why
- Design decisions where failure of a subsystem must not affect the parent

**dding-dong example:**
- All hook catch blocks call `process.exit(0)` — notification failure must never block Claude Code
- `detached: true` + `.unref()` pattern: audio processes are fire-and-forget to meet the 5s hook timeout

## Category 6: Hidden Configuration Rules

Configuration behaviors that aren't apparent from the config schema alone.

**Grep patterns:**
```
_meta|\.meta|internal|private|reserved
diff.only|override|merge.*before|merge.*after
backup|restore|rollback
```

**What to look for:**
- Fields extracted/re-attached around merge operations (isolation patterns)
- Config scopes that store partial data (diffs vs snapshots)
- Automatic backup/restore mechanisms

**dding-dong example:**
- `config.mjs:178-184,219`: `_meta` field extracted before deepMerge, re-attached after — prevents project config from overwriting global setup metadata
- `config.mjs:227`: Project/Local scopes store diff-only overrides, not full config snapshots
- `config.mjs:250-256`: Round-trip JSON.parse validation after save; on failure, auto-restores from backup

## Category 7: Cooldown & Deduplication

Rate limiting or deduplication logic with non-obvious scope.

**Grep patterns:**
```
cooldown|throttle|debounce|rate.limit
lastNotified|lastRun|lastExec|timestamp
```

**What to look for:**
- Cooldowns that are global vs per-event vs per-source
- Timestamps that prevent expected operations from firing
- Edge cases where rapid successive events suppress each other

**dding-dong example:**
- `config.mjs:43`: Single global `cooldown_seconds: 3` with one `lastNotifiedAt` timestamp
- Gotcha: a `task.complete` notification suppresses a `session.start` notification that follows within 3 seconds — the cooldown is global, not per-event-type

## Category 8: Reserved / Unimplemented Features

Defined interfaces with no actual implementation or trigger.

**Grep patterns:**
```
TODO|FIXME|HACK|XXX|DEPRECATED
reserved|future|placeholder|not.yet|unimplemented
```

**What to look for:**
- Event types defined in config/messages but with no corresponding hook
- API routes declared but not wired to handlers
- Feature flags that are always false

**dding-dong example:**
- `task.error` event: defined in `DEFAULT_CONFIG.sound.events`, has messages in `messages.mjs`, but no hook in `hooks.json` triggers it
- Only testable via CLI `test` mode. Reserved for future Claude Code error hook support

## Mining Summary Template

After scanning, organize findings in this format:

```markdown
## Discovered Gotchas

| # | Category | Description | Source | In CLAUDE.md? |
|---|----------|-------------|--------|---------------|
| 1 | Timing | 5s→4s→2s budget leaves ~2s for notify() | _common.mjs:21,52 | No → Add |
| 2 | Implicit | null = key deletion in deepMerge | config.mjs:157 | No → Add |
| 3 | Platform | WSL detected via /proc/version, not process.platform | platform.mjs:14 | No → Add |
| ... | ... | ... | ... | ... |
```

This table drives Step 3 (optimization) of the skill workflow.
