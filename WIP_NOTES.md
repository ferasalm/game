# WIP_NOTES (P1a flow and state) - delete before merging
Edit tip: multi-line python edits work via a script file in the scratchpad (heredoc+python was sometimes refused).
## Done (committed or in the working tree; features/combat tests passed 98/98 before test_battle_outcome was added)
- 1 Save: core/save/save_codec.gd (v4, _v1.._v3_to_v4, sanitize, summary), save_service.gd (SaveService.new(dir),
  write/read/read_backup/summary/delete/exists, .bak + tmp rename), GameState v4 (money, bag, vitals, save_point,
  cleared_patrols, play_seconds, start_new(), holdings()/take()), tests core/tests/test_save_codec.gd,
  test_save_service.gd, fixtures/save_v3.json, test_game_state literals -> 4. 29 core tests pass.
- 2 Items: ConsumableDef, EconomyRulesDef (+start_party), CountMap, content/items/consumables.json,
  content/economy/rules.json, items.csv rows, Bag, ItemEffect, Vitals, Holdings, RewardResult, Rewards,
  features/items/reward_applier.gd (RewardApplier.victory/chest/chests_at), ChestDef/EncounterDef with money +
  consumables, encounters patrol_scouts/patrol_gate, chests.json. Tests test_bag.gd, test_rewards.gd pass.
- 3 Registries in ContentDB (consumable, economy_rules, shop, arena, transition, puppet, clip, camera_preset,
  place), arenas.json (rooftop_arena origin [0,0,300]), transitions.json.
- 4 Battle contract: BattleSetup, BattleSim.create_from(setup) (+setup, bag fields), BattleOutcome.from_sim(sim,
  result) + rewarded flag, BattleLoader.make_setup / party_from_equipment(equipment, hero_ids) / economy,
  BattleRulesDef speed + melee numbers (rules.json), UnitState.create(..., rules), Formation.melee_multiplier(a,t,rules),
  BattleStage: environment var, no previous camera, Djanbeyyah.WIELDER. battle_probe updated.
  UNCOMMITTED/UNTESTED: features/combat/tests/test_battle_outcome.gd (written, never run).
## Not started
- 5 Fix Chest.is_open to start from GameState.flags[Chests.flag(id)] (and lid fully open); PrototypeMain stops holding
  loot (use RewardApplier); test_prototype must not call _grant (test_winning_grants... uses main._grant).
- 6 Router (core/scene_router.gd still the stub). Plan: AreaPort (core/area_port.gd, virtual: world(), suspend(),
  resume(), reset_patrol(), restore_camera(), last_safe_position(), place_party(save_point)), RooftopPort in
  features/prototype; Router.register_area(port); start_battle(request): snapshot (add snapshotted/retry_count to
  BattleRequest), last_frame capture (guard headless), hide + PROCESS_MODE_DISABLED the world, arena root via new
  features/combat/view/arena_builder.gd (floor + Diorama.make_sun, env = Diorama.make_environment(look).environment
  given to stage.environment), BattleStage as sibling, signal stage_created(stage), stage.hud.end_panel.set_loot;
  on end: BattleOutcome.from_sim, victory -> GameState.vitals/bag = outcome, RewardApplier.victory, cleared_patrols,
  free stage+arena, show/enable world, reset_patrol, restore_camera, set_exploring(true), emit battle_finished,
  flow_changed, EventBus.battle_started/ended; retry -> restore snapshot, seed+retry_count, relaunch; defeat ->
  restore snapshot, return to area. Also is_exploring, can_save (exploring and not Screens.is_open()), has_save,
  save_slot, new_game, load_slot (scene_reloader Callable override for tests, skip_title flag taken by
  PrototypeMain), go_to_title, unstuck, play_seconds tick (delta / Engine.time_scale, not when paused).
  New content: content/prototype/flow.json kind flow_rules (arena_id, music ids, safe_idle_seconds, debug font/pos);
  move rooftop.gd debug label numbers there (RooftopDebug node), add Rooftop.last_safe_position (SafeSpot: stood still
  for safe_idle_seconds), place_party. rooftop.gd is at 193 lines: split before adding.
  PrototypeMain: composition root; keep stage_created signal (forward Router's) and `stage` getter (Router.stage)
  because test_popups.gd and tools/shot_battle.gd use them; GameState.start_new() if party empty; set area_id.
- 7 test_smoke_flow.gd + tests for Router round trip, Retry snapshot, vitals carry. Update test_prototype.
- Finish: tools/run_godot.sh --import, bash tools/check.sh (read FAIL lines), python tools/map.py, commit.
## Gotchas
- `x == y as T` parses as `(x == y) as T`: parenthesise. Object has _set: don't name methods _set.
- JSON ints arrive as floats; CountMap handles it. Rooftop camera is current in viewport: stage must not swoop from it.
