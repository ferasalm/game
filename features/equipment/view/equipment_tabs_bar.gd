class_name EquipmentTabsBar
extends HBoxContainer
## purpose: Top bar (1760x64 at 80,40) with title pair and menu tabs (Equipment, Items, Map).

signal items_requested
signal map_requested

var _eq_btn: Button
var _items_btn: Button
var _map_btn: Button


func _init() -> void:
	position = Vector2(80.0, 40.0)
	custom_minimum_size = Vector2(1760.0, 64.0)
	size = Vector2(1760.0, 64.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	var title_box := Ui.title_plate(Ui.text("EQUIP_TITLE"), Ui.text("EQUIP_TITLE_MUSNAD"))
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(title_box)

	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 16)
	add_child(tabs_row)

	_eq_btn = Button.new()
	_eq_btn.text = Ui.text("EQUIP_TAB_EQUIPMENT")
	_eq_btn.theme_type_variation = &"TabButton"
	_eq_btn.focus_mode = Control.FOCUS_NONE
	tabs_row.add_child(_eq_btn)

	_items_btn = Button.new()
	_items_btn.text = Ui.text("EQUIP_TAB_ITEMS")
	_items_btn.theme_type_variation = &"TabButton"
	_items_btn.pressed.connect(items_requested.emit)
	tabs_row.add_child(_items_btn)

	_map_btn = Button.new()
	_map_btn.text = Ui.text("EQUIP_TAB_MAP")
	_map_btn.theme_type_variation = &"TabButton"
	_map_btn.pressed.connect(map_requested.emit)
	tabs_row.add_child(_map_btn)
