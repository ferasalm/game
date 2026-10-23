class_name PuzzleBoard
extends Node3D
## purpose: Holds both valve puzzle states and their views, in the grey-box yard or placed on the rooftop level.

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
var level_mode: bool = false
var level_player: Player
var level_spots: Array[PuzzlePieceSpot] = []

var _built: bool = false
var _hints: PuzzleHintsView
var light_done: bool = false


func _init(in_level: bool = false) -> void:
	level_mode = in_level
	_build()


func redraw() -> void:
	if not _built:
		return
	var light_open: bool = LightLock.solved(light_def, light_state)
	light_view.sync(light_state)
	water_view.sync(water_state, light_open)
	if light_open:
		light_done = true
		GameState.flags[FLAG_LOCK] = true
	if WaterNet.solved(water_def, water_state):
		GameState.flags[FLAG_WATER] = true
	PuzzlePieces.place_marker(marker, nearest_piece(_actor_position()), light_def, water_def, yard)


func act(piece_id: StringName) -> bool:
	if not _built:
		return false
	var lock_before: bool = light_solved()
	var water_before: bool = water_solved()
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
	_say_outcome(piece_id, lock_before, water_before)
	return true


func interact() -> void:
	if not _built:
		return
	var id: StringName = nearest_piece(_actor_position())
	if id != &"":
		act(id)
	else:
		say(PuzzleFeedback.idle_key(self))


func can_touch(piece_id: StringName) -> bool:
	return _built and (not PuzzlePieces.is_water(water_def, piece_id) or light_solved())


func nearest_piece(pos: Vector3) -> StringName:
	if not _built:
		return &""
	var local: Vector3 = to_local(pos) if is_inside_tree() else pos
	var best: StringName = &""
	var best_dist: float = yard.interact_range
	var unlocked: bool = light_done or LightLock.solved(light_def, light_state)
	for id: StringName in PuzzlePieces.ids(light_def, water_def):
		if not unlocked and PuzzlePieces.is_water(water_def, id):
			continue
		var at: Vector3 = PuzzlePieces.position(light_def, water_def, id)
		var dist: float = Vector2(local.x - at.x, local.z - at.z).length()
		if dist <= yard.interact_range and (best == &"" or dist < best_dist):
			best = id
			best_dist = dist
	return best


func move_player(direction: Vector3, delta: float) -> void:
	if _built and player != null:
		player.move(direction, delta)
		PuzzlePieces.place_marker(marker, nearest_piece(_actor_position()), light_def, water_def, yard)


func advance(delta: float) -> void:
	if _hints != null:
		_hints.advance(delta, light_done, WaterNet.solved(water_def, water_state))


func hints_due() -> Array[StringName]:
	if _hints == null:
		return []
	return _hints.due(light_done, WaterNet.solved(water_def, water_state))


func check_return() -> void:
	if _hints != null and water_view != null:
		_hints.check_return(light_done, water_view.grate_share())


func say(key: StringName) -> void:
	if _hints != null and key != &"":
		_hints.queue_hint(key)


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


func canyon_gauge_top() -> Vector3:
	if not _built:
		return global_position
	return to_global(water_view.canyon_at() + Vector3(0.0, yard.gauge_height, 0.0))


func edge_share(from: StringName, to: StringName) -> float:
	return water_view.edge_share(from, to) if _built else 0.0


func water_strip_visible(from: StringName, to: StringName) -> bool:
	return water_view.water_strip_visible(from, to) if _built else false


func setup_level(valve_world: Vector3, rules: ExploreRulesDef, actor: Player, parent: Node3D) -> void:
	level_player = actor
	PuzzleLevel.place(self, valve_world, rules, actor, parent)


func _build() -> void:
	if _built:
		return
	_built = true
	if not PuzzleSceneBuilder.build_board(self):
		_built = false
		return
	var drive := PuzzleBoardDrive.new(self)
	add_child(drive)


func _actor_position() -> Vector3:
	if level_player != null:
		return level_player.global_position if level_player.is_inside_tree() else level_player.position
	return player.position if player != null else Vector3.ZERO


func _say_outcome(piece_id: StringName, lock_before: bool, water_before: bool) -> void:
	say(PuzzleFeedback.outcome(self, piece_id, lock_before, water_before))
