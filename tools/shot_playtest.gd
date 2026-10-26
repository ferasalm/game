extends Node
## purpose: Opens the playtest capture on the roof with the real screen grab, draws a circle and a stroke, and saves it.

const SETTLE_FRAMES: int = 90

var _game: NeonGame
var _capture: PlaytestCapture
var _frame: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = (load("res://features/neon/neon_game.tscn") as PackedScene).instantiate() as NeonGame
	add_child(_game)


func _child(kind: Variant) -> Node:
	for node: Node in _game.get_children():
		if is_instance_of(node, kind) and not node.is_queued_for_deletion():
			return node
	return null


func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			(_child(StartFlow) as StartFlow).done.emit(&"normal")
		10:
			(_child(ColdOpen) as ColdOpen).done.emit()
		SETTLE_FRAMES:
			_open()
		SETTLE_FRAMES + 5:
			_draw()
		SETTLE_FRAMES + 10:
			_capture.save_capture()
		SETTLE_FRAMES + 20:
			get_tree().quit()


func _open() -> void:
	_capture = _child(PlaytestCapture) as PlaytestCapture
	_capture.open_capture()
	print("playtest capture open on ", _game.stage)


func _draw() -> void:
	_capture.add_stroke(PlaytestStrokes.ellipse(Vector2(500.0, 300.0), Vector2(900.0, 650.0)))
	_capture.add_stroke(PackedVector2Array([Vector2(300.0, 700.0), Vector2(500.0, 740.0), Vector2(800.0, 720.0)]))
	_capture.set_note("render test")
