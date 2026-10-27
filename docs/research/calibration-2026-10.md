# Calibration 2026-10-27: cheapest reader and review lens that keep quality (checklist P2.0)
Gold A (reading, 12 claims on the pre-P1 tools, worktree at 1981e15; key in docs/briefs/p2a-calibration-reviewers.md)
and gold B (6 planted defects + 2 decoys on branch cal/planted, deleted after). Whole calibration cost ~2% of the
5-hour window (35% -> 37%).

| Candidate | A right / wrong / unsure | A tokens | B found /6 | B false flags | B tokens |
|---|---|---|---|---|---|
| Haiku low | 8 / 1 (A8) / 3 | 75.8k | 6 | 0 | 61.9k |
| Haiku high | 9 / 0 / 3 | 79.3k | 6 | 0 | 63.2k |
| Haiku max | 9 / 0 / 3 | 123.2k | 6 | 0 | 86.1k |
| nemotron-3-ultra-550b :free | 8 / 2 (A8, A9) / 0 * | n/a | 6 | 0 | n/a |
| laguna-s-2.1 :free | not run | n/a | 5 (missed B6 licence) | 0 | n/a |

\* Not a clean reader test: the OpenRouter tool takes text only (no key in the shell), so the 5 files could not be
sent whole; key excerpts were pasted. Even with those hints it got 2 wrong. It fails the reader bar.
UNSURE on A2, A5, A7 (claims that something is absent) came from all three Haiku runs; UNSURE is allowed, no wrong verdict.

## Winners (bar: reader >= 90% of Haiku max and 0 wrong on A7/A11/A12; lens >= 5/6 and 0 false critical)
- **Reader: Haiku, effort high.** Low scored 8/9 = 89% and gave one false verdict (A8). Max adds 55% tokens for nothing.
- **Lens: nemotron-3-ultra-550b-a55b:free** (6/6, 0 decoys), then laguna-s-2.1:free (5/6) as second free route.
  Agents run on Haiku effort low (6/6, 0 decoys) when the free route is not available; free route = oc_review.sh or
  `mcp__openrouter__send-message` with the diff pasted (public content only, within 50 requests a day).
- Requests used: 3 of 10 free (2 lens, 1 reader). Planted defects: B1 tautology, B2 deleted check, B3 constant 7,
  B4 get_node("../Scale"), B5 headless return, B6 licence CC0. Decoys never flagged by any candidate.

## Caveats
- One gold set each; the lens set is easy (obvious patterns). Recheck with a harder set.
- A model that says UNSURE on "nothing does X" claims: Claude greps for absence claims itself.
- Recheck date: the first ops-review (docs/audits plan P4), or when OpenRouter's free list changes.
