class_name TestPlaytestCanvas
extends TestCase
## purpose: PlaytestCanvas turns real mouse drags into marks: a left drag shows while drawn and is kept on release, a
## right drag keeps a clean ellipse inside its box (no line back to the corner where the drag began).


func _canvas() -> PlaytestCanvas:
	var canvas := PlaytestCanvas.new()
	canvas.size = Vector2(400.0, 300.0)
	tree.root.add_child(canvas)
	return canvas


func _button(index: MouseButton, pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = at
	return event


func _motion(at: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = at
	return event


func test_left_drag_shows_live_and_is_kept_on_release() -> void:
	var canvas: PlaytestCanvas = _canvas()
	canvas._gui_input(_button(MOUSE_BUTTON_LEFT, true, Vector2(10.0, 10.0)))
	canvas._gui_input(_motion(Vector2(30.0, 20.0)))
	canvas._gui_input(_motion(Vector2(50.0, 40.0)))
	check_eq(canvas.strokes.current().size(), 3, "the open stroke holds every point so far")
	check_eq(canvas.strokes.count(), 0, "nothing is kept before the release")
	canvas._gui_input(_button(MOUSE_BUTTON_LEFT, false, Vector2(50.0, 40.0)))
	check_eq(canvas.strokes.count(), 1, "the release keeps the stroke")
	check(canvas.strokes.current().is_empty(), "no stroke is open after the release")
	canvas.queue_free()


func test_right_drag_keeps_a_clean_ellipse_inside_its_box() -> void:
	var canvas: PlaytestCanvas = _canvas()
	var a := Vector2(100.0, 50.0)
	var b := Vector2(300.0, 250.0)
	canvas._gui_input(_button(MOUSE_BUTTON_RIGHT, true, a))
	canvas._gui_input(_motion(b))
	canvas._gui_input(_button(MOUSE_BUTTON_RIGHT, false, b))
	check_eq(canvas.strokes.count(), 1, "the right drag keeps one stroke")
	var ring: PackedVector2Array = canvas.strokes.strokes()[0]
	check(ring[0].distance_to(a) > 1.0, "the ellipse does not start at the drag corner")
	check(ring[0].is_equal_approx(ring[ring.size() - 1]), "the ellipse is closed")
	var box := Rect2(a, b - a).grow(0.01)
	for point: Vector2 in ring:
		check(box.has_point(point), "every point lies inside the drag box: %s" % point)
	canvas.queue_free()
