class_name WorkshopPreviewPanel
extends PanelContainer
## purpose: Stats preview panel (460x620 at 1380,140) comparing now vs after or recipe description.

var _vbox: VBoxContainer
var _content: Control


func _init() -> void:
	custom_minimum_size = Vector2(460.0, 620.0)
	size = Vector2(460.0, 620.0)
	position = Vector2(1380.0, 140.0)
	theme_type_variation = &"InsetPanel"
	_build_ui()


## Updates the comparison stats between current and proposed hero state.
func update_stats(now_def: CombatantDef, after_def: CombatantDef) -> void:
	_clear_content()
	if now_def == null or after_def == null:
		return
	var style: UiStyleDef = Ui.style()

	var cols_header := HBoxContainer.new()
	var empty_lbl := Ui.label("", &"CaptionLabel")
	empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols_header.add_child(empty_lbl)
	var now_lbl := Ui.label(Ui.text("WORKSHOP_NOW"), &"CaptionLabel", style.colour(&"c_muted"))
	now_lbl.custom_minimum_size.x = 60.0
	now_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cols_header.add_child(now_lbl)
	var arrow_space := Control.new()
	arrow_space.custom_minimum_size.x = 24.0
	cols_header.add_child(arrow_space)
	var after_lbl := Ui.label(Ui.text("WORKSHOP_AFTER"), &"CaptionLabel", style.colour(&"c_brass"))
	after_lbl.custom_minimum_size.x = 60.0
	after_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cols_header.add_child(after_lbl)
	_content.add_child(cols_header)

	var stat_keys: Array[Dictionary] = [
		{"name": "HP", "now": now_def.max_hp, "after": after_def.max_hp},
		{"name": "ATK", "now": now_def.attack, "after": after_def.attack},
		{"name": "DEF", "now": now_def.defense, "after": after_def.defense},
		{"name": "AGI", "now": now_def.agility, "after": after_def.agility},
		{"name": "WT", "now": roundi(now_def.weight), "after": roundi(after_def.weight), "invert": true},
	]

	for entry: Dictionary in stat_keys:
		_add_stat_row(entry["name"], entry["now"], entry["after"], bool(entry.get("invert", false)))


## Updates the panel with a crafting recipe's output description.
func update_recipe(recipe: RecipeDef) -> void:
	_clear_content()
	if recipe == null:
		return
	var style: UiStyleDef = Ui.style()
	var is_stone: bool = ContentDB.get_def("stone", recipe.output) != null
	var name_str: String = String(recipe.output)
	var desc_str: String = ""
	var rarity_id: StringName = &"common"

	if is_stone:
		var st := ContentDB.get_def("stone", recipe.output) as StoneDef
		if st != null:
			name_str = Ui.text(st.name_key)
			desc_str = Ui.text(st.desc_key)
			rarity_id = st.rarity
	else:
		var con := ContentDB.get_def("consumable", recipe.output) as ConsumableDef
		if con != null:
			name_str = Ui.text(con.name_key)
			desc_str = Ui.text(con.desc_key)

	var title_lbl := Ui.label(name_str, &"TitleLabel", UiRarity.colour(rarity_id))
	_content.add_child(title_lbl)
	_content.add_child(UiRarity.tag(rarity_id))
	_content.add_child(Ui.divider())
	var desc_lbl := Ui.label(desc_str, &"BodyLabel", style.colour(&"c_text"))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(desc_lbl)


func _build_ui() -> void:
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	var title := Ui.label(Ui.text("WORKSHOP_PREVIEW"), &"TitleLabel", Ui.style().colour(&"c_brass"))
	_vbox.add_child(title)
	_vbox.add_child(Ui.divider())

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	_vbox.add_child(_content)


func _clear_content() -> void:
	for child: Node in _content.get_children():
		child.queue_free()


func _add_stat_row(label_text: String, now_val: int, after_val: int, invert: bool) -> void:
	var style: UiStyleDef = Ui.style()
	var row := HBoxContainer.new()
	var name_lbl := Ui.label(label_text, &"NameLabel", style.colour(&"c_text"))
	name_lbl.custom_minimum_size.x = 80.0
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var now_lbl := Ui.label(str(now_val), &"NumberLabel", style.colour(&"c_muted"))
	now_lbl.custom_minimum_size.x = 60.0
	now_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(now_lbl)

	var arrow := Ui.label("→", &"NumberLabel", style.colour(&"c_muted"))
	arrow.custom_minimum_size.x = 24.0
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(arrow)

	var col: Color = style.colour(&"c_text")
	if after_val != now_val:
		var better: bool = (after_val < now_val) if invert else (after_val > now_val)
		col = style.colour(&"c_good" if better else &"c_bad")

	var after_lbl := Ui.label(str(after_val), &"NumberLabel", col)
	after_lbl.custom_minimum_size.x = 60.0
	after_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(after_lbl)

	_content.add_child(row)
