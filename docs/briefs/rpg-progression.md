# Brief: rpg-progression (<= 60 lines; run AFTER rpg-rolls-flee merges; it may run beside zayd-kit)
You are in your own worktree on branch oc/rpg-progression (made from claude/menus-rpg-5089fa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras: classic JRPG progression (experience, levels, a class per hero, stats that grow with level and class) and armor
that raises HP and defense, beside the jambiyah, the prosthetic and the hilt gemstones.

## Read first
docs/design/rpg-systems.md sections 4-8 and 10 (THE SPEC; every number); docs/design/hilt-stones.md 2-5;
features/items/logic/gear.gd, inventory.gd, perks.gd; features/jambiyah/logic/loadout.gd; features/items/defs/equip_def.gd,
rarity_def.gd; core/game_state.gd; core/save/save_codec.gd (_v3_to_v4 is the model); core/content_db.gd (KINDS,
ITEM_KINDS); core/battle_session.gd (_win); features/combat/harness/battle_loader.gd; features/equipment/logic/
equipment_options.gd (a Gear.build caller).

## What to build
1. Content + Defs (registered in ContentDB.KINDS; armor in ITEM_KINDS): content/progression/levels.json (LevelsDef:
   xp_total array), content/progression/classes.json (ClassDef: hero, name_key, desc_key, growth dict, passive perk
   id), content/items/armor.json (ArmorDef extends EquipDef: max_hp, defense, agility, weight, heroes), content/
   jambiyah/stones.json (StoneDef extends EquipDef: the 12 stones of hilt-stones.md 5, effects as perk ids or stat
   adds), rarities.json `stone_slots` (hilt-stones.md 2), content/jambiyah/heirloom.json (rank -> flag). New perks
   in perks.json for the passives and stone effects that map onto existing perk kinds; the 4 stones whose effects
   need zayd-kit moves (qamar_stone, ayn_bead, marib_stone, jadd_aqiq) get perk kinds with `TODO(zayd-kit)` and a
   no-op apply, so content loads.
2. Pure logic features/progression/logic/: Progression.level(xp, levels) (cap = array length), Progression.grow(base,
   class, level) -> new CombatantDef (growth x (level - 1)); Progression.award(xp: Dictionary, party, amount) ->
   Array of LevelUp {hero, from, to, gains}; encounter_xp(encounter) = sum of enemy xp; repeat share from
   EconomyRulesDef `repeat_xp_share` 0.5 (add it to content/economy/rules.json).
3. Gear: new `Gear.build_hero(hero_id: StringName, state: GearState) -> CombatantDef`; GearState (RefCounted) holds
   level, armor, hilt, blade, prosthetic, socketed stones, upgrades, perks. Merge order exactly rpg-systems.md 7.
   Keep the old Gear.build(...) as a thin wrapper (old tests and callers keep working). Hilt stones: Stones.open_slots
   (hilt, flags) (heirloom rank from flags), Stones.fits(stone, hilt), Stones.set_stone(sockets, hilt, slot, stone)
   (moving it out of any other hilt).
4. GameState: xp {hero: int}, sockets {hilt: Array[StringName]}, upgrades {item: int}, materials {id: int}; to_dict /
   from_dict; SaveCodec VERSION 5 with _v4_to_v5 exactly as rpg-systems.md 10. start_new() gives the start armor.
5. BattleSession._win: award XP (repeat share when the patrol was already cleared), raise current HP/SP by the gains,
   put the LevelUp list on BattleOutcome (`level_ups`); battle_end_panel shows one line per LevelUp: "Zayd reached
   Lv 3" + "HP +30  ATK +2 ..." (localization/combat.csv UI_LEVEL_UP, English only).
6. Battles build heroes with Gear.build_hero from GameState (battle_loader.gd / battle_runner path); the harness takes
   a level per encounter (patrol_pair 1, patrol_drone 2, patrol_gate 3, abu_nabil_duel 1 and 3) and prints them.

## Do NOT edit
features/world/**, content/world/**, features/ui/view/screens/**, features/equipment/view/**, features/combat/logic/
battle_resolver.gd, battle_rolls.gd, timeline.gd, battle_ai.gd, content/combat/actions.json, statuses.json,
docs/DECISIONS.md, HANDOFF.md, any *.import. zayd-kit runs beside you: in combatants.json, combatant_def.gd, perks.json
and localization/combat.csv make the smallest edit (add fields and keys at the end; never retune numbers).

## Tests (features/progression/tests/, core/tests/test_game_state.gd)
level(xp) at each threshold and the cap; grow() at Lv1 equals the base; Lv3 Zayd = base + 2 x growth; award shares
full XP to downed heroes and 50% on a repeat win; a LevelUp raises current HP by the max HP gain; merge order (armor
before hilt; caps last; AGI cap 99 with growth); stones: fit by rarity, heirloom rank 1 opens 1 slot, moving a stone
empties its old socket; v4 save -> v5 with the start armor, Red Aqiq in the heirloom and xp 0; a round trip of v5;
old Gear.build gives the same fighter as before.

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends with the Built-by line.
