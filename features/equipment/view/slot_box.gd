class_name SlotBox
extends Button
## purpose: 150x150 equipment slot box showing slot label, item icon or gemstone sockets.

signal slot_activated(part: StringName)

var part: StringName = &""
var is_gemstones: bool = false
var _label: Label
var _icon: TextureRect
var _sockets_row: HBoxContainer
var _socket_panels: Array[PanelContainer] = []


func _init() -> void:
	custom_minimum_size = Vector2(150.0, 150.0)
	size = Vector2(150.0, 150.0)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	flat = true
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(queue_redraw)
	pressed.connect(_on_pressed)


func _ready() -> void:
	_build_ui()


func setup(part_name: StringName, display_label: String, gemstones: bool = false) -> SlotBox:
	part = part_name
	is_gemstones = gemstones
	if is_gemstones:
		focus_mode = Control.FOCUS_NONE
	if _label != null:
		_label.text = display_label
	if _sockets_row != null:
		_sockets_row.visible = is_gemstones
	if _icon != null:
		_icon.visible = not is_gemstones
	queue_redraw()
	return self


func set_item(item: EquipDef) -> void:
	if is_gemstones or _icon == null:
		return
	if item != null and "icon" in item and not str(item.get("icon")).is_empty():
		_icon.texture = load(str(item.get("icon"))) as Texture2D
	else:
		_icon.texture = null


func set_sockets(stones_list: Array, open_count: int) -> void:
	if not is_gemstones:
		return
	for i: int in range(3):
		if i >= _socket_panels.size():
			break
		var panel: PanelContainer = _socket_panels[i]
		if i >= open_count:
			panel.visible = false
		else:
			panel.visible = true
			var stone_id: StringName = StringName(str(stones_list[i])) if i < stones_list.size() else &""
			_draw_socket_content(panel, stone_id)


func _build_ui() -> void:
	for child: Node in get_children():
		child.queue_free()
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)

	_label = Ui.label(part.to_upper(), &"CaptionLabel", Ui.style().colour(&"c_cyan"))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_label)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(96.0, 96.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.visible = not is_gemstones
	column.add_child(_icon)

	_build_sockets_row(column)


func _build_sockets_row(parent: Control) -> void:
	_sockets_row = HBoxContainer.new()
	_sockets_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_sockets_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sockets_row.add_theme_constant_override("separation", 6)
	_sockets_row.visible = is_gemstones
	_socket_panels.clear()
	for i: int in range(3):
		var socket := PanelContainer.new()
		socket.custom_minimum_size = Vector2(44.0, 44.0)
		socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sockets_row.add_child(socket)
		_socket_panels.append(socket)
	parent.add_child(_sockets_row)


func _draw_socket_content(panel: PanelContainer, stone_id: StringName) -> void:
	for c: Node in panel.get_children():
		c.queue_free()
	var style: UiStyleDef = Ui.style()
	var s_box := StyleBoxFlat.new()
	s_box.set_corner_radius_all(22)
	if stone_id == &"":
		s_box.draw_center = false
		s_box.border_color = style.colour(&"c_muted")
		s_box.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", s_box)
	else:
		var stone_def := ContentDB.get_def("stone", stone_id) as StoneDef
		var col: Color = UiRarity.colour(stone_def.rarity) if stone_def != null else style.colour(&"c_cyan")
		s_box.bg_color = Color(col.r, col.g, col.b, 0.5)
		s_box.border_color = col
		s_box.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", s_box)
		if stone_def != null and "icon" in stone_def and not str(stone_def.get("icon")).is_empty():
			var tex := TextureRect.new()
			tex.texture = load(str(stone_def.get("icon"))) as Texture2D
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(tex)


func _on_focus_entered() -> void:
	Ui.sweep(self)
	queue_redraw()


func _on_pressed() -> void:
	if not is_gemstones:
		slot_activated.emit(part)


func _draw() -> void:
	var style: UiStyleDef = Ui.style()
	var rect := Rect2(Vector2.ZERO, size)
	var bg_col := Color(0.02, 0.04, 0.07, 0.8)
	draw_rect(rect, bg_col, true)
	if has_focus():
		draw_rect(rect, style.colour(&"c_brass"), false, 3.0)
	else:
		draw_rect(rect, style.colour(&"c_cyan"), false, 2.0)
