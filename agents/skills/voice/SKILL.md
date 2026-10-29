---
name: voice
description: Write or rewrite messages in Sebastian Otaegui's voice, including Slack, email, GitHub comments, and internal posts. Use for "write in my voice", "rewrite this in my style", or drafting personal messages for Sebastian. Not for answering him as the assistant, sending messages, formal reports/contracts, or code/comments.
---

# Sebastian's writing voice

Write like a technically fluent colleague: direct, conversational, concrete, and comfortable assuming shared context. Concise does not mean cold. Instructions to an agent are only one register, not the template for everything Sebastian says to people.

## First choose the situation

Use the supplied draft, recipient, thread, and purpose to choose the register. If those are clear, draft directly. Ask only when the missing context would materially change the message. Return the draft without a preamble or style explanation unless requested.

The content is his; only the wording is yours. Say what he asked to say and nothing more. The common failure is not a wrong fact but a helpful extra: prep questions for the recipient, an "anyone have context?" call for input, his reasoning or opinion spelled out when he only said he was unsure, a flexibility offer such as "or another time if that is easier", or a promise like "I will send the invite". Each of these speaks for him. If an addition seems genuinely useful, suggest it to the user after the draft instead of putting it in.

When the request is already worded like the message ("tell Priya no, the deploy is not blocked..."), it is his draft: change as little as possible. Drop the instruction wrapper ("tell X", "reply to Y:") and the third-person references it implies ("she can go ahead" becomes "go ahead"), but keep his words, his contractions or full forms, and his grammar. Do not add words he did not write: "tell Ji-woo the PR looks good" becomes "looks good", not "the PR looks good".

- **Rewriting a supplied draft:** move it into his voice, do not just touch it up. Keep every fact, commitment, and the emotional weight, but rework the casing, phrasing, and rhythm so it reads the way he would have typed it. Changing only the greeting is not a rewrite. Keep his own words for people and sensitive subjects ("father" stays "father"); rework the wrapping around them, not the substance.
- **Quick reply / ongoing DM:** fragments and short acknowledgments are natural. Answer the actual question; do not recap the whole thread. A greeting usually adds nothing mid-conversation.
- **Human request / coordination:** direct questions such as "can you", "can we", "do you want to", or "got a minute?" are normal. Brief context, the ask, and any real timing constraint. Do not turn a collaborative request into an order.
- **Technical discussion / debugging:** observation first, relevant evidence or constraint, then the hypothesis or question. Distinguish what he tried from what he suspects. Include his reasoning when he supplied it; do not construct reasoning for him.
- **Status / findings / handoff:** lead with what changed or where things stand; include the remaining gap and next action or specific question. A few short paragraphs often suffice. Longer findings are fine when the facts need them; there is no 200–400-word target.
- **Social / personal / supportive:** warmth, enthusiasm, jokes, greetings, thanks, and apologies are part of the voice. Match the relationship and moment. Do not flatten these into technical imperatives or invent personal details.
- **Agent instructions:** terse verbs and explicit boundaries fit here: "check the diff, do not commit yet". Keep this register separate from messages to coworkers.

## Stable tendencies

### Rhythm and phrasing

- Lowercase-leaning openings, short clauses, conversational connectors: "so", "also", "but", "I mean", "actually", "btw", "for context". Use them when they carry the thought, not as a checklist.
- He often develops a thought through short follow-ups. In one draft, use short paragraphs to keep that rhythm; do not pretend to send a burst of separate messages. Start a new line where a separate thought starts (a hypothesis, the remaining gap), not for a short closing clause such as "go ahead".
- Casual commas and fragments fit. Periods and complete sentences also fit. Never manufacture run-ons, dropped articles, typos, or an accent, and do not correct the ones in his own wording either.
- He mixes contractions and full forms freely, with any recipient: "I'm", "Im", and "I am"; "don't", "dont", and "do not". The one consistent pattern is emphasis: he drops the contraction when he wants a claim to land harder ("I do not want this merged yet", "that is not the issue"). So use contractions for ordinary flow and full forms where the point is emphatic. Spelling out every contraction makes a draft sound stiff; contracting everything loses his emphasis. This applies to wording you write; when he already chose "don't" or "do not", keep his choice.
- Both apostrophized and bare spellings ("don't", "dont", "lets") occur. Keep whichever the supplied draft uses; do not mechanically add or strip apostrophes.
- Skip stock politeness that pads without saying anything: "I have not had a chance to", "just wanted to", "I hope this finds you well", "please do not hesitate to". Say the thing: "I have not checked yet".
- Always capitalize people's names, in every channel, even when the user typed them in lowercase. Product names often stay lowercase in casual Slack prose; in email, capitalize them. Acronym casing varies in actual chat; prefer readable conventional casing (API, MCP, EKS) without altering identifiers, commands, paths, URLs, or quoted text.

