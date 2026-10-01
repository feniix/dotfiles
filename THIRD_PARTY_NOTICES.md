# Third-party notices

The root MIT license applies to code authored for this repository. It does not
relicense third-party material.

## Anthropic skills

The following skills under `agents/skills/` are © Anthropic, PBC. They are not
covered by this repository's MIT license, and each keeps the `LICENSE.txt` it
shipped with.

### Proprietary (all rights reserved)

- `docx`
- `pdf`
- `pptx`
- `xlsx`

These are from [`anthropics/skills`](https://github.com/anthropics/skills).
Their use is governed by your agreement with Anthropic, or failing that by
Anthropic's [Consumer Terms](https://www.anthropic.com/legal/consumer-terms) or
[Commercial Terms](https://www.anthropic.com/legal/commercial-terms), as stated
in each skill's `LICENSE.txt`. They are kept here only so the author's own
agent tools can load them. No license to use, copy, modify or redistribute them
is granted by this repository.

### Apache License 2.0

- `claude-api`, `mcp-builder`, `internal-comms` and `webapp-testing`, from
  [`anthropics/skills`](https://github.com/anthropics/skills).
- `frontend-design` and `skill-creator`, vendored from
  [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official)
  at the commit pinned in `agents/skills.lock`.

The full license text is in each skill's `LICENSE.txt`.

## Vendored sources

These are copied into `agents/skills/` by `scripts/agents/vendor_skills.sh`
from the sources declared in `agents/skills.vendor`, at the commits pinned in
`agents/skills.lock`. They keep their upstream licenses. Anthropic's
`frontend-design` and `skill-creator` are vendored the same way; see the
Anthropic section above.

### Matt Pocock's skills (MIT)

- Upstream: [`mattpocock/skills`](https://github.com/mattpocock/skills), tag
  `v1.2.3`, pinned at commit `6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`
- License: MIT, `Copyright (c) 2026 Matt Pocock`
- Full text: [`LICENSES/MIT-mattpocock-skills.txt`](LICENSES/MIT-mattpocock-skills.txt)
- Skills: `ask-matt`, `claude-handoff`, `codebase-design`, `diagnosing-bugs`,
  `domain-modeling`, `git-guardrails-claude-code`, `grill-me`,
  `grill-with-docs`, `grilling`, `handoff`, `implement`,
  `improve-codebase-architecture`, `loop-me`, `migrate-to-shoehorn`,
  `mp-code-review` (upstream `code-review`, renamed), `prototype`, `research`,
  `resolving-merge-conflicts`, `scaffold-exercises`,
  `setup-matt-pocock-skills`, `setup-pre-commit`, `setup-ts-deep-modules`,
  `tdd`, `to-questionnaire`, `to-spec`, `to-tickets`, `triage`, `wait-what`,
  `wayfinder`, `wizard`, `writing-beats`, `writing-for-agents`,
  `writing-fragments`, `writing-shape`
- Local changes: `mp-code-review` is renamed, with references rewritten, and
  `git-guardrails-claude-code/scripts/block-dangerous-git.sh` is replaced by
  the patched hook in `scripts/agents/vendor_skills.sh`.

### TypeSafe (MIT)

- Upstream: [`typesafe-ai/skills`](https://github.com/typesafe-ai/skills),
  pinned at commit `65a39f393687675ce170e6094757de20370365b9`
- License: MIT, `Copyright (c) 2026 TypeSafe AI`
- Full text: `agents/skills/typesafe-ai/LICENSE`, shipped with the skill
- Skills: `typesafe-ai`

### i-have-adhd (MIT)

- Upstream: [`ayghri/i-have-adhd`](https://github.com/ayghri/i-have-adhd),
  pinned at commit `839872f9d1cd634fed642b4589ce7226199cc15f`
- License: MIT, `Copyright (c) 2026 Ayoub Ghriss`
- Full text: [`LICENSES/MIT-ayghri-i-have-adhd.txt`](LICENSES/MIT-ayghri-i-have-adhd.txt)
- Skills: `i-have-adhd`

## Copied (not vendored) sources

These were copied into `agents/skills/` by hand, so no commit is pinned. Each
upstream repo was checked on 2026-10-01 and the commit given is its default
branch at that time, not necessarily the one the copy came from.

### Entire skills (MIT)

- Upstream: [`entireio/skills`](https://github.com/entireio/skills), checked
  at `fe5266f76d846222c73b080ce39fd803dd705198` (`skills/<name>/`)
- License: MIT, `Copyright (c) 2026 Entire`
- Full text: [`LICENSES/MIT-entireio-skills.txt`](LICENSES/MIT-entireio-skills.txt)
- Skills: `address-findings`, `explain`, `recall`, `replay`, `review`,
  `session-crosslink`, `session-handoff`, `session-to-skill`, `teach`,
  `using-entire`, `what-happened`

### Hindsight skills (MIT)

- Upstream: [`vectorize-io/hindsight`](https://github.com/vectorize-io/hindsight),
  checked at `ec39e10900c6a971f1a73cd37402228d5cccaa25`
- License: MIT, `Copyright (c) 2025 Vectorize AI, Inc.`
- Full text: [`LICENSES/MIT-vectorize-io-hindsight.txt`](LICENSES/MIT-vectorize-io-hindsight.txt)
- Skills: `hindsight-architect`, `hindsight-cloud`, `hindsight-docs`,
  `hindsight-self-hosted` (from `skills/<name>/`) and `hindsight-coding-agent`
  (from `hindsight-integrations/coding-agents/skill/`)
- Local changes: `hindsight-cloud` and `hindsight-self-hosted` carry local
  edits (commit `c1e94c9`).

### agent-browser (Apache License 2.0)

- Upstream: [`vercel-labs/agent-browser`](https://github.com/vercel-labs/agent-browser),
  checked at `d01253d9db28d75080e36da3c1c31ef89454731e` (`skills/agent-browser/`)
- License: Apache License 2.0, `Copyright 2025 Vercel Inc.`; the upstream repo
  has no `NOTICE` file
- Full text: [`LICENSES/Apache-2.0-vercel-labs-agent-browser.txt`](LICENSES/Apache-2.0-vercel-labs-agent-browser.txt)
- Skills: `agent-browser`

### gh-stack (MIT)

- Upstream: [`github/gh-stack`](https://github.com/github/gh-stack), checked
  at `2bd699a544a09cb5c45a013d03416e0894b0454e` (`skills/gh-stack/`)
- License: MIT, `Copyright GitHub, Inc.`
- Full text: [`LICENSES/MIT-gh-stack.txt`](LICENSES/MIT-gh-stack.txt)
- Skills: `gh-stack`

## Unknown source and license

- `herdr`
- `performance-optimization`
- `python-refactor`

These do not appear to have been written for this repository, but where
they came from and under what license is not known. Until the source and license are identified
and recorded here, no license to them is granted by this repository; they
should be identified or removed.
