extends Node
## Smoke test of the real start: loads the main scene, starts a new game, runs it a while, quits (tools/sync_main.sh).

const MAIN_SCENE: String = "res://features/prototype/prototype_main.tscn"
const KEEPER_SCENE: String = "res://tools/smoke_keeper.tscn"


func _ready() -> void:
	var keeper: Node = (load(KEEPER_SCENE) as PackedScene).instantiate()
	get_tree().root.call_deferred("add_child", keeper)
	get_tree().call_deferred("change_scene_to_file", MAIN_SCENE)
