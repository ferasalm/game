class_name CameraRoomDef
extends RefCounted
## Specification and authored dimensions for the framed shot grey-box test room (content/world/camera.json).

class Shot extends RefCounted:
	var id: StringName = &""
	var cam_pos: Vector3 = Vector3.ZERO
	var look_target: Vector3 = Vector3.ZERO
	var rect: Rect2 = Rect2()
	var fov: float = 45.0


var floor_w: float = 8.0
var floor_d: float = 5.0
var wall_h: float = 3.0
var wall_t: float = 0.2
var bench_w: float = 1.6
var bench_d: float = 0.6
var bench_h: float = 0.45
var bench_x: float = 4.0
var bench_z: float = 1.5
var window_gap_w: float = 1.5
var window_gap_h: float = 1.5
var window_gap_y: float = 0.8
var shots: Array[Shot] = []


static func read_from(tr: DefReader) -> CameraRoomDef:
	var s := CameraRoomDef.new()
	s.floor_w = tr.number("floor_w", 1.0, 100.0, 8.0, false)
	s.floor_d = tr.number("floor_d", 1.0, 100.0, 5.0, false)
	s.wall_h = tr.number("wall_h", 1.0, 20.0, 3.0, false)
	s.wall_t = tr.number("wall_t", 0.01, 5.0, 0.2, false)
	s.bench_w = tr.number("bench_w", 0.1, 10.0, 1.6, false)
	s.bench_d = tr.number("bench_d", 0.1, 10.0, 0.6, false)
	s.bench_h = tr.number("bench_h", 0.1, 5.0, 0.45, false)
	s.bench_x = tr.number("bench_x", -50.0, 50.0, 4.0, false)
	s.bench_z = tr.number("bench_z", -50.0, 50.0, 1.5, false)
	s.window_gap_w = tr.number("window_gap_w", 0.1, 10.0, 1.5, false)
	s.window_gap_h = tr.number("window_gap_h", 0.1, 10.0, 1.5, false)
	s.window_gap_y = tr.number("window_gap_y", 0.0, 10.0, 0.8, false)
	for sr: DefReader in tr.optional_objects("shots"):
		var shot := Shot.new()
		shot.id = sr.id()
		shot.cam_pos = Vector3(sr.number("cam_x", -50.0, 50.0), sr.number("cam_y", -50.0, 50.0),
			sr.number("cam_z", -50.0, 50.0))
		shot.look_target = Vector3(sr.number("look_x", -50.0, 50.0), sr.number("look_y", -50.0, 50.0),
			sr.number("look_z", -50.0, 50.0))
		var coords: Array[float] = sr.float_list("rect", -50.0, 50.0)
		if coords.size() == 4:
			shot.rect = Rect2(coords[0], coords[1], coords[2] - coords[0], coords[3] - coords[1])
		shot.fov = sr.number("fov", 5.0, 120.0, 45.0, false)
		s.shots.append(shot)
	return s
