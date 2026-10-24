extends TestCase
## purpose: Tests city-map projection bounds, real label sets, district polygons, pins and localization rows.

const CANVAS: Vector2 = Vector2(1200.0, 800.0)


func test_every_district_has_six_to_ten_points() -> void:
	var districts: Array[CityDistrictDef] = _city_data()["districts"]
	for d: CityDistrictDef in districts:
		check(d.polygon.size() >= 6, "%s has >= 6 points (%d)" % [d.id, d.polygon.size()])
		check(d.polygon.size() <= 10, "%s has <= 10 points (%d)" % [d.id, d.polygon.size()])


func test_projected_districts_inside_canvas() -> void:
	var data: Dictionary = _city_data()
	var bounds: Rect2 = HoloMapGeo.city_bounds(data["districts"], data["features"], data["pins"], Rect2(Vector2.ZERO, CANVAS))
	var tr: Dictionary = HoloMapGeo.fit(bounds, CANVAS, 0.08)
	var scale: float = float(tr["scale"])
	var offset: Vector2 = tr["offset"] as Vector2
	var canvas_rect := Rect2(Vector2.ZERO, CANVAS)
	for d: CityDistrictDef in data["districts"]:
		for p: Vector2 in d.polygon:
			var screen: Vector2 = HoloMapGeo.project(p, scale, offset)
			check(canvas_rect.has_point(screen), "%s point %s inside canvas" % [d.id, screen])


func test_city_map_name_keys_are_localized() -> void:
	for d_id: StringName in ContentDB.ids("city_district"):
		var d := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if d == null:
			continue
		check(not d.name_key.is_empty(), "%s has a name_key" % d_id)
		check(TranslationServer.translate(StringName(d.name_key)) != d.name_key, "%s is localized" % d.name_key)


func test_city_labels_do_not_overlap() -> void:
	var canvas := HoloMapCanvas.new()
	canvas.mode = HoloMapCanvas.Mode.CITY
	var labels: Array[HoloMapLabel] = canvas.city_label_set(Ui.theme().default_font)
	check(labels.size() >= 9, "city labels include districts and one pin (%d)" % labels.size())
	_check_no_overlap(labels)
	canvas.free()


func test_area_v4_labels_do_not_overlap() -> void:
	var canvas := HoloMapCanvas.new()
	canvas.area_def = ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef
	check(canvas.area_def != null, "v4 area exists")
	canvas.refresh_plan()
	var labels: Array[HoloMapLabel] = canvas.area_label_set(Ui.theme().default_font)
	check(labels.size() >= 3, "v4 has real place labels (%d)" % labels.size())
	_check_no_overlap(labels)
	canvas.free()


func test_shared_souq_pins_draw_once() -> void:
	var pins: Array[CityDistrictDef] = _city_data()["pins"]
	var unique: Array[Dictionary] = HoloMapCityView.unique_pins(pins, &"souq_rooftops")
	check_eq(unique.size(), 1, "one pin for the shared souq spot")
	if unique.size() == 1:
		check(bool(unique[0]["active"]), "shared pin is active for souq_rooftops")


func test_flicker_values_come_from_content() -> void:
	var flicker := ContentDB.get_def("city_district", &"hologram_flicker") as CityDistrictDef
	check(flicker != null, "flicker def exists")
	if flicker != null:
		check_eq(flicker.flicker_period, 1.6, "period is 1.6 s")
		check_eq(flicker.flicker_base, 0.85, "base alpha")
		check_eq(flicker.flicker_amplitude, 0.15, "amplitude")


func _check_no_overlap(labels: Array[HoloMapLabel]) -> void:
	var resolved: Array[HoloMapLabel] = HoloMapLabels.resolve(labels, Rect2(Vector2.ZERO, CANVAS))
	for i: int in range(resolved.size()):
		for j: int in range(i + 1, resolved.size()):
			check(not resolved[i].rect.intersects(resolved[j].rect),
				"%s and %s overlap" % [resolved[i].text, resolved[j].text])


func _city_data() -> Dictionary:
	var districts: Array[CityDistrictDef] = []
	var features: Array[CityDistrictDef] = []
	var pins: Array[CityDistrictDef] = []
	for d_id: StringName in ContentDB.ids("city_district"):
		var d := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if d == null:
			continue
		match d.feature:
			&"district":
				districts.append(d)
			&"area_pin":
				pins.append(d)
			_:
				features.append(d)
	return {"districts": districts, "features": features, "pins": pins}
