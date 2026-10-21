class_name ItemsScreen
extends UiScreen
## The Items screen (Screens id &"items", opened from the pause menu): the bag on the left, the chosen item's
## description and effect on the right, and under it the hero picker. A on an item moves to the heroes, A on a hero
## uses it (FieldUse via ItemService), B goes back a step. An all-party item has one "whole party" button.
## Heroes the item would not change are disabled. Rules live in FieldUse; this only draws and routes input.

const ID: StringName = &"items"

var _rows: Dictionary[StringName, Button] = {}
var _hero_buttons: Dictionary[StringName, Button] = {}
var _list: UiPanel
var _picker: VBoxContainer
var _title: Label
var _desc: Label
var _effect: Label
var _message: Label
var _selected: StringName = &""
var _picking: bool = false
var _empty: Label


func _init() -> void:
	super()
	prompts = [{"key": "accept", "text": "ITEMS_PROMPT_USE"}, {"key": "back", "text": "ITEMS_PROMPT_BACK"}]


func build(_args: Dictionary) -> void:
	var style: UiStyleDef = Ui.style()
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_margin"))
	centre.add_child(row)
	_list = Ui.panel(Ui.text("ITEMS_TITLE"), Ui.text("ITEMS_TITLE_AR"))
	_list.custom_minimum_size = Vector2(style.size(&"s_pause_w"), style.size(&"s_pause_h"))
	row.add_child(_list)
	var right: UiPanel = Ui.panel()
	right.custom_minimum_size = Vector2(style.size(&"s_party_w") * 0.5, style.size(&"s_pause_h"))
	row.add_child(right)
	_title = Ui.label("", &"NameLabel")
	_desc = Ui.label("", &"MutedLabel")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect = Ui.label("", &"SmallLabel", style.colour(&"c_good"))
	_picker = VBoxContainer.new()
	_message = Ui.label("", &"SmallLabel", style.colour(&"c_brass"))
	for node: Control in [_title, _desc, _effect, Ui.divider(), Ui.label(Ui.text("ITEMS_USE_ON"), &"CaptionLabel"), _picker, _message]:
		right.body.add_child(node)
	_fill_list()


func focus_default() -> void:
	if _picking and _selected != &"" and focus_first_hero():
		return
	if _rows.has(_selected):
		_rows[_selected].grab_focus()
	elif not _rows.is_empty():
		_rows.values()[0].grab_focus()


func on_back() -> bool:
	if _picking:
		_picking = false
		_rows[_selected].grab_focus()
		return true
	close()
	return true


## The consumable ids listed, top to bottom (for tests).
func item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_rows.keys())
	return out


func row_of(item_id: StringName) -> Button:
	return _rows.get(item_id)


func hero_button(hero: StringName) -> Button:
	return _hero_buttons.get(hero)


## Picks an item as if its row was pressed: shows it and builds the hero picker.
func choose(item_id: StringName) -> void:
	_selected = item_id
	var def := ContentDB.get_def("consumable", item_id) as ConsumableDef
	_title.text = "%s  (%s)" % [Ui.text(def.name_key), Ui.text("ITEMS_OWNED") % GameState.bag.get(item_id, 0)]
	_desc.text = Ui.text(def.desc_key)
	_effect.text = ItemsText.effect(def)
	_fill_picker(def)
	_picking = true
	focus_first_hero()


## Uses the chosen item on a hero (any hero for an all-party item) and refreshes everything.
func use_on(hero: StringName) -> void:
	var def := ContentDB.get_def("consumable", _selected) as ConsumableDef
	var result: Dictionary = ItemService.use(_selected, hero)
	if not result["ok"]:
		_message.text = Ui.text("ITEMS_FULL")
		return
	var name_text: String = Ui.text(def.name_key)
	_message.text = Ui.text("ITEMS_USED_PARTY") % name_text if def.target == &"all_allies" \
			else Ui.text("ITEMS_USED") % [name_text, _hero_name(hero)]
	var keep: StringName = _selected
	_fill_list()
	if GameState.bag.get(keep, 0) > 0:
		choose(keep)
	else:
		_picking = false
		_clear_detail()
		focus_default()


func focus_first_hero() -> bool:
	for button: Button in _hero_buttons.values():
		if not button.disabled:
			button.grab_focus()
			return true
	return false


func _fill_list() -> void:
	_drop(_rows)
	if _empty != null:
		_empty.queue_free()
		_empty = null
	var owned: Array[ConsumableDef] = ItemService.owned()
	if owned.is_empty():
		_empty = Ui.label(Ui.text("ITEMS_EMPTY"), &"MutedLabel")
		_list.body.add_child(_empty)
	for def: ConsumableDef in owned:
		var button := Button.new()
		button.text = "%s   x%d" % [Ui.text(def.name_key), GameState.bag.get(def.id, 0)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
		button.pressed.connect(choose.bind(def.id))
		sweep_on_focus(button)
		_list.body.add_child(button)
		_rows[def.id] = button


## Frees every button of a registry (queue_free: a pressed button may be among them).
func _drop(buttons: Dictionary[StringName, Button]) -> void:
	for old: Button in buttons.values():
		old.queue_free()
	buttons.clear()


func _fill_picker(def: ConsumableDef) -> void:
	_drop(_hero_buttons)
	var maxes: Dictionary = ItemService.maxes()
	var vitals: Dictionary = GameState.vitals
	if def.target == &"all_allies":
		_add_hero_button(&"party", Ui.text("ITEMS_USE_PARTY"),
				FieldUse.can_use(def, vitals, ItemService.targets_for(def, &""), maxes))
		return
	for hero: StringName in GameState.party:
		var label: String = "%s   %s" % [_hero_name(hero), ItemsText.preview(def, vitals, hero, maxes)]
		_add_hero_button(hero, label, FieldUse.can_target(def, vitals, hero, maxes))


func _add_hero_button(key: StringName, content: String, usable: bool) -> void:
	var button := Button.new()
	button.text = content
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not usable
	button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
	button.pressed.connect(use_on.bind(key))
	sweep_on_focus(button)
	_picker.add_child(button)
	_hero_buttons[key] = button


func _hero_name(hero: StringName) -> String:
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	return String(hero) if def == null else Ui.text(def.name_key)


func _clear_detail() -> void:
	_selected = &""
	_title.text = ""
	_desc.text = ""
	_effect.text = ""
	_drop(_hero_buttons)
