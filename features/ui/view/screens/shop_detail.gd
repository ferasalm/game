class_name ShopDetail
extends PanelContainer
## Shop detail panel at (840,140) 560x760: icon 160, name, desc, effect, and per-hero comparison.

var _icon: TextureRect
var _name: Label
var _desc: Label
var _effect: Label
var _compare_box: VBoxContainer


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(560, 760)
	size = Vector2(560, 760)
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(box)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(160, 160)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"inset"))
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(160, 160)
	icon_box.add_child(_icon)
	box.add_child(icon_box)

	_name = Ui.label("", &"TitleLabel")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_name)

	_desc = Ui.label("", &"MutedLabel")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc)

	_effect = Ui.label("", &"SmallLabel", style.colour(&"c_good"))
	_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_effect)

	box.add_child(Ui.divider())

	var cmp_title := Ui.label(Ui.text("SHOP_COMPARISON"), &"TitleLabel", style.colour(&"c_brass"))
	box.add_child(cmp_title)

	_compare_box = VBoxContainer.new()
	_compare_box.add_theme_constant_override("separation", style.size(&"s_gap"))
	box.add_child(_compare_box)


## Backward-compatible stub (money is handled in summary panel).
func show_money(_amount: int) -> void:
	pass


## Updates the detail panel for the chosen item.
func show_item(def: ConsumableDef, _price: int, _qty: int, _money: int, _owned: int, _selling: bool) -> void:
	if def == null:
		_name.text = ""
		_desc.text = ""
		_effect.text = ""
		_clear_comparisons()
		return

	var rarity_col: Color = UiRarity.colour(def.rarity if "rarity" in def else &"")
	_name.text = Ui.text(def.name_key)
	_name.add_theme_color_override("font_color", rarity_col)
	_desc.text = Ui.text(def.desc_key)
	_effect.text = ItemsText.effect(def)
	ItemIcons.apply(_icon, def, 160)
	_build_comparisons(def)


func icon_rect() -> TextureRect:
	return _icon


func _clear_comparisons() -> void:
	for child: Node in _compare_box.get_children():
		child.queue_free()


func _build_comparisons(def: ConsumableDef) -> void:
	_clear_comparisons()
	var party: Array = GameState.party if not GameState.party.is_empty() else [&"zayd", &"bilqis"]
	var vitals: Dictionary = GameState.get(&"vitals") if GameState.get(&"vitals") is Dictionary else {}
	var maxes: Dictionary = _hero_maxes(party)

	for hero_v: Variant in party:
		var hero: StringName = StringName(hero_v)
		var cdef := ContentDB.get_def("combatant", hero) as CombatantDef
		var hero_name: String = Ui.text(cdef.name_key) if cdef != null else String(hero)
		var top: Vector2i = maxes.get(hero, Vector2i(100, 50))
		var cur_hp: int = Vitals.hp_of(vitals, hero, top.x)
		var cur_sp: int = Vitals.sp_of(vitals, hero, top.y)

		var gain: Dictionary = FieldUse.preview(def, vitals, hero, maxes)
		var hp_gain: int = int(gain.get("hp", 0))
		var sp_gain: int = int(gain.get("sp", 0))

		var row := HBoxContainer.new()
		row.add_child(Ui.label(hero_name, &"NameLabel"))
		var stats_str: String = ""
		if hp_gain > 0:
			stats_str += "  " + ItemsText.comparison("HP", cur_hp, clampi(cur_hp + hp_gain, 0, top.x), hp_gain)
		if sp_gain > 0:
			stats_str += "  " + ItemsText.comparison("SP", cur_sp, clampi(cur_sp + sp_gain, 0, top.y), sp_gain)
		if stats_str.is_empty():
			stats_str = "  --"
		var lbl: Label = Ui.label(stats_str, &"SmallLabel", Ui.style().colour(&"c_good" if hp_gain > 0 or sp_gain > 0 else &"c_muted"))
		row.add_child(lbl)
		_compare_box.add_child(row)


func _hero_maxes(party: Array) -> Dictionary:
	var out: Dictionary = {}
	for hero_v: Variant in party:
		var hero: StringName = StringName(hero_v)
		var cdef := ContentDB.get_def("combatant", hero) as CombatantDef
		out[hero] = Vector2i(cdef.max_hp, cdef.max_sp) if cdef != null else Vector2i(100, 50)
	return out
