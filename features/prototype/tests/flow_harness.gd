class_name FlowHarness
extends RefCounted
## Test helpers for the game flow: a PrototypeMain whose battles run instantly with the AI choosing for the heroes, a
## patrol touch, a scratch save folder and a Router that records reloads instead of reloading the scene.

const DT: float = 1.0 / 60.0
const SAVE_DIR: String = "user://test_saves_flow"

var reloads: int = 0
var outcomes: Array[BattleOutcome] = []
var _tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_tree = scene_tree
	GameState.reset()
	Router.state = Router.STATE_TITLE
	Router.save_dir = SAVE_DIR
	Router.scene_reloader = func() -> void: reloads += 1
	Router.battle_finished.connect(_on_finished)
	SaveService.new(SAVE_DIR).delete(1)


## The main scene, with battles on auto_play and instant.
func make_main() -> PrototypeMain:
	var main := (load("res://features/prototype/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	main.stage_created.connect(func(stage: BattleStage) -> void:
		stage.auto_play = true
		stage.instant = true)
	_tree.root.add_child(main)
	return main


## Walks the patrol into the player and returns once the battle has started.
func touch(main: PrototypeMain) -> void:
	main.rooftop.patrol.position = main.rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	main.rooftop.patrol._physics_process(DT)


func finish() -> void:
	Router.battle_finished.disconnect(_on_finished)
	Router.scene_reloader = Callable()
	Router.save_dir = SaveService.DEFAULT_DIR
	Router.state = Router.STATE_TITLE
	SaveService.new(SAVE_DIR).delete(1)
	GameState.reset()


func _on_finished(outcome: BattleOutcome) -> void:
	outcomes.append(outcome)
