class_name EquipmentMenu
extends UiScreen
## purpose: Equipment menu with Neon sprite hologram hero, slot boxes, owned list, stats comparison and tabs.

const ID: StringName = &"equipment"

enum Mode { SLOTS, LIST }

var hero: StringName = &"rydan"
var heroes: Array[StringName] = []
var active_slot: StringName = &"blade"
var mode: Mode = Mode.SLOTS
var root: Control
var tabs: EquipmentTabsBar
var header: EquipmentHeroHeader
var owned_list: EquipmentOwnedList
var stage: HologramStage
var boxes_manager := EquipmentBoxes.new()
var stats: EquipmentStatsPanel
var desc: EquipmentDescBar
var _data := EquipmentData.new()
var _is_open: bool = false


func _init() -> void:
	super()
	visible = false
	backdrop_id = ID
	prompts = [
		{"key": "accept", "text": "EQUIP_PROMPT_EQUIP"}, {"key": "hero", "text": "EQUIP_PROMPT_HERO"},
		{"key": "back", "text": "EQUIP_PROMPT_BACK"}, {"key": "tab", "text": "EQUIP_PROMPT_TAB"},
	]


func open(args: Dictionary = {}) -> void:
	_is_open = true
	visible = true
	super(args)


func close(result: Variant = null) -> void:
	_is_open = false
	super(result)


func cancel() -> void:
	_is_open = false
	visible = false
	closed.emit(null)


func is_open() -> bool:
	return _is_open and not is_closing()


func build(_args: Dictionary) -> void:
	root = Ui.screen_root()
	add_child(root)
	heroes.clear()
	for h: Variant in GameState.party:
		heroes.append(StringName(str(h)))
	if heroes.is_empty():
		heroes = [&"rydan", &"bilqis"]
	hero = heroes[0]
	_build_components()
	show_hero(hero)


func focus_default() -> void:
	if mode == Mode.LIST:
		owned_list.focus_first()
	else:
		boxes_manager.focus_first()


func on_back() -> bool:
	if mode == Mode.LIST:
		mode = Mode.SLOTS
		boxes_manager.set_allow_hover_focus(true)
		boxes_manager.focus_slot(active_slot)
		return true
	close()
	return true


func _unhandled_input(event: InputEvent) -> void:
	var step: int = EquipmentTabsBar.event_step(event)
	if step != 0:
		cycle_hero(step)
		get_viewport().set_input_as_handled()
		return
	if tabs != null and tabs.handle_input(event):
		get_viewport().set_input_as_handled()


func _build_components() -> void:
	tabs = EquipmentTabsBar.new().setup(EquipmentTabsBar.Tab.EQUIPMENT)
	header = EquipmentHeroHeader.new()
	owned_list = EquipmentOwnedList.new()
	owned_list.item_focused.connect(_on_item_focused)
	owned_list.item_activated.connect(_on_item_pressed)
	stage = HologramStage.new()
	stage.position = Vector2(560.0, 140.0)
	stats = EquipmentStatsPanel.new()
	stats.position = Vector2(1400.0, 140.0)
	desc = EquipmentDescBar.new()
	for n: Control in [tabs, header, owned_list, stage, stats, desc]:
		root.add_child(n)
	boxes_manager.build(root, stage, _on_slot_activated, _on_slot_focused)


func show_hero(hero_id: StringName) -> void:
	hero = hero_id
	header.set_hero(hero)
	stage.set_hero(hero)
	mode = Mode.SLOTS
	boxes_manager.refresh(hero)
	boxes_manager.set_allow_hover_focus(true)
	var parts: Array[StringName] = EquipmentOptions.parts_for(hero)
	active_slot = parts[0] if not parts.is_empty() else &"armor"
	boxes_manager.set_active_slot(active_slot)
	stage.set_active_slot(active_slot)
	owned_list.populate(hero, active_slot)
	stats.update_stats(hero)
	_update_desc_from_worn()


func _on_slot_focused(slot_name: StringName) -> void:
	if active_slot == slot_name and mode == Mode.SLOTS:
		return
	active_slot = slot_name
	boxes_manager.set_active_slot(active_slot)
	stage.set_active_slot(active_slot)
	owned_list.populate(hero, active_slot)
	stats.update_stats(hero)
	_update_desc_from_worn()


func _on_slot_activated(slot_name: StringName) -> void:
	active_slot = slot_name
	boxes_manager.set_active_slot(active_slot)
	stage.set_active_slot(active_slot)
	owned_list.populate(hero, active_slot)
	mode = Mode.LIST
	boxes_manager.set_allow_hover_focus(false)
	owned_list.focus_first()


func _on_item_focused(item: EquipDef) -> void:
	if active_slot != &"gemstones":
		stats.update_stats(hero, Inventory.slot_key(hero, active_slot), item.id)
	desc.set_item(item)


func _on_item_pressed(item: EquipDef) -> void:
	if active_slot != &"gemstones":
		var slot_key: StringName = Inventory.slot_key(hero, active_slot)
		Inventory.equip(GameState.equipment, GameState.inventory, slot_key, item)
	boxes_manager.refresh(hero)
	owned_list.populate(hero, active_slot)
	stats.update_stats(hero)
	desc.set_item(item)


func _update_desc_from_worn() -> void:
	var item: EquipDef = _data.worn_item(GameState.equipment, hero, active_slot)
	desc.set_item(item)


func cycle_hero(dir: int) -> void:
	var idx: int = heroes.find(hero)
	var next_idx: int = (idx + dir + heroes.size()) % heroes.size()
	show_hero(heroes[next_idx])
	boxes_manager.focus_first()
