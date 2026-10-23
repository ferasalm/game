class_name BattleSession
extends RefCounted
## One battle from the Router's side: launches a BattleRunner beside the area, and when the stage ends turns its result
## into GameState changes. Victory carries vitals and herbs and pays the rewards once; defeat restores the pre-battle
## snapshot; Retry restores it and launches the fight again with a new seed. The Defeat screen's other picks leave the
## fight: Load goes to the last save (Router.load_slot), Title to the title (Router.go_to_title). `finished` fires for
## victory and a plain defeat (back to the area); Load and Title rebuild the whole game instead.

signal stage_created(new_stage: BattleStage)
signal finished(outcome: BattleOutcome)

var request: BattleRequest
var _host: Node
var _runner: BattleRunner


func _init(host: Node, battle_request: BattleRequest) -> void:
	_host = host
	request = battle_request


## The running stage, null when no fight is on.
func stage() -> BattleStage:
	return _runner.stage if _runner != null else null


func launch() -> void:
	_runner = BattleRunner.new()
	_runner.name = "BattleRunner"
	_host.add_child(_runner)
	_runner.stage_created.connect(stage_created.emit)
	_runner.ended.connect(_on_stage_ended)
	if not _runner.begin(request):
		var failed := BattleOutcome.new()
		failed.encounter_id = request.encounter_id
		failed.result = BattleOutcome.DEFEAT
		free_runner()
		_restore_snapshot()
		finished.emit(failed)


## Takes the arena and stage out of the tree at once and frees them.
func free_runner() -> void:
	if _runner == null:
		return
	_host.remove_child(_runner)
	_runner.queue_free()
	_runner = null


func _on_stage_ended(result: StringName) -> void:
	var outcome: BattleOutcome = BattleOutcome.from_sim(_runner.stage.sim, result)
	outcome.practice = request.practice
	free_runner()
	if result == BattleOutcome.RETRY:
		_restore_snapshot()
		request.retry_count += 1
		launch()
		return
	if result == BattleOutcome.TITLE:
		Router.go_to_title()
		return
	if result == BattleOutcome.LOAD:
		if Router.load_slot(Router.last_slot).is_empty():
			return
		outcome.result = BattleOutcome.DEFEAT  # the save could not be read: back to the area, as after a defeat
	if request.practice:
		_restore_snapshot()
	elif result == BattleOutcome.VICTORY:
		_win(outcome)
	elif result == BattleOutcome.FLED:
		# Fled: keep vitals and bag, pay nothing, never clear patrol.
		GameState.set_vitals(outcome.vitals)
		GameState.set_bag(outcome.bag)
		# The area return path stays as after a defeat (patrol reset, grace time handled by Router),
		# but vitals and bag are preserved.
	else:
		_restore_snapshot()
	finished.emit(outcome)


## Carries the fight's vitals and herbs into the game, awards XP and level-ups, and pays rewards once.
func _win(outcome: BattleOutcome) -> void:
	var was_cleared: bool = GameState.cleared_patrols.has(outcome.encounter_id)
	_award_battle_xp(outcome, was_cleared)
	GameState.set_vitals(outcome.vitals)
	GameState.set_bag(outcome.bag)
	var reward: RewardResult = RewardApplier.victory(outcome.encounter_id)
	outcome.money = reward.money
	outcome.items = reward.items
	outcome.consumables = reward.consumables.duplicate()
	outcome.rewarded = true
	_award_battle_materials(outcome.encounter_id, was_cleared)
	if not was_cleared:
		GameState.cleared_patrols.append(outcome.encounter_id)


func _award_battle_materials(encounter_id: StringName, was_cleared: bool) -> void:
	var enc := ContentDB.get_def("encounter", encounter_id) as EncounterDef
	if enc == null or enc.materials.is_empty():
		return
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	var share: float = rules.repeat_payout if (was_cleared and rules != null) else 1.0
	for mat_id: StringName in enc.materials:
		var count: int = floori(float(enc.materials[mat_id]) * share)
		if count > 0:
			Materials.add(GameState.materials, mat_id, count)


func _award_battle_xp(outcome: BattleOutcome, was_cleared: bool) -> void:
	var encounter_def := ContentDB.get_def("encounter", outcome.encounter_id) as EncounterDef
	var combatants: Dictionary[StringName, CombatantDef] = {}
	for cid: StringName in ContentDB.ids("combatant"):
		combatants[cid] = ContentDB.get_def("combatant", cid) as CombatantDef
	var xp_base: int = Progression.encounter_xp(encounter_def, combatants)
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	var share: float = rules.repeat_xp_share if (was_cleared and rules != null) else 1.0
	var xp_amount: int = floori(xp_base * share)
	var levels_def := ContentDB.get_def("levels", &"default") as LevelsDef
	var classes: Dictionary[StringName, ClassDef] = {}
	for class_id: StringName in ContentDB.ids("class"):
		var c := ContentDB.get_def("class", class_id) as ClassDef
		classes[c.hero] = c
	outcome.level_ups = Progression.award(GameState.xp, GameState.party, xp_amount, levels_def, classes)
	for lu: LevelUp in outcome.level_ups:
		if outcome.vitals.has(lu.hero):
			var vit: Dictionary = outcome.vitals[lu.hero]
			vit["hp"] = int(vit.get("hp", 0)) + lu.gains.get(&"max_hp", 0)
			vit["sp"] = int(vit.get("sp", 0)) + lu.gains.get(&"max_sp", 0)


func restore_snapshot() -> void:
	_restore_snapshot()


func _restore_snapshot() -> void:
	GameState.set_vitals(request.vitals_before)
	GameState.set_bag(request.bag_before)
	GameState.money = request.money_before
