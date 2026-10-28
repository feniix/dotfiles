---
name: voice
description: Write or rewrite messages in Sebastian Otaegui's voice, including Slack, email, GitHub comments, and internal posts. Use for "write in my voice", "rewrite this in my style", or drafting personal messages for Sebastian. Not for answering him as the assistant, sending messages, formal reports/contracts, or code/comments.
---

# Sebastian's writing voice

Write like a technically fluent colleague: direct, conversational, concrete, and comfortable assuming shared context. Concise does not mean cold. Instructions to an agent are only one register, not the template for everything Sebastian says to people.

## First choose the situation

Use the supplied draft, recipient, thread, and purpose to choose the register. If those are clear, draft directly. Ask only when the missing context would materially change the message. Return the draft without a preamble or style explanation unless requested.

- **Quick reply / ongoing DM:** fragments and short acknowledgments are natural. Answer the actual question; do not recap the whole thread. A greeting usually adds nothing mid-conversation.
- **Human request / coordination:** direct questions such as "can you", "can we", "do you want to", or "got a minute?" are normal. Brief context, the ask, and any real timing constraint. Do not turn a collaborative request into an order.
- **Technical discussion / debugging:** observation first, relevant evidence or constraint, then the hypothesis or question. Distinguish what he tried from what he suspects. Add the reason when it helps the recipient decide or troubleshoot.
- **Status / findings / handoff:** lead with what changed or where things stand; include the remaining gap and next action or specific question. A few short paragraphs often suffice. Longer findings are fine when the facts need them; there is no 200–400-word target.
- **Social / personal / supportive:** warmth, enthusiasm, jokes, greetings, thanks, and apologies are part of the voice. Match the relationship and moment. Do not flatten these into technical imperatives or invent personal details.
- **Agent instructions:** terse verbs and explicit boundaries fit here: "check the diff, do not commit yet". Keep this register separate from messages to coworkers.

## Stable tendencies

### Rhythm and phrasing

- Lowercase-leaning openings, short clauses, conversational connectors: "so", "also", "but", "I mean", "actually", "btw", "for context". Use them when they carry the thought, not as a checklist.
- He often develops a thought through short follow-ups. In one draft, use short paragraphs to keep that rhythm; do not pretend to send a burst of separate messages.
- Casual commas and fragments fit. Periods and complete sentences also fit. Never manufacture run-ons, dropped articles, typos, or an accent.
- "I am", "I have", "I think", "I do not", "I will", and "let me" are natural constructions. Do not compress everything into contractions.
- Preserve informal spellings such as "lets", "dont", or "cant" when they fit the supplied draft. Apostrophized contractions occur too; do not mechanically strip apostrophes, especially in careful or personal messages.
- Product names often stay lowercase in casual prose. Acronym casing varies in actual chat; prefer readable conventional casing (API, MCP, EKS) without altering identifiers, commands, paths, URLs, or quoted text.

### Stance and relationships

- Be direct about an observed failure, but keep genuine uncertainty: "I think", "maybe", "probably", "it looks like", "I am not sure", "I have not tried it". These are meaningful, including at the start of a sentence, not filler to delete.
- Ask concrete questions instead of adding generic calls for feedback. A constraint followed by "what if..." or "would that work?" is a natural way to propose something.
- Correct course without ceremony: "actually", "I meant", or a brief "no" plus the correction. "nono" fits an emphatic casual correction but is not a mandatory signature.
- Allow brief enthusiasm and acknowledgment: "cool", "sounds good", "awesome", "lol", "haha". Occasional emoji or emphasis can fit social exchanges; do not decorate every draft or inject jokes into serious messages.
- "hey", "hi", "good morning", "thanks", and "sorry" are available when the situation calls for them. Skip canned pleasantries and formal sign-offs by default in chat, not human warmth.
- Blunt criticism and profanity can occur with familiar people. Do not introduce profanity, hostility, or extra certainty merely to make a draft sound less polished.

## Format and destination

**Slack / Discord:** prose and paragraph breaks by default. Short replies may be a single line. Links can follow the relevant claim or stand alone. Use code blocks for exact technical evidence when supplied. Lists and headings are exceptions for genuinely structured material or an explicit request, not forbidden syntax. Avoid boilerplate "TL;DR", "Summary", and "Conclusion" wrappers.

**Email:** carry over directness and concrete asks, but match recipient and stakes. A greeting, sign-off, normal capitalization, or more context can be appropriate. This is an extrapolation from Slack, not a separately measured email profile.

**GitHub comments:** keep prose direct; use bullets for action items and file lists, headings for substantial reviews, and exact identifiers. Formatting should make the work reviewable. GitHub-specific conventions are destination guidance, not conclusions from a GitHub corpus.

## Before returning

- Does this fit the audience and purpose, rather than treating every recipient as an agent?
- Are the facts, uncertainty, ownership, timing, and commitments unchanged? Do not invent work completed, approval, promises, or rationale.
- Is it as short as the content allows without making the recipient reconstruct missing context?
- Does it sound conversational without forced mistakes, missing punctuation, or a pile of signature phrases?
- Did useful warmth or a real question survive the rewrite?

For situation-specific calibration, read [examples.md](references/examples.md). Examples are synthetic; never pull private conversation details into a draft merely to imitate the voice. This skill drafts text; it does not authorize sending it.

## Evidence limits

This profile draws on a broad sample of Slack DMs and public-channel messages. Private-channel coverage was sparse; email and GitHub guidance is an adaptation, not separately measured. Messages may include pasted or AI-assisted text, so treat the patterns as tendencies, not rules. Prefer the user’s corrections and recent, audience-matched examples.
