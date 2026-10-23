class_name WorkshopSocketsRow
extends HBoxContainer
## purpose: Displays the worn hilt's 3 gemstone sockets (96px circles) under the hologram.

signal socket_selected(slot: int)
signal socket_focused(slot: int)

var selected_slot: int = 0
var _buttons: Array[Button] = []
var _socket_stones: Array[StringName] = []


func _init() -> void:
	custom_minimum_size = Vector2(760.0, 96.0)
	size = Vector2(760.0, 96.0)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 32)
	_build_sockets()


## Updates the display with currently socketed stones and the number of unlocked sockets.
func set_sockets(stones: Array, open_count: int, active_slot: int = 0) -> void:
	_socket_stones.clear()
	for s: Variant in stones:
		_socket_stones.append(StringName(str(s)))
	selected_slot = active_slot
	for i: int in 3:
		var btn: Button = _buttons[i]
		btn.visible = (i < open_count)
		var stone_id: StringName = _socket_stones[i] if i < _socket_stones.size() else &""
		btn.set_meta(&"stone_id", stone_id)
		btn.queue_redraw()


func focus_socket(slot: int) -> void:
	if slot >= 0 and slot < _buttons.size() and _buttons[slot].visible:
		_buttons[slot].grab_focus()


func _build_sockets() -> void:
	for i: int in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(96.0, 96.0)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_pressed.bind(i))
		btn.focus_entered.connect(_on_focused.bind(i))
		btn.draw.connect(_draw_socket.bind(btn, i))
		add_child(btn)
		_buttons.append(btn)


func _on_pressed(slot: int) -> void:
	selected_slot = slot
	socket_selected.emit(slot)
	queue_redraw()


func _on_focused(slot: int) -> void:
	selected_slot = slot
	socket_focused.emit(slot)
	queue_redraw()


func _draw_socket(btn: Button, slot: int) -> void:
	var style: UiStyleDef = Ui.style()
	var center := btn.size * 0.5
	var radius: float = 40.0
	var stone_id: StringName = btn.get_meta(&"stone_id", &"")
	var is_focused: bool = btn.has_focus() or (selected_slot == slot)

	var bg_col := Color(0.08, 0.1, 0.14, 0.8)
	if stone_id != &"":
		var tier_col: Color = UiRarity.item_colour(stone_id)
		bg_col = Color(tier_col.r, tier_col.g, tier_col.b, 0.35)
		btn.draw_circle(center, radius, bg_col)
		btn.draw_circle(center, radius * 0.5, tier_col)
	else:
		btn.draw_circle(center, radius, bg_col)

	var ring_col: Color = style.colour(&"c_brass" if is_focused else &"c_muted")
	var ring_width: float = 3.5 if is_focused else 1.5
	btn.draw_arc(center, radius, 0.0, TAU, 32, ring_col, ring_width, true)
