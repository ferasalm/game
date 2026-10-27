extends Node
## purpose: Renders the Neon Glitch first playable stage by stage (start, cold open shots 2 and 3 and the lock, the
## roof after the hatch burst, the fight on the roof) to this checkout's inbox/neon_game_<n>.png; run non-headless.

const OUT_DIR: String = "res://inbox"  ## the checkout's own inbox (git-ignored), never another checkout's

var _game: NeonGame
var _frame: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_game = (load("res://features/neon/neon_game.tscn") as PackedScene).instantiate() as NeonGame
	add_child(_game)


func _child(kind: Variant) -> Node:
	for node: Node in _game.get_children():
		if is_instance_of(node, kind) and not node.is_queued_for_deletion():
			return node
	return null


func _process(_delta: float) -> void:
	_frame += 1
	var cold := _child(ColdOpen) as ColdOpen
	match _frame:
		90: _save("1_start")
		91: (_child(StartFlow) as StartFlow).done.emit(&"normal")
		95: cold.time = ColdOpenTimeline.shot_start(cold.def, 1) + 3.0
		110: _save("2_cold_checkpoint")
		111: cold.time = ColdOpenTimeline.alert_begin(cold.def) + cold.def.alert_fill * 0.5
		125: _save("3_cold_alert")
		126: cold.time = ColdOpenTimeline.lock_time(cold.def) + 0.3
		140: _save("4_cold_locked")
		141: cold.done.emit()
		250: _save("5_roof")
		251: _touch_guard()
		420: _save("6_fight")
		700: _save("7_fight_later")
		701: get_tree().quit()


func _touch_guard() -> void:
	var roof := _child(RoofScene) as RoofScene
	var guard: IsoActor = roof.guards()[0]
	roof.hero().position = guard.position - IsoDir.vector(guard.facing) * 40.0


func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_DIR).path_join("neon_game_%s.png" % name))
	print("shot ", name, " stage ", _game.stage)
