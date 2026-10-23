extends TestCase
## Unit tests for Level 1 atmosphere and visuals: mist layer clearance, storm height fog, and NPC/patrol sprites.

const AREA_ID: StringName = &"souq_rooftops_v4"


func _area() -> AreaDef:
	return ContentDB.get_def("area", AREA_ID) as AreaDef


func _lowest_floor(area: AreaDef) -> float:
	var lowest: float = INF
	for z: int in area.depth():
		for x: int in area.width():
			if not area.is_walkable(x, z):
				continue
			var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
			if tile != null:
				lowest = minf(lowest, tile.height)
	return lowest


func test_no_mist_layer_reaches_within_two_metres_of_lowest_floor() -> void:
	var area: AreaDef = _area()
	var lowest_floor: float = _lowest_floor(area)
	check(lowest_floor < INF, "lowest floor found")
	for mist_id: StringName in area.mist:
		var mist := ContentDB.get_def("mist", mist_id) as MistDef
		check(mist != null, "mist def %s exists" % mist_id)
		for i: int in mist.stack:
			var layer_y: float = mist.height + float(i) * mist.step
			check(lowest_floor - layer_y >= 2.0,
				"mist %s layer %d (y=%.2f) stays >= 2 m below lowest floor (%.2f)" % [mist_id, i, layer_y, lowest_floor])


func test_storm_and_height_fog_below_the_low_roofs() -> void:
	var area: AreaDef = _area()
	check_eq(area.weather, "storm", "level 1 is a night storm")
	check(not is_nan(area.fog_height) and _lowest_floor(area) - area.fog_height >= 2.0,
		"height fog pools >= 2 m below the lowest roof")


func test_every_patrol_and_npc_has_a_sprite() -> void:
	for area_id: StringName in ContentDB.ids("area"):
		var area := ContentDB.get_def("area", area_id) as AreaDef
		for place: PlaceDef in area.places_of(PlaceDef.PATROL) + area.places_of(PlaceDef.NPC):
			check(place.sprite != &"", "%s %s has a sprite" % [area_id, place.id])
