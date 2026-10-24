# RPG systems (v1, 2026-10-23; approved by Feras; every number is [PLACEHOLDER] until the harness and a play-through)
Feras asked for classic JRPG depth around the timeline battles: escape that can fail, XP and levels, a class per hero,
armor, resist / dodge / crit rolls, and a workshop for upgrades, gemstones and crafting. His choices: flee is a short
cast that can be interrupted; one fixed class per hero; crafting small but real; the equipment screen shows a live 3D
hologram (screens: docs/design/rpg-menus.md). Every number below lives in content JSON; code reads it from Defs.

## 1. Stats
HP, SP, ATK, DEF, AGI, WT as today, plus one new stat: **LCK** (CombatantDef `luck`, int 0-99, default 5): crits and
status resist. Zayd 10, Bilqis 12, concession_enforcer 5, survey_drone 8, abu_nabil 15.
CombatantDef also gains `xp` (int 0-9999, default 0): what beating one of this kind is worth.

## 2. Rolls (pure class BattleRolls, no timeline dependency, so it survives the action-combat rewrite)
- RNG: a SECOND RandomNumberGenerator, `roll_rng`, seeded with `hash([battle seed, "rolls"])`; the battle RNG is left
  untouched, so every existing seeded sequence, damage number and test keeps its value.
- Order per target, once per action (not per hit), after the confusion miss (unchanged: one roll for the whole action):
  dodge, then crit, then (when a status would land) resist.
- **Dodge** (hostile moves with power > 0; ActionDef `sure_hit: true` and the reverse stab skip it):
  hit = clamp(hit_base 0.95 + hit_agi_k 0.006 x (attacker AGI - target AGI) - target dodge_bonus, hit_min 0.60,
  hit_max 0.99). Dodged: event `dodged` (unit = target, detail = action id); that target takes no damage, knockback,
  cancel or status. Other targets of an all_foes move roll on their own.
- **Crit**: chance = clamp(crit_base 0.05 + crit_lck_k 0.004 x attacker LCK + attacker crit_bonus, 0, crit_max 0.40).
  On a crit every hit on that target deals x crit_mult 1.5 (after variance, before damage_taken) and the first hit's
  knockback is x crit_knockback 1.25. Event `crit` (unit = target) comes right before that target's first `damage`.
- **Resist** (a hostile status about to land on a living target): chance = clamp(resist_base 0.10 + resist_lck_k 0.01 x
  (target LCK - attacker LCK) - attacker status_pierce, 0, resist_max 0.75). Resisted: event `resisted` (unit = target,
  detail = status id) instead of `status`.
- Event order (combat.md list): ... act, missed, dodged, crit, damage, interrupted / knocked_back, healed, revived,
  status / resisted, status_ended, down, fizzled, flee_failed, fled, victory, defeat.
- Constants: content/combat/rules.json battle_rules gains hit_base, hit_agi_k, hit_min, hit_max, crit_base, crit_lck_k,
  crit_max, crit_mult, crit_knockback, resist_base, resist_lck_k, resist_max.
