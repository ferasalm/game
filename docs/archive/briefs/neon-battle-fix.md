# Brief: neon-battle-fix (fix pass on the merged map battle; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow GEMINI.md / AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
The map battle (features/neon/battle/, brief docs/briefs/neon-battle.md) merged, but a review found that real fights
skip the attack animation, foes killed mid-fight stay standing, and a level-1 Rydan loses about 95 % of the first
fight (this is the tutorial fight: it must be won most of the time).

## Read first
docs/briefs/neon-battle.md. features/neon/battle/ (all). How the 3D view reads the sim: features/combat/view/
battle_event_player.gd (line ~62: the acting unit's action comes from `sim.timeline.find(event.unit_id).acted`),
battle_session.gd `_award_battle_xp` (~110-129) and its `cleared_patrols` use (~94). Balance harness:
grep docs/MAP.md "features/combat/harness/".

## What to fix
1. map_battle_play.gd: `act` events carry no detail (features/combat/logic/timeline.gd ~82), so every act fell into
   the "apply all hits at once" path. Take the action from `sim.timeline.find(event.unit_id).acted` like
   battle_event_player.gd. A melee act then dashes to 70 px in front of the target, plays "attack", applies the hit
   on IsoActor.impact, runs back; a tech move plays "cast" + the coloured flash on every target (not only damaged).
2. map_battle_play.gd: stop skipping non-damage events. `down` plays "ko" at once and the actor stays down (last
   frame); `healed` / `revived` update shown_hp and the bars (revived plays "idle"). shown_hp must equal the sim's hp
   after every batch.
3. Hit freeze: freeze attacker AND target for the hitstop (view.hitstop seconds).
4. Shake: offset the current Camera2D (`get_viewport().get_camera_2d()`, skip when null), not `_world.position`
   (the plate is not inside World, so actors slid over a still floor).
5. Store `ambush` in begin(); Retry rebuilds with the same ambush value and the same pre-battle snapshot.
6. map_battle_end.gd: apply XP like battle_session.gd `_award_battle_xp`, including level-up HP/SP gains from the
   return of Progression.award.
7. Balance: add a weaker combatant `prison_guard` to content/combat/combatants.json (copy concession_enforcer's
   fields and kit, name_key NEON_NAME_GUARD) and use it twice in encounter `neon_prison_guards` in
   content/combat/encounters.json. Tune ONLY prison_guard's max_hp and attack so a fresh save (XP 0, starting gear)
   wins 80-90 % of 200 seeded auto-played fights. Print the measured rate in your final message.
8. Move the leftover numbers into content/neon/battle_view.json + NeonBattleViewDef (menu offset 440/420, the 1.2 s
   end wait, 0.12 s, 0.35 s, 700 px/s, HUD offsets, shadow offsets, grow 3.0); read `hero_bar_bottom` where the
   bottom offset is set (map_battle_vitals.gd ~20); delete never-called helpers (hide_defeat, foe_bar, timeline,
   unused HERO_ID) unless a test needs them.
9. `var seed_override: int = -1` on MapBattle: when >= 0 it replaces randi() (tests use it).

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/roof/`
`features/neon/start/`
`features/neon/cold_open/`
`features/neon/neon_game.gd`
`features/neon/neon_game.tscn`
`features/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`content/art/`
`assets/`
`core/`
content/combat/*.json: only the new prison_guard entry and the neon_prison_guards enemies list.

## Tests (features/neon/battle/tests/)
- test_map_battle.gd: remove `GameState.xp[&"zayd"] = 2000`; use seed_override; a fresh save auto-fight ends with
  ended fired once. New: a played (not direct) melee act applies its damage only after the impact signal; a foe
  downed mid-fight shows "ko" before the fight ends; shown_hp equals the sim hp after each batch.
- A balance test: 200 seeded auto fights at XP 0, win rate between 0.80 and 0.90.

## Checklist
- has: features/neon/battle/map_battle.gd :: var seed_override
- test: features/neon/battle/tests/test_map_battle.gd :: test_played_melee_waits_for_impact
- test: features/neon/battle/tests/test_map_battle.gd :: test_midfight_ko_shows
- key: localization/neon.csv :: NEON_NAME_GUARD

## Proof
`bash tools/check.sh` raw last 15 lines; render tools/shot_neon_battle.tscn -> C:/dev/game/inbox/neon_battle.png
mid-attack (the hero next to a guard); small WIP commits.
