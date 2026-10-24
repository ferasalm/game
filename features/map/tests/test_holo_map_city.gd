extends TestCase
## purpose: Tests city-map schematic blocks, look parameters, label de-overlap and localization rows.

const CANVAS: Vector2 = Vector2(1200.0, 800.0)
const OLD_CITY_DISTRICTS: Array[StringName] = [&"old_city", &"bab_al_yaman", &"al_saila", &"tahrir", &"zubairi"]


func test_every_district_has_schematic_block_inside_canvas() -> void:
	var canvas_rect := Rect2(Vector2.ZERO, CANVAS)
	var districts: Array[CityDistrictDef] = _city_data()["districts"]
	check_eq(districts.size(), 8, "8 districts exist")
	for d: CityDistrictDef in districts:
		check(d.has_schematic(), "%s has schematic block" % d.id)
		check(canvas_rect.has_point(d.schematic_center),
			"%s schematic center %s inside canvas" % [d.id, d.schematic_center])


func test_every_name_key_and_musnad_key_has_localization_row() -> void:
	for d_id: StringName in ContentDB.ids("city_district"):
		var d := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		if d == null:
			continue
		check(not d.name_key.is_empty(), "%s has a name_key" % d_id)
		check(TranslationServer.translate(StringName(d.name_key)) != d.name_key, "%s is localized" % d.name_key)
		if d.feature == &"district":
			check(not d.musnad_key.is_empty(), "%s has a musnad_key" % d_id)
		if not d.musnad_key.is_empty():
			var tr: String = TranslationServer.translate(StringName(d.musnad_key))
			check(tr != d.musnad_key, "%s musnad is localized" % d.musnad_key)


func test_look_values_load_from_content_and_missing_key_fails() -> void:
	var look := HoloCityLook.load_from_content()
	check(look != null, "look loaded from content")
	check_eq(look.get_size("old_city_radius"), 190.0, "radius is 190")
	check_eq(look.get_count("old_city_rings"), 7, "7 rings")
	check_eq(look.get_color("old_city"), Color("#ff5a2a"), "orange-red fill")
	check(look.has_key("sizes", "old_city_radius"), "old_city_radius key exists")
	check(not look.has_key("sizes", "missing_test_key"), "missing key detected")
	var failed := [false]
	look.require_key("sizes", "missing_test_key", func() -> void: failed[0] = true)
	check(failed[0], "missing key reported failure")


func test_every_district_has_six_to_ten_points() -> void:
	var districts: Array[CityDistrictDef] = _city_data()["districts"]
	for d: CityDistrictDef in districts:
		check(d.polygon.size() >= 6, "%s has >= 6 points (%d)" % [d.id, d.polygon.size()])
		check(d.polygon.size() <= 10, "%s has <= 10 points (%d)" % [d.id, d.polygon.size()])


func test_projected_districts_inside_canvas() -> void:
	var canvas := HoloMapCanvas.new()
	canvas.mode = HoloMapCanvas.Mode.CITY
	canvas._ensure_city_fit()
	var data: Dictionary = _city_data()
	var canvas_rect := Rect2(Vector2.ZERO, CANVAS)
	for d: CityDistrictDef in data["districts"]:
		for p: Vector2 in d.polygon:
			var screen: Vector2 = canvas._project(p)
			check(canvas_rect.has_point(screen), "%s point %s inside canvas" % [d.id, screen])
	canvas.free()


func test_old_city_districts_span_canvas_width() -> void:
	var canvas := HoloMapCanvas.new()
	canvas.mode = HoloMapCanvas.Mode.CITY
	canvas._ensure_city_fit()
	var data: Dictionary = _city_data()
	var min_x: float = INF
	var max_x: float = -INF
	for d: CityDistrictDef in data["districts"]:
		if not OLD_CITY_DISTRICTS.has(d.id):
			continue
		for p: Vector2 in d.polygon:
			var screen: Vector2 = canvas._project(p)
			min_x = minf(min_x, screen.x)
			max_x = maxf(max_x, screen.x)
	var span: float = max_x - min_x
	check(span >= CANVAS.x * 0.35, "old-city districts span >= 35%% of canvas")
	canvas.free()


func test_city_labels_do_not_overlap() -> void:
	var canvas := HoloMapCanvas.new()
	canvas.mode = HoloMapCanvas.Mode.CITY
	var labels: Array[HoloMapLabel] = canvas.city_label_set(Ui.theme().default_font)
	check(labels.size() >= 9, "city labels include districts and one pin (%d)" % labels.size())
	var pin_screen := Vector2(781.0, 392.0)
	var pin_rect := Rect2(pin_screen - Vector2(16.0, 16.0), Vector2(32.0, 32.0))
	_check_no_overlap(labels, pin_rect)
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


func _check_no_overlap(labels: Array[HoloMapLabel], obstacle: Rect2 = Rect2()) -> void:
	var obstacles: Array[Rect2] = []
	if obstacle.size != Vector2.ZERO:
		obstacles.append(obstacle)
	var resolved: Array[HoloMapLabel] = HoloMapLabels.resolve(labels, Rect2(Vector2.ZERO, CANVAS), obstacles)
	for i: int in range(resolved.size()):
		if obstacle.size != Vector2.ZERO:
			check(not resolved[i].rect.intersects(obstacle), "%s covers player pin" % resolved[i].text)
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
			&"district": districts.append(d)
			&"area_pin": pins.append(d)
			_: features.append(d)
	return {"districts": districts, "features": features, "pins": pins}
