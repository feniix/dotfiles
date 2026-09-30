# Float time-entry prose

Use this house style whenever synthesizing notes from git activity.

## Rules

- Lead with a concrete workstream, feature, or issue: `Console shell serving (EVP-345): ...` or `EVP-368: ...`.
- Group commits into coherent outcomes. Do not narrate commit chronology or repeat prefixes such as `feat`, `fix`, and `test`.
- Prefer dense, specific technical prose: name the behavior, failure mode, boundary, or mechanism that changed.
- Use compact colon-led bullets with comma- or semicolon-separated outcomes when summarizing several workstreams.
- For one substantial end-to-end initiative, use a heading plus sub-bullets covering scope, implementation, surfaces, and review hardening.
- For a discrete high-impact fix, a short narrative may state the failure, root cause, correction, and verification.
- Preserve issue IDs and established project vocabulary when present. Never invent them.
- Mention tests, review fixes, or operational verification when they materially establish correctness; include concrete evidence such as counts or environments when available.
- Avoid generic framing such as “worked on,” “delivered improvements,” or “various fixes.” Avoid turning precise commit language into vague product prose.
- Stay under Float's 1500-character limit. When space is tight, keep issue IDs, shipped behavior, risky edge cases, and verification; drop routine scaffolding and low-signal refactors first.

## Examples

- Console shell serving (EVP-345): content-derived ETag for the SPA shell, shell fallback for unknown navigations, legible not-found surface, stale-tab announce strip, one shell load per process, throttled version poll off-dashboard
- Monitoring page: host metric fixtures, metric parsing, on-demand host metrics API
- GitHub ingest (EVP-338): scoped the dead-repo verdict to the repository surface, skip one unreachable PR instead of retiring the repo, keep the replay floor and log the skip
- Backfill pacing (EVP-339): pace iterations that persist nothing, move the sweep verdict to where the failure is handled, share worker fixture scaffolding
- Slack cursor escalation (EVP-241/242): count and retry cursor-write failures, escalate sustained failure once per episode, surface cursor-write state in stream status, terminate the catch-up sweep after one fixed-window pass
- Landing recovery (EVP-270/271): deleted dead files, symbols and re-exports; un-exported file-local symbols across packages; entities reduced to a migration holder
- Push retry and engine failures: ADR-0094 time-and-class-aware push retry; correlate failed engine ops to episodes and stop reporting failures whose episodes recovered
- OpenClaw client: accept string-shaped message content, silence the injected heartbeat-poll prompt, cover envelope and sentinel edges
- Sync status display (EVP-331): source-led SOURCE cells, full-source hover titles, blank discovery labels treated as absent

GitHub activity integration (EVP-316) — end to end:

- PRD-055 resolved all six open questions; implementation plan + doc-review pass
- New integration-github package: App auth (JWT, discovery, token cache), installation confirmation gate, live ingest provider + daemon registration, digest consumer with commit claiming and the withdrawal contract
- Bounded backfill sweep and a per-repo purge command in the CLI
- Web: GitHub integration route and page — status, confirm, manifest wizard, instructions, installations list
- Hardening from review: rate-limited 403s treated as transient, same-second watermark loss window closed, per-repo tick failures isolated, stranded installers converged, pull lifecycle events deduped, repos granted after first enumeration backfilled

Memory push retry rework:

- Persisted failure class, reason, and retry-timing columns
- Time-aware and class-aware give-up rule; transients back off and recover
- Unknown-fate dead-letters given their own failure class
- Coverage for outage survival, recovery, and the persisted reason

Docs: dev-workflow, quickstart, product, glossary, testing rewritten in ASD-STE100 style; STE scope codified; ADR-0091 accepted

EVP-368: fixed the retrieval eval's hindsight leg, which passed an empty payload builder registry, so every corpus document failed at the push stage and the gate could not produce a delta. The eval now owns its builders: the production ones parse production episode keys and cannot handle a synthetic eval key, and calendar owns no integration package at all. Verified against a local engine: 399/399 documents pushed with zero failures, and a second run correctly skipped the warm bank.

EVP-367: fixed the hindsight upgrade rescue, which left the daemon outside launchd's domain, making it worse than no rescue. Reused the wait-then-bootstrap sequence to avoid the bootout race, branched on the real bootstrap result instead of always reporting success, and widened the health probe from 30s to 150s to allow for a cold start. Verified on a VM with an injected failure.

Docs: documented the subscription-provider local engine recipe (the device-code path needs a placeholder LLM key, and the Batch API is unsupported) and the operator-settable reasoning-effort variables.
