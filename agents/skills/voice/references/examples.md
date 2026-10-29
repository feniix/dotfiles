# Calibration examples

These are invented situations, not quotes or paraphrases of private Slack conversations or emails. They illustrate choices, not fixed templates. Preserve the facts of the user's actual request.

## Human request, not agent command

Input: Ask a colleague to check a proposed cache change before tomorrow's rollout.

> can you look at the cache change before we roll it out tomorrow?

Avoid: "review cache, approve, deploy". That changes the relationship and invents approval and deployment instructions.

## Uncertain technical hypothesis

Input: The worker restarted twice; queue depth looks normal. A memory leak is possible but unverified. Ask whether the other person has seen it.

> the worker restarted twice, queue depth looks normal so I am not sure what is causing it
>
> maybe a memory leak, have you seen this before?

Avoid: "the worker has a memory leak, fix it". Directness is not permission to turn a hypothesis into a fact.

## Brief status and remaining gap

Input: Parsing works locally. Retry behavior remains untested. Ask whether staging is available for testing today.

> parsing is working locally, I still need to test the retries
>
> can I use staging today?

Avoid a polished report with three headings or an invented claim that tests passed.

## Findings that need context

Input: A benchmark improved latency from 180 ms to 120 ms with a smaller batch size. Only one machine was tested. Suggest repeating on another machine before changing the default.

> the smaller batch brought latency down from 180ms to 120ms, but I only tested it on one machine
>
> I think we should try it on another one before changing the default

Keep the numbers, limitation, and next step. Do not pad it to a target word count or remove "I think" by rule.

## Coordination and warmth

Input: A colleague is unwell; offer to postpone the review until next week.

> do you want to move the review to next week? no rush, hope you feel better

Avoid an abrupt "move review to next week". The offer is not a decision already made.

## Rewrite, not touch-up

Input: Rewrite this in my voice: "Hello team, I wanted to let you know that I will be unable to attend tomorrow's planning meeting due to a scheduling conflict. Could someone please take notes? Thank you."

> I cant make planning tomorrow, I have a conflict
>
> can someone take notes?

Every fact and the request survive; the greeting, the "I wanted to let you know" wind-up, and the sign-off do not. Avoid returning the original with "Hello team" swapped for "hey team".

## Uncertainty without invented reasoning

Input: Ask the on-call engineer whether the 5-minute alert threshold is right. Unsure about it.

> not sure the 5 minute threshold on that alert is right, what do you think?

Avoid: "5 minutes feels too noisy given the traffic pattern". He did not say why he was unsure; do not supply a reason for him.

## Familiar correction

Input: Clarify that the change belongs in the worker, not the API. The API should stay unchanged.

> actually I meant the worker, the API should stay as it is

"nono" could fit an already casual back-and-forth, but adding it to every correction becomes a caricature.

## Short reply

Input: Agree to pair after lunch.

> sounds good, lets pair after lunch

Do not expand a simple agreement into a formal acknowledgment.

## Agent instruction

Input: Ask an agent to inspect a failing test and propose a fix without editing files.

> check why the test is failing, propose a fix but do not change files yet

Here imperatives and explicit action boundaries fit. The skill must preserve the "no edits" constraint.

## Email to a less familiar recipient

Input: Ask a new collaborator, Alex, to send the integration requirements before a scheduled call. Sign as Seb.

> Hi Alex,
>
> Can you send the integration requirements before our call?
>
> Best,
> Seb

This is a synthetic example of the fuller external-email mode seen in sent mail, not a required template. Keep a requested signature; do not remove one mechanically.

## Email reply within an established thread

Input: A collaborator proposes moving the call to Thursday. Ask whether the time will stay the same; do not confirm availability yet.

> Same time on Thursday?

A greeting, recap, and closing are unnecessary here. Do not change the question into "Thursday works for me"; availability was not given.

## External email with scheduling options

Input: Offer Morgan either Tuesday at 10 AM UTC or Wednesday at 2 PM UTC for a review. Ask which works; neither is booked yet. Sign as Seb.

> Hi Morgan,
>
> I can do Tuesday at 10 AM UTC or Wednesday at 2 PM UTC for the review. Which works better for you?
>
> Best,
> Seb

Two options fit in a sentence; a bullet list for them reads templated. Bullets earn their place with three or more options or options that each carry detail. Preserve both options and the time zone; do not invent a preference or imply that a meeting is already scheduled.

## Contractions and emphasis

Input: Tell a teammate the flaky test is not caused by the new cache, the cache is disabled in CI, and ask them to keep looking elsewhere.

> it's not the cache, the cache is not even enabled in CI. can you keep looking?

Contractions carry the ordinary flow ("it's"); the full form ("is not even enabled") is where the claim lands hardest. He mixes both with anyone. Avoid spelling out every contraction ("it is not the cache"), and avoid adding a suggestion such as "I'd check the fixtures next" that he did not give.

## Concise support email

Input: The upload now completes, but the preview is still blank. Ask whether the recipient can reproduce it.

> The upload works now, but the preview is still blank. Can you reproduce that on your end?

External correspondence does not always need a formal opening or a long explanation. Preserve what changed and what remains broken.
