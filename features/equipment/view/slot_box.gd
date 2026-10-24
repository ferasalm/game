class_name SlotBox
extends Button
## purpose: 150x150 equipment slot box showing slot label, item icon or gemstone sockets.

signal slot_activated(part: StringName)
signal slot_focused(part: StringName)

var part: StringName = &""
var is_gemstones: bool = false
## Shows the worn item's gem sockets under the label instead of its icon (the accessory ring).
var show_sockets: bool = false
var is_selected: bool = false
var allow_hover_focus: bool = true
var _label: Label
var _icon: TextureRect
var _name_label: Label
var _sockets_row: HBoxContainer
var _socket_panels: Array[PanelContainer] = []
var _worn_item: EquipDef = null
var _has_dim_ring: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(150.0, 150.0)
	size = Vector2(150.0, 150.0)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	flat = true
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)


func _ready() -> void:
	_build_ui()


func setup(part_name: StringName, display_label: String, gemstones: bool = false, with_sockets: bool = false) -> SlotBox:
	part = part_name
	is_gemstones = gemstones
	show_sockets = with_sockets
	if _label != null:
		_label.text = display_label
	if _sockets_row != null:
		_sockets_row.visible = is_gemstones or show_sockets
	if _icon != null:
		_icon.visible = not is_gemstones and not show_sockets
	queue_redraw()
	return self


func set_item(item: EquipDef) -> void:
	if is_gemstones or _icon == null:
		return
	_worn_item = item
	if item != null:
		_has_dim_ring = false
		if show_sockets:
			_icon.visible = false
			_sockets_row.visible = true
		else:
			ItemIcons.apply(_icon, item, 96)
		if _name_label != null:
			_name_label.text = Ui.text(item.name_key)
			_name_label.add_theme_color_override("font_color", UiRarity.colour(item.rarity))
	else:
		_has_dim_ring = true
		for c: Node in _icon.get_children():
			c.queue_free()
		_icon.texture = ItemIcons.dim_ring(96)
		if show_sockets:
			_icon.visible = true
			_sockets_row.visible = false
		if _name_label != null:
			_name_label.text = ""
			_name_label.remove_theme_color_override("font_color")


func item_name() -> String:
	return _name_label.text if _name_label != null else ""


func has_dim_ring() -> bool:
	return _has_dim_ring


func is_empty_slot() -> bool:
	return _has_dim_ring


func name_label() -> Label:
	return _name_label


func icon_texture() -> Texture2D:
	return _icon.texture if _icon != null else null


func set_sockets(stones_list: Array, open_count: int) -> void:
	if not is_gemstones and not show_sockets:
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
	_icon.visible = not is_gemstones and not show_sockets
	column.add_child(_icon)

	_build_sockets_row(column)

	_name_label = Label.new()
	_name_label.name = &"ItemName"
	_name_label.theme_type_variation = &"SmallLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-20.0, 154.0)
	_name_label.size = Vector2(190.0, 24.0)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)


func _build_sockets_row(parent: Control) -> void:
	_sockets_row = HBoxContainer.new()
	_sockets_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_sockets_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sockets_row.add_theme_constant_override("separation", 6)
	_sockets_row.visible = is_gemstones or show_sockets
	_socket_panels.clear()
	for i: int in range(3):
		var socket := PanelContainer.new()
		socket.custom_minimum_size = Vector2(44.0, 44.0)
		socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sockets_row.add_child(socket)
		_socket_panels.append(socket)
	parent.add_child(_sockets_row)


func _draw_socket_content(panel: PanelContainer, stone_id: StringName) -> void:
	SlotSocketDraw.draw(panel, stone_id)


func _on_focus_entered() -> void:
	Ui.sweep(self)
	queue_redraw()
	slot_focused.emit(part)


func _on_mouse_entered() -> void:
	if allow_hover_focus:
		grab_focus()


func _on_pressed() -> void:
	slot_activated.emit(part)


func _draw() -> void:
	var style: UiStyleDef = Ui.style()
	var rect := Rect2(Vector2.ZERO, size)
	var bg_col: Color = style.colour(&"c_glass_menu")
	draw_rect(rect, bg_col, true)
	if has_focus() or is_selected:
		draw_rect(rect, style.colour(&"c_brass"), false, 3.0)
	else:
		draw_rect(rect, style.colour(&"c_cyan"), false, 2.0)
