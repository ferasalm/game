# Overnight retro: Neon Glitch first playable (2026-10-26/27)
Written by the overnight coordinator chat (Opus 5.5) from what it lived through, the manager chat's reports and
Feras's 25 playtest captures (inbox/playtest/2026-10-27_*/: shot.png, marked.png, state.json "note"). Input for the
process audit; each line: what happened -> cost -> root cause -> fix to adopt.

## A. Process bottlenecks (cost us tokens or hours)
1. Coordinator context bloat: the overnight chat reached ~400k tokens before handing off (rule: ~150k); the 5-hour
   window went 8% -> 40% in ~2.5 h, mostly from re-reading that context. Cause: browser work (Flow screenshots, DOM
   probing), image reviews and builder briefs all in one chat. Fix: the orchestrator only plans, briefs, merges;
   art/browser/bake work goes to short sessions or subagents; get_usage at every milestone; hard handoff at 150k.
2. Late handoff wakeups: builders launched from the old chat woke it on finish (3 full-context turns for nothing).
   Fix: launch builders from the session that will review them; the retiring chat launches nothing.
3. Rediscovery: ~30 tool calls to find a Flow route (the pane cannot download or reach localhost; Chrome works:
   own <input> + file_upload + synthetic drop; "Download media" -> 2K -> ~/Downloads). Fix: a flow-images skill
   with the JS snippets, so the next session spends 3 calls, not 30. Same for the Rodin route (A-pose via Flow ->
   upload PUT -> generate -> rig `ue` -> rewrite_glb.py -> models.json) and the sprite bake (bake_sprites.tscn ->
   sprite_sheet.py; the batch script lived in the scratchpad: move it into tools/art/).
4. Memory: 4 builder runs + their Godot tests left 10 MB free; the desktop app froze. Fix: <= 2 builders + 1 Godot,
   slots.sh refuses a launch under a free-memory floor (not only a count).
5. Config drift: slots.sh capped agy at 0 while agy worked (ping OK). Fix: caps in one config read by slots.sh, a
   builder ping before marking one "out".
6. Builder misses: agy sat 55 min on baseline checks with no code (cold open, written by Claude instead); DeepSeek
   shrank Rydan's model and texture (a Do-NOT-edit path; caught in review, not by the gate); a fix run started from
   stale code because the pipeline forks origin/<base> and the base was not pushed. Fix: gate BREACH must fail the
   run; push the base before launch (pipeline checks it); a "no commit after N min" watchdog kills idle runs.
7. Small time sinks: git commit hooks exceed the Bash 120 s timeout (run commits in the background); a new CSV needs
   a "keep" .import that builders cannot write (the lead pre-creates CSVs before briefing); map.py listed untracked
   files and CI failed "MAP.md current"; a network outage killed the manager's turn (resume by message worked).

## B. Quality misses Feras found (why the review let them through)
| Note (capture time) | Root cause in our process |
|---|---|
| Sprites grey, motion low FPS, "retro" (00:27) | Bake sampled 4-16 frames per clip to save size; colour lost in the flat ink shader + 256-colour quantize; judged on still frames, never in motion. Bar: Hades = full colour, smooth (~24-30 fps) |
| Static world: no moving or flickering lights, no wind, no shadows; qamariya casts none (00:29, 00:48) | The plate is one flat picture; no light, emissive or shadow layers were planned when it was made |
| Floodlight "off" is a dark rectangle (00:35) | A polygon overlay instead of a lights-off plate variant blended in |
| Booth does not block; walkable spots that are illogical; occluder looks pasted and crops the hero (00:36-00:38) | Walk polygon hand-traced from a grid image; occluder = plate crop without an object mask; no overlay render of the walk mask, no edge-walk test |
| Open door invites entry (00:38) | Level design never asked what the plate promises the player |
| Portraits in grey boxes, badly cropped (00:31, 00:33) | Edges faded to alpha instead of a real cut-out; never checked in the dialogue box |
| Fonts unreadable, word spacing, pink/cyan text clashing with white (00:15, 00:20, 00:41, 00:42) | Builders do not judge legibility; renders reviewed small; no UI legibility checklist |
| Two titles, title loop not seamless, low resolution (00:10, 00:12) | Clip with a baked logo plus an overlay; 360p source upscaled; loop never watched |
| Weak narrative, unclear text (00:21, 00:24) | Captions drafted fast by Claude without the narrative pass or Feras's review |
| Rain overlay looks wrong in play (00:24) | Overlay added because the brief said so, not judged in motion |
| Flee does nothing, zero items (00:43); corpses linger, KO'd guards "wake up" dead (00:45, 00:48) | Solo fight reused systems without a starter bag or flee rule for scripted fights; tests checked the sim, not what the player sees after the fight |
| No SFX or VFX on attacks (00:44) | Not in the battle brief; the 3D VFX player was not ported |
Common cause: nobody played it like Feras before he did. Fix: a "player's-eye gate" before a build reaches him: a
recorded playthrough (GIF/frames at full size) reviewed against an acceptance list written from his references
(Hades: colour, motion, light, VFX/SFX, readable UI) plus the F12 capture tool used by Claude on its own run.

## C. Feras's directions in the notes (for the next build chat; log as decisions where marked)
- DECISION (logged 10-27): player-facing spelling "Jambiya" (no h).
- Title: one title only (the clip's), upscaled; a seamless title loop made with Hyper3D's video generator from the
  title picture in inbox/Neon Glitch concept art; the "O" of the logo as a qamariya stained-glass window.
- No rain during gameplay; acid rain is a world rule: people carry umbrellas; an umbrella item/icon protects from it.
- Music changed; SFX and flashy VFX on every hit; colour sprites with Hades-smooth motion; living, lit environment
  (moving and flickering lights, wind, shadows, qamariya light) planned carefully before building.
- Use the empty space (00:16); a richer prologue that hints at the story, better written lines.

## D. What worked (keep)
- Builders in parallel on disjoint folders after Claude wrote the shared foundation (defs, IsoActor, walk logic).
- Flow for images ($0 API), Rodin from a Flow A-pose (one model, one rig), sprites baked from 3D in Godot.
- Briefs with Do-NOT-edit lists and checklists; manager chat merging; F12 playtest capture (screens + marks + state).
- Spend: Runware/OpenRouter $0; two Rodin jobs.
