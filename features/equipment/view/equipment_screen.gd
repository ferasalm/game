class_name EquipmentScreen
extends CanvasLayer
## The equipment screen (the bench): a tab per hero (Zayd: hilt, blade, prosthetic; Bilqis: prosthetic), the OWNED
## items of each slot with rarity colours and tags, the perk and tech moves of the focused item, and the stat
## comparison base vs. the staged kit. Confirm writes GameState.equipment through Inventory.equip; back leaves
## without saving. Keyboard, pad and mouse work through Button focus.
## Use: add it to the scene, call open(), listen to closed.

## Emitted once each time the screen closes (Confirm or back).
signal closed

var _data: EquipmentData
var _worn: Dictionary[StringName, StringName] = {}
var _staged: Dictionary[StringName, StringName] = {}
var _owned: Array[StringName] = []
var _hero: StringName = &""
var _page: EquipmentPage
var _tabs: Dictionary[StringName, Button] = {}
var _buttons: Array[Button] = []
var _opened_frame: int = -1


func _ready() -> void:
	layer = 10
	visible = false
	_data = EquipmentData.new()
	_build()


## Shows the screen with what each hero wears staged, on the first hero's tab.
func open() -> void:
	_worn = {}
	_owned = GameState.inventory.duplicate()
	for hero: StringName in _data.heroes:
		_worn.merge(EquipmentOptions.worn(GameState.equipment, _data.starts[hero]))
	for item_id: StringName in _worn.values():
		Inventory.add(_owned, item_id)
	_staged = _worn.duplicate()
	show_hero(_data.heroes[0])
	AudioDirector.play_ui(&"menu_open")
	visible = true
	_opened_frame = Engine.get_process_frames()
	_focus_first()


func is_open() -> bool:
	return visible


## Switches to a hero's tab (rebuilds the item lists).
func show_hero(hero: StringName) -> void:
	_hero = hero
	_tabs[hero].set_pressed_no_signal(true)
	_page.clear_list()
	_buttons.clear()
	for part: StringName in EquipmentOptions.parts_for(hero):
		_add_section(hero, part)
	_preview({}, &"")


## Stages an owned item in a slot ("zayd.hilt"); refused with a warning when unknown, not owned or not fitting.
func select(slot: StringName, item_id: StringName) -> void:
	var problem: String = Inventory.equip_problem(_owned, slot, _data.items.get(item_id) as EquipDef)
	if not problem.is_empty():
		push_warning("EquipmentScreen: " + problem)
		return
	_staged[slot] = item_id
	for button: Button in _buttons:
		if button.get_meta("slot") == slot:
			button.set_pressed_no_signal(button.get_meta("item_id") == item_id)
	_preview({}, item_id)


## Saves every staged slot into GameState.equipment and closes.
func confirm() -> void:
	if not visible:
		return
	AudioDirector.play_ui(&"menu_confirm")
	for problem: String in EquipmentOptions.apply(GameState.equipment, _owned, _staged, _data.items):
		push_warning("EquipmentScreen: " + problem)
	_close()


## Closes without changing anything.
func cancel() -> void:
	if visible:
		AudioDirector.play_ui(&"menu_cancel")
		_close()


## The item buttons of the hero now shown, in list order. Meta "slot" and "item_id".
func item_buttons() -> Array[Button]:
	return _buttons


func tab_button(hero: StringName) -> Button:
	return _tabs[hero]


func hero() -> StringName:
	return _hero


func staged() -> Dictionary[StringName, StringName]:
	return _staged


func detail() -> EquipmentDetail:
	return _page.detail


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"back") or event.is_action_pressed(&"ui_cancel")):
		cancel()
		get_viewport().set_input_as_handled()


func _add_section(hero: StringName, part: StringName) -> void:
	_page.add_to_list(Ui.label(Ui.text("WORKSHOP_PART_" + String(part).to_upper()), &"CaptionLabel"))
	var slot: StringName = Inventory.slot_key(hero, part)
	var group := ButtonGroup.new()
	var fitting: Array[EquipDef] = EquipmentOptions.options(_owned, _data.all_items(), hero, part, _data.rarity_order)
	if fitting.is_empty():
		_page.add_to_list(Ui.label(Ui.text("WORKSHOP_EMPTY"), &"MutedLabel"))
	for item: EquipDef in fitting:
		var button: Button = EquipmentItemButton.make(item, slot, group, _worn.get(slot) == item.id)
		button.set_pressed_no_signal(_staged.get(slot) == item.id)
		button.pressed.connect(_on_pressed.bind(slot, item.id))
		button.focus_entered.connect(_on_focused.bind(slot, item.id))
		button.mouse_entered.connect(button.grab_focus)
		_page.add_to_list(button)
		_buttons.append(button)


## Describes `item_id` (the focused or just-staged item) and compares the hero with `trial` slots laid over staged.
func _preview(trial: Dictionary[StringName, StringName], item_id: StringName) -> void:
	var kit: Dictionary[StringName, StringName] = _staged.duplicate()
	kit.merge(trial, true)
	var base := ContentDB.get_def("combatant", _hero) as CombatantDef
	var merged: CombatantDef = EquipmentOptions.fighter(base, _hero, kit, _data.items, _data.perks)
	_page.detail.show_rows(Ui.text(base.name_key), WorkshopStats.rows(base, merged))
	if item_id == &"" and not _buttons.is_empty():
		item_id = _buttons[0].get_meta("item_id")
	_page.detail.show_item(item_id)


func _on_pressed(slot: StringName, item_id: StringName) -> void:
	if Engine.get_process_frames() == _opened_frame:
		return
	AudioDirector.play_ui(&"menu_confirm")
	select(slot, item_id)


func _on_focused(slot: StringName, item_id: StringName) -> void:
	AudioDirector.play_ui(&"menu_move")
	_preview({slot: item_id}, item_id)


func _focus_first() -> void:
	for button: Button in _buttons:
		if button.button_pressed:
			button.grab_focus()
			return
	_page.confirm_button.grab_focus()


func _close() -> void:
	visible = false
	closed.emit()


func _build() -> void:
	var root: Control = Ui.screen_root()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var scrim := ColorRect.new()
	scrim.color = Ui.style().colour(&"c_scrim")
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	_page = EquipmentPage.new()
	_page.build()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, Ui.style().size(&"s_margin"))
	root.add_child(_page)
	for hero: StringName in _data.heroes:
		var base := ContentDB.get_def("combatant", hero) as CombatantDef
		var tab: Button = _page.add_tab(Ui.text(base.name_key))
		tab.pressed.connect(show_hero.bind(hero))
		_tabs[hero] = tab
	_page.confirm_button.pressed.connect(confirm)
