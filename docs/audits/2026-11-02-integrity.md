# Integrity Audit: 2026-11-02

## 1. Dead scenes and scripts
features/neon/battle/battle_demo.tscn:1 | loaded by tools/shot_neon_battle.gd:13 via load("res://features/neon/battle/battle_demo.tscn") | archive
features/neon/battle/battle_demo.gd:1 | attached script to battle_demo.tscn, only reached via tool shot_neon_battle | archive
features/puzzles/defs/light_lock_def.gd:1 | unreached by game roots; preloaded in core/content_db.gd:51 but kind unused in game | leave
features/puzzles/defs/water_net_def.gd:1 | unreached by game roots; preloaded in core/content_db.gd:52 but kind unused in game | leave
features/puzzles/logic/water_net.gd:1 | reachable only by features/puzzles/tests/test_water_net.gd; uncalled by game loop | leave
features/ui/view/loot_popup.gd:1 | reachable only by features/ui/tests/test_popups.gd; uninstantiated in runtime scenes | leave
features/ui/view/area_title_card.gd:1 | reachable only by features/ui/tests/test_title_overlay.gd; no caller in features/neon | leave
features/workshop/logic/materials.gd:1 | reachable only by features/workshop/tests/test_workshop_logic.gd; static class unused in game | leave
assets/portraits/rydan_neutral.png:1 | runtime-loaded via res://assets/portraits/<speaker>_<expr>.png in pause/dialogue | leave
assets/textures/ui_bg/pause.webp:1 | runtime-loaded via Image.load_webp_from_buffer in features/ui/view/menu_backdrop.gd:18 | leave

## 2. Exactly what row 4 archives from the turn-based battle
features/combat/logic/timeline.gd:1 | Grandia-style turn-based timeline simulation and tick loop | archive
features/combat/logic/formation.gd:1 | two-row turn-based battle formation slots and melee coverage rules | archive
features/combat/logic/battle_sim.gd:1 | turn-based battle simulation state, seeded turn RNG, and event processing | archive
features/combat/logic/battle_ai.gd:1 | turn-based enemy move selection heuristics and heal/guard thresholds | archive
features/combat/logic/battle_action_rules.gd:1 | turn-based action validation and damage calculation formulas | archive
features/combat/defs/battle_rules_def.gd:1 | tunable turn-based combat formula parameters (factors, variance, SP gains) | archive
features/combat/defs/battle_view_def.gd:1 | turn-based battle screen layout and pacing definitions | archive
features/combat/defs/vfx_def.gd:1 | turn-based battle VFX configuration | archive
features/combat/view/battle_timeline_bar.gd:1 | UI bar rendering turn timeline and unit turn icons | archive
features/combat/view/battle_hud.gd:1 | turn-based battle HUD container | archive
features/combat/harness/balance.gd:1 | headless Monte Carlo balance runner for turn-based combat | archive
features/combat/tests/test_battle_sim.gd:1 | unit test suite for turn-based battle sim | archive
features/neon/battle/map_battle.gd:1 | on-map turn-based battle orchestrator and event pump | archive
features/neon/battle/battle_demo.tscn:1 | turn-based battle testing arena scene | archive
features/neon/battle/defs/neon_battle_view_def.gd:1 | layout definitions for on-map turn-based battle | archive
features/neon/battle/tests/test_map_battle.gd:1 | integration test suite for on-map turn-based battle | archive
content/combat/rules.json:1 | content data for turn-based battle formulas | archive
content/combat/view.json:1 | content layout data for turn-based battle screen | archive
content/neon/battle_view.json:1 | content layout data for on-map battle HUD | archive
localization/battle.csv:1 | player text strings for turn-based combat HUD and menus | archive
localization/neon_battle.csv:1 | player text strings for on-map battle intro and victory banners | archive
tools/shot_neon_battle.gd:1 | developer tool script rendering turn-based battle demo | archive
features/combat/defs/combatant_def.gd:1 | core stats (HP, attack, defense, agility) shared by items, equipment, and party | leave
features/combat/defs/action_def.gd:1 | action definition schema shared by consumables and equipment | leave
features/combat/defs/encounter_def.gd:1 | encounter reward container (XP, riyal, loot) used by progression and rewards | leave
content/combat/combatants.json:1 | character base stats for Rydan, Bilqis, Zayd, Roya, Abu Nabil | leave
content/combat/actions.json:1 | player technique costs and power data | leave
content/combat/encounters.json:1 | encounter reward tables | leave

