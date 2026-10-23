# Brief: zayd-kit (<= 60 lines; run AFTER rpg-rolls-flee is merged into claude/menus-rpg-5089fa)
You are in your own worktree on branch oc/zayd-kit (made from claude/menus-rpg-5089fa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras: "all Zayd's SP moves are weaker than his normal attack, while also all having the same effect ... basically
useless. They should be interesting to use." His approved redesign (2026-10-22) was never built.

## Read first
docs/design/zayd-moves.md ALL of it (sections 3, 4, 5 and 7 are the spec; section 7 = the damage fix);
features/combat/logic/battle_resolver.gd, timeline.gd, battle_sim.gd, battle_ai.gd, battle_rolls.gd;
content/combat/actions.json, statuses.json; features/combat/defs/action_def.gd, status_def.gd.

## What to build
1. Damage fix (zayd-moves.md 7): per hit = max(1, round((power + (attack - defense x defense_factor) / hit_count)
   x row x variance)); then crit, then damage_taken as today. Single-hit moves give the same numbers as before.
2. actions.json numbers: jambiyah_strike power 12 x 2; breaker power 30, SP 7; crushing_blow (Flash Flood) SP 8;
   quick_slash (Gazelle Step) power 10, SP 4, no cancel; piston_jab (Piston Shove) power 6, knockback 2600,
   ignores_cover, SP 4, no cancel; elder_cut (Elder's Patience) target self, power 0, cast 2.0, recovery 0, SP 3,
   applies poised, no cancel. Names and descriptions (localization/combat.csv): the English names in section 3; the
   description line adds the Yemeni name in Latin letters ("Darba", "Kasr", ...). No Arabic script anywhere.
3. Engine fields (section 4 table, exactly): ActionDef sp_gain, after_act_pos, cast_status, bonus_vs_status +
   bonus_mult; StatusDef counter_action, counter_ranged; statuses poised (1 turn, damage_taken 0.5, counter_action
   reverse_stab) and exposed (damage_taken 1.5); jambiyah_strike sp_gain 2; quick_slash after_act_pos 4500;
   crushing_blow cast_status exposed; arc_discharge bonus_vs_status jammed, bonus_mult 1.5.
4. Counter: the first hostile melee hit that leaves a poised unit alive -> event `countered` (unit = the poised unit,
   detail = attacker id), then strike(reverse_stab) at the attacker, then poised ends. Edge cases in section 4.
5. BattleAI rules of section 4 (stance, shove, arc, no Flash Flood near an enemy ACT).
6. View: popups "Countered!" and "Conducted" (x1.5 on a jammed foe), the exposed icon on the hero's strip, a ghost
   marker on the timeline bar for Piston Shove's landing (pure query knockback_preview(actor, action, target) -> int
   on BattleSim). Text keys in localization/combat.csv.
7. Re-run the balance harness; tune ONLY enemy numbers in combatants.json (HP, attack) until every row is 65-90% wins
   and 40-90 s; paste the table into docs/design/prosthetics.md with the date.

## Do NOT edit
features/world/**, content/world/**, features/equipment/**, features/ui/view/screens/**, core/**, docs/DECISIONS.md,
HANDOFF.md, any *.import, features/progression/**, features/items/**, content/progression/**, content/jambiyah/**,
content/items/**. battle_rolls.gd: read only. rpg-progression runs beside you: in combatants.json, combatant_def.gd,
perks.json and localization/combat.csv make the smallest edit (change your rows, append new keys at the end).

## Tests (features/combat/tests/test_zayd_kit.gd + the list in zayd-moves.md section 5)
Every test of section 5; plus: the damage split (2-hit strike at Atk 26 vs Def 14 = 2 x round(12 + 9.5) with variance
0); a single-hit move gives the same damage as before the change; at base stats breaker and crushing_blow out-damage
jambiyah_strike on the same enforcer; arc_discharge on 2 enforcers out-damages one strike; Zayd's start loadout holds
exactly one cancel move.

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits after each step; final message ends with
`Built-by: <model> (opencode)` or `Built-by: Gemini 3.8 Flash (agy)`.
