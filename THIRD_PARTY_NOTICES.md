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
