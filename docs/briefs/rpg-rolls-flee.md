# Brief: rpg-rolls-flee (<= 60 lines)
You are in your own worktree on branch oc/rpg-rolls-flee (made from claude/menus-rpg-5089fa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras: battles need a resist chance, a dodge/miss chance and crits from both fighters' stats, and an escape that must not
always work and is never allowed against bosses.

## Read first
docs/design/rpg-systems.md sections 1, 2, 3 (THE SPEC: every number and event there); docs/design/combat.md "Resolving
an action"; features/combat/logic/battle_resolver.gd (_hit_target, _damage, _apply_status), battle_action_rules.gd
(rolls_miss), battle_sim.gd (rng, choose), battle_outcome.gd; core/battle_session.gd (_on_stage_ended);
features/combat/view/battle_command_menu.gd (the Items entry is the model for Flee), battle_stage.gd lines 110-130,
battle_numbers.gd and battle_notices.gd (pop-up text and banners).

## What to build
1. CombatantDef: `luck` (int 0-99, default 5), `xp` (int 0-9999, default 0), `dodge_bonus`, `crit_bonus`,
   `status_pierce` (float 0-1, default 0). combatants.json: luck zayd 10, bilqis 12, concession_enforcer 5,
   survey_drone 8, abu_nabil 15; xp enforcer 30, drone 45, abu_nabil 150. Perks.apply adds the 3 new perk kinds
   dodge_bonus, crit_bonus, status_pierce (perks.json reader accepts them).
2. battle_rules (rules.json + BattleRulesDef): hit_base 0.95, hit_agi_k 0.006, hit_min 0.60, hit_max 0.99, crit_base
   0.05, crit_lck_k 0.004, crit_max 0.40, crit_mult 1.5, crit_knockback 1.25, resist_base 0.10, resist_lck_k 0.01,
   resist_max 0.75, flee_base 0.50, flee_agi_k 0.01, flee_step 0.15, flee_ambushed -0.20, flee_ambusher 0.20,
   flee_min 0.10, flee_max 0.95.
3. New pure class features/combat/logic/battle_rolls.gd (BattleRolls, static funcs, no Timeline): hit_chance(att, tgt,
   rules), crit_chance(att, rules), resist_chance(att, tgt, rules), flee_chance(party: Array[UnitState], foes, fails,
   ambush, rules); each clamps as the spec says.
4. BattleSim gets a second RNG `roll_rng`, seeded `hash([battle.seed, "rolls"])`; the existing `rng` draws stay
   exactly as they are. BattleSim.rolls_enabled (default true): old tests that pin exact damage set it false.
5. BattleResolver, per target, once per action, after the confusion miss: dodge (skip when power == 0, action
   `sure_hit`, or the reverse stab) -> event `dodged` (unit target, detail action id), nothing else on that target;
   crit -> event `crit` before that target's first `damage`, all its hits x crit_mult, first-hit knockback x
   crit_knockback; resist when a hostile status would land -> event `resisted` (detail status id) instead of `status`.
   ActionDef gains `sure_hit` (bool, default false). Update combat.md's event list.
6. Flee: actions.json `flee` (target self, power 0, cast_speed 1.4, recovery 1000, sp_cost 0, vfx none). The command
   menu shows a FLEE entry after Items for party units; EncounterDef `can_flee` (default true), false on
   abu_nabil_duel: the entry is disabled with the chip "Can't flee" and BattleSim.choose refuses flee there. At ACT
   roll flee_chance with BattleSim.flee_fails: success = event `fled` and sim.result = &"fled"; failure = event
   `flee_failed` (value = fails + 1), fails += 1. Interrupted flee = no roll.
7. BattleOutcome.FLED = &"fled". battle_stage: on fled, banner "Escaped!" (UI_FLED) then end with &"fled", no end
   panel. BattleSession: FLED keeps vitals and bag (GameState.set_vitals / set_bag), pays nothing, never adds to
   cleared_patrols; the area return path stays as after a defeat (patrol reset, grace time).
8. View pops (battle_numbers / battle_labels): "Dodged" (c_muted) on the target, "Critical!" (c_qam_amber, 1.3x size)
   with the damage number, "Resisted" (c_epithet), "Escape failed" banner. Texts in localization/combat.csv (keys
   UI_DODGED, UI_CRIT, UI_RESISTED, UI_FLED, UI_FLEE_FAILED, UI_FLEE, UI_CANT_FLEE). English only; no Arabic script.
9. The balance harness (features/combat/harness) still runs; paste its table into docs/design/prosthetics.md's table
   spot with the date.

## Do NOT edit
features/world/**, content/world/**, features/equipment/**, features/ui/view/screens/**, core/game_state.gd,
core/save/**, docs/DECISIONS.md, HANDOFF.md, any *.import. Smallest edits in shared files (EventBus, ContentDB).

## Tests (features/combat/tests/test_battle_rolls.gd, test_flee.gd)
Each chance formula at its clamps (min and max) and one middle value; equal stats give hit 0.95, crit 0.05 + 0.004 x
LCK; a dodged target takes no damage, knockback or status; a forced crit (crit_base 1.0 in a test rules copy) does
x1.5; a forced resist emits `resisted` and no `status`; sure_hit never dodges; flee chance +0.15 per fail and ambush
-0.20/+0.20; flee refused on abu_nabil_duel; an interrupted flee does not count a fail; FLED outcome keeps vitals and
does not clear the patrol; with rolls_enabled false an old seeded battle gives the same numbers as before.

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits after each step; final message ends with
`Built-by: inkling:free (opencode)`.
