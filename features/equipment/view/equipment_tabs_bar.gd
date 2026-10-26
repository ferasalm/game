class_name EquipmentTabsBar
extends HBoxContainer
## purpose: Shared top bar (1760x64 at 80,40) with the screen title and the Equipment / Items / Map tabs.

enum Tab { EQUIPMENT, ITEMS, MAP }

const IDS: Array[StringName] = [&"equipment", &"items", &"map"]
const TAB_KEYS: Array[String] = ["EQUIP_TAB_EQUIPMENT", "EQUIP_TAB_ITEMS", "EQUIP_TAB_MAP"]

var current: Tab = Tab.EQUIPMENT

var _buttons: Dictionary[int, Button] = {}
var _info_main: String = ""
var _info_sub: String = ""
var _lt_down: bool = false
var _rt_down: bool = false


func _init() -> void:
	position = Vector2(80.0, 40.0)
	custom_minimum_size = Vector2(1760.0, 64.0)
	size = Vector2(1760.0, 64.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sets the highlighted tab (and so the title) and optional info text; returns self.
func setup(current_tab: Tab, info_main: String = "", info_sub: String = "") -> EquipmentTabsBar:
	current = current_tab
	_info_main = info_main
	_info_sub = info_sub
	return self


func _ready() -> void:
	_build_ui()


## The button of one tab (null before the bar is in the tree).
func tab_button(tab: Tab) -> Button:
	return _buttons.get(int(tab))


## Switches screens as if the tab was clicked; the current tab does nothing.
func press_tab(tab: Tab) -> void:
	_open_tab(int(tab))


## Moves to the next registered tab `step` places away, wrapping round and skipping missing screens (LB/RB and Q/E).
func cycle(step: int) -> void:
	if step == 0:
		return
	var next: int = int(current)
	for _i: int in IDS.size():
		next = (next + step + IDS.size()) % IDS.size()
		if next == int(current):
			return
		if _available(next):
			_open_tab(next)
			return


## Handles the tab keys and quick-switch keys: returns true when it switched.
func handle_input(event: InputEvent) -> bool:
	var step: int = tab_step(event)
	if step == 0:
		step = event_step(event)
	if step == 0:
		return false
	cycle(step)
	return true


## Tab / Shift+Tab and LT/RT move between the screens; 0 for anything else.
func tab_step(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB:
			return -1 if event.shift_pressed else 1
	elif event is InputEventJoypadMotion:
		return _trigger_step(event)
	return 0


## -1 for LB/Q, 1 for RB/E, 0 for anything else (the hero switch on Equipment).
static func event_step(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q or event.physical_keycode == KEY_Q:
			return -1
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			return 1
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			return -1
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			return 1
	return 0


func _trigger_step(event: InputEventJoypadMotion) -> int:
	var down: bool = event.axis_value > 0.5
	if event.axis == JOY_AXIS_TRIGGER_LEFT:
		var was_left: bool = _lt_down
		_lt_down = down
		return -1 if down and not was_left else 0
	if event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var was_right: bool = _rt_down
		_rt_down = down
		return 1 if down and not was_right else 0
	return 0


## Tab is consumed by the focus system before _unhandled_input, so the bar claims it first.
func _input(event: InputEvent) -> void:
	var step: int = tab_step(event)
	if step == 0:
		return
	cycle(step)
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	_buttons.clear()
	var title_box := Ui.title_plate(Ui.text(_title_key(0)), Ui.text(_title_key(1)))
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(title_box)
	if not _info_main.is_empty():
		add_child(_info_box())
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 16)
	add_child(tabs_row)
	for index: int in IDS.size():
		if _available(index):
			_add_tab(tabs_row, index)


## True when a screen is registered for that tab (the Map tab is skipped when no map screen exists).
func _available(tab: int) -> bool:
	return Screens.has_screen(IDS[tab])


func _add_tab(parent: Control, tab: int) -> void:
	var button := Button.new()
	button.text = Ui.text(TAB_KEYS[tab])
	button.theme_type_variation = &"TabButton"
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_open_tab.bind(tab))
	button.focus_entered.connect(UiSweep.start.bind(button))
	button.focus_exited.connect(UiSweep.clear.bind(button))
	button.mouse_entered.connect(button.grab_focus)
	if tab == int(current):
		_mark_current(button)
	parent.add_child(button)
	_buttons[tab] = button


func _mark_current(button: Button) -> void:
	var style: UiStyleDef = Ui.style()
	button.add_theme_color_override("font_color", style.colour(&"c_cyan"))
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, UiBoxes.pill_button(style, &"pressed"))


func _info_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(Ui.label(_info_main, &"NameLabel", Ui.style().colour(&"c_brass")))
	if not _info_sub.is_empty():
		box.add_child(Ui.label(_info_sub, &"SmallLabel", Ui.style().colour(&"c_cyan")))
	return box


func _title_key(slot: int) -> String:
	match int(current):
		int(Tab.ITEMS):
			return "ITEMS_TITLE" if slot == 0 else "ITEMS_TITLE_MUSNAD"
		int(Tab.MAP):
			return "MAP_TITLE" if slot == 0 else "MAP_TITLE_MUSNAD"
		_:
			return "EQUIP_TITLE" if slot == 0 else "EQUIP_TITLE_MUSNAD"


func _open_tab(tab: int) -> void:
	if tab == int(current) or not _available(tab):
		return
	var screen: UiScreen = Screens.top()
	if screen != null:
		screen.close()
	Screens.open(IDS[tab])
