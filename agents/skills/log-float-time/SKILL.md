---
name: log-float-time
description: Log or record the user's work time in Float for the Spantree / Evie Platform project through a dedicated agent-browser Chrome profile that holds the user's Float login. Use when the user asks to log Float time, record hours against an Evie Platform task, or submit a day's work to Float. Resolve date, hours, task, and notes; summarize git commits when notes are omitted; require confirmation before the live write; and verify the result afterward.
---

# Log time to Float

Log one time entry through Float's own API, called from a page in a Chrome profile that
agent-browser owns and the user has signed in to once. The user is a **Member**, not an
Account Owner, so there is **no API key** — auth must come from a logged-in page. Never read,
print, return, export, or persist the session token yourself.

This mutates a live timesheet. Confirm before writing; verify after.

## Resolve the entry

- `date` — default **today**. Resolve to `YYYY-MM-DD` in the user's timezone.
  Accept unambiguous forms (`today`, `yesterday`, ISO) directly. **Ask the user to confirm
  any slash-form or incomplete date** — `08/04`, `08/04/2026`, `04/08` — showing the plausible
  readings in ISO. Never silently pick a locale convention. Resolve the date *before* reading
  commits, and continue only once one exact `YYYY-MM-DD` is settled.
- `hours` — default **8**. Float allows at most 24; `0` soft-deletes.
- `task` — default **"Tooling & Internal Platform"**. Must match a live task name exactly.
- `notes` — supplied text, or summarized from that date's git commits.

### Stable coordinates

`people_id` `17853024` · `project_id` `11348463` (Spantree / Evie Platform) · `phase_id` `0`.
These do not change.

### Tasks are NOT stable

Known names as of 2026-09-30: `Product Development`, `Tooling & Internal Platform`,
`Training Material Development`, `Product Management`. **Treat this list and every cached
id as advisory only — always resolve the id from the live task list at write time.**

The helper deliberately holds no task table, because a stale one is what caused the
failure documented under "Gotchas".

## Build the notes

```bash
git -C <repo> log --author="feniix@gmail.com" \
  --since="<date> 00:00:00" --until="<date> 23:59:59" \
  --no-merges --pretty=format:'- %s'
```

Before drafting, **read `references/time-entry-prose.md` completely** and follow its house
style. Treat commit subjects as an index into the day's work: read the relevant commits or
diffs when the subjects are too terse to support concrete technical prose. Never invent an
issue ID, mechanism, outcome, or verification claim.

Group by deliverable, workstream, or issue — not by commit type or chronology. Preserve issue
IDs and project vocabulary. Stay under **1500 characters**, prioritizing shipped behavior,
important hardening, and concrete verification over routine implementation detail.

If there are no commits, stop and ask whether to use empty or supplied notes.

## Confirm before writing

Show the resolved date, hours, task, and the exact notes preview. Ask for explicit
confirmation. Do not open Float or create an entry until the user confirms.

## Browser setup

Every command below runs through this shell prelude. Shell state does not survive between
tool invocations, so **repeat the prelude at the top of every Bash call**, or batch several
steps into one call. The session id is deterministic per worktree, so repeating it reconnects
to the same browser. **Pass `--profile` on every call**, not only on `open`: a call without
it relaunches a different browser and loses the page state.

```bash
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix float)"
ab() { agent-browser --profile "$HOME/.agent-browser-float" "$@"; }
```

- The profile directory `~/.agent-browser-float` holds the Float login. It runs headless by
  default. Do **not** use `--restore` or `state save`; the profile is the only persisted auth,
  and the token itself is never written anywhere by this skill.
- The transient message `Could not configure browser: Failed to connect` on the first `open`
  after a `close` is harmless; the command still succeeds.
- Do not connect to the user's own Chrome (`--auto-connect`, `--cdp`). The dedicated profile
  is the only session this skill uses.

### Sign-in (only when the page is not logged in)

If `ab get url` lands on `/login` after opening the log-time page, the profile has no live
session. Do this:

1. Close the headless browser: `ab close`.
2. Relaunch visibly, passing `--headed` **on every command** for this part:
   `agent-browser --headed --profile "$HOME/.agent-browser-float" open https://spantree.float.com/log-time`
3. Ask the user to sign in by hand in that window with **email and password**. The user does
   not use Google sign-in for Float; never click "Sign in with Google" and never type
   credentials yourself.
4. When the user confirms, `agent-browser --headed --profile ... close`, then continue
   headless with the `ab` prelude. The profile keeps the session across restarts.

## Write

