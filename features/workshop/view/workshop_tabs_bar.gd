class_name WorkshopTabsBar
extends HBoxContainer
## purpose: Header bar (1760x64 at 80,40) with title pair, mode tabs, and money counter.

signal tab_selected(index: int)

enum Tab { UPGRADE = 0, GEMSTONES = 1, CRAFTING = 2 }

var current_tab: int = Tab.UPGRADE
var _buttons: Array[Button] = []
var _counter: MoneyCounter


func _init() -> void:
	position = Vector2(80.0, 40.0)
	custom_minimum_size = Vector2(1760.0, 64.0)
	size = Vector2(1760.0, 64.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_ui()


func set_money(amount: int, animate: bool = true) -> void:
	if _counter != null:
		_counter.set_amount(amount, animate)


func select_tab(index: int) -> void:
	current_tab = clampi(index, 0, Tab.CRAFTING)
	for i: int in _buttons.size():
		var btn: Button = _buttons[i]
		var is_active: bool = (i == current_tab)
		btn.add_theme_color_override("font_color", Ui.style().colour(&"c_brass" if is_active else &"c_muted"))
	tab_selected.emit(current_tab)


func next_tab() -> void:
	select_tab((current_tab + 1) % 3)


func prev_tab() -> void:
	select_tab((current_tab + 2) % 3)


func _build_ui() -> void:
	for child: Node in get_children():
		child.queue_free()
	_buttons.clear()

	var title_box := Ui.title_pair(Ui.text("WORKSHOP_TITLE"), Ui.text("WORKSHOP_TITLE_MUSNAD"))
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(title_box)

	var tabs_box := HBoxContainer.new()
	tabs_box.add_theme_constant_override("separation", 16)
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(tabs_box)

	var keys: Array[String] = ["WORKSHOP_TAB_UPGRADE", "WORKSHOP_TAB_GEMSTONES", "WORKSHOP_TAB_CRAFTING"]
	for i: int in keys.size():
		var btn := Button.new()
		btn.text = Ui.text(keys[i])
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(select_tab.bind(i))
		tabs_box.add_child(btn)
		_buttons.append(btn)

	_counter = Ui.money_counter()
	_counter.custom_minimum_size.x = 240.0
	_counter.set_amount(GameState.money, false)
	add_child(_counter)

	select_tab(Tab.UPGRADE)
