class_name BuildingDef
extends Def
## One Sana'a tower-house as data: footprint (metres), floors (the lowest stone_floors are basalt), window
## columns per facade, frieze style, qamariya glass letters, lit-window ratio, parapet style and roof extras.

const FRIEZES: Array[StringName] = [&"zigzag", &"triangles", &"rosettes", &"none"]
const PARAPETS: Array[StringName] = [&"crenellated", &"stepped", &"horned", &"plain"]
const EXTRAS: Array[StringName] = [&"water_tank", &"dish", &"antenna", &"solar"]

var footprint_w: int = 5
var footprint_d: int = 5
var floors: int = 5
var stone_floors: int = 1
var columns_front: int = 2
var columns_side: int = 2
var frieze: StringName = &"zigzag"
var qamariya: Array[String] = []
var lit_ratio: float = 0.4
var shutter_ratio: float = 0.2
var parapet: StringName = &"crenellated"
var roof_extras: Array[StringName] = []
var floor_height: float = 3.0
var glow: float = 1.5
var seed_value: int = 1


func read(r: DefReader) -> void:
	id = r.id()
	footprint_w = r.integer("footprint_w", 3, 20)
	footprint_d = r.integer("footprint_d", 3, 20)
	floors = r.integer("floors", 2, 12)
	stone_floors = r.integer("stone_floors", 1, 3)
	columns_front = r.integer("columns_front", 1, 5)
	columns_side = r.integer("columns_side", 1, 5)
	frieze = r.one_of("frieze", FRIEZES)
	for letter: StringName in r.id_list("qamariya"):
		qamariya.append(String(letter))
	lit_ratio = r.number("lit_ratio", 0.0, 1.0)
	shutter_ratio = r.number("shutter_ratio", 0.0, 1.0, 0.2, false)
	parapet = r.one_of("parapet", PARAPETS)
	roof_extras = r.id_list("roof_extras")
	floor_height = r.number("floor_height", 2.0, 4.0, 3.0, false)
	glow = r.number("glow", 0.0, 8.0, 1.5, false)
	seed_value = r.integer("seed", 0, 99999)
	if qamariya.is_empty():
		r.problem("qamariya", "needs at least one glass colour letter")
	if stone_floors >= floors:
		r.problem("stone_floors", "must be fewer than floors")
	for extra: StringName in roof_extras:
		if not EXTRAS.has(extra):
			r.problem("roof_extras", "'%s' is not one of %s" % [extra, EXTRAS])
	_check_columns(r)


## Every window column needs room: 36 px of window per 32 px metre of facade.
func _check_columns(r: DefReader) -> void:
	if columns_front * 36 > footprint_w * 32 or columns_side * 36 > footprint_d * 32:
		r.problem("columns", "too many window columns for the footprint")


func total_height() -> float:
	return floors * floor_height


func facade_spec(side: bool) -> FacadeSpec:
	var spec := FacadeSpec.new()
	spec.width_m = footprint_d if side else footprint_w
	spec.floors = floors
	spec.stone_floors = stone_floors
	spec.columns = columns_side if side else columns_front
	spec.frieze = frieze
	spec.qamariya = qamariya
	spec.lit_ratio = lit_ratio
	spec.shutter_ratio = shutter_ratio
	spec.door = not side
	spec.floor_px = roundi(floor_height * FacadePainter.PX_PER_M)
	spec.seed_value = seed_value + (7919 if side else 0)
	return spec
