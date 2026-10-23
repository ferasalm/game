class_name PuzzleBoard
extends Node3D
## purpose: One self-contained grey-box valve-puzzle scene: builds the yard, holds both puzzle states, moves a
## stand-in player and redraws every view.

const FLAG_LOCK: StringName = &"puzzle_valve_lock"
const FLAG_WATER: StringName = &"puzzle_valve_water"

var yard: PuzzleYardDef
var light_def: LightLockDef
var water_def: WaterNetDef
var light_state: LightLockState
var water_state: WaterNetState
var light_view: PuzzleLightView
var water_view: PuzzleWaterView
var player: PuzzlePlayer
var marker: MeshInstance3D
var camera: Camera3D
var hint_label: Label

var _built: bool = false
var _hints: PuzzleHintsView
var _light_done: bool = false


func _init() -> void:
	_build()


func redraw() -> void:
	if not _built:
		return
	var light_open: bool = LightLock.solved(light_def, light_state)
	light_view.sync(light_state)
	water_view.sync(water_state, light_open)
	if light_open:
		_light_done = true
		GameState.flags[FLAG_LOCK] = true
	if WaterNet.solved(water_def, water_state):
		GameState.flags[FLAG_WATER] = true
	_update_marker()


func act(piece_id: StringName) -> bool:
	if not _built:
		return false
	if light_def.get_window(piece_id) != null:
		LightLock.toggle_shutter(light_state, piece_id)
	elif light_def.get_mirror(piece_id) != null:
		LightLock.turn_mirror(light_state, piece_id)
	else:
		var node: WaterNodeDef = water_def.node_def(piece_id)
		if node == null:
			return false
		if node.kind == &"gate":
			if node.jammed and not water_state.freed.get(piece_id, false):
				WaterNet.free_gate(water_state, water_def, piece_id)
			else:
				WaterNet.toggle_gate(water_state, water_def, piece_id)
		elif node.kind == &"spout":
			WaterNet.swing_spout(water_state, piece_id)
		else:
			return false
	redraw()
	return true


func interact() -> void:
	if _built:
		var id: StringName = nearest_piece(player.position)
		if id != &"":
			act(id)


func nearest_piece(pos: Vector3) -> StringName:
	if not _built:
		return &""
	var best: StringName = &""
	var best_dist: float = yard.interact_range
	var unlocked: bool = _light_done or LightLock.solved(light_def, light_state)
	for id: StringName in PuzzlePieces.ids(light_def, water_def):
		if not unlocked and PuzzlePieces.is_water(water_def, id):
			continue
		var at: Vector3 = PuzzlePieces.position(light_def, water_def, id)
		var dist: float = Vector2(pos.x - at.x, pos.z - at.z).length()
		if dist <= yard.interact_range and (best == &"" or dist < best_dist):
			best = id
			best_dist = dist
	return best


func move_player(direction: Vector3, delta: float) -> void:
	if _built:
		player.move(direction, delta)
		_update_marker()


func advance(delta: float) -> void:
	if _hints != null:
		_hints.advance(delta, _light_done, WaterNet.solved(water_def, water_state))


func hints_due() -> Array[StringName]:
	if _hints == null:
		return []
	return _hints.due(_light_done, WaterNet.solved(water_def, water_state))


func light_solved() -> bool:
	return _built and LightLock.solved(light_def, light_state)


func water_solved() -> bool:
	return _built and WaterNet.solved(water_def, water_state)


func beam_count() -> int:
	return light_view.beam_count() if _built else 0


func lens_color() -> Color:
	return light_view.lens_color() if _built else Color.BLACK


func canyon_gauge() -> float:
	return water_view.canyon_gauge() if _built else 0.0


func edge_share(from: StringName, to: StringName) -> float:
	return water_view.edge_share(from, to) if _built else 0.0


func water_strip_visible(from: StringName, to: StringName) -> bool:
	return water_view.water_strip_visible(from, to) if _built else false


func _build() -> void:
	if _built:
		return
	_built = true
	yard = ContentDB.get_def("puzzle_yard", &"yard") as PuzzleYardDef
	light_def = ContentDB.get_def("light_lock", &"valve_lock") as LightLockDef
	water_def = ContentDB.get_def("water_net", &"valve_water") as WaterNetDef
	if yard == null or light_def == null or water_def == null:
		push_error("PuzzleBoard: missing puzzle content")
		_built = false
		return
	light_state = LightLockState.start(light_def)
	water_state = WaterNetState.start(water_def)
	_apply_saved()
	PuzzleSceneBuilder.build_yard(self, yard)
	light_view = PuzzleLightView.new()
	add_child(light_view)
	light_view.setup(light_def, yard)
	water_view = PuzzleWaterView.new()
	add_child(water_view)
	water_view.setup(water_def, yard)
	player = PuzzleSceneBuilder.build_player(self, yard)
	marker = PuzzleSceneBuilder.build_marker(self, yard)
	camera = PuzzleSceneBuilder.build_camera(self, yard)
	_hints = PuzzleSceneBuilder.build_hints(self, yard, light_def, water_def)
	hint_label = _hints.label
	redraw()


func _apply_saved() -> void:
	if PuzzleSave.has_lock():
		_light_done = true
		light_state = PuzzleSave.solved_light(light_def)
	if PuzzleSave.has_water():
		water_state = PuzzleSave.solved_water(water_def)


func _update_marker() -> void:
	PuzzlePieces.place_marker(marker, nearest_piece(player.position), light_def, water_def, yard)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not input.is_zero_approx():
		move_player(Vector3(input.x, 0.0, input.y), delta)


func _unhandled_input(event: InputEvent) -> void:
	if player != null and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _hints == null:
		return
	advance(delta)
	for key: StringName in hints_due():
		_hints.queue_hint(key)
	_hints.check_return(_light_done, water_view.grate_share())
	_hints.update_label(delta)
