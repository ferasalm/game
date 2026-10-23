class_name TestPuzzlePlace
extends TestCase
## purpose: Tests the valve puzzles placed on the level: order, saved flags, roof cells, party spawn and the R5 view.

const LOCK: StringName = &"puzzle_valve_lock"
const WATER: StringName = &"puzzle_valve_water"

var _parents: Array[Node3D] = []


func test_valve_water_runs_the_light_lock_before_the_water() -> void:
	var area: AreaDef = _area()
	var board: PuzzleBoard = _board(area)
	var water_at: Vector3 = board.to_global(_node_at(board.water_def, &"g1"))
	check_eq(board.nearest_piece(water_at), &"", "no water piece before the lock")
	_solve_light(board)
	check(board.light_solved(), "the lock is solved")
	check_eq(GameState.flags.get(LOCK, false), true, "solving sets puzzle_valve_lock")
	check_eq(board.nearest_piece(water_at), &"g1", "water is offered after the lock")
	check(board.can_touch(&"g1"), "the gate accepts the player after the lock")
	_clean()


func test_water_is_refused_until_the_lock_flag_is_set() -> void:
	GameState.flags.erase(LOCK)
	var area: AreaDef = _area()
	var board: PuzzleBoard = _board(area)
	check(not board.can_touch(&"g1"), "a gate is refused before the lock")
	check(not board.can_touch(&"s2"), "a spout is refused before the lock")
	GameState.flags[LOCK] = true
	var loaded: PuzzleBoard = _board(area, false)
	check(loaded.can_touch(&"g1"), "a saved lock flag opens the water")
	_clean()
	_clean()


func test_both_flags_survive_a_save_and_a_load() -> void:
	var board: PuzzleBoard = _board(_area())
	_solve_light(board)
	_solve_water(board)
	check_eq(GameState.flags.get(WATER, false), true, "solving sets puzzle_valve_water")
	var data: Dictionary = GameState.to_dict()
	var loaded: Node = load("res://core/game_state.gd").new()
	loaded.call("from_dict", data)
	var flags: Dictionary = loaded.get("flags")
	check_eq(flags.get(LOCK, false), true, "the lock flag survives the save")
	check_eq(flags.get(WATER, false), true, "the water flag survives the save")
	loaded.free()
	_clean()


func test_the_level_valve_owns_the_placed_board() -> void:
	var area: AreaDef = _area()
	var parent := Node3D.new()
	tree.root.add_child(parent)
	_parents.append(parent)
	var actors := AreaActors.build(parent, area, _rules(), AreaWalk.floor_height(area))
	var valve: ValveSpot = null
	for candidate: ValveSpot in actors.valves:
		if candidate.place.id == &"valve_water":
			valve = candidate
	check(valve != null, "the valve_water spot exists")
	check(actors.puzzle != null and valve.board == actors.puzzle, "the valve hands interact to the board")
	check(actors.puzzle.level_mode, "the board is in level mode")
	var source: Vector3 = _node_at(actors.puzzle.water_def, &"valve")
	check(actors.puzzle.to_global(source).distance_to(_valve_world(area)) < 0.01,
		"the valve source stands on the valve place")
	check_eq(actors.puzzle.level_spots.size(),
		PuzzlePieces.ids(actors.puzzle.light_def, actors.puzzle.water_def).size(), "one spot per piece")
	_clean()


func test_every_piece_stands_on_a_walkable_roof_cell() -> void:
	var area: AreaDef = _area()
	var board: PuzzleBoard = _board(area)
	for window: LightLockWindow in board.light_def.windows:
		_check_roof(area, board.to_global(window.at), "window " + String(window.id))
	for mirror: LightLockMirror in board.light_def.mirrors:
		_check_roof(area, board.to_global(mirror.at), "mirror " + String(mirror.id))
	for node: WaterNodeDef in board.water_def.nodes:
		_check_roof(area, board.to_global(node.at), "water " + String(node.id))
	_clean()


func test_the_party_starts_clear_of_every_mirror() -> void:
	var area: AreaDef = _area()
	var board: PuzzleBoard = _board(area)
	var spawn: PlaceDef = area.place(&"spawn_start")
	var party := Vector3(spawn.pos.x, 0.0, spawn.pos.z)
	for mirror: LightLockMirror in board.light_def.mirrors:
		var at: Vector3 = board.to_global(mirror.at)
		check(Vector2(party.x - at.x, party.z - at.z).length() >= 1.5,
			"spawn is 1.5 m clear of " + String(mirror.id))
	_clean()


func test_the_canyon_gauge_projects_inside_the_r5_camera() -> void:
	var area: AreaDef = _area()
	var board: PuzzleBoard = _board(area)
	var zone: PlaceDef = area.place(&"zone_r5")
	var rig: CameraRigDef = ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	var follow := FollowCam.new(rig)
	follow.enter_zone(deg_to_rad(zone.yaw), deg_to_rad(zone.pitch), zone.distance, zone.fov,
		deg_to_rad(zone.roll))
	follow.update(_valve_world(area), Vector3.ZERO, 2.0)
	var camera := Camera3D.new()
	tree.root.add_child(camera)
	camera.fov = follow.fov
	camera.global_position = follow.camera_position()
	camera.look_at(follow.aim)
	camera.rotate_object_local(Vector3.FORWARD, follow.roll)
	check(camera.is_position_in_frustum(board.canyon_gauge_top()), "the canyon gauge is in the R5 view")
	camera.free()
	_clean()


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _valve_world(area: AreaDef) -> Vector3:
	var place: PlaceDef = area.place(&"valve_water")
	var tile: TileDef = ContentDB.get_def("tile", area.tile_id_at(place.cell.x, place.cell.y)) as TileDef
	return Vector3(place.pos.x, tile.height if tile != null else 0.0, place.pos.z)


func _board(area: AreaDef, reset_flags: bool = true) -> PuzzleBoard:
	if reset_flags:
		GameState.flags.erase(LOCK)
		GameState.flags.erase(WATER)
	var rules: ExploreRulesDef = _rules()
	var parent := Node3D.new()
	tree.root.add_child(parent)
	var board := PuzzleBoard.new(true)
	parent.add_child(board)
	var player := Player.new(rules)
	parent.add_child(player)
	board.setup_level(_valve_world(area), rules, player, parent)
	_parents.append(parent)
	return board


func _node_at(def: WaterNetDef, id: StringName) -> Vector3:
	var node: WaterNodeDef = def.node_def(id)
	return node.at if node != null else Vector3.ZERO


func _solve_light(board: PuzzleBoard) -> void:
	board.act(&"yellow")
	board.act(&"blue")
	board.act(&"m1")
	board.act(&"m2")
	board.act(&"m2")


func _solve_water(board: PuzzleBoard) -> void:
	board.act(&"g3")
	board.act(&"g3")
	board.act(&"g1")
	board.act(&"g4")
	board.act(&"s1")
	board.act(&"s2")


func _check_roof(area: AreaDef, at: Vector3, what: String) -> void:
	var cx: int = floori(at.x)
	var cz: int = floori(at.z)
	check(area.is_walkable(cx, cz), what + " stands on a walkable cell")
	var tile: StringName = area.tile_id_at(cx, cz)
	check(tile == &"roof_r4" or tile == &"roof_r5", what + " is on R4 or R5")


func _clean() -> void:
	for parent: Node3D in _parents:
		parent.free()
	_parents.clear()
