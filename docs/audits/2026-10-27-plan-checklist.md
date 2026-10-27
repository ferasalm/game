# Plan checklist (process audit, approved 2026-10-27)
One line per item of docs/audits/2026-10-27-process-audit-plan.md. Each P-chat ticks its own lines ([x] plus the
commit), and leaves a line open only with a reason after it. P4 runs a conformance pass over every line.
Format: [ ] id | item | how to check

## P1 Tools (Sonnet, medium; DeepSeek builds)
- [x] P1.0 | Baseline in USAGE: /context start cost, window % of the last 3 sessions, .result verdict counts, 25 notes per build | grep "Baseline" docs/USAGE.md -- done 6bbd03b
- [x] P1.1 | tools/builders.conf + tools/lib.sh sourced by slots, check_slot, build_pipeline, cf_build, merge_run, agy_review, check | grep -l "lib.sh" tools/*.sh -- done ab94d41,67ee6a8 (check_slot.sh stays standalone: it is sourced by check.sh, which sources lib.sh)
- [x] P1.2 | slots.sh: total cap, memory floor (stubbed), finds C:/dev/game-wt from any worktree | tools/test_slots.py -- done ab94d41
- [x] P1.3 | build_pipeline.sh: refuses when slots is full or base is unpushed; pid in .result; idle watchdog; </dev/null; non-zero unless PASS; pastes .claude/rules/code.md; --import | tools/test_build_pipeline.py -- done a969eb6
- [x] P1.4 | agy_task/oc_task: outside timeout; oc default model DeepSeek; refuses a worktree with another base | tests in test_build_pipeline.py -- done a969eb6
- [x] P1.5 | build_gate.py: no "Do NOT edit" heading = FAIL; tests/ + assets/ protected unless "May edit"; removed assert/test = FAIL; new tests must fail on base; *.import under assets counts | tools/test_build_gate.py -- done b7ea45f
- [x] P1.6 | cf_build.sh spend from the saved build log; cf_mcp triage uses DeepSeek | test_slots.py spend case; grep server.py -- done ab94d41
- [x] P1.7 | map.py `--cached` only; check.sh runs every tools/**/test_*.py and a boot smoke; check_slot.sh wait limit | tools/test_map.py; check.sh output -- done 67ee6a8,a969eb6
- [x] P1.8 | session-start.sh: $PWD + `timeout 15 git fetch`; tools/wt_clean.sh; doc_check warns at 75%; .gitignore .env | hook test; grep .gitignore -- done 67ee6a8
- [x] P1.9 | Paid-tool PreToolUse hook script (exit 2 without Feras's OK; credit reminder for Hyper3D) + its test (D21) | tools/test_pre_spend.py -- done 67ee6a8
- [x] P1.10 | Dry run on a toy brief: a planted test edit gives BREACH and a non-zero exit; merged only with 0 runs live | .result of the dry run -- done: docs/audits/2026-10-27-p1-dryrun.md (BREACH exit 1; clean PASS exit 0)

## P2 Skills and reviewers (Sonnet, medium)
- [x] P2.0 | Calibration: free readers vs Haiku low/high/max on the gold set; routing table chosen | docs/research/calibration-2026-10.md -- done P2a: reader Haiku high, lens nemotron-3-ultra :free / Haiku low (docs/research/calibration-2026-10.md)
- [x] P2.1 | builders skill (<= 80 lines); architecting-, coding-, debugging-games deleted; emergency-efficiency a <= 30-line delta (D3) | ls .claude/skills -- done P2a: builders skill 81 lines, 3 skills deleted, emergency delta 24 lines
- [x] P2.2 | flow-media skill with the exact Flow JS (Nano Banana images, Omni video); localhost route marked dead | grep "file_upload" .claude/skills/flow-media/SKILL.md (route verified 2026-10-26; re-verify at first real use)
- [x] P2.3 | 3d-model skill: Rodin call order, credit rules, free route stub to prove before access ends | grep "rodin_generate_rigging"
- [x] P2.4 | sprite-bake skill; tools/art/bake_all.sh with arguments; tools/art/test_sprite_sheet.py | test passes in check.sh
- [x] P2.5 | players-eye-gate skill; tools/eye_gate.sh; tools/eye_metrics.py + test; docs/design/acceptance.md draft | one eye_gate render of neon_game
- [x] P2.6 | ops-review (context: fork, agent: Explore) and market-player skills | ls .claude/skills
- [x] P2.7 | Reviewer agents review-code/-player/-canon/-cost/-market/-feras with name, description, model, tools, maxTurns | panel run on the neon-battle diff flags the model shrink -- done P2a: six review-*.md; review-code 6/6 on cal/planted; agents list after a fresh chat (Agent tool cannot name them in this chat)
- [x] P2.8 | Each skill has lessons.md + research-queue.md | find .claude/skills -name research-queue.md -- builders + emergency-efficiency only (lessons.md, research-queue.md) done P2a; other skills with P2b
- [x] P2.9 | Agency retire list moved to .agents/archive/; role cards gameplay, art, ui | ls .agents
- [x] P2.10 | Fixes: design/characters-3d.md:92 dead ref; shot_neon_game.gd:5 inbox path | grep

## P0 VISION (Opus, high; an interview)
- [ ] P0.1 | docs/VISION.md (<= 60 lines): vision, mission, pillars, objectives, roadmap M1..Mn, market brief; Feras edited it | file exists, Feras OK logged
- [ ] P0.2 | docs/playtest/2026-10-27.md: the 25 notes re-triaged for real-time combat (D15) | file exists
- [ ] P0.3 | M1 spike defined: real-time combat, Mobile renderer + touch, full-colour 24-30 fps bake, 2D lights, Android CI export | VISION M1 section
- [ ] P0.4 | docs/research/hades-digest.md from the plan's appendix | file exists

## P3 Docs, memory, ~/.claude (Sonnet, high)
- [ ] P3.1 | CLAUDE.md: north star, advisor duty, Opus standard, D1/D4/D10, one usage rule, python, sync_main.sh, CANON pointer, skill map line | doc_check; grep
- [ ] P3.2 | .claude/rules/code.md with paths:; GEMINI.md/AGENTS.md builder-only, Neon Glitch | grep -c Qarnaw = 0
- [ ] P3.3 | DECISIONS process-only, superseded struck to decisions-archive, D1-D22 summarized; docs/CANON.md holds content lines | doc_check
- [ ] P3.4 | LESSONS ~50 lines; route lessons in skills; opencode/Inkling lines archived; today's 4 lessons | wc -l
- [ ] P3.5 | docs/WORKFLOW.md (from EFFICIENCY.md): protocols, departments, limits table, routes table (free first), research protocol | file exists; old refs updated
- [ ] P3.6 | docs/design index with statuses; 3D-era designs to docs/archive/design-3d/; BRIEFING to docs/archive | ls
- [ ] P3.7 | docs/SPEND.md; docs/feras-notes.md; docs/design/systems-map.md | files exist
- [ ] P3.8 | TEMPLATE: base origin/main, D6 defaults (tests, assets, tools/, .github/), May edit, Ripple, player-visible tests, timebox, first commit, pillar | grep
- [ ] P3.9 | settings.json: binary read-denies, skillOverrides name-only (syntax verified), InstructionsLoaded log, paid-tool hook wired | settings.json
- [ ] P3.10 | Memory: claude-as-manager deleted, big-asks fixed, openrouter-free-only updated, MEMORY.md index | ls memory dir
- [ ] P3.11 | ~/.claude: unused agents/skills moved to ~/.claude/archive with MOVED.txt; start cost measured before and after into USAGE; connector list for Feras | MOVED.txt; USAGE row
- [ ] P3.12 | docs/audits/2026-10-27-process-audit.md: findings, sources, notes for other track owners | file exists

## P4 Close
- [ ] P4.1 | Conformance pass over this checklist: every line [x] or open with a reason | this file
- [ ] P4.2 | `bash tools/check.sh` green (FAIL lines read); doc_check under caps | .check logs
- [ ] P4.3 | Pushed to origin main from a worktree (never git in C:\dev\game); HANDOFF Shared + Efficiency updated; /handoff | git log origin/main
