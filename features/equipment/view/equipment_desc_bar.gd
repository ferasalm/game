class_name EquipmentDescBar
extends PanelContainer
## purpose: Description bar (1760x90 at 80,900) showing item name, rarity, description and combat effect.

var _title: Label
var _body: Label
var _effect: Label


func _init() -> void:
	position = Vector2(80.0, 900.0)
	custom_minimum_size = Vector2(1760.0, 90.0)
	size = Vector2(1760.0, 90.0)
	add_theme_stylebox_override("panel", UiBoxes.panel(Ui.style(), &"panel"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_ui()


func set_item(item: EquipDef) -> void:
	if item == null:
		_title.text = ""
		_body.text = ""
		_effect.text = ""
		return
	_title.text = Ui.text(item.name_key)
	_title.add_theme_color_override("font_color", UiRarity.colour(item.rarity))
	_body.text = Ui.text(item.desc_key)
	var effect_text: String = ""
	if item is HiltDef and (item as HiltDef).ability != &"":
		var action := ContentDB.get_def("action", (item as HiltDef).ability) as ActionDef
		effect_text = Ui.text(action.name_key) if action != null else String((item as HiltDef).ability)
	elif item.perk != &"":
		var p_def := ContentDB.get_def("perk", item.perk) as PerkDef
		if p_def != null:
			effect_text = Ui.text(p_def.name_key)
	_effect.text = effect_text


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	add_child(hbox)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size.x = 350.0
	hbox.add_child(left_col)
	_title = Ui.label("", &"NameLabel")
	left_col.add_child(_title)

	var mid_col := VBoxContainer.new()
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(mid_col)
	_body = Ui.label("", &"MutedLabel")
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid_col.add_child(_body)

	_effect = Ui.label("", &"SmallLabel", Ui.style().colour(&"c_good"))
	hbox.add_child(_effect)
