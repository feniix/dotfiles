# Discoverability Filter Methodology

Based on Addy Osmani's [agents-md](https://addyosmani.com/blog/agents-md/) blog post and supporting research.

## Core Principle

> "Can the agent find this by reading the code? If yes, delete it."

CLAUDE.md should contain only information that is:
1. **Non-discoverable** — cannot be found by reading source code, running `ls`, or following imports
2. **Operationally significant** — changes how the agent executes tasks
3. **Impossible to guess** — not inferable from standard conventions

## The 10-Second Rule

For each line in CLAUDE.md, ask: "Can an agent discover this using Glob, Grep, or Read within 10 seconds?"

- **Yes** → Mark as `discoverable` → Remove
- **No, but the info is correct** → Mark as `operational` → Keep
- **Partially** — the fact exists in code but the *implication* doesn't → Mark as `verbose` → Compress

## Category Classification

### Discoverable (Remove)

Information agents find automatically through standard exploration:

| Pattern | How Agent Discovers It |
|---------|----------------------|
| Directory structure trees | `ls -la`, `Glob **/*` |
| Data flow diagrams | Follow `import`/`require` chains |
| Tech stack descriptions | `package.json`, file extensions, imports |
| "X uses Y" explanations | Import statements are self-documenting |
| File-by-file descriptions | Reading the file itself is faster than reading about it |
| Architecture overviews | Module boundaries visible from directory + imports |
| Event/type enumerations | Grep for type definitions, enum values |
| Config path listings | Constants in config modules |
| Standard build steps | `package.json` scripts, `Makefile` targets |
| Dependency relationships | `import` graph traversal |

### Operational (Keep)

Information that requires human experience to know:

| Pattern | Why Not Discoverable |
|---------|---------------------|
| Timing constraints | Timeout values exist in code but their *budget allocation* across stages isn't obvious |
| Mandatory response contracts | Code shows `stdout.write()` but not *why* it's critical (e.g., blocks Claude) |
| Null semantics in merge | `delete result[key]` exists but the design choice that "null = deletion" is a gotcha |
| Error exit policies | `exit(0)` in catch blocks exists but the rule "never block Claude" is a design decision |
| Platform detection gotchas | Code checks `/proc/version` but the fact that `process.platform === "linux"` on WSL is a trap |
| Cooldown scope decisions | Single timestamp exists but "global, not per-event" is a design choice |
| Commit ordering conventions | No code enforces "feature commit first, then version bump" |
| Non-standard tool choices | `uv` vs `pip`, `bun` vs `npm` — convention, not discoverable |
| Reserved/unimplemented features | Defined in config but no hook exists — requires cross-referencing multiple files |

### Verbose (Compress)

Operational knowledge expressed in too many lines:

**Indicators:**
- Config merge explanation spanning 10+ lines → Compress to 1-line summary with stage order
- Cross-platform table with obvious entries → Keep only non-obvious platforms (e.g., WSL)
- Multi-paragraph explanations of backup behavior → Compress to "max N, auto-rotated"

**Compression Techniques:**
- **Table → bullet**: Convert multi-row tables to single-line `key: value` bullets
- **Paragraph → condition-result**: "When X happens, Y occurs" in one line
- **Enumeration → range**: "5 event types: ..." → Only mention the one with a caveat
- **Section → subsection**: Promote to parent section's bullet point

## Efficiency Data

Research findings supporting this methodology:

| Study | Finding |
|-------|---------|
| Lulla et al. (2026) | Human-authored AGENTS.md reduced wall-clock runtime by **28.64%** and token consumption by **16.58%** |
| ETH Zurich | LLM-generated context files **reduced** task success by 2-3% while **increasing** cost by 20%+ |
| Arize AI | Automated refinement of agent instructions achieved +5.19% accuracy improvement |

Key insight: **Adding information can hurt performance.** Redundant context forces agents to process the same information twice, consuming tokens and increasing latency without improving accuracy.

## The Pink Elephant Problem

Mentioning a deprecated pattern anchors the model toward it. If CLAUDE.md says "Don't use the old auth module," the agent becomes more likely to reference it. Instead:
- Delete mentions of deprecated code entirely
- If the agent encounters it, it will ask or investigate — which is the correct behavior

## Maintenance Philosophy

> "AGENTS.md is a living list of codebase smells you haven't fixed yet, not a permanent configuration."

Implications:
- When a gotcha is fixed in code, remove it from CLAUDE.md
- Periodically audit: "Is this still true? Is this still non-discoverable?"
- Prefer fixing the code over documenting the gotcha
- Start nearly empty, add only what causes agent confusion

## Section Structure for Optimized CLAUDE.md

Recommended sections (in order):

1. **Project description** — 1-2 lines, what the project does + key constraint (e.g., "zero dependencies")
2. **Development Commands** — Scripts and their purposes (not discoverable from code alone)
3. **Design Rules** — Non-negotiable constraints that cause failures if violated
4. **Gotchas & Landmines** — Categorized by domain (timing, config, platform, etc.)
5. **Conventions** — Non-standard patterns specific to this project
6. **Version/Release** — Workflow that can't be inferred from code
7. **Testing** — Framework choice and priorities (especially if no tests exist yet)
