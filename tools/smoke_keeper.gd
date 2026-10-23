extends Node
## Survives scene changes during tools/smoke_new_game: starts a new game, waits, reports the scene, quits.

const NEW_GAME_FRAME: int = 30
const END_FRAME: int = 400

var _frame: int = 0


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == NEW_GAME_FRAME:
		Router.new_game()
	elif _frame == END_FRAME:
		var scene: Node = get_tree().current_scene
		print("SMOKE scene=", scene.name if scene != null else "none")
		get_tree().quit(0 if scene != null else 1)
