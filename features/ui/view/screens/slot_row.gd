class_name SlotRow
extends Button
## One save slot row: thumbnail 300x170, slot label, area, play time, date, or empty slot.

var slot_number: int = 1
var is_saved: bool = false
var _thumb: TextureRect
var _slot_label: Label
var _area_label: Label
var _time_label: Label
var _date_label: Label
var _empty_label: Label
var _content_box: HBoxContainer


func setup(slot: int, has_data: bool, summary: Dictionary, service: SaveService, mode: StringName) -> SlotRow:
	slot_number = slot
	is_saved = has_data
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(900, 190)
	alignment = HORIZONTAL_ALIGNMENT_LEFT

	_empty_label = Ui.label(Ui.text("SLOT_EMPTY_ROW"), &"TitleLabel", style.colour(&"c_muted"))
	_empty_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_empty_label)

	_content_box = HBoxContainer.new()
	_content_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_box.add_theme_constant_override("separation", style.size(&"s_margin"))
	_content_box.offset_left = style.size(&"s_pad")
	_content_box.offset_right = -style.size(&"s_pad")
	add_child(_content_box)

	_content_box.add_child(_build_thumb(style))
	_content_box.add_child(_build_info(style, slot, summary, service))

	if has_data:
		_empty_label.visible = false
		_content_box.visible = true
		_thumb.texture = service.read_thumbnail(slot)
	else:
		_empty_label.visible = true
		_content_box.visible = false

	if mode == SlotPickerScreen.MODE_LOAD and not has_data:
		disabled = true

	focus_entered.connect(UiSweep.start.bind(self))
	focus_exited.connect(UiSweep.clear.bind(self))
	mouse_entered.connect(grab_focus)
	return self


func _build_thumb(style: UiStyleDef) -> Control:
	var thumb_box := PanelContainer.new()
	thumb_box.custom_minimum_size = Vector2(300, 170)
	thumb_box.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"inset"))
	thumb_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb = TextureRect.new()
	_thumb.custom_minimum_size = Vector2(300, 170)
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_box.add_child(_thumb)
	return thumb_box


func _build_info(style: UiStyleDef, slot: int, summary: Dictionary, service: SaveService) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_slot_label = Ui.label("SLOT %02d" % slot, &"TitleLabel", style.colour(&"c_brass"))
	col.add_child(_slot_label)

	var area_id: StringName = StringName(str(summary.get("area", "")))
	var area_def := ContentDB.get_def("area", area_id) as AreaDef
	var place: String = Ui.text(area_def.name_key) if area_def != null else String(area_id)
	_area_label = Ui.label(place, &"NameLabel", style.colour(&"c_cyan"))
	col.add_child(_area_label)

	var secs: float = float(summary.get("play_seconds", 0.0))
	var hours: int = int(secs) / 3600
	var mins: int = (int(secs) % 3600) / 60
	_time_label = Ui.label(Ui.text("SLOT_PLAY_TIME_FMT") % ("%02dh %02dm" % [hours, mins]), &"SmallLabel")
	col.add_child(_time_label)

	var mtime: int = service.modified_time(slot)
	var date_str: String = Time.get_datetime_string_from_unix_time(mtime, true) if mtime > 0 else ""
	if date_str.contains("T"):
		date_str = date_str.replace("T", " ").left(16)
	_date_label = Ui.label(Ui.text("SLOT_DATE_FMT") % date_str, &"SmallLabel", style.colour(&"c_muted"))
	col.add_child(_date_label)
	return col


func thumbnail_rect() -> TextureRect:
	return _thumb