## 3. Files past the code rules
features/workshop/view/workshop_materials_bar.gd:19 | func update_requirements() (50 lines, max 40) | action: split function
features/audio/tests/test_music_contexts.gd:85 | func test_fallback_resolution_chains_and_missing() (49 lines, max 40) | action: split function
tools/bake_sprites.gd:60 | func _restyle() (46 lines, max 40) | action: split function
features/ui/view/screens/pause_menu.gd:20 | func build() (45 lines, max 40) | action: split function
features/puzzles/defs/light_lock_def.gd:15 | func read() (45 lines, max 40) | action: split function
features/ui/view/screens/shop_summary.gd:11 | func _init() (44 lines, max 40) | action: split function
features/equipment/view/equipment_stats_panel.gd:67 | func _build_ui() (44 lines, max 40) | action: split function
features/ui/view/screens/shop_detail.gd:12 | func _init() (42 lines, max 40) | action: split function
features/ui/view/screens/slot_row.gd:15 | func setup() (42 lines, max 40) | action: split function
features/neon/battle/defs/neon_battle_view_def.gd:50 | func read() (41 lines, max 40) | action: split function
core/content_db.gd:1 | ## ContentDB autoload: preloads and parses content JSON; lacks literal "purpose:" | action: leave
core/game_state.gd:1 | ## GameState autoload: single source of truth for runtime state; lacks literal "purpose:" | action: leave
core/scene_router.gd:1 | ## Router autoload: owns scenes, transitions and save states; lacks literal "purpose:" | action: leave

## 4. Numbers in code that belong in content JSON
features/combat/logic/timeline.gd:8 | const COMMAND_POINT: int = 7000 | action: move to JSON
features/combat/logic/timeline.gd:9 | const ACT_POINT: int = 10000 | action: move to JSON
features/combat/logic/timeline.gd:10 | const INTERRUPT_POS: int = 2500 | action: move to JSON
features/combat/logic/timeline.gd:11 | const AFTER_ACT_POS: int = 2000 | action: move to JSON
features/combat/logic/battle_ai.gd:129 | if move.power <= 4 and move.applies_status != &"": | action: move to JSON
features/combat/logic/battle_ai_tactics.gd:23 | if not move.cancels_cast and move.knockback >= 2000 and move.is_hostile(): | action: move to JSON
features/combat/defs/combatant_def.gd:6 | const AGILITY_MIN: int = 1 | action: move to JSON
features/combat/defs/combatant_def.gd:7 | const AGILITY_MAX: int = 99 | action: move to JSON
features/combat/defs/combatant_def.gd:8 | const CAST_SPEED_MIN: float = 0.5 | action: move to JSON
features/combat/defs/combatant_def.gd:9 | const CAST_SPEED_MAX: float = 2.0 | action: move to JSON
features/neon/battle/logic/map_formation.gd:8 | const HERO_OFFSET: float = 120.0 | action: move to JSON
features/neon/battle/logic/map_formation.gd:9 | const FOE_OFFSET: float = 140.0 | action: move to JSON
features/neon/battle/logic/map_formation.gd:10 | const FOE_GAP: float = 110.0 | action: move to JSON
features/ui/view/screens/shop_detail.gd:122 | out[hero] = Vector2i(cdef.max_hp, cdef.max_sp) if cdef != null else Vector2i(100, 50) | action: move to JSON
features/ui/view/screens/shop_party_mini.gd:31 | var max_hp: int = cdef.max_hp if cdef != null else 100 | action: move to JSON

