# Evidence and calibration limits

Analysis date: 2026-10-28. This note supports maintenance of the profile; it is not text to include in outgoing drafts.

## Corpus and selection

The locally ingested Slack projection contained **6,343 nonempty, nondeleted records attributed to Sebastian**, spanning **2025-08-12 through 2026-10-28**, across **75 conversations** and 15 calendar months:

| Conversation kind | Records | Conversations |
| --- | ---: | ---: |
| One-to-one DM | 1,673 | 17 |
| Group DM | 739 | 11 |
| Public channel | 3,906 | 44 |
| Private channel | 25 | 3 |

Identity was resolved against Slack user metadata. Two matching account identities were checked; only one had qualifying messages in the projection. Counts use current message rows keyed by conversation and timestamp, not repeated ingestion/edit events. This is the available ingested window, **not a claim of complete Slack history**.

Filtering, applied in this order, removed:

1. 35 channel-join/leave events.
2. 73 thread-broadcast records, conservatively avoiding possible duplicate weighting.
3. 352 messages in known bot/app DMs or beginning with a known bot mention. All 17 one-to-one DM conversations had participant metadata; three were filtered as bot/app conversations.
4. 756 nonprose records after stripping fenced code, inline code, quote lines, links/mentions, and Slack emoji names; retained text needed at least two consecutive ASCII letters.
5. 74 messages containing credential-related topic markers, excluded conservatively rather than used for calibration.
6. 2 slash-command records.

That leaves **5,051 candidate prose messages** across 53 conversations. This is a heuristic prose subset, not certified human-to-human or unaided writing: bot references elsewhere in a sentence, pasted passages, unmarked quotes, logs, and generated drafts can remain. Short replies such as laughter are retained. Keyword exclusions also remove some ordinary technical discussion.

## Breadth of close reading

Before qualitative interpretation, messages were stratified by conversation kind × conversation × calendar month: 236 populated strata. Within each stratum, a deterministic shuffle (seed 20261028, timestamp-ordered input, sorted strata) reserved one message for confirmation and selected up to the next four for exploration.

- Exploratory selection: 604 records, of which 473 survived the prose filters.
- Reserved confirmation selection: 236 records, of which 161 survived.
- Close reading examined the exploratory selection and then the 161 eligible reserved messages, looking for counterexamples to the initial rules. Long exploratory entries were excerpted, not all read in full. Counts and word-length measurements were computed over the full filtered corpus.

The reserved set was read before the final rewrite. It is **not** an independent blind evaluation, a model benchmark, or proof of user preference. Full-corpus metrics also included it. Conversation/month stratification favors breadth over frequency; the close-reading sample is not a population-weighted random sample. Mostly isolated authored messages were read, not every surrounding thread, so interpersonal interpretation remains qualitative.

## Measured signals

Word lengths below are whitespace-delimited counts after the stripping described above. They measure individual Slack messages, not entire multi-message turns, and are not drafting limits.

| Kind | Eligible messages | Median words | 90th percentile words |
| --- | ---: | ---: | ---: |
| One-to-one DM | 1,478 | 7 | 23 |
| Group DM | 638 | 7 | 19 |
| Public channel | 2,912 | 7 | 22 |
| Private channel | 23 | 5 | 24 |

Message-level marker counts across the 5,051 eligible messages:

- **81** begin with `hey`, `hi`, `hello`, `good morning`, or `morning`.
- **29** contain `thanks`, `thank you`, or `thx`.
- **429** contain `I think`, `maybe`, `probably`, `perhaps`, `I guess`, or `not sure`.
- **91** contain a `can/could/would you/we` construction.
- **372** contain full negations: `do not`, `does not`, `did not`, `is not`, `are not`, `cannot`, `will not`, or `would not`.
- **135** contain bare forms from `dont/cant/doesnt/isnt/lets/whats/thats/wasnt/werent/didnt`; **75** contain apostrophized counterparts, including curly apostrophes.

Matchers were case-insensitive with word boundaries, with greeting matches anchored to the stripped text's start. Counts are messages matching each family, not token totals; families overlap. These lexical markers are not semantic labels. For example, a quoted-looking passage can survive and "probably" does not by itself establish interpersonal hedging. The counts establish that absolute bans are unsupported, not that every draft needs those features.

## Supported changes

- Preserve concise, context-heavy phrasing, but separate agent commands from requests to people.
- Allow genuine uncertainty, including sentence-initial "I think"; do not replace it with unsupported certainty.
- Allow greetings, appreciation, humor, enthusiasm, and care where appropriate. Low ceremony is not emotional flatness.
- Treat lowercase, informal spelling, fragments, and comma chains as tendencies, not mandatory transformations. Full forms such as "I do not" are prominent.
- Keep explanations when needed to make a technical question or recommendation useful. Brief replies and long findings can coexist; no fixed findings-post word target is justified.
- Do not infer email or GitHub-specific norms from Slack alone. Their guidance is an explicit adaptation.

An auxiliary Jev decision check using only anonymous aggregate evidence supported context-sensitive guidance and labeling email guidance as extrapolation. That check is corroborative, not independent source evidence or a voice-quality score.

## Limits and privacy

Only 23 private-channel messages survived, all in one conversation; do not infer a general private-channel register. DMs and public channels provide much broader evidence. Ingestion coverage, collaborators, topics, mobile typing, copied text, and AI assistance can all affect the distribution. No reliable unaided-authorship labels were available. Polished outliers were not treated as a new universal voice, nor rejected as definitely AI-written.

The repository contains no Slack transcript export, message IDs, channel names, participant roster, private links, or verbatim private examples. Calibration examples are synthetic and use invented scenarios. The raw source and temporary analysis files are not repository artifacts. Future refinements should prefer the user's corrections and recent, audience-matched examples over rigidly enforcing these historical tendencies.
