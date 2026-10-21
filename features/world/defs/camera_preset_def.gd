class_name CameraPresetDef
extends Def
## Stub (v0.3 registry, filled by the level builder): one named camera pose with its own field of view and depth
## of field, e.g. "explore_wide" or "dialogue".

var fov: float = 30.0
var distance: float = 10.0
var pitch_deg: float = 25.0


func read(r: DefReader) -> void:
	id = r.id()
	fov = r.number("fov", 5.0, 120.0, 30.0, false)
	distance = r.number("distance", 1.0, 200.0, 10.0, false)
	pitch_deg = r.number("pitch_deg", 0.0, 89.0, 25.0, false)
