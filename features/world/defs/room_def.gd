class_name RoomDef
extends Def
## purpose: Room content definition (content/world/rooms.json): dimensions, walls, qamariya, props, shots, spots.

class Shot extends RefCounted:
	var id: StringName = &""
	var cam_pos: Vector3 = Vector3.ZERO
	var look_target: Vector3 = Vector3.ZERO
	var rect: Rect2 = Rect2()
	var fov: float = 45.0

class SitSpot extends RefCounted:
	var id: StringName = &""
	var pos: Vector3 = Vector3.ZERO
	var yaw: float = 0.0

var size: Vector3 = Vector3(7.0, 3.0, 5.0)
var wall_color: String = "w"
var trim_color: String = "q"
var qamariya_walls: Array[String] = ["north", "east", "west"]
var entry_pos: Vector3 = Vector3(3.5, 0.0, 4.0)
var entry_yaw: float = 180.0
var exit_pos: Vector3 = Vector3(30.5, 1.6, 4.5)
var exit_yaw: float = 0.0
var props: Array[Placement] = []
var shots: Array[Shot] = []
var sit_spots: Array[SitSpot] = []


func read(r: DefReader) -> void:
	id = r.id()
	var sz: Array[float] = r.float_list("size", 0.5, 50.0)
	if sz.size() == 3:
		size = Vector3(sz[0], sz[1], sz[2])
	wall_color = r.text("wall_color", "w", false)
	trim_color = r.text("trim_color", "q", false)
	var qw: PackedStringArray = r.text_list("qamariya_walls")
	if not qw.is_empty():
		qamariya_walls.assign(qw)
	_read_spots(r)
	_read_props(r)
	_read_shots(r)


func references() -> Array[Array]:
	var out: Array[Array] = []
	for p: Placement in props:
		out.append(["prop", p.ref])
	return out


func _read_spots(r: DefReader) -> void:
	var ep: Array[float] = r.float_list("entry_pos", -100.0, 100.0)
	if ep.size() == 3:
		entry_pos = Vector3(ep[0], ep[1], ep[2])
	entry_yaw = r.number("entry_yaw", -360.0, 360.0, 180.0, false)
	var xp: Array[float] = r.float_list("exit_pos", -100.0, 100.0)
	if xp.size() == 3:
		exit_pos = Vector3(xp[0], xp[1], xp[2])
	exit_yaw = r.number("exit_yaw", -360.0, 360.0, 0.0, false)
	for sr: DefReader in r.optional_objects("sit_spots"):
		var spot := SitSpot.new()
		spot.id = sr.id()
		var sp: Array[float] = sr.float_list("pos", -100.0, 100.0)
		if sp.size() == 3:
			spot.pos = Vector3(sp[0], sp[1], sp[2])
		spot.yaw = sr.number("yaw", -360.0, 360.0, 0.0, false)
		sit_spots.append(spot)


func _read_props(r: DefReader) -> void:
	for pr: DefReader in r.optional_objects("props"):
		var p := Placement.new()
		p.read(pr)
		props.append(p)


func _read_shots(r: DefReader) -> void:
	for sr: DefReader in r.optional_objects("shots"):
		var shot := Shot.new()
		shot.id = sr.id()
		var cp: Array[float] = sr.float_list("cam_pos", -100.0, 100.0)
		if cp.size() == 3:
			shot.cam_pos = Vector3(cp[0], cp[1], cp[2])
		var lt: Array[float] = sr.float_list("look_target", -100.0, 100.0)
		if lt.size() == 3:
			shot.look_target = Vector3(lt[0], lt[1], lt[2])
		var rc: Array[float] = sr.float_list("rect", -100.0, 100.0)
		if rc.size() == 4:
			shot.rect = Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		shot.fov = sr.number("fov", 5.0, 120.0, 45.0, false)
		shots.append(shot)
