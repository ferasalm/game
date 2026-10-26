class_name PlaytestCanvas
extends Control
## purpose: Draws a capture's strokes in red and records left-drag freehand and right-drag ellipse strokes.

const LINE_WIDTH: float = 4.0
const LINE_COLOR: Color = Color.RED
const ELLIPSE_SEGMENTS: int = 48

var strokes: PlaytestStrokes = PlaytestStrokes.new()
var _drawing: bool = false
var _ellipse_mode: bool = false
var _ellipse_start: Vector2 = Vector2.ZERO
var _ellipse_points: PackedVector2Array = PackedVector2Array()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _drawing:
		_mouse_motion(event as InputEventMouseMotion)


func _draw() -> void:
	for stroke: PackedVector2Array in strokes.strokes():
		_draw_stroke(stroke)
	if _ellipse_mode:
		_draw_stroke(_ellipse_points)


## Adds a finished stroke (used by the render test and by the capture's shot).
func add_stroke(points: PackedVector2Array) -> void:
	if points.is_empty():
		return
	strokes.begin(points[0])
	for i: int in range(1, points.size()):
		strokes.add(points[i])
	strokes.end()
	queue_redraw()


func reset() -> void:
	strokes = PlaytestStrokes.new()
	_drawing = false
	_ellipse_mode = false
	_ellipse_points = PackedVector2Array()
	queue_redraw()


func _mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_left_button(event)
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_right_button(event)
		accept_event()


func _left_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		strokes.begin(event.position)
		_drawing = true
		_ellipse_mode = false
	elif _drawing and not _ellipse_mode:
		strokes.add(event.position)
		strokes.end()
		_drawing = false
	queue_redraw()


func _right_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		_ellipse_start = event.position
		_ellipse_mode = true
		_drawing = true
		_ellipse_points = PlaytestStrokes.ellipse(event.position, event.position, ELLIPSE_SEGMENTS)
	else:
		_commit_ellipse()
	queue_redraw()


func _mouse_motion(event: InputEventMouseMotion) -> void:
	if _ellipse_mode:
		_ellipse_points = PlaytestStrokes.ellipse(_ellipse_start, event.position, ELLIPSE_SEGMENTS)
	else:
		strokes.add(event.position)
	queue_redraw()
	accept_event()


func _commit_ellipse() -> void:
	if _ellipse_mode:
		strokes.begin(_ellipse_start)
		for point: Vector2 in _ellipse_points:
			strokes.add(point)
		strokes.end()
	_ellipse_mode = false
	_drawing = false
	_ellipse_points = PackedVector2Array()


func _draw_stroke(stroke: PackedVector2Array) -> void:
	if stroke.size() == 1:
		draw_circle(stroke[0], LINE_WIDTH * 0.5, LINE_COLOR)
	elif stroke.size() > 1:
		draw_polyline(stroke, LINE_COLOR, LINE_WIDTH, true)
