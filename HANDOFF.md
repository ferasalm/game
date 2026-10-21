# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-21, session 5 (Opus 5.5, `claude-opus-5-5`, lead, xhigh): v0.3 "Painted Rooftops" in progress.
Plan (approved by Feras): docs/design/v03-plan.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- v0.2 is on main and plays. Feras's play-test notes (12) became the v0.3 plan: painted diorama look, painted
  puppets, separate battle arena with a qamariya-shatter warp, shop + riyal + consumable herbs, sabil save spot,
  HP/SP carry over, pause menu with reset/unstuck, pulled-back camera with occlusion, stuck-bug fix.
- Phase 0 done (on claude/night-sanaa, pushed): decisions logged; specs docs/design/economy.md, ui.md (v2),
  rooftop-v3.md, v03-text.md, art-prompts-v03.md; contract stubs core/scene_router.gd (autoload Router),
  features/ui/view/ui_stack.gd (autoload Screens), features/combat/logic/battle_request.gd + battle_outcome.gd,
  EventBus money_changed/game_paused, `menu` input, localization shop/sabil/pause.csv. check.sh: 273 tests ok.
- In flight when the 5-h limit hit (local worktree branches; each should have a WIP commit + WIP_NOTES.md at its
  root; if a note is missing, read `git -C <worktree> log` and `diff`):
  - P1b DONE (143bc79, check.sh ok, 307 tests; APIs + leftovers in its WIP_NOTES.md): merge as is:
    worktree-agent-a053ea400a3633839. Leftover: create_timer in battle_action_player/battle_stage/fighters.
  - P1a partial (3f22d3e: items 1-4 done; Router, chest fix, PrototypeMain, smoke test left; test_battle_outcome
    unrun): worktree-agent-a6fa1b1bce014b0a4.
  - Look spike (painted light, bake, outlines, grade, camera presets, 3 variants): .claude/worktrees/
    agent-a4e91f85045597ede (worktree-agent-a4e91f85045597ede), 9cb5b23: shaders, bake (WebP), outline, grade/AA,
    presets, 3 looks built; left: painted Zayd, checks, renders to inbox/spike/, FPS.
- Herb seller name "Umm Nabil" (Narrative Designer); Feras may rename.

## Waiting on the owner
1. After the reset: start a NEW chat with the prompt below (not this long chat: its cache has expired, so
   continuing it would re-send ~150k tokens uncached).
2. Checkpoint 1 (soon): pick a look and camera from the spike's 3 renders in inbox/spike/.
3. Optional: Flow/Gemini pictures from docs/design/art-prompts-v03.md (herb seller, parts sheets, herb icons).

## Next steps
1. Finish Phase 1 and the look spike: start FRESH agents (Agent tool, isolation worktree), for P1a and the spike; each
   brief = the original brief in docs/design/v03-plan.md Phase 1 / look spike + "git merge --ff-only
   claude/night-sanaa && git merge <WIP branch>, read WIP_NOTES.md, continue". Lead reviews, merges P1a then
   P1b into claude/night-sanaa, runs check.sh. Model: Opus lead (high); Sonnet builders (high); spike Opus (high).
   Effort: high.
2. Checkpoint 1 with Feras (look/camera pick), then Phase 2 builders B1-B6 as in the plan. Model: Opus lead,
   Sonnet builders, Haiku helpers. Effort: high (lead), medium/high (builders).
3. Phase 3 integration (smoke test, renders, fps_probe, Code Reviewer Opus), merge to main, /handoff.
   Model: Opus. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3 "Painted Rooftops". Read HANDOFF.md and docs/design/v03-plan.md.
Do not resume old agents: start fresh agents from each WIP branch's WIP_NOTES.md (HANDOFF Status lists them).
Finish Phase 1 (P1a, P1b) and the look spike, merge P1a then P1b into claude/night-sanaa, run tools/check.sh,
show me the 3 look renders and ask me to pick (2-4 options), then run Phase 2 per the plan. Keep briefs exact and
reports <= 300 words; WIP commits after each unit; /handoff before ~150k tokens or near the usage limit.
Opus lead, high effort; Sonnet builders; Haiku for mechanical parts.
```
