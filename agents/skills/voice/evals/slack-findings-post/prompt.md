---
tags: [skill-creator]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

write a slack post for #platform in my voice with these findings: moved the ci runners from m5.xlarge to c6i.xlarge last week. median build time went 14m -> 9m. cost per month roughly the same, maybe slightly lower but I only have 5 days of billing data. two jobs (e2e-android, docs-build) got slower, not sure why yet. next: watch billing for the rest of the month and look at the two slow jobs
