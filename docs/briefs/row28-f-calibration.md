# Brief: row28-f-calibration (head + builders; runs after Feras's candidate research; D11)
You are in your own worktree on branch worktree-row28-f (made from origin/main after parts a and e). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/nv_audit.sh, tools/test_nv_audit.py
Timebox: 45 min per candidate (hard cap). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: other models may replace DeepSeek or fill the :free chain if they do the work as well; calibrate each against a gold task, scored versus Haiku and agy (D11). Candidates so far: the OpenRouter :free text models that could build (nemotron-3-ultra-550b, nemotron-3.5-super, gemma-4-31b, north-mini-code, inkling), Cerebras qwen-3.8-27b (out of the chain 11-05 until calibrated; paid credit, so a SPEND line and his OK) and anything Feras names. Pillar served: none directly.

## Read first
docs/decisions-process.md D11, .claude/skills/builders/models.md (earlier calibration table), .claude/skills/low-cost-pipeline/proof.md.

## What to build
1. Pick one gold task: a small typed GDScript logic file with 3 red tests (head writes the tests; reuse the row 18 toy if it fits). One run per candidate, same brief, same base, the free route only.
2. Score each: PASS or not, fix passes used, wall time, reviewer misses (seeded-defect review by another family), cost 0 or $.
3. Append one table to models.md with the date; a candidate that passes gets its own family chain in builders.conf and a routing.md role only with Feras's OK (11-05: a chain holds one model); one that fails is listed with its failure.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`.claude/skills/builders/models.md`

## Ripple
NV_CHAIN and free_providers.txt change only after the table and Feras's OK. models.md has a size cap: keep the table to one line per candidate.

## Pre-mortem
- n=1 noise: a result reads as a signal only after two runs; one run is marked n=1 in the table.
- A free route is rate limited mid-run: NV_FALLBACK_RE marks it quota, not a fail.
- Scoring bias to one family: the reviewer is another family than the builder.

## Tests
- none beyond check.sh: the output is a table in docs. Player-visible: not applicable.

## Checklist
- file: .claude/skills/builders/models.md

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