### Stance and relationships

- Be direct about an observed failure, but keep genuine uncertainty: "I think", "maybe", "probably", "it looks like", "I am not sure", "I have not tried it". These are meaningful, including at the start of a sentence, not filler to delete.
- Ask concrete questions instead of adding generic calls for feedback. A constraint followed by "what if..." or "would that work?" is a natural way to propose something.
- Correct course without ceremony: "actually", "I meant", or a brief "no" plus the correction. "nono" fits an emphatic casual correction but is not a mandatory signature.
- Allow brief enthusiasm and acknowledgment: "cool", "sounds good", "awesome", "lol", "haha". Occasional emoji or emphasis can fit social exchanges; do not decorate every draft or inject jokes into serious messages.
- In Slack, start without a greeting by default: under 2% of his messages open with "hey", "hi", or "good morning", even when asking for something. Open with the ask, the news, or the person's name. Save "hey" for a first message after a long gap or a light social opener, and avoid it before bad news or condolences, where it reads breezy. "thanks" and "sorry" are available when meant. Skip canned pleasantries and formal sign-offs in chat, not human warmth. Email is different; see below.
- Blunt criticism and profanity can occur with familiar people. Do not introduce profanity, hostility, or extra certainty merely to make a draft sound less polished.

## Format and destination

**Slack / Discord:** prose and paragraph breaks by default. Short replies may be a single line. Links can follow the relevant claim or stand alone. Use code blocks for exact technical evidence when supplied. Lists and headings are exceptions for genuinely structured material or an explicit request, not forbidden syntax. Avoid boilerplate "TL;DR", "Summary", and "Conclusion" wrappers.

**Email:** preserve directness, but do not apply chat typography or agent-command brevity mechanically. Sent-email examples show both terse replies and fuller external correspondence:

- **Ongoing thread:** answer or clarify the immediate point. A one-line acknowledgment, timing question, or status update can be enough; do not restart every reply with a greeting and signature.
- **New external conversation / substantive follow-up:** conventional capitalization, a named greeting, brief thanks or acknowledgment, and a closing such as "Best," or "Best regards," can fit. Lead into the concrete ask, update, or relevant context. Do not add ceremonial praise just to sound professional.
- **Coordination / handoff:** make the requested action and supplied timing explicit. Two simple options read naturally in one sentence ("Tuesday or Wednesday afternoon, US Eastern"); save bullets for three or more options or options that each carry detail. Preserve time zones and constraints. Mention an attachment only when the user says it is attached, and preserve a supplied signature without inventing contact details.
- **Support / troubleshooting:** a concise observation and question can still be natural with an external recipient. Do not inflate a simple reply into a formal letter or repeat the quoted thread.

In email, capitalize names of people, companies, and products ("Dana", "Northwind", "Evie") even when the user typed them in lowercase. Match the supplied email and relationship before choosing spelling, greeting, or closing. The email sample is limited and may include assisted composition; polished wording is not a new universal style.

**GitHub comments:** keep prose direct; use bullets for action items and file lists, headings for substantial reviews, and exact identifiers. Formatting should make the work reviewable. GitHub-specific conventions are destination guidance, not conclusions from a GitHub corpus.

## Before returning

- Does this fit the audience and purpose, rather than treating every recipient as an agent?
- Are the facts, uncertainty, ownership, timing, and commitments unchanged? Read each sentence and ask whether he supplied it. Remove invented asks, offers, promises, rationale, opinions, and calls for input, however helpful they seem.
- If this was a rewrite, would he recognize it as his own phrasing rather than the original lightly edited?
- In Slack, does it open with a greeting he would not have used?
- Is it as short as the content allows without making the recipient reconstruct missing context?
- Does it sound conversational without forced mistakes, missing punctuation, or a pile of signature phrases?
- Did useful warmth or a real question survive the rewrite?

For situation-specific calibration, read [examples.md](references/examples.md). Examples are synthetic; never pull private conversation details into a draft merely to imitate the voice. This skill drafts text; it does not authorize sending it.

## Evidence limits

This profile draws on a broad sample of Slack DMs and public-channel messages, plus a smaller sample of sent work emails. Private-channel and internal-email coverage were sparse; GitHub guidance remains an adaptation. Messages may include pasted or AI-assisted text, so treat the patterns as tendencies, not rules. Prefer the user’s corrections and recent, audience-matched examples.
