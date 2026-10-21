class_name FakeClipSource
extends VisualSource
## A stand-in VisualSource for battle view tests: a model-like source of a known size that sends clip events only
## when the test says so, and records what the battle asked of it (clips, facings, hit pauses, collapses).

var clips: Array[StringName] = []
var faces: Array[Vector3] = []
var pauses: Array[float] = []
var downs: Array[bool] = []
var size: Vector2 = Vector2(0.8, 1.8)


func play_clip(state: StringName, _facing: float) -> void:
	clips.append(state)


func face_dir(dir: Vector3) -> void:
	faces.append(dir)


func hit_stop(seconds: float) -> void:
	pauses.append(seconds)


func set_down(down: bool, _animate: bool) -> void:
	downs.append(down)


func height() -> float:
	return size.y


func width() -> float:
	return size.x


func anchor(which: StringName) -> Vector3:
	match which:
		&"head":
			return Vector3(0.0, size.y, 0.0)
		&"hand":
			return Vector3(size.x * 0.5, size.y * 0.5, 0.0)
	return Vector3.ZERO
