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

## Cross-review and race calibration notes (moved from .claude/skills/builders/lessons.md, row 24, 2026-11-01; dated history, parts since superseded by models.md)
- Cross-review calibration (row 12, 2026-10-28; D11): agy reviews cf's hook diff `git diff 152f962 783eefd` with the
  brief as cf saw it (152f962), one-shot from an empty folder (no repo, so no `git log` to 5008b5d), packet =
  tools/cross_review_prompt.md + brief + diff + code-reviewer skill + code rules. Scoring, fixed before reading: found =
  the right file and the mechanism of one key bug (a-e, docs/archive/briefs/cross-review.md); real = Opus confirms it against
  783eefd. On: >= 3/5 found and most findings real; else tune the prompt once and rerun.
  Run 1 (agy, ~3 min, format valid): 2/5 found, a (warnings repeat while a compaction sits in the window) and b
  (fallback counts pre-compaction text); 9 findings, ~6 real (anchor-less f\d{8} regex, ../ escapes the exempt
  folder, main() 56 lines, null usage fields; 2 not real, 1 cosmetic). Missed c and d, which were bugs in the brief
  (the code followed it), and e, which lives in the wiring outside the diff. Tune: question the brief (legit inputs,
  every caller shape) and the wiring (fail open or closed when the file is missing).
  Run 2 (tuned prompt, ~8 min): 3/5 found (b; c inbox documents; d files as a list of strings), a dropped, e never
  found; 12 findings, ~8 real (by-design flags: the Flow folder exemption, fail-open on errors). Verdict: agy is ON as
  the cross-reviewer of DeepSeek-built runs; recall varies run to run (union 4/5), so Opus still reads the risky hunks.
  DeepSeek reviewing agy-built runs is uncalibrated: provisional, Opus reads the whole diff until it is calibrated.
- agy's first Python run (row 12 C, 10-28): PASS in ~40 min, +69 lines over 5 tools; Opus fixed 3: a bash function
  called before its definition (an untested refusal path), BREACH filtered into FAIL (Claude's red test demanded FAIL
  for an assets/ edit: a red test can force a wrong design, so test verdict precedence too) and a fix-pass prompt
  that ran Godot in a py run. Brief every refusal path with a test.
- Race B (row 12, 10-28; parser brief, py run): agy and cf each made a first commit in 17-20 min and both parsers passed the 7 red tests, but both runs then burned ~70 min of fix passes on a pipeline leak (RUN_KIND=py reached test_build_pipeline); cf "fixed" it in protected check.sh = BREACH, agy PASSed once re-gated. Cross-review gave 0/2 usable blocks (agy headless denies its tools without --dangerously-skip-permissions; DeepSeek explored 520 s and wrote no block); Opus found 2 real bugs (non-UTF-8 log crash, CRLF out). Verdict: no races for now; one builder + Opus review is cheaper (2026-10-28).
- Cross-review calibration (row 12 A, 10-29): tools/cross_review.sh, agy with --dangerously-skip-permissions --sandbox
  from an empty box (packet.md only), on cf's hook diff 783eefd: one round, 11 min, a valid block, 10 findings, box
  untouched. Key 3 of 5: (b) pre-compaction fallback, (c) inbox documents blocked, (d) plain-list files unchecked;
  (a) repeat warnings only brushed, (e) missed. Of the other 7: 1 harmful (review_gate should fail closed = the
  opposite of (e): sent as a fix pass it would bring that bug back), 1 false (git-common-dir join is right: cwd=here),
  1 real and minor, still on main (RENDER_NAME.search is anchored only at the end), 1 moot (code since rewritten), 3
  unchecked. PASS on found (>= 3), borderline on "most real": fail-open/closed findings go to Opus, never to the
  builder. DeepSeek live (10-29, agy's parser, 2 known bugs): 3 runs, 0 blocks. Run 1: read the packet, then its step
  ended at opencode's 32k output cap (finish "length", --format json) with no text; the packet had main's newer
  commits + MAP.md (2-dot diff, fixed: merge base, generated files out); runs 2-3 on the 17 KB packet: no text again.
  DeepSeek is off as a reviewer. nemotron-3-ultra :free (oc reviewer) on the same parser: one round, 7 min, 3
  findings: 1 of 2 key (non-UTF-8 crash; CRLF missed), 1 real minor (unwritable --out crashes), 1 doubtful (drive-
  letter paths, which the prompt excludes). On for agy runs as a free pre-pass; Opus vets every finding (10-29).