## 5. Player text outside TextDB
features/equipment/view/equipment_hero_header.gd:177 | _lv_lbl.text = "Lv %d" % lv | action: key
features/ui/view/screens/pause_hero_row.gd:103 | _lv_node.text = "Lv %d" % lv | action: key
features/equipment/view/equipment_hero_header.gd:187 | _xp_text.text = "MAX" | action: key
features/ui/view/screens/slot_detail.gd:63 | _header.text = "SLOT %02d" % slot | action: key
features/ui/view/screens/shop_summary.gd:57 | _qty.text = "00" | action: key
features/equipment/view/equipment_hero_header.gd:45 | _class_lbl.text = "(%s)" % Ui.text(c_def.name_key) if c_def != null else "" | action: key
features/ui/view/screens/pause_menu.gd:144 | button.text = "%d  %s" % [index, Ui.text(PauseLogic.label_key(id))] | action: key
features/workshop/view/workshop_materials_bar.gd:63 | _riyal_label.text = "%s %s" % [PauseLogic.grouped(riyal_cost), Ui.text("MONEY_GLYPH")] | action: key
features/ui/view/screens/items_party_panel.gd:61 | text = "%s  %s" % [text, cures] | action: key
features/neon/battle/map_battle_hud.gd:55 | _stamp.text = "%s\n%s   %s" % [BattleStyle.text("NEON_BATTLE_VICTORY"), | action: key
features/ui/view/party_card.gd:69 | _hp_text.text = "%d/%d" % [hp, int(_hp_bar.max_value)] | action: key
features/ui/view/party_card.gd:70 | _sp_text.text = "%d/%d" % [sp, int(_sp_bar.max_value)] | action: key
features/ui/view/screens/pause_hero_row.gd:107 | _xp_text.text = "%d/%d" % [xp_amount, next_xp] | action: key
features/ui/view/screens/pause_hero_row.gd:136 | _hp_text.text = "%d/%d" % [hp, int(_hp_bar.max_value)] | action: key
features/ui/view/screens/pause_hero_row.gd:137 | _sp_text.text = "%d/%d" % [sp, int(_sp_bar.max_value)] | action: key

## 6. Tests that only check a mock
features/combat/tests/test_action_def.gd:28 | check("\n".join(_read({"target": "everyone"})).contains("target"), "unknown target") | action: fix test
features/combat/tests/test_action_def.gd:29 | check("\n".join(_read({"vfx": "fireball"})).contains("vfx"), "unknown vfx") | action: fix test
features/combat/tests/test_action_def.gd:30 | check("\n".join(_read({"target": "foe", "heal": 10})).contains("cannot heal"), "a foe move cannot heal") | action: fix test
features/combat/tests/test_action_def.gd:31 | check("\n".join(_read({"target": "ally", "power": 5, "heal": 10})).contains("cannot hurt"), "an ally move has power 0") | action: fix test
features/combat/tests/test_action_def.gd:32 | check("\n".join(_read({"target": "self", "cancels_cast": true})).contains("cannot hurt or cancel"), "or cancel") | action: fix test
features/combat/tests/test_action_def.gd:33 | check("\n".join(_read({"target": "ally", "revive": true})).contains("revive"), "revive needs heal") | action: fix test
features/combat/tests/test_action_def.gd:34 | check("\n".join(_read({"target": "all_allies", "heal": 10, "revive": true})).contains("revive"), "revive needs target ally") | action: fix test
features/combat/tests/test_action_def.gd:35 | check_eq(_read({"target": "ally", "heal": 10, "revive": true, "vfx": "heal"}), PackedStringArray(), "a valid revive") | action: fix test
core/tests/test_def_reader.gd:12 | var pair: Array = _read({"slots": [0, 2, 3.0]}) | action: fix test
features/ui/tests/test_screens.gd:133 | Screens.register(&"dummy", func() -> Control: return Dummy.new()) | action: fix test

## Top 10
features/combat/logic/timeline.gd:1 | Grandia-style turn-based timeline simulation and tick loop | archive
features/neon/battle/map_battle.gd:1 | on-map turn-based battle orchestrator and event pump | archive
features/combat/logic/battle_sim.gd:1 | turn-based battle simulation state, seeded turn RNG, and event processing | archive
features/combat/defs/battle_rules_def.gd:1 | tunable turn-based combat formula parameters (factors, variance, SP gains) | archive
features/combat/tests/test_action_def.gd:28 | check("\n".join(_read({"target": "everyone"})).contains("target"), "unknown target") | action: fix test
features/workshop/view/workshop_materials_bar.gd:19 | func update_requirements() (50 lines, max 40) | action: split function
features/ui/view/screens/pause_menu.gd:20 | func build() (45 lines, max 40) | action: split function
features/combat/logic/timeline.gd:8 | const COMMAND_POINT: int = 7000 | action: move to JSON
features/ui/view/screens/shop_detail.gd:122 | out[hero] = Vector2i(cdef.max_hp, cdef.max_sp) if cdef != null else Vector2i(100, 50) | action: move to JSON
features/equipment/view/equipment_hero_header.gd:177 | _lv_lbl.text = "Lv %d" % lv | action: key