1. Open the page and confirm it is signed in and on the right workspace:
   ```bash
   ab open https://spantree.float.com/log-time && ab wait --load networkidle
   ab get url                                  # must be https://spantree.float.com/log-time, not /login
   ab snapshot -i | grep -i -E 'spantree|next week'
   ```
   **The visible workspace must be `Spantree`.** The URL host is the reliable signal; the
   snapshot grep only confirms the page rendered (entry rows also contain the word). If it is another workspace, stop and ask.
   Never submit from the wrong account. Do not inspect cookies, storage, or profile files.
2. Inject the helper. It installs the passive auth hook and exposes `floatPrimeAuth()`,
   `floatListTasks()`, `floatListEntries()`, `floatLogTime()`, and `floatUpdateTime()` on
   `window`; they persist across `eval` calls for the life of the page.
   ```bash
   ab eval --stdin < ~/.claude/skills/log-float-time/float-log-time.js
   ```
3. **Prime auth.** Float renders an adjacent week from data it already holds, so a single
   arrow click often sends nothing; the helper steps the week forward until a `/svc/api3/`
   request actually fires, then restores the week it started on.
   ```bash
   printf 'floatPrimeAuth()' | ab eval --stdin
   ```
   Success is `{ ok: true }`. `ok: false` with `api3Seen: 0` means no request fired at all —
   re-check step 1. Do not obtain or display the token.
4. **Duplicate check.** `eval` awaits a returned promise but rejects top-level `await`, so wrap
   calls in an async IIFE and return only the fields you need (raw bodies get truncated):
   ```bash
   cat <<'EOF' | ab eval --stdin
   (async () => {
     const r = await floatListEntries("<date>");
     return { status: r.status, ok: r.ok,
       entries: r.entries.map(e => ({ id: e.logged_time_id, date: e.date, hours: e.hours,
         task: e.task_name, noteLength: e.noteLength })) };
   })()
   EOF
   ```
   If an entry with the same date, hours, project, task, and notes already exists, report
   success without writing again. If the date has any other logged time or an ambiguous
   block, describe it and ask the user before adding a second entry.
5. **Confirm the task is live:**
   ```bash
   cat <<'EOF' | ab eval --stdin
   (async () => { const r = await floatListTasks(); return { status: r.status, tasks: r.tasks }; })()
   EOF
   ```
   `floatLogTime` repeats this check and refuses an unknown or stale task, but look at the
   list yourself so a rename surfaces to the user rather than as a thrown error.
6. Write. Emit the notes as a **JSON string literal** (a valid JS string literal), never a
   template literal: a backtick or `${` in the prose would break or interpolate the script.
   ```bash
   cat <<'EOF' | ab eval --stdin
   (async () => {
     const r = await floatLogTime({ date: "<date>", hours: <hours>,
       task: "<exact live name>", notes: "<JSON-escaped notes>" });
     return { status: r.status, ok: r.ok, task: r.task, noteLength: r.noteLength };
   })()
   EOF
   ```
   Success is `{ ok: true }` with a 2xx status.

**Never interpret a lost response, truncated output, or timeout as permission to retry.**
Re-read the date with `floatListEntries` and confirm the entry is absent before writing again.

## Verify and report

Re-read the saved entry with the step-4 listing and confirm date, hours, project, task name,
and note length. Prefer this API read-back over opening the block in the UI — it cannot
mutate anything. If a dialog does open, close it with `Cancel`, never `Update`.

Report the date, hours, task, and note length. Finish with `ab close`.

## Gotchas

- **Do NOT drive the UI by clicking or filling.** The task picker is a filter-select and Notes
  is a Slate editor that intercepts stray keystrokes; stray clicks also open edit dialogs on
  unrelated entries. The helper bypasses all of it.
- **An unknown `task_meta_id` is NOT rejected.** Float creates a new blank task on the shared
  project and attaches the entry to it. This has happened. It is why every write must resolve
  its id from a live `task-meta` response.
- A stray blank task can be removed with `DELETE /svc/api3/v3/task-meta/<id>` (204).
- To edit an entry use `floatUpdateTime(id, patch)` — the id goes in the **path**;
  `PUT` to the bare collection returns 404. The PUT response shape is inconsistent, so always
  re-read afterward rather than trusting the returned body.
- `GET /svc/api3/v3/logged-time` returns the **whole team's** rows. Filter by `people_id`
  before concluding anything about the user's own timesheet. `floatListEntries` does this.
- Injected `window` functions live only as long as the page. After `ab open`, `ab reload`, or a
  browser relaunch, inject the helper and prime auth again.
- Session-bound: after a fresh login the in-memory token changes; the hook re-captures it on
  the next request (step 3).
- Never print, return, or persist the session token.
