# Chat brief: cross-review lane (A), agy's wider lane (C), one race (B) (Feras 2026-10-28)
HANDOFF queue row 11 (Dept Ops). Free builders build (agy, cf); the chat (Opus) briefs, calibrates, reviews, merges.

## Why
Feras 10-28: "Queue A + C, and also try B (two builders race on the same brief, each reviews the other) on one small
task as an experiment." Goal: less Claude work; free builders of different model families review each other before
Claude's final gate. Facts (10-28): agy has not built since 10-26 18:55 (its lane was Godot only; every run since went
to DeepSeek); cf, oc and opencode all run DeepSeek V4.1 Flash (one family, shared blind spots); the gate-passed cf
hooks of row 1 still held 5 real bugs that Opus found.

## What to build
1. C, agy's lane: WORKFLOW Routing (lanes line) and the builders skill: agy also takes Python tools, docs and review
   work whenever its quota is free; cf stays the Godot fallback. Check that tools/slots.sh lets a non-Godot agy run
   start without a Godot slot (CAP_AGY, CAP_GODOT, memory floor), with a test.
2. A, cross-review step (build_pipeline.sh or a new tools/cross_review.sh, with tests): after a PASS run the other
   family reviews it: cf/oc-built -> agy; agy-built -> cf. Input: the brief, the diff against its base, the
   code-reviewer skill (.agents/skills/code-reviewer) and .claude/rules/code.md. Output: .check/reviews/<run>-cross.md
   in a fixed template (severity | file:line | failure scenario | fix); a parser test rejects free prose. The builder
   gets one fix round (cap 2), then the gate runs again. The review itself runs no Godot.
3. Calibrate before switching A on (D11): give the reviewer cf's original hook diff (783eefd against its base), never
   the answer key. Key = the 5 bugs Opus fixed in 5008b5d: (a) the 80k/100k token warnings repeated while a compaction
   sat in the recent transcript; (b) the word-count fallback counted text from before the compaction; (c) inbox
   documents were blocked as renders; (d) artifact files passed as a plain list were never checked; (e) a missing hook
   file exited 2 and blocked tool calls. On: >= 3 of 5 found, most findings real. Else tune the prompt once and retest.
   Write both runs into the builders skill's lessons.md.
4. Claude's gate after A: Opus reads the gate result, the cross-review findings and the risky hunks (WORKFLOW
   Protocols: Review); Haiku only for big diffs. Opus still signs off on everything that reaches Feras.
5. B, one race: a small Python-only piece of this row (e.g. the findings parser + its test), so no Godot slot is used.
   agy and cf build the same brief in two worktrees, each cross-reviews the other's, the gate and the findings pick
   the winner, Opus reviews the winner only. Record in the builders skill: time to PASS, findings, Opus fixes needed,
   Claude tokens, verdict (adopt for risky tasks or drop).

## Limits
Free models may train on prompts: public repo content only. OpenRouter :free: 50 requests a day. Never starve M1
(row 4) of Godot slots. Builders never merge or push to main (D3).

## Ripple
build_pipeline.sh, build_gate.py, slots.sh, docs/briefs/TEMPLATE.md (a Cross-review line), the builders skill,
WORKFLOW (Routing, Protocols: Review), review-code, tools/status.sh (shows cross-review runs), DECISIONS Builders line,
docs/MAP.md.

## Done when
check.sh passes; the calibration result is written; A and C merged and on (or A off, with the reason); the race verdict
logged; row 11 closed; /handoff.
