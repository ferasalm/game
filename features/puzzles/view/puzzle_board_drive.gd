class_name PuzzleBoardDrive
extends Node
## purpose: Ticks the board's hints and, for the grey-box board only, walks the stand-in player and reads interact.

var board: PuzzleBoard


func _init(p_board: PuzzleBoard) -> void:
	board = p_board


func _physics_process(delta: float) -> void:
	if board == null or board.player == null:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not input.is_zero_approx():
		board.move_player(Vector3(input.x, 0.0, input.y), delta)


func _unhandled_input(event: InputEvent) -> void:
	if board == null or board.player == null:
		return
	if event.is_action_pressed("interact"):
		board.interact()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if board == null:
		return
	board.advance(delta)
	for key: StringName in board.hints_due():
		board.say(key)
	board.check_return()


func _exit_tree() -> void:
	board = null
