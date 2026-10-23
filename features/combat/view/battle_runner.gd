class_name BattleRunner
extends Node3D
## One fight, away from the exploring area: builds the arena from the request, the sim from content and the saved
## gear, the BattleStage beside it, and reports the stage's result. It changes no game state; the Router does that.
## Lives at the world origin as a sibling of the area (the Router adds and frees it).

## The stage exists but start() has not run: tests switch on auto_play / instant here.
signal stage_created(new_stage: BattleStage)
## The stage finished (victory, defeat or retry).
signal ended(result: StringName)

var stage: BattleStage
var arena: Node3D


## Returns false (and builds nothing) when the encounter or arena is missing from content.
func begin(request: BattleRequest) -> bool:
	var def := ContentDB.get_def("arena", request.arena_id) as ArenaDef
	var loader: BattleLoader = BattleLoader.from_db(ContentDB, request.encounter_id)
	if def == null or loader.encounter == null:
		push_error("BattleRunner: missing arena '%s' or encounter '%s'" % [request.arena_id, request.encounter_id])
		return false
	var setup: BattleSetup = _setup(loader, request, def)
	arena = ArenaBuilder.build(def)
	add_child(arena)
	stage = BattleStage.new()
	stage.environment = ArenaBuilder.environment(def)
	stage.look = ArenaBuilder.look_of(def)
	stage.warp_frame = Router.last_frame if request.retry_count == 0 else null  # a retry has no frame to break
	stage.practice = request.practice
	add_child(stage)
	stage.ended.connect(ended.emit)
	stage_created.emit(stage)
	stage.start(BattleSim.create_from(setup), setup.anchor)
	stage.hud.end_panel.set_loot([] if request.practice else _loot_shown(loader.encounter))
	var reward: RewardResult = _reward_preview(loader) if not request.practice else RewardResult.new()
	stage.hud.end_panel.set_rewards(reward.money, reward.consumables)
	if not request.practice:
		stage.hud.end_panel.set_level_ups(_level_up_preview(loader))
	return true


## The fight's data: the party as worn, the carried vitals and herbs of the request's snapshot, and a seed that
## changes with each retry so a retry is not a replay.
func _setup(loader: BattleLoader, request: BattleRequest, def: ArenaDef) -> BattleSetup:
	var heroes: Array[StringName] = request.party if not request.party.is_empty() else GameState.party
	var party: Array[CombatantDef] = loader.party_from_state(GameState, heroes)
	var setup: BattleSetup = loader.make_setup(party, request.seed + request.retry_count, request.ambush)
	if request.encounter_id == &"abu_nabil_duel" or request.opening == BattleRequest.OPENING_ENEMY_FIRST:
		setup.actions = loader.actions.duplicate()
		setup.actions.erase(&"reverse_stab")
	setup.vitals = Vitals.copy(request.vitals_before)
	setup.bag = request.bag_before.duplicate()
	setup.equipment = GameState.equipment.duplicate()
	setup.arena_id = request.arena_id
	setup.anchor = ArenaBuilder.anchor(def)
	return setup


## A patrol already paid out gives no loot again, so the end panel lists none.
func _loot_shown(encounter: EncounterDef) -> Array[StringName]:
	if GameState.flags.get(Rewards.paid_flag(encounter.id), false):
		return []
	return encounter.loot


## What a win would pay right now (riyal, herbs), worked out on a copy so nothing is paid or flagged yet.
func _reward_preview(loader: BattleLoader) -> RewardResult:
	var held: Holdings = GameState.holdings()
	held.inventory = held.inventory.duplicate()
	held.flags = held.flags.duplicate()
	return Rewards.victory(loader.encounter, held, loader.economy, loader.consumables)


func _level_up_preview(loader: BattleLoader) -> Array:
	var was_cleared: bool = GameState.cleared_patrols.has(loader.encounter.id)
	var share: float = loader.economy.repeat_xp_share if (was_cleared and loader.economy != null) else 1.0
	var xp_amount: int = floori(Progression.encounter_xp(loader.encounter, loader.combatants) * share)
	var temp_xp: Dictionary[StringName, int] = GameState.xp.duplicate()
	return Progression.award(temp_xp, GameState.party, xp_amount, loader.levels, loader.classes)
