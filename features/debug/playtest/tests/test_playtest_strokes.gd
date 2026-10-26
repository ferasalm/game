class_name TestPlaytestStrokes
extends TestCase
## purpose: PlaytestStrokes keeps freehand and ellipse strokes, undo drops only the last, and an ellipse is closed
## and inside the box it was dragged over.


func test_begin_add_end_makes_one_stroke() -> void:
	var strokes := PlaytestStrokes.new()
	strokes.begin(Vector2(1.0, 2.0))
	strokes.add(Vector2(3.0, 4.0))
	strokes.end()
	check_eq(strokes.count(), 1, "one stroke after end")
	check_eq(strokes.strokes().size(), 1, "strokes lists it")
	check_eq(strokes.strokes()[0].size(), 2, "both points are kept")


func test_undo_removes_only_the_last() -> void:
	var strokes := PlaytestStrokes.new()
	for i: int in 2:
		strokes.begin(Vector2(float(i), float(i)))
		strokes.add(Vector2(float(i + 1), float(i + 1)))
		strokes.end()
	strokes.undo()
	check_eq(strokes.count(), 1, "one stroke left")
	check_eq(strokes.strokes()[0][0], Vector2.ZERO, "the first stroke stays")


func test_undo_on_empty_is_safe() -> void:
	var strokes := PlaytestStrokes.new()
	strokes.undo()
	check_eq(strokes.count(), 0, "still empty")


func test_ellipse_is_closed_and_inside_its_box() -> void:
	var a := Vector2(10.0, 20.0)
	var b := Vector2(110.0, 80.0)
	var ellipse := PlaytestStrokes.ellipse(a, b, 32)
	check_eq(ellipse[0], ellipse[ellipse.size() - 1], "the ellipse closes on itself")
	for point: Vector2 in ellipse:
		check(point.x >= a.x - 0.01 and point.x <= b.x + 0.01, "x stays in the box")
		check(point.y >= a.y - 0.01 and point.y <= b.y + 0.01, "y stays in the box")
