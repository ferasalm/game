class_name FlowHarness
extends RefCounted
## Test helpers for the game flow: a PrototypeMain whose battles run instantly with the AI choosing for the heroes, a
## patrol touch, a scratch save folder and a Router that records reloads instead of reloading the scene.

const DT: float = 1.0 / 60.0

var reloads: int = 0
var outcomes: Array[BattleOutcome] = []
var _tree: SceneTree


func save_dir() -> String:
	return SaveService.default_dir.path_join("flow")


func _init(scene_tree: SceneTree) -> void:
	_tree = scene_tree
	GameState.reset()
	Router.state = Router.STATE_TITLE
	Router.save_dir = save_dir()
	Router.scene_reloader = func() -> void: reloads += 1
	Router.battle_finished.connect(_on_finished)
	SaveService.new(save_dir()).delete(1)


## The main scene, with battles on auto_play and instant.
func make_main(area_id: StringName = &"souq_rooftops") -> PrototypeMain:
	if area_id != &"":
		GameState.area_id = area_id
	var main := (load("res://features/prototype/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	main.stage_created.connect(func(stage: BattleStage) -> void:
		stage.auto_play = true
		stage.instant = true)
	_tree.root.add_child(main)
	return main


## Walks the patrol into the player and returns once the battle has started.
func touch(main: PrototypeMain) -> void:
	GameState.flags[&"party_after_first_win_done"] = true  # the first-win talk holds walking; test_talk_interact covers it
	main.rooftop.patrol.position = main.rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	main.rooftop.patrol._physics_process(DT)


func finish() -> void:
	Router.battle_finished.disconnect(_on_finished)
	Router.scene_reloader = Callable()
	Router.save_dir = ""
	Router.state = Router.STATE_TITLE
	SaveService.new(save_dir()).delete(1)
	GameState.reset()


func _on_finished(outcome: BattleOutcome) -> void:
	outcomes.append(outcome)
