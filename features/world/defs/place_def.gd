class_name PlaceDef
extends Def
## A named spot in an area (areas.json "places"): where the player stands to use it, or the patrol lane, so code
## finds it by id instead of by node path. kind: spawn, workshop, npc, shop, save (the sabil), chest, vista, patrol
## (a lane from pos to end, fighting `encounter`) or safe (an unstuck target). Yaw 0 faces +z in degrees. An npc
## with a `prop` keeps it (a stall): he stands at its counter's end (StallKeeper) and his place is where he is talked to.

const SPAWN: StringName = &"spawn"
const WORKSHOP: StringName = &"workshop"
const NPC: StringName = &"npc"
const SHOP: StringName = &"shop"
const SAVE: StringName = &"save"
const CHEST: StringName = &"chest"
const VISTA: StringName = &"vista"
const PATROL: StringName = &"patrol"
const SAFE: StringName = &"safe"
const CAMERA_ZONE: StringName = &"camera_zone"
const KINDS: Array[StringName] = [SPAWN, WORKSHOP, NPC, SHOP, SAVE, CHEST, VISTA, PATROL, SAFE, CAMERA_ZONE]

var area: StringName = &""
var kind: StringName = &""
## The floor point (x, z; y is 0, callers add the floor height).
var pos: Vector3 = Vector3.ZERO
var yaw: float = 0.0
var pitch: float = 0.0
var distance: float = 0.0
var fov: float = 0.0
## camera_zone: active x/z rect in metres.
var zone_rect: Rect2 = Rect2()
## vista: the zone in cells (x0, z0, x1, z1 inclusive).
var rect: Rect2i = Rect2i()
## patrol: the far end of the lane (x, z) and the encounter it starts.
var end: Vector3 = Vector3.ZERO
var encounter: StringName = &""
## npc and patrol: the picture id; shop: the shop id; shop and save: the prop standing at the spot.
var sprite: StringName = &""
var shop: StringName = &""
var prop: StringName = &""
var cell: Vector2i = Vector2i.ZERO


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	if kind == VISTA:
		var cells: Array[int] = r.int_list("rect", 0, 500)
		if cells.size() == 4:
			rect = Rect2i(cells[0], cells[1], cells[2] - cells[0] + 1, cells[3] - cells[1] + 1)
		else:
			r.problem("rect", "needs 4 numbers: x0, z0, x1, z1")
		return
	if kind == CAMERA_ZONE:
		var coords: Array[float] = r.float_list("rect", -500.0, 500.0)
		if coords.size() == 4:
			zone_rect = Rect2(coords[0], coords[1], coords[2] - coords[0], coords[3] - coords[1])
			pos = Vector3(coords[0], 0.0, coords[1])
			cell = Vector2i(floori(pos.x), floori(pos.z))
		else:
			r.problem("rect", "needs 4 numbers: x0, z0, x1, z1")
		yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
		pitch = r.number("pitch", -89.0, 89.0, 0.0, false)
		distance = r.number("distance", 0.1, 100.0, 6.5, false)
		fov = r.number("fov", 5.0, 120.0, 50.0, false)
		return
	pos = Vector3(r.number("x", -500.0, 500.0), 0.0, r.number("z", -500.0, 500.0))
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
	cell = Vector2i(floori(pos.x), floori(pos.z))
	if kind == PATROL:
		end = Vector3(r.number("bx", -500.0, 500.0), 0.0, r.number("bz", -500.0, 500.0))
		encounter = StringName(r.text("encounter"))
	sprite = StringName(r.text("sprite", "", false))
	shop = StringName(r.text("shop", "", false))
	prop = StringName(r.text("prop", "", false))
	if kind == SHOP and shop == &"":
		r.problem("shop", "a shop place needs a shop id")


func references() -> Array[Array]:
	var out: Array[Array] = []
	if encounter != &"":
		out.append(["encounter", encounter])
	if shop != &"":
		out.append(["shop", shop])
	if prop != &"":
		out.append(["prop", prop])
	return out
