class_name ItemsScreen
extends UiScreen
## The Items screen (Screens id &"items"): the bag on the left, a PartyCard per hero on the right with the selected
## item's real gain previewed on each, and the item's description at the bottom. A on an item moves to the cards,
## A on a card uses it (FieldUse via ItemService), B goes back a step. Battle-only items never list.
## Rules live in FieldUse; this only draws and routes input.

const ID: StringName = &"items"

var tabs: EquipmentTabsBar
var list: ItemsListPanel
var party_panel: ItemsPartyPanel
var desc: ItemsDescBar

var _selected: StringName = &""
var _picking: bool = false


func _init() -> void:
	super()
	backdrop_id = ID
	prompts = [
		{"key": "accept", "text": "ITEMS_PROMPT_USE"},
		{"key": "back", "text": "ITEMS_PROMPT_BACK"},
		{"key": "tab", "text": "EQUIP_PROMPT_TAB"},
	]


func build(_args: Dictionary) -> void:
	var root := Ui.screen_root()
	add_child(root)
	tabs = EquipmentTabsBar.new().setup(EquipmentTabsBar.Tab.ITEMS)
	root.add_child(tabs)
	list = ItemsListPanel.new()
	list.item_focused.connect(_on_item_focused)
	list.item_activated.connect(choose)
	root.add_child(list)
	party_panel = ItemsPartyPanel.new()
	party_panel.setup_party(_party())
	party_panel.hero_chosen.connect(use_on)
	root.add_child(party_panel)
	desc = ItemsDescBar.new()
	root.add_child(desc)
	list.populate()
	party_panel.set_picking(false)


func focus_default() -> void:
	if not is_inside_tree():
		return
	if _picking and party_panel.focus_first_usable():
		return
	list.focus_first()


func on_back() -> bool:
	if _picking:
		_set_picking(false)
		var row: Button = list.row_of(_selected)
		if row != null:
			row.grab_focus()
		else:
			list.focus_first()
		return true
	close()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if tabs != null and tabs.handle_input(event):
		get_viewport().set_input_as_handled()


## The field-usable consumable ids listed, top to bottom (for tests).
func item_ids() -> Array[StringName]:
	return list.ids()


func row_of(item_id: StringName) -> Button:
	return list.row_of(item_id)


func hero_button(hero: StringName) -> Button:
	return party_panel.hero_button(hero)


func hero_card(hero: StringName) -> PartyCard:
	return party_panel.hero_card(hero)


func selected_item() -> StringName:
	return _selected


func is_picking() -> bool:
	return _picking


## Shows an item's description and previews without entering the target step.
func select_item(item_id: StringName) -> void:
	_selected = item_id
	var def := ContentDB.get_def("consumable", item_id) as ConsumableDef
	if def == null:
		desc.clear()
		party_panel.clear_preview()
		return
	desc.set_item(def, GameState.bag.get(item_id, 0))
	party_panel.show_preview(def, GameState.vitals, ItemService.maxes())
	party_panel.set_picking(_picking)


## Picks an item as if its row was pressed: shows it and moves focus to the hero cards.
func choose(item_id: StringName) -> void:
	select_item(item_id)
	if _selected == &"":
		return
	_set_picking(true)
	party_panel.focus_first_usable()


## Uses the chosen item on a hero (any hero for an all-party item) and refreshes everything.
func use_on(hero: StringName) -> void:
	if not _picking or _selected == &"":
		return
	var def := ContentDB.get_def("consumable", _selected) as ConsumableDef
	var result: Dictionary = ItemService.use(_selected, hero)
	if not result["ok"]:
		Ui.toast(Ui.text("ITEMS_FULL"), &"bad")
		return
	var name_text: String = Ui.text(def.name_key)
	var used_text: String = Ui.text("ITEMS_USED_PARTY") % name_text if def.target == &"all_allies" \
			else Ui.text("ITEMS_USED") % [name_text, _hero_name(hero)]
	Ui.toast(used_text, &"good")
	party_panel.refresh_vitals()
	var keep: StringName = _selected
	list.populate()
	if GameState.bag.get(keep, 0) > 0:
		choose(keep)
	else:
		_set_picking(false)
		_selected = &""
		desc.clear()
		party_panel.clear_preview()
		list.focus_first()


func _set_picking(on: bool) -> void:
	_picking = on
	party_panel.set_picking(on)


func _on_item_focused(item_id: StringName) -> void:
	if item_id != _selected:
		select_item(item_id)


func _party() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(GameState.party)
	return out


func _hero_name(hero: StringName) -> String:
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	return String(hero) if def == null else Ui.text(def.name_key)
