extends TestCase
## Tests for souq R2 layout: sabil flush against wall, walkable save spot, Musnad sign on same wall, and herb stall crates clear of Abu Nabil.

const AREA_ID: StringName = &"souq_rooftops_v4"
const R2_EAST_WALL_X: float = 37.0
const WALL_TOLERANCE: float = 0.05
const SELLER_CLEARANCE: float = 1.5


func _area() -> AreaDef:
	return ContentDB.get_def("area", AREA_ID) as AreaDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _prop_placement(area: AreaDef, prop_id: StringName) -> Placement:
	for p: Placement in area.props:
		if p.ref == prop_id:
			return p
	return null


func _sabil_prop_def() -> PropDef:
	return ContentDB.get_def("prop", &"sabil") as PropDef


func _herb_stall_prop_def() -> PropDef:
	return ContentDB.get_def("prop", &"herb_stall") as PropDef


func test_sabil_back_flush_against_r2_wall_and_save_walkable() -> void:
	var area: AreaDef = _area()
	check(area != null, "area souq_rooftops_v4 exists")
	var sabil_prop: Placement = _prop_placement(area, &"sabil")
	check(sabil_prop != null, "sabil prop placed in souq_rooftops_v4")
	var sabil_def: PropDef = _sabil_prop_def()
	check(sabil_def != null, "sabil prop def exists")

	var slab: PropPart = sabil_def.parts[0]
	var local_back_z: float = slab.at.z - slab.size.z / 2.0
	var xform := Transform3D(Basis(Vector3.UP, deg_to_rad(sabil_prop.yaw)), Vector3(sabil_prop.pos.x, 0.0, sabil_prop.pos.z))
	var world_back: Vector3 = xform * Vector3(0.0, 0.0, local_back_z)

	var dist_to_wall: float = absf(world_back.x - R2_EAST_WALL_X)
	check(dist_to_wall <= WALL_TOLERANCE, "sabil back is within 0.05 m of R2 East parapet (got %.3f)" % dist_to_wall)

	var save_place: PlaceDef = area.place(&"sabil")
	check(save_place != null and save_place.kind == PlaceDef.SAVE, "sabil save place exists")
	var sc := Vector2i(floori(save_place.pos.x), floori(save_place.pos.z))
	check(area.is_walkable(sc.x, sc.y), "save place is on a walkable cell (%d, %d)" % [sc.x, sc.y])

	var wg: WalkGraph = AreaWalk.build(area, _rules())
	var spawn: PlaceDef = area.place(&"spawn_start")
	var spawn_cell := Vector2i(floori(spawn.pos.x), floori(spawn.pos.z))
	var reached: Dictionary[Vector2i, bool] = wg.reachable_with_crossings(spawn_cell, area.places_of(PlaceDef.CROSSING))
	check(reached.has(sc), "save place is reachable on walk graph")

	var basin: PropPart = sabil_def.parts[16]
	var world_basin: Vector3 = xform * Vector3(0.0, 0.0, basin.at.z)
	var dist_to_basin: float = Vector2(save_place.pos.x, save_place.pos.z).distance_to(Vector2(world_basin.x, world_basin.z))
	check(absf(dist_to_basin - 2.0) <= 0.05, "save place is 2 m in front of basin (got %.3f)" % dist_to_basin)

	var stall_prop: Placement = _prop_placement(area, &"herb_stall")
	check(stall_prop != null, "herb stall prop placed")
	var dist_to_stall: float = Vector2(sabil_prop.pos.x, sabil_prop.pos.z).distance_to(Vector2(stall_prop.pos.x, stall_prop.pos.z))
	check(dist_to_stall >= 3.0, "sabil is >= 3 m from herb stall (got %.2f)" % dist_to_stall)


func test_musnad_sign_on_same_wall_above_niche() -> void:
	var area: AreaDef = _area()
	var sabil_sign: SignSpec = null
	for s: SignSpec in area.signs:
		if s.key == "WORLD_SIGN_SABIL":
			sabil_sign = s
			break
	check(sabil_sign != null, "WORLD_SIGN_SABIL sign placed in area")

	var sign_xform := Transform3D(Basis(Vector3.UP, deg_to_rad(sabil_sign.yaw)), sabil_sign.pos)
	var sign_back: Vector3 = sign_xform * Vector3(0.0, 0.0, -NeonSign.BOARD_DEPTH / 2.0)
	var dist_to_wall: float = absf(sign_back.x - R2_EAST_WALL_X)
	check(dist_to_wall <= WALL_TOLERANCE, "sign back is within 0.05 m of same wall (got %.3f)" % dist_to_wall)
	check(sabil_sign.pos.y >= 2.0, "sign is above the niche (y=%.2f)" % sabil_sign.pos.y)

	var text: String = tr(sabil_sign.key)
	check(not text.is_empty(), "sign text is localized")
	check(_is_musnad_only(text), "sign text '%s' is Musnad only (no Latin, no Arabic)" % text)


func test_crates_and_barrels_stay_clear_of_abu_nabil() -> void:
	var area: AreaDef = _area()
	var seller_place: PlaceDef = area.place(&"herb_seller")
	check(seller_place != null, "herb_seller place exists")
	var seller_pos := Vector2(seller_place.pos.x, seller_place.pos.z)

	var stall_prop: Placement = _prop_placement(area, &"herb_stall")
	check(stall_prop != null, "herb stall prop placed")
	var stall_def: PropDef = _herb_stall_prop_def()
	var stall_xform := Transform3D(Basis(Vector3.UP, deg_to_rad(stall_prop.yaw)), Vector3(stall_prop.pos.x, 0.0, stall_prop.pos.z))

	for i: int in stall_def.parts.size():
		var part: PropPart = stall_def.parts[i]
		var is_crate: bool = part.pattern == &"planks" and part.size.x < 1.0
		var is_barrel: bool = part.shape == &"frustum" and (part.sides == 10 or part.sides == 8) and part.at.y < 0.8
		if not is_crate and not is_barrel:
			continue
		var world_pos: Vector3 = stall_xform * part.at
		var d: float = Vector2(world_pos.x, world_pos.z).distance_to(seller_pos)
		var kind: String = "crate" if is_crate else "barrel"
		check(d >= SELLER_CLEARANCE, "%s part %d (world %.2f, %.2f) is >= 1.5 m from herb_seller (got %.2f)" % [kind, i, world_pos.x, world_pos.z, d])


func _is_musnad_only(text: String) -> bool:
	var has_musnad: bool = false
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		if code == 0x20:
			continue
		if code >= 0x10A60 and code <= 0x10A7F:
			has_musnad = true
			continue
		return false
	return has_musnad
