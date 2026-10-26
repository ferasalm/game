class_name PlaytestStrokes
extends RefCounted
## purpose: The strokes of one playtest capture: freehand and ellipse paths in overlay space, with undo.

const ELLIPSE_SEGMENTS: int = 48

var _strokes: Array[PackedVector2Array] = []
var _current: PackedVector2Array = PackedVector2Array()
var _active: bool = false


## Starts a new stroke at `point`.
func begin(point: Vector2) -> void:
	_current = PackedVector2Array([point])
	_active = true


## Extends the stroke being drawn; ignored when no stroke is open.
func add(point: Vector2) -> void:
	if _active:
		_current.append(point)


## Finishes the stroke being drawn and keeps it.
func end() -> void:
	if not _active:
		return
	_strokes.append(_current)
	_current = PackedVector2Array()
	_active = false


## Removes the last finished stroke; safe when there is none.
func undo() -> void:
	if not _strokes.is_empty():
		_strokes.remove_at(_strokes.size() - 1)


func count() -> int:
	return _strokes.size()


func strokes() -> Array[PackedVector2Array]:
	return _strokes.duplicate()


## A closed ellipse that fits the box from `a` to `b`.
static func ellipse(a: Vector2, b: Vector2, segments: int = ELLIPSE_SEGMENTS) -> PackedVector2Array:
	var points := PackedVector2Array()
	var center: Vector2 = (a + b) * 0.5
	var radius: Vector2 = (b - a).abs() * 0.5
	var steps: int = maxi(segments, 4)
	for i: int in steps:
		var angle: float = TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	if not points.is_empty():
		points.append(points[0])
	return points
