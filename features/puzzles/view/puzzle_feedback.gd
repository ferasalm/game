class_name PuzzleFeedback
extends RefCounted
## purpose: Picks the localization key for the board's spoken feedback after a move or at the valve.

static func outcome(board: PuzzleBoard, piece_id: StringName, lock_before: bool,
		water_before: bool) -> StringName:
	if not lock_before and board.light_solved():
		return &"PUZZLE_LIGHT_SOLVED"
	if not water_before and board.water_solved():
		return &"PUZZLE_WATER_SOLVED"
	return piece_key(board, piece_id)


static func piece_key(board: PuzzleBoard, piece_id: StringName) -> StringName:
	if board.light_def.get_window(piece_id) != null:
		return &"PUZZLE_LIGHT_SHUTTER"
	if board.light_def.get_mirror(piece_id) != null:
		return &"PUZZLE_LIGHT_MIRROR"
	var node: WaterNodeDef = board.water_def.node_def(piece_id)
	if node != null and node.kind == &"gate":
		return &"PUZZLE_WATER_GATE"
	return &"PUZZLE_WATER_SPOUT"


static func idle_key(board: PuzzleBoard) -> StringName:
	if not board.light_solved():
		return &"PUZZLE_LIGHT_LOOK"
	if not board.water_solved():
		return &"PUZZLE_WATER_VALVE"
	return &"PUZZLE_VALVE_DONE"
