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
	else:
		_restore_snapshot()
	finished.emit(outcome)


## Carries the fight's vitals and herbs into the game and pays the encounter's rewards once.
func _win(outcome: BattleOutcome) -> void:
	GameState.set_vitals(outcome.vitals)
	GameState.set_bag(outcome.bag)
	var reward: RewardResult = RewardApplier.victory(outcome.encounter_id)
	outcome.money = reward.money
	outcome.items = reward.items
	outcome.consumables = reward.consumables.duplicate()
	outcome.rewarded = true
	if not GameState.cleared_patrols.has(outcome.encounter_id):
		GameState.cleared_patrols.append(outcome.encounter_id)


func restore_snapshot() -> void:
	_restore_snapshot()


func _restore_snapshot() -> void:
	GameState.set_vitals(request.vitals_before)
	GameState.set_bag(request.bag_before)
	GameState.money = request.money_before
