# Systems map: what a change touches (D21; read before writing a spec's or brief's Ripple section)
State of main on 2026-10-27, built from docs/MAP.md plus greps. Paths are greppable; when a row is wrong, fix it in the
same commit as the code. Combat is still the turn-based map fight; VISION's real-time combat replaces combat/logic and
combat/view, while the content, harness, save and UI rows below stay the ripple points.

## The spine (every feature follows it)
- content/<feature>/*.json -> read-only Def classes (features/*/defs, core/defs) -> pure rules (features/*/logic) ->
  view nodes (features/*/view). Numbers live in content, never in view code.
- Runtime state: core/game_state.gd (flags, party, equipment, inventory, bag, money, vitals, xp, sockets, upgrades,
  materials, cleared_patrols, area_id, save_point). Saves: core/save/save_codec.gd VERSION 6; a new or renamed field
  = a version bump + one migrate step + a test.
- Player text: localization/<feature>.csv through the TextDB autoload (new keys go into an existing CSV).
- Flow: core/scene_router.gd (flow_changed); Neon entry features/neon/neon_game.gd (start -> cold open -> roof -> map
  fight -> cable line).

## Assets that appear in more than one place (check each place)
| asset | appears in | player-visible check |
|---|---|---|
| hero portrait assets/portraits/<hero>_neutral.png | dialogue box (dialogue/view/portraits.gd, dialogue_layout.gd; content/dialogue/speakers.json, box.json); menus (ui/view/portrait_faces.gd -> party_card, items_hero_card, shop_keeper_box; equipment_hero_header; equipment hologram_stage/hologram_sprite); ui/style.json | face inside the dialogue frame AND every menu frame, uncropped (feras-notes: cropped portraits); CharacterIcons fallback when missing |
| Neon sprite sets content/neon/sprites.json (baked by tools/art, sprite-bake skill) | NeonSpriteSetDef -> neon/view/iso_actor.gd in the cold open, the roof, the map fight | full colour (colour count above the floor in acceptance.md); same scale in every scene |
| light: neon/roof/view/roof_floodlight.gd | a Polygon2D cone (additive glow, multiply dark) over the plate; it lights neither iso_actor sprites nor props (no normal maps); numbers in code (HANDOFF gap) | a light change touches the plate art, the sprite bake (normal maps), roof_occluders.gd and roof_rules.json; test that pixels around the source change, not a rectangle (feras-notes: light rectangle) |
| sounds content/audio/sounds.json | core/audio_director (item_gained); combat battle_command_menu, battle_menu_chips; dialogue_box; ui loot_popup, choice_screen, toast_host, ui_transition; music: music.json, screen_music.json -> music_deck | the Neon map fight plays none yet (feras-notes 22) |
| VFX content/combat/vfx.json | combat/view/vfx_sprite.gd(+.gdshader); art/view/character_fx.gd | none in the Neon map fight yet (feras-notes 22) |

## Change type -> what else it touches
| change | touches |
|---|---|
| combat rule or number | content/combat (actions, combatants, encounters, rules, statuses) -> combat/logic (battle_sim, battle_resolver, battle_rolls, battle_ai) -> balance: features/combat/harness/balance.gd, band in HANDOFF Shared (start gear 82.7-89% wins over N simulated battles) -> VFX (vfx.json) -> SFX (sounds.json) -> UI (combat/view timeline bar, command menu, flee button; combat.csv, battle.csv, neon_battle.csv) -> save (vitals, xp, bag, cleared_patrols) -> Neon map fight (features/neon/battle, content/neon/battle_view.json) |
| item, gear, shop, workshop | content/items, economy, workshop, progression -> items/item_service, reward_applier, shop_service, workshop_service -> EventBus item_gained / item_obtained / money_changed -> ui/view/loot_popup, core/audio_director -> save (inventory, bag, equipment "<hero>.<part>", sockets, upgrades, materials, money) -> equipment and workshop menus |
| dialogue | content/dialogue (dialogues, talks, speakers, box) -> dialogue_box, dialogue_effects -> EventBus battle_requested (scene_router; no host in Neon yet), item_* -> portraits row above -> dialogue.csv |
| hero id or name (zayd -> rydan) | ids in every content JSON; save keys (party, equipment, xp, vitals) + a SaveCodec step; portrait and sprite file names; sprites.json; localization keys; tests naming the id |
| scene, area or flow | content/neon (rooms, start_flow, cold_open, roof_rules) -> neon_game.gd, scene_router -> GameState area_id / save_point -> screen_music.json -> renders (tools/shot_neon_game.tscn) and the eye gate |
| menu or HUD | ui/view/ui_stack (game_paused), content/ui (style, backdrops, hologram_2d), ui.csv / screens.csv / pause.csv -> every screen sharing the style; touch layout (D17 Android) |

## EventBus (core/event_bus.gd)
- Live: battle_requested, item_gained, item_obtained, money_changed, game_paused (users in the rows above).
- Declared, no emitter or listener outside tests: area_entered, battle_started, battle_ended, lore_read,
  dialogue_started, dialogue_ended, music_mood_requested. Wire or remove one when a change needs it; grep before trusting it.