- New perk kinds (content/items/perks.json): dodge_bonus (float, subtracts from the attacker's hit chance), crit_bonus
  (float), status_pierce (float). CombatantDef gains the three fields (default 0.0); Perks.apply adds them.

## 3. Flee (a short cast that can be hit)
- Battle command "Flee" for a party unit at COMMAND, after Items. ActionDef `flee`: target self, power 0, cast speed
  1.4, recovery 1000, vfx none, in no combatant's move list (offered by the command menu like Items).
- A hit before ACT cancels it like any cast (that is not a failed try).
- At ACT: chance = clamp(flee_base 0.50 + flee_agi_k 0.01 x (mean AGI of living party - mean AGI of living foes)
  + flee_step 0.15 x fails + ambush_mod, flee_min 0.10, flee_max 0.95); ambush_mod = flee_ambushed -0.20 when
  ambush 1, flee_ambusher +0.20 when ambush 2, else 0. `fails` counts failed tries of the whole party this battle.
- Success: event `fled`, the battle ends with result FLED. Failure: event `flee_failed` (value = fails after the try),
  fails +1, the hero's turn is spent (recovery as usual).
- EncounterDef `can_flee` (bool, default true); false on abu_nabil_duel and every boss. There the button is disabled
  with the tag "Can't flee"; BattleSim.choose refuses flee too (a test).
- FLED (BattleOutcome.FLED): no rewards, no XP; vitals and bag carry over as after a win (downed heroes stand up at
  the economy rules' HP); the patrol is NOT cleared, goes back to its lane start and the grace time starts (the same
  PatrolDirector path as after a retry), so it cannot touch the party again at once.
- Patrol pair (AGI 30) vs Zayd + Bilqis (40, 44): 62%. Drone (48): 56%. Ambushed by the drone: 36%, then 51%, 66%...

## 4. XP and levels
- GameState.xp {hero id: int}; the level is DERIVED (never saved) from content/progression/levels.json: kind
  "levels", id "default", `xp_total` = [0, 60, 150, 280, 450, 670, 940, 1260, 1640, 2080] (index = level - 1; cap
  = its length, 10 in the demo).
- Encounter XP = sum of its enemies' `xp`: concession_enforcer 30, survey_drone 45, abu_nabil 150.
- Every party hero gets the full encounter XP, downed ones too (levels stay in step). A repeat win (patrol beaten
  before since the last sabil) pays repeat_xp_share 0.5 (economy rules, same as riyal), rounded down.
- Level-up: max HP and SP grow by the class growth; current HP and SP rise by the same amount (no full heal: the
  sabil is the heal). The battle end panel lists "Zayd reached Lv 3" and the gains (HP +30, ATK +2 ...).
- Pace: the first patrol (60) lifts both to Lv2; the next two fights reach Lv3; Abu Nabil (150) is worth a level.
  The full demo ends near Lv4. Harness levels: patrol_pair Lv1, patrol_drone Lv2, patrol_gate Lv3, abu_nabil_duel
  Lv1 and Lv3. Target unchanged: 65-90% wins per pairing.

## 5. Classes (content/progression/classes.json, kind "class"; one fixed class per hero)
Lv1 = today's stats (combatants.json), so balance holds at the start. Growth is added per level above 1 (no random).
| Hero | Class id (name) | Growth per level | Passive (a perk id) |
|---|---|---|---|
| zayd | courier (Courier) | HP +30, SP +2, ATK +2, DEF +2, AGI +1, LCK +1 | couriers_footing: dodge_bonus 0.05 |
| bilqis | rigger (Rigger) | HP +20, SP +4, ATK +2, DEF +1, AGI +1, LCK +2 | clean_code: status_pierce 0.15 |
| hamoud (later) | warden (Warden) | HP +40, SP +2, ATK +3, DEF +3, AGI +0, LCK +0 | old_guard: interrupt resist +0.2 |
ClassDef: id, name_key, desc_key, hero, growth {max_hp, max_sp, attack, defense, agility, luck}, passive (perk id).

## 6. Armor (slot "<hero>.armor"; stats only, the 3D model does not change in the demo)
ArmorDef extends EquipDef (content/items/armor.json, kind "armor"): max_hp, defense, agility (may be negative),
weight, heroes (who may wear it), upgrade. Weight slows the timeline (existing speed_weight_factor): the trade-off.
| Id | Rarity | Heroes | Stats | Where |
|---|---|---|---|---|
| courier_jacket | Common | zayd | HP +20, DEF +2, WT +0.5 | start |
| rig_shawl | Common | bilqis | HP +12, DEF +1, WT +0.3 | start |
| souq_leather | Uncommon | zayd, bilqis | HP +40, DEF +4, WT +1.5 | bench 120 |
| mesh_abaya | Uncommon | bilqis | HP +30, DEF +3, AGI +1, WT +0.5 | chest |
| concession_plate | Rare | zayd | HP +70, DEF +7, AGI -2, WT +3 | patrol_gate loot |

## 7. Gear merge (Gear.build; one new CombatantDef, the shared one never changes)
base -> level growth (class x level) -> armor -> hilt -> blade -> pistol (frame, barrel) -> stones (the worn
hilt's and ring's sockets) -> prosthetic -> upgrades (each worn item's upgrade x its level) -> perks (gear perks
+ class passive) -> caps (AGI 1-99, cast 0.5-2.0).

## 8. Hilt stones
Built as docs/design/hilt-stones.md says (stones.json, rarities.json `stone_slots`, heirloom rank from flags).
GameState.sockets {hilt id: [stone id or "", ...]} (length = the hilt's open slots). Set and removed at the
workshop only; the equipment screen shows them read only.

## 9. Workshop: upgrades, materials, crafting (nothing ever fails: no success rate)
- Upgrades: GameState.upgrades {item id: 0-3}. EquipDef gains `upgrade` {stat: add per level} (e.g. a blade
  {"attack": 2}, armor {"max_hp": 15, "defense": 1}). Costs per next level in content/workshop/upgrades.json, kind
  "upgrade_costs", by rarity: riyal [40, 80, 140] x rarity factor (Common 1.0, Uncommon 1.25, Rare 1.5, Epic 2,
  Legendary 2.5) plus materials ({scrap_copper: 2} at +1, {scrap_copper: 3, drone_coil: 1} at +2, {drone_coil: 2,
  salt_crystal: 1} at +3). The heirloom hilt has no upgrade: it grows by rank and stones.
- Materials: MaterialDef (content/items/materials.json, kind "material": id, name_key, desc_key, rarity, icon).
  GameState.materials {id: count}, cap 99 each. Encounters and chests gain an optional `materials` {id: count}.
  scrap_copper (Common; enforcers: 1 each), drone_coil (Uncommon; drones: 1 each), salt_crystal (Uncommon; chests).
  Repeat wins pay materials at the repeat share, rounded down. Materials never sell.
- Crafting: content/workshop/recipes.json, kind "recipe": id, output (item id), count, riyal, materials {id: count}.
  feathered herb x2 <- scrap_copper 1 + 10 riyal; a second herb x1 <- drone_coil 1 + 20; sulaimani (stone) <-
  scrap_copper 3 + 30; fayruz (stone) <- drone_coil 2 + salt_crystal 1 + 40. A stone already owned cannot be crafted
  again (stones are unique). Herb ids come from content/items/consumables.json.

## 10. Save version 5 (SaveCodec._v4_to_v5, with a migration test)
Adds xp {} (every hero 0), sockets {"grandfather_hilt": ["aqiq_red"]}, upgrades {}, materials {}, and the start armor
in equipment ("zayd.armor": courier_jacket, "bilqis.armor": rig_shawl) plus both in inventory.
