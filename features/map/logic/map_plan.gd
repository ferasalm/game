class_name MapPlan
extends RefCounted
## purpose: Pure logic for planning area walkable cells, aspect fitting, and marker positioning.


## Computes walkable cell runs, crossings, place labels, and bounds for an area.
static func plan(area: AreaDef) -> Dictionary:
	var runs_data: Dictionary = _find_runs(area)
	return {
		"runs": runs_data.runs,
		"walkable": runs_data.runs,
		"bounds": runs_data.bounds,
		"crossings": _find_crossings(area),
		"places": _find_places(area),
	}


static func _find_runs(area: AreaDef) -> Dictionary:
	var runs: Array[Rect2i] = []
	var min_x: int = 999999
	var max_x: int = -999999
	var min_z: int = 999999
	var max_z: int = -999999
	var depth: int = area.depth()
	var width: int = area.width()
	for z: int in depth:
		var start_x: int = -1
		for x: int in width:
			if area.is_walkable(x, z):
				if start_x < 0:
					start_x = x
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_z = mini(min_z, z)
				max_z = maxi(max_z, z)
			elif start_x >= 0:
				runs.append(Rect2i(start_x, z, x - start_x, 1))
				start_x = -1
		if start_x >= 0:
			runs.append(Rect2i(start_x, z, width - start_x, 1))
	var bounds: Rect2 = Rect2(0.0, 0.0, float(maxi(width, 1)), float(maxi(depth, 1)))
	if not runs.is_empty():
		bounds = Rect2(float(min_x), float(min_z), float(max_x - min_x + 1), float(max_z - min_z + 1))
	return {"runs": runs, "bounds": bounds}


static func _find_crossings(area: AreaDef) -> Array[PackedVector2Array]:
	var crossings: Array[PackedVector2Array] = []
	for p: PlaceDef in area.places_of(&"crossing"):
		crossings.append(PackedVector2Array([Vector2(p.pos.x, p.pos.z), Vector2(p.end.x, p.end.z)]))
	return crossings


static func _find_places(area: AreaDef) -> Array[Dictionary]:
	var places: Array[Dictionary] = []
	for p: PlaceDef in area.places:
		var name_key: String = ""
		match p.kind:
			PlaceDef.SHOP:
				name_key = "SHOP_HERB_STALL"
			PlaceDef.WORKSHOP:
				name_key = "WORKSHOP_TITLE"
			PlaceDef.SAVE:
				name_key = "SABIL_TITLE"
			PlaceDef.NPC:
				name_key = "MAP_PLACE_HERB_SELLER"
		places.append({
			"id": p.id,
			"kind": p.kind,
			"name_key": name_key,
			"pos": Vector2(p.pos.x, p.pos.z),
			"cell": p.cell,
		})
	return places


## Calculates scale and offset to fit the plan inside target_rect while maintaining aspect ratio.
static func fit(plan_data: Dictionary, target_rect: Rect2) -> Dictionary:
	var bounds: Rect2 = plan_data.get("bounds", Rect2(0.0, 0.0, 1.0, 1.0))
	var w: float = maxf(bounds.size.x, 1.0)
	var h: float = maxf(bounds.size.y, 1.0)
	var pad: float = 32.0
	var avail_w: float = maxf(target_rect.size.x - pad * 2.0, 1.0)
	var avail_h: float = maxf(target_rect.size.y - pad * 2.0, 1.0)
	var scale: float = minf(avail_w / w, avail_h / h)
	var fitted_size: Vector2 = bounds.size * scale
	var offset: Vector2 = target_rect.position + (target_rect.size - fitted_size) * 0.5 - bounds.position * scale
	return {
		"scale": scale,
		"offset": offset,
	}


## Filters markers for the area, excluding quest markers whose flag is already set.
static func markers(area: AreaDef, marker_defs: Array, flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: Variant in marker_defs:
		if m == null:
			continue
		var m_kind: StringName = StringName(m.kind if "kind" in m else (m as Dictionary).get("kind", ""))
		var m_flag: StringName = StringName(m.flag if "flag" in m else (m as Dictionary).get("flag", ""))
		var m_place: StringName = StringName(m.place if "place" in m else (m as Dictionary).get("place", ""))
		var m_id: StringName = StringName(m.id if "id" in m else (m as Dictionary).get("id", ""))
		if m_kind == &"quest" and not m_flag.is_empty():
			if bool(flags.get(m_flag, false)):
				continue
		var p: PlaceDef = area.place(m_place)
		if p != null:
			out.append({
				"id": m_id,
				"kind": m_kind,
				"cell": p.cell,
				"pos": Vector2(p.pos.x, p.pos.z),
			})
	return out
