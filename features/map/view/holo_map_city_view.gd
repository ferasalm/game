class_name HoloMapCityView
extends RefCounted
## purpose: Builds city-map district and area-pin labels and collapses pins that share one real place.

const MUSNAD_FONT_PATH: String = "res://assets/fonts/noto_sans_old_south_arabian.ttf"


static func labels(font: Font, districts: Array[CityDistrictDef], pins: Array[CityDistrictDef],
		scale: float, offset: Vector2, current_area_id: StringName, _color: Color,
		center: Vector2 = Vector2.ZERO, k: float = 0.0, r: float = HoloMapGeo.DEFAULT_RADIAL_R) -> Array[HoloMapLabel]:
	var out: Array[HoloMapLabel] = []
	var musnad_font: Font = load(MUSNAD_FONT_PATH) as Font
	var look := HoloCityLook.load_from_content()

	for d: CityDistrictDef in districts:
		var pos: Vector2 = d.schematic_center if d.has_schematic() else HoloMapGeo.centroid(
			HoloMapGeo.to_screen_polygon(d.polygon, scale, offset, center, k, r))
		var anchor: Vector2 = pos
		if d.has_schematic() and d.schematic.has("reticle_center"):
			var ret_raw: Array = d.schematic["reticle_center"] as Array
			anchor = Vector2(float(ret_raw[0]), float(ret_raw[1]))
		var musnad_text: String = ""
		if not d.musnad_key.is_empty():
			musnad_text = TranslationServer.translate(StringName(d.musnad_key))
		var lbl: HoloMapLabel = HoloMapLabels.make_boxed(font, musnad_font, pos, Ui.text(d.name_key), musnad_text, look)
		lbl.anchor = anchor
		out.append(lbl)

	for pin: Dictionary in unique_pins(pins, current_area_id):
		var p: CityDistrictDef = pin["def"]
		var pin_pos: Vector2 = look.get_point("old_city_center") + look.get_point("pin_offset")
		var pos: Vector2 = p.schematic_center if p.has_schematic() else pin_pos
		var font_sz: int = int(look.get_size("font_tooltip"))
		var lbl: HoloMapLabel = HoloMapLabels.make_boxed(font, musnad_font, pos, Ui.text(p.name_key), "", look, font_sz)
		lbl.anchor = pin_pos
		out.append(lbl)
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
