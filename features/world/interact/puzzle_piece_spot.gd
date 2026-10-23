class_name PuzzlePieceSpot
extends InteractSpot
## purpose: Interact spot on one valve-puzzle piece; routes the key press to the level's puzzle board.

var board: PuzzleBoard
var piece_id: StringName


func setup(p_board: PuzzleBoard, id: StringName) -> void:
	board = p_board
	piece_id = id


func _interact() -> void:
	if board != null:
		board.act(piece_id)


func _can_interact() -> bool:
	return super() and board != null and board.can_touch(piece_id)
