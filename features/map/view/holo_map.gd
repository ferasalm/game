class_name HoloMap
extends UiScreen
## purpose: Holographic map screen with floor plan, markers, district radar, and city map toggle.

const ID: StringName = &"map"

var canvas: HoloMapCanvas
var legend: HoloMapLegend
var city_preview: HoloMapCityPreview
var player_pos_override: Variant = null

var _root: Control
var _coord_label: Label
var _area_def: AreaDef


func _init() -> void:
	super()
	backdrop_id = ID
	prompts = [
		{"key": "y", "text": "MAP_PROMPT_CITY_AREA"},
		{"key": "back", "text": "MAP_PROMPT_BACK"},
	]


func build(_args: Dictionary) -> void:
	_root = Ui.screen_root()
	add_child(_root)
	_load_area()
	_build_header()
	_build_panels()
	_build_coordinates()


func _load_area() -> void:
	var a_id: StringName = GameState.area_id
	if a_id == &"":
		a_id = &"souq_rooftops"
	_area_def = ContentDB.get_def("area", a_id) as AreaDef


func _build_header() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(80.0, 40.0)
	bar.custom_minimum_size = Vector2(1760.0, 64.0)
	bar.size = Vector2(1760.0, 64.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)

	var title_plate := Ui.title_plate(Ui.text("MAP_TITLE"), "𐩱𐩡𐩭𐩧𐩺𐩷𐩠")
	title_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title_plate)

	var right_box := VBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var area_name: String = Ui.text(_area_def.name_key) if _area_def != null else "Souq al-Milh"
	right_box.add_child(Ui.label(area_name, &"NameLabel", Ui.style().colour(&"c_brass")))
	right_box.add_child(Ui.label("SANA'A SECTOR 01", &"SmallLabel", Ui.style().colour(&"c_cyan")))
	bar.add_child(right_box)


func _build_panels() -> void:
	canvas = HoloMapCanvas.new()
	canvas.area_def = _area_def
	canvas.flags = GameState.flags
	canvas.refresh_plan()
	_root.add_child(canvas)

	legend = HoloMapLegend.new()
	_root.add_child(legend)

	city_preview = HoloMapCityPreview.new()
	_root.add_child(city_preview)


func _build_coordinates() -> void:
	var info := ContentDB.get_def("map_info", &"default") as MapInfoDef
	var coords: String = info.coordinates if info != null else "15 21'04\"N 44 12'32\"E"
	_coord_label = Ui.label(coords, &"SmallLabel", Ui.style().colour(&"c_cyan"))
	_coord_label.position = Vector2(80.0, 960.0)
	_root.add_child(_coord_label)


func _process(delta: float) -> void:
	if canvas == null:
		return
	canvas.pulse_time += delta
	canvas.player_world_pos = get_live_player_position()
	canvas.queue_redraw()
	if city_preview != null:
		city_preview.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var y_pressed: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Y) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y)
	if not y_pressed and InputMap.has_action(&"action_y") and event.is_action_pressed(&"action_y"):
		y_pressed = true
	if y_pressed:
		toggle_mode()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func toggle_mode() -> void:
	if canvas.mode == HoloMapCanvas.Mode.AREA:
		canvas.mode = HoloMapCanvas.Mode.CITY
	else:
		canvas.mode = HoloMapCanvas.Mode.AREA
	canvas.queue_redraw()


func get_live_player_position() -> Vector3:
	if player_pos_override != null:
		return player_pos_override as Vector3
	var port: Object = Router.get("_port")
	if port != null:
		if port.has_method("player_position"):
			return port.player_position()
		var rooftop: Object = port.get("_rooftop")
		if rooftop != null and "player" in rooftop and rooftop.player != null:
			return rooftop.player.global_position
	if _area_def != null:
		return _area_def.spawn_position_for(GameState.save_point)
	return Vector3.ZERO
