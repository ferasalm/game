class_name SlotDetail
extends PanelContainer
## Details panel for the focused save slot: header, thumbnail 440x248, party, riyal, play time.

var _header: Label
var _thumb: TextureRect
var _time: Label
var _money: MoneyCounter
var _empty_note: Label
var _content: VBoxContainer
var _party_row: HBoxContainer


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(460, 620)
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(box)

	_header = Ui.label("", &"TitleLabel", style.colour(&"c_brass"))
	box.add_child(_header)
	box.add_child(Ui.divider())

	_empty_note = Ui.label(Ui.text("SLOT_EMPTY_ROW"), &"NameLabel", style.colour(&"c_muted"))
	_empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_empty_note)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", style.size(&"s_gap"))
	box.add_child(_content)
	_build_content(style)


func _build_content(style: UiStyleDef) -> void:
	var thumb_box := PanelContainer.new()
	thumb_box.custom_minimum_size = Vector2(440, 248)
	thumb_box.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"inset"))
	_thumb = TextureRect.new()
	_thumb.custom_minimum_size = Vector2(440, 248)
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb_box.add_child(_thumb)
	_content.add_child(thumb_box)


	_time = Ui.label("", &"SmallLabel")
	_content.add_child(_time)

	var money_row := HBoxContainer.new()
	_money = Ui.money_counter()
	money_row.add_child(_money)
	_content.add_child(money_row)

	_party_row = HBoxContainer.new()
	_party_row.add_theme_constant_override("separation", style.size(&"s_pad"))
	_content.add_child(_party_row)


func show_slot(slot: int, has_data: bool, summary: Dictionary, service: SaveService) -> void:
	_header.text = "SLOT %02d" % slot
	if not has_data:
		_empty_note.visible = true
		_content.visible = false
		return

	_empty_note.visible = false
	_content.visible = true
	_thumb.texture = service.read_thumbnail(slot)


	var secs: float = float(summary.get("play_seconds", 0.0))
	var hours: int = int(secs) / 3600
	var mins: int = (int(secs) % 3600) / 60
	_time.text = Ui.text("SLOT_PLAY_TIME_FMT") % ("%02dh %02dm" % [hours, mins])
	_money.set_amount(int(summary.get("money", 0)), false)
	_refresh_party(slot, service)


func _refresh_party(slot: int, service: SaveService) -> void:
	for child: Node in _party_row.get_children():
		child.queue_free()
	var party: Array = []
	if service != null and service.exists(slot):
		var full: Dictionary = service.read(slot)
		party = full.get("party", [])
	if party.is_empty():
		party = [&"rydan", &"bilqis"]
	for hero_v: Variant in party:
		var hero: StringName = StringName(hero_v)
		var face: Control = PortraitFaces.face(hero, Ui.style().colour(&"c_party"))
		face.custom_minimum_size = Vector2(48, 48)
		_party_row.add_child(face)


func thumbnail_rect() -> TextureRect:
	return _thumb
