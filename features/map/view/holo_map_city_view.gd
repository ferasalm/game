class_name HoloMapCityView
extends RefCounted
## purpose: Builds city-map district and area-pin labels and collapses pins that share one real place.

const PIN_LABEL_OFFSET: Vector2 = Vector2(14.0, 0.0)


static func labels(font: Font, districts: Array[CityDistrictDef], pins: Array[CityDistrictDef],
		scale: float, offset: Vector2, current_area_id: StringName, color: Color,
		center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = HoloMapGeo.DEFAULT_RADIAL_R) -> Array[HoloMapLabel]:
	var out: Array[HoloMapLabel] = []
	for d: CityDistrictDef in districts:
		var pts: PackedVector2Array = HoloMapGeo.to_screen_polygon(d.polygon, scale, offset, center, k, r)
		if pts.size() >= 3:
			out.append(HoloMapLabels.make(font, HoloMapGeo.centroid(pts), Ui.text(d.name_key), color))
	for pin: Dictionary in unique_pins(pins, current_area_id):
		var p: CityDistrictDef = pin["def"]
		var pos: Vector2 = HoloMapGeo.project(p.center, scale, offset, center, k, r) + PIN_LABEL_OFFSET
		out.append(HoloMapLabels.make(font, pos, Ui.text(p.name_key), color))
	return out


## One pin per place: pins with the same centre collapse, and the group is active when any shares the current area.
static func unique_pins(pins: Array[CityDistrictDef], current_area_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: CityDistrictDef in pins:
		var found: int = -1
		for i: int in range(out.size()):
			var q: CityDistrictDef = out[i]["def"]
			if q.center.distance_squared_to(p.center) < 1.0:
				found = i
				break
		if found < 0:
			out.append({"def": p, "active": p.area_id == current_area_id})
		elif p.area_id == current_area_id:
			out[found]["active"] = true
	return out
