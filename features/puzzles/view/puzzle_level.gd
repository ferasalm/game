class_name PuzzleLevel
extends RefCounted
## purpose: Places a level-mode puzzle board on the rooftops from the valve place and builds one spot per piece.

static func place(board: PuzzleBoard, valve_world: Vector3, rules: ExploreRulesDef, actor: Player,
		parent: Node3D) -> void:
	var source: WaterNodeDef = _source(board.water_def)
	if source == null:
		return
	var yaw: float = deg_to_rad(board.yard.place_yaw)
	var basis := Basis(Vector3.UP, yaw)
	board.global_position = valve_world - basis * source.at
	board.global_rotation = Vector3(0.0, yaw, 0.0)
	board.level_spots.clear()
	var lift: float = rules.prompt_height + rules.capsule_height
	for id: StringName in PuzzlePieces.ids(board.light_def, board.water_def):
		var at: Vector3 = board.to_global(PuzzlePieces.position(board.light_def, board.water_def, id))
		var spot := PuzzlePieceSpot.new(rules, actor, _prompt(board, id), lift)
		spot.setup(board, id)
		spot.position = Vector3(at.x, valve_world.y, at.z)
		parent.add_child(spot)
		board.level_spots.append(spot)


static func _source(def: WaterNetDef) -> WaterNodeDef:
	for node: WaterNodeDef in def.nodes:
		if node.kind == &"source":
			return node
	return null


static func _prompt(board: PuzzleBoard, id: StringName) -> String:
	if board.light_def.get_window(id) != null:
		return "PUZZLE_PROMPT_WINDOW"
	if board.light_def.get_mirror(id) != null:
		return "PUZZLE_PROMPT_MIRROR"
	var node: WaterNodeDef = board.water_def.node_def(id)
	if node != null and node.kind == &"gate":
		return "PUZZLE_PROMPT_GATE"
	return "PUZZLE_PROMPT_SPOUT"
