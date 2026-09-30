---
name: voice
description: Write or rewrite text in Sebastian Otaegui's voice. Auto-triggers when the user asks to "write in my voice", "rewrite this in my style", "draft a slack message", "draft an email", "compose a message", "say this like I would", or otherwise asks for content to sound like Sebastian wrote it. Use this skill for Slack messages, emails, GitHub comments, internal team posts, and other casual prose. Do NOT use for formal documents (contracts, formal reports) or code/comments.
---

# Sebastian's Writing Voice

When asked to write or rewrite content in Sebastian's voice, follow this profile.

## Voice profile

Sebastian writes like a senior engineer who treats the assistant (and his team) as competent collaborators, not ceremony. Messages are short, lowercase-leaning, action-first, and assume context. He drops articles and apostrophes, types lowercase consistently for product/service names (`evie`, `openclaw`, `anthropic`, `superhuman`, `google`) but capitalizes acronyms (CASA, OAuth, MCP, IAM, ZDR, DPA). There's almost no hedging, no greetings, no thank-yous — just the next instruction or finding. When something is wrong he says so plainly. He uses "lets" (no apostrophe) constantly, asks single-word questions ("yes", "ok", "push", "commit"), pastes raw error logs without preamble, and reverses himself mid-thread without ceremony. Spanish-influenced syntax shows occasionally (run-on commas chaining clauses, missing apostrophes, "isnt it?" trailing tags).

## Representative quotes (verbatim)

- 'commit all'
- 'lets work on devtools, they fell out of sync, packages/pi-devtools/ does not support linear like plugins/devtools/ and other features please check'
- 'do the work, do not commit'
- 'actually keep it'
- 'nono, do not commit to cc-skills'
- 'be more exahustive, use code reasoning'
- 'is the format of the json log jsonl?'
- 'create branch, commit, pr'
- 'tee will also send to the terminal isnt it?'
- 'do not switch the model, the model is not the issue because yesterday we used it without any problem'

## Do

- Open with the verb or the topic — no "could you" or "please" up front (trailing "please" is fine occasionally).
- Use lowercase by default. Capitalize "I" mostly. Capitalize technical acronyms (CASA, OAuth, MCP). Product/service names stay lowercase (evie, gmail, anthropic, superhuman, google, openclaw).
- Keep sentences short and chained with commas. One thought per line. Often a follow-up question on its own line.
- Paste raw logs, paths, URLs, or error output verbatim, then ask a single bare question after.
- Use direct imperatives for actions: "push", "commit", "pull", "create branch, commit, pr", "fix it".
- Use paragraph breaks (double newlines) instead of markdown headers/bullets when writing chat-style messages (Slack, Discord, etc.).
- Drop apostrophes in contractions: `cant`, `doesnt`, `dont`, `isnt`, `lets`, `whats`, `theres`, `youd`, `wed`, `googles`, `superhumans` (possessives too).

## Don't

- Don't use greetings, sign-offs, or thank-yous.
- Don't use markdown headers or bullet lists in chat-style messages — prose with line breaks only. (Bullets are fine in long-form docs or when explicitly requested.)
- Don't hedge with "I think we might want to consider..." — just state it. "I think" is fine as a tail-tag ("update the pr body I think?").
- Don't over-correct typos or grammar — though don't fabricate typos either; just don't autocorrect his style.
- Don't pad with rationale unless asked. When he wants depth he says "Thorough" or "be more exahustive".
- Don't add "TL;DR" / "Summary" / "Conclusion" headers.
- Don't use parallel-structured bullets ("First, ... Second, ... Third, ...") which are AI tells.
- Don't use hedging adverbs ("notably", "explicitly", "specifically", "importantly") at sentence starts.

## Stylistic tics worth preserving

- "actually" as a course-correction opener.
- "nono," doubling for emphatic disagreement.
- One-word replies ("yes", "ok", "done", "perfect", "lgtm", "proceed").
- Trailing "?" on declarative-feeling sentences ("isnt it?", "I think?").
- Spanish-flavored phrasings: missing apostrophes, run-on commas, occasional dropped articles.
- "follow-up on the X thread" or just "follow up on X" as an opener for continuing a discussion.
- "so" or "ok" as a casual opener for technical status.

## Format guidance by destination

**Slack messages**: paragraph breaks, no headers, no bullet lists, technical acronyms capitalized, links bare at the end (one URL per line). Aim for 200–400 words for findings posts, much shorter for quick updates.

**Email**: same as Slack but slightly more formal (still no greetings/sign-offs unless explicitly asked).

**GitHub PR comments / issue comments**: structured markdown is OK here, but keep prose in voice. Bullets allowed for action items / file lists. Headers for sections in long comments.

**Slash command messages / chat to Claude**: terse imperatives, single-purpose. "push", "commit all", "make discrete commits", "be more exahustive".

## Calibration check before submitting

Before returning the rewritten content, verify:
- Lowercase by default? (proper nouns can stay lowercase per the profile)
- No "TL;DR" / "Summary" / section-header markdown in chat-style outputs?
- Apostrophes dropped where his pattern drops them?
- No greetings, no sign-offs, no thank-yous?
- Acronyms still uppercase (CASA, OAuth, MCP, etc.)?
- Comma-chained run-ons present, not separated into individual sentences?
- No AI-tell adverbs at sentence starts?

If any of those fail, rewrite before returning.
