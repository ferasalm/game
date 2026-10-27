class_name ShopPartyMini
extends PanelContainer
## Party mini cards panel at (1440,600) 400x300: compact HP and SP bars for each hero with painted portraits.

var _box: VBoxContainer


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(400, 300)
	size = Vector2(400, 300)
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", style.size(&"s_pad"))
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	refresh()


func refresh() -> void:
	for child: Node in _box.get_children():
		child.queue_free()

	var party: Array = GameState.party if not GameState.party.is_empty() else [&"rydan", &"bilqis"]
	var vitals: Dictionary = GameState.get(&"vitals") if GameState.get(&"vitals") is Dictionary else {}

	for hero_v: Variant in party:
		var hero: StringName = StringName(hero_v)
		var cdef := ContentDB.get_def("combatant", hero) as CombatantDef
		var max_hp: int = cdef.max_hp if cdef != null else 100
		var max_sp: int = cdef.max_sp if cdef != null else 50
		var hp: int = Vitals.hp_of(vitals, hero, max_hp)
		var sp: int = Vitals.sp_of(vitals, hero, max_sp)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiBoxes.panel(Ui.style(), &"inset"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", Ui.style().size(&"s_pad"))
		card.add_child(row)

		var face: Control = PortraitFaces.face(hero, Ui.style().colour(&"c_party"))
		face.custom_minimum_size = Vector2(56, 56)
		row.add_child(face)

		var stats_col := VBoxContainer.new()
		stats_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(stats_col)

		stats_col.add_child(_mini_bar("UI_HP", &"HpBar", hp, max_hp))
		stats_col.add_child(_mini_bar("UI_SP", &"SpBar", sp, max_sp))

		_box.add_child(card)


func _mini_bar(tag_key: String, bar_kind: StringName, current: int, maximum: int) -> Control:
	var line := HBoxContainer.new()
	line.add_child(Ui.label(Ui.text(tag_key), &"CaptionLabel"))
	var bar := ProgressBar.new()
	bar.theme_type_variation = bar_kind
	bar.show_percentage = false
	bar.max_value = maximum
	bar.value = current
	bar.custom_minimum_size = Vector2(180, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	line.add_child(Ui.label("%d/%d" % [current, maximum], &"NumberLabel"))
	return line
