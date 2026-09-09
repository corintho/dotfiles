---
description: Write terse one-line PR review comments
---

Load and activate the caveman-review skill.

Use this command to generate concise, actionable pull request review comments in ultra-compressed format:
- One line per comment
- Format: `L<line>: <problem>. <fix>.`
- Example: `L42: bug: user null. Add guard.`
- Cut all noise while preserving the actionable signal
- Each comment is location, problem, fix

This skill auto-triggers when reviewing pull requests.
