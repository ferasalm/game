class_name ArenaDef
extends Def
## A battle arena: a painted roof built as a sibling of the exploring area, far from it (origin), so the fight never
## shares space with the rooftop. The party and enemies are placed around origin; look names a LookDef. Dressing:
## the roof tile and the parapet tile (TileDef ids), props and practical lights in metres from the origin, and the
## skyline id of the city behind. Floor colour is the fallback when the roof tile is missing.

var origin: Vector3 = Vector3.ZERO
var look: StringName = &"painted_b"
var floor_size: Vector3 = Vector3(24.0, 0.5, 24.0)
var floor_color: Color = Color(0.78, 0.7, 0.55)
var floor_tile: StringName = &"roof_floor"
var parapet_tile: StringName = &"parapet"
## Metres the parapet stands in from the floor's edge, and its thickness.
var parapet_inset: float = 0.5
var parapet_thickness: float = 0.5
var skyline: StringName = &"arena_city"
## At most this many real lights burn at once, and how fast they fade in.
var light_budget: int = 4
var light_fade: float = 3.0
var props: Array[Placement] = []
var lights: Array[LightSpec] = []


func read(r: DefReader) -> void:
	id = r.id()
	origin = _vec3(r, "origin")
	floor_size = _vec3(r, "floor_size")
	look = StringName(r.text("look"))
	floor_color = r.color("floor_color")
	floor_tile = StringName(r.text("floor_tile"))
	parapet_tile = StringName(r.text("parapet_tile"))
	parapet_inset = r.number("parapet_inset", 0.0, 10.0)
	parapet_thickness = r.number("parapet_thickness", 0.1, 4.0)
	skyline = StringName(r.text("skyline"))
	light_budget = r.integer("light_budget", 0, 8, 4, false)
	light_fade = r.number("light_fade", 0.1, 20.0, 3.0, false)
	if floor_size.x <= 0.0 or floor_size.y <= 0.0 or floor_size.z <= 0.0:
		r.problem("floor_size", "every side must be above 0")
	for reader: DefReader in r.optional_objects("props"):
		var placement := Placement.new()
		placement.read(reader)
		props.append(placement)
	for reader: DefReader in r.optional_objects("lights"):
		var light := LightSpec.new()
		light.read(reader)
		lights.append(light)


func references() -> Array[Array]:
	var out: Array[Array] = [["look", look], ["tile", floor_tile], ["tile", parapet_tile], ["skyline", skyline]]
	for placement: Placement in props:
		out.append(["prop", placement.ref])
	return out


## A tiny AreaDef the world's builders can work from: floor_size.x by floor_size.z cells, props as placed.
func as_area() -> AreaDef:
	var area := AreaDef.new()
	area.id = id
	var row: String = ".".repeat(maxi(1, roundi(floor_size.x)))
	for i: int in maxi(1, roundi(floor_size.z)):
		area.rows.append(row)
	area.props = props
	return area


static func _vec3(r: DefReader, key: String) -> Vector3:
	var values: Array[float] = r.float_list(key, -100000.0, 100000.0)
	if values.size() != 3:
		r.problem(key, "needs three numbers [x, y, z]")
		return Vector3.ZERO
	return Vector3(values[0], values[1], values[2])
