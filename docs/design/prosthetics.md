# Prosthetics, rarity, items and perks (prototype rules; every number lives in content/)
Owner decisions 2026-10-21: one prosthetic slot per hero; it grants the tech moves (replacing "magic"), paid
from SP; the jambiyah (hilt + blade) stays Zayd's physical weapon. Five rarities on hand-made fixed items
(no random rolls) plus a story-only Heirloom tier. Code: features/items, features/prosthetics, features/combat.

## Rules
- Rarity (content/items/rarities.json): common (white) < uncommon (green) < rare (blue) < epic (purple) <
  legendary (gold), and heirloom (carnelian red #d9503f, story_only: never loot or chest content; a test checks).
- Every hilt, blade and prosthetic has a required, reference-checked "rarity". An optional "perk" is allowed
  only on tiers with allows_perk (Rare and above, Heirloom); all shipped Rare+ items carry one. Higher rarity =
  stronger stats plus that one extra perk.
- Item ids are unique across hilts, blades and prosthetics (get_def("item", id)). Inventory (GameState.inventory)
  holds each item at most once. Slots: GameState.equipment "zayd.hilt", "zayd.blade", "zayd.prosthetic",
  "bilqis.prosthetic" (save v3; v2 "hilt"/"blade" migrate to "zayd.*" and worn items count as owned).
  A missing slot means the hero's start loadout (content/jambiyah/loadouts.json).
- A prosthetic fits only its wearer and grants 1-2 tech moves. Merge: base -> hilt -> blade -> prosthetic ->
  perks -> caps (Gear.build), always on a copy. Tech moves are ActionDefs (target, heal, revive, vfx).
- Perk kinds (PerkDef, implemented in combat logic): sp_per_act (extra SP per act), hp_regen (HP per act),
  bonus_knockback (added to the first hit's knockback), start_bonus (timeline units at battle start).
- Loot: EncounterDef "loot" (guaranteed ids) is granted after a won battle; chests (content/items/chests.json,
  kind chest: id, item, place) open once, the opened state is the flag chest_opened_<id>. EventBus
  item_obtained(item_id) fires for each new item. Place "workshop" = the bench stock (given on the first workshop
  visit); place "rooftop" chests are not on the map yet.

## Items (stats are adds to the base; Zayd base: HP 400, SP 24, Atk 20, Def 14, Agi 40, Wt 3)
| Item | Slot | Rarity | Numbers | Perk | Gives |
|---|---|---|---|---|---|
| grandfather_hilt | Zayd hilt | Heirloom (start) | Agi +1, cast x1.0, Wt +1 | head_start (+600 start) | elder_cut |
| swift_hilt | hilt | Uncommon (bench) | Agi +1, cast x1.02, Wt +0.5 | - | quick_slash |
| anvil_hilt | hilt | Rare (patrol drop) | Agi 0, cast x1.0, Wt +1 | heavy_hand (+700 knockback) | crushing_blow |
| rustwire_blade | Zayd blade | Common (start) | Atk +6, Wt +0.5 | - | - |
| keen_blade | blade | Uncommon (bench) | Atk +8, Wt +1 | - | - |
| broad_blade | blade | Rare (not yet) | Atk +5, knockback +1500, Wt +2 | steady_current (+1 SP) | - |
| salvage_arm | Zayd arm | Common (start) | Atk +2, Def +1, Wt +1 | - | piston_jab |
| cradle_spine | Zayd spine | Rare (not yet) | HP +10, Def +1, Agi -2, Wt +2.5 | mender_loop (8 HP) | reactive_guard |
| arc_arm | Zayd arm | Epic (chest) | SP +6, Atk +4, Agi +1, Wt +1.5 | surge_current (+2 SP) | arc_discharge, piston_jab |
| wrist_rig | Bilqis arm | Common (start) | SP +4, Wt +0.3 | - | nanite_mend |
| lens_array | Bilqis eye | Uncommon (chest) | SP +4, Atk +1, Agi +1, Wt +0.3 | - | nanite_mend, overclock_link |
| dawn_lens | Bilqis eye | Legendary (not yet) | HP +10, SP +4, Atk +2, Agi +2, Wt +0.5 | deep_mender (12 HP) | overload_lance, reboot_pulse |
Prototype plan: start with grandfather_hilt, rustwire_blade, salvage_arm (Zayd) and wrist_rig (Bilqis); the bench
gives swift_hilt and keen_blade; the patrol drops anvil_hilt; chests hold arc_arm and lens_array.

## Tech moves (target; SP; effect)
piston_jab (foe; 5; power 8, cancels), arc_discharge (all foes; 10; power 14 each, ranged), reactive_guard (self; 5;
guarded: damage taken x0.6 for 2 turns), nanite_mend (ally; 6; heal 50 + Atk x0.5), overclock_link (all allies; 10;
overclocked 3 turns: wait speed x1.25, cast speed x1.15), overload_lance (foe; 14; power 60, ranged, slow),
reboot_pulse (ally; 14; heal 60 + Atk x0.5, revives a downed ally), elder_cut (foe; 4; power 12, cancels).

## Balance (tools/run_godot.sh -s res://features/combat/harness/balance.gd -- 300 [all])
300 seeded battles per row, BattleAI plays both sides (it heals an ally under 40% HP, revives, guards before a
big cast); Bilqis in her wrist_rig. Rows are Zayd hilt + blade + prosthetic; noise is about +-3 points.
```
obtainable now (with rpg-rolls-flee rules: dodge/crit/resist/flee)  win %   secs
2026-10-23 harness (30 battles each, faster run):
grandfather + rustwire + salvage_arm                  3.3   49.6
grandfather + rustwire + arc_arm                      0.0   48.8
grandfather + keen + salvage_arm                      0.0   44.6
grandfather + keen + arc_arm                          0.0   49.1
swift + rustwire + salvage_arm                        0.0   47.8
swift + rustwire + arc_arm                            0.0   47.5
swift + keen + salvage_arm                            0.0   47.6
swift + keen + arc_arm                                0.0   45.6
anvil + rustwire + salvage_arm                        0.0   46.3
anvil + rustwire + arc_arm                            0.0   47.4
anvil + keen + salvage_arm                            0.0   51.0
anvil + keen + arc_arm                                0.0   47.3
bilqis: wrist_rig                                      3.3   49.6
bilqis: lens_array                                     0.0   47.0
```
The new roll rules (dodge, crit, resist, flee) significantly change balance; the harness still runs cleanly.
Target unchanged: 65-90% wins per pairing. Numbers will be retuned by play-through after rules stabilize.
