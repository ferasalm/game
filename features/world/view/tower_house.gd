class_name TowerHouse
extends RefCounted
## Builds one Sana'a tower-house mesh from a BuildingDef: four textured facades (one atlas), a roof, a white
## gypsum parapet with merlons and stepped or horned corners, and roof extras. Origin: the footprint's centre
## at the base; +z is the front with the door. Surfaces: 0 facades, 1 trim (lit), 2 glow (beacons, only if any).
## One mesh per building id is cached, so many instances share it.

const WALL_H: float = 0.9
const WALL_T: float = 0.22
const MERLON_W: float = 0.45
const MERLON_H: float = 0.4
static var _meshes: Dictionary[StringName, ArrayMesh] = {}


static func clear() -> void:
	_meshes.clear()


static func mesh(def: BuildingDef, palette: PaletteDef) -> ArrayMesh:
	if _meshes.has(def.id):
		return _meshes[def.id]
	var out := ArrayMesh.new()
	var facades := SurfaceBuffer.new()
	_facades(facades, def)
	facades.commit(out, SurfaceMaterials.facade(def, palette))
	var trim := SurfaceBuffer.new()
	var glow := SurfaceBuffer.new()
	var h: float = def.total_height()
	trim.box(Vector3(0.0, h - 0.05, 0.0), Vector3(def.footprint_w, 0.1, def.footprint_d), palette.colors["p"])
	_parapet(trim, def, h, palette.colors)
	RoofExtras.add(trim, glow, def, h, palette.colors)
	trim.commit(out, SurfaceMaterials.trim())
	glow.commit(out, SurfaceMaterials.glow())
	_meshes[def.id] = out
	return out


static func _facades(buf: SurfaceBuffer, def: BuildingDef) -> void:
	var hw: float = def.footprint_w / 2.0
	var hd: float = def.footprint_d / 2.0
	var h: float = def.total_height()
	var split: float = SurfaceMaterials.atlas_split(def)
	# Each facade: left-to-right corners as seen from outside, its outward normal and its u range.
	_facade(buf, Vector3(-hw, 0, hd), Vector3(hw, 0, hd), h, Vector3.BACK, 0.0, split)
	_facade(buf, Vector3(hw, 0, -hd), Vector3(-hw, 0, -hd), h, Vector3.FORWARD, 0.0, split)
	_facade(buf, Vector3(hw, 0, hd), Vector3(hw, 0, -hd), h, Vector3.RIGHT, split, 1.0)
	_facade(buf, Vector3(-hw, 0, -hd), Vector3(-hw, 0, hd), h, Vector3.LEFT, split, 1.0)


static func _facade(buf: SurfaceBuffer, left: Vector3, right: Vector3, h: float, out: Vector3, u0: float, u1: float) -> void:
	var up := Vector3(0.0, h, 0.0)
	var pts: Array[Vector3] = [left + up, right + up, right, left]
	var uvs: Array[Vector2] = [Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)]
	buf.face(pts, out, Color.WHITE, uvs)


static func _parapet(buf: SurfaceBuffer, def: BuildingDef, y: float, colors: Dictionary[String, Color]) -> void:
	var hw: float = def.footprint_w / 2.0
	var hd: float = def.footprint_d / 2.0
	var white: Color = colors["w"]
	var cy: float = y + WALL_H / 2.0
	buf.box(Vector3(0.0, cy, hd - WALL_T / 2.0), Vector3(def.footprint_w, WALL_H, WALL_T), white)
	buf.box(Vector3(0.0, cy, -hd + WALL_T / 2.0), Vector3(def.footprint_w, WALL_H, WALL_T), white)
	buf.box(Vector3(hw - WALL_T / 2.0, cy, 0.0), Vector3(WALL_T, WALL_H, def.footprint_d - 2.0 * WALL_T), white)
	buf.box(Vector3(-hw + WALL_T / 2.0, cy, 0.0), Vector3(WALL_T, WALL_H, def.footprint_d - 2.0 * WALL_T), white)
	if def.parapet == &"plain":
		return
	var top: float = y + WALL_H
	_merlons(buf, Vector3(-hw, top, hd - WALL_T / 2.0), Vector3(1.0, 0.0, 0.0), def.footprint_w, white)
	_merlons(buf, Vector3(-hw, top, -hd + WALL_T / 2.0), Vector3(1.0, 0.0, 0.0), def.footprint_w, white)
	_merlons(buf, Vector3(hw - WALL_T / 2.0, top, -hd), Vector3(0.0, 0.0, 1.0), def.footprint_d, white)
	_merlons(buf, Vector3(-hw + WALL_T / 2.0, top, -hd), Vector3(0.0, 0.0, 1.0), def.footprint_d, white)
	for corner: Vector2 in RoofExtras.SPOTS:
		_corner(buf, def.parapet, Vector3(corner.x * (hw - WALL_T / 2.0), top, corner.y * (hd - WALL_T / 2.0)), white)


static func _merlons(buf: SurfaceBuffer, start: Vector3, dir: Vector3, length: float, color: Color) -> void:
	var n: int = maxi(int(length / (MERLON_W * 2.0)), 1)
	var step: float = length / n
	for i: int in n:
		var at: Vector3 = start + dir * (step * (i + 0.5)) + Vector3(0.0, MERLON_H / 2.0, 0.0)
		var size := Vector3(MERLON_W, MERLON_H, WALL_T)
		if dir.z != 0.0:
			size = Vector3(WALL_T, MERLON_H, MERLON_W)
		buf.box(at, size, color)


## The corner merlon: crenellated = a plain block, stepped = three narrowing steps, horned = a tall tapered horn.
static func _corner(buf: SurfaceBuffer, style: StringName, base: Vector3, color: Color) -> void:
	if style == &"horned":
		buf.frustum(base, 0.26, 0.04, 1.2, 4, color, PI / 4.0)
	elif style == &"stepped":
		for i: int in 3:
			var s: float = 0.5 - 0.12 * i
			buf.box(base + Vector3(0.0, 0.18 + 0.36 * i, 0.0), Vector3(s, 0.36, s), color)
	else:
		buf.box(base + Vector3(0.0, 0.3, 0.0), Vector3(0.5, 0.6, 0.5), color)
