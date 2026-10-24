extends TestCase
## The shared Equipment / Items / Map tabs bar: every screen reaches every other tab by confirm and LB/RB or Q/E.

const IDS: Array[StringName] = [&"equipment", &"items", &"map"]


func test_every_screen_reaches_every_other_tab_by_confirm() -> void:
	for start: StringName in IDS:
		for target: StringName in IDS:
			if target == start:
				continue
			var screen: UiScreen = _open(start)
			_bar_of(screen).press_tab(_tab_of(target))
			check_eq(_top_id(), target, "%s -> %s by tab confirm" % [start, target])
	_clean()


func test_every_screen_cycles_tabs_with_lb_and_rb() -> void:
	for start: StringName in IDS:
		var screen: UiScreen = _open(start)
		screen._unhandled_input(_pad(JOY_BUTTON_RIGHT_SHOULDER))
		check_eq(_top_id(), _neighbour(start, 1), "%s -> next by RB" % start)
		_clean()
		screen = _open(start)
		screen._unhandled_input(_pad(JOY_BUTTON_LEFT_SHOULDER))
		check_eq(_top_id(), _neighbour(start, -1), "%s -> previous by LB" % start)
	_clean()


func test_every_screen_cycles_tabs_with_q_and_e() -> void:
	for start: StringName in IDS:
		var screen: UiScreen = _open(start)
		screen._unhandled_input(_key(KEY_E))
		check_eq(_top_id(), _neighbour(start, 1), "%s -> next by E" % start)
		_clean()
		screen = _open(start)
		screen._unhandled_input(_key(KEY_Q))
		check_eq(_top_id(), _neighbour(start, -1), "%s -> previous by Q" % start)
	_clean()


func test_current_tab_is_highlighted() -> void:
	var screen: UiScreen = _open(&"items")
	var button: Button = _bar_of(screen).tab_button(EquipmentTabsBar.Tab.ITEMS)
	check(button != null, "items tab button exists")
	if button != null:
		check_eq(button.get_theme_color("font_color"), Ui.style().colour(&"c_cyan"), "the current tab is cyan")
	_clean()


func test_prompt_strip_shows_the_tab_switch() -> void:
	for id: StringName in IDS:
		var screen: UiScreen = _open(id)
		var keys: Array[String] = []
		for pair: Dictionary in screen.prompts:
			keys.append(String(pair["key"]))
		check(keys.has("tab"), "%s prompts show the tab switch" % id)
	_clean()


func _open(id: StringName) -> UiScreen:
	Screens.clear()
	GameState.start_new()
	Router.state = Router.STATE_EXPLORING
	return Screens.open(id)


func _bar_of(screen: UiScreen) -> EquipmentTabsBar:
	if screen is EquipmentMenu:
		return (screen as EquipmentMenu).tabs
	if screen is ItemsScreen:
		return (screen as ItemsScreen).tabs
	return (screen as HoloMap).tabs


func _top_id() -> StringName:
	var top: UiScreen = Screens.top()
	if top is EquipmentMenu:
		return &"equipment"
	if top is ItemsScreen:
		return &"items"
	if top is HoloMap:
		return &"map"
	return &""


func _tab_of(id: StringName) -> EquipmentTabsBar.Tab:
	match id:
		&"equipment":
			return EquipmentTabsBar.Tab.EQUIPMENT
		&"items":
			return EquipmentTabsBar.Tab.ITEMS
		_:
			return EquipmentTabsBar.Tab.MAP


func _neighbour(start: StringName, step: int) -> StringName:
	var index: int = IDS.find(start)
	return IDS[(index + step + IDS.size()) % IDS.size()]


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _clean() -> void:
	Screens.clear()
	GameState.reset()
	Router.state = Router.STATE_TITLE
