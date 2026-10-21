class_name PauseParty
extends VBoxContainer
## The right half of the pause screen: a card per hero (name, HP and SP bars with numbers, KO tag), the worn gear of
## each hero, and under a frieze the area name, play time and riyal. Vitals, money and play time are read defensively
## from GameState (they arrive with the v4 save); a missing record means full HP/SP, zero money and zero time.

var _equipment: EquipmentData = EquipmentData.new()


func fill() -> void:
	var style: UiStyleDef = Ui.style()
	add_theme_constant_override("separation", style.size(&"s_gap"))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(cards)
	for hero: StringName in heroes():
		cards.add_child(_card(hero))
	add_child(Ui.divider())
	for hero: StringName in heroes():
		add_child(Ui.label(_gear_line(hero), &"MutedLabel"))
	add_child(Ui.divider())
	add_child(_footer())


## The party: GameState.party, or the heroes of the start loadouts when none is set yet.
func heroes() -> Array[StringName]:
	return GameState.party if not GameState.party.is_empty() else _equipment.heroes


func _card(hero: StringName) -> Control:
	var style: UiStyleDef = Ui.style()
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"InsetPanel"
	panel.custom_minimum_size = Vector2(style.size(&"s_card_w"), style.size(&"s_card_h"))
	var box := VBoxContainer.new()
	panel.add_child(box)
	if def == null:
		box.add_child(Ui.label(String(hero), &"NameLabel"))
		return panel
	var now: Vector2i = PauseLogic.vitals_of(GameState.get(&"vitals"), hero, def.max_hp, def.max_sp)
	var head := HBoxContainer.new()
	var name_label: Label = Ui.label(Ui.text(def.name_key), &"NameLabel")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	if now.x <= 0:
		head.add_child(Ui.label(Ui.text("PAUSE_KO"), &"NumberLabel", style.colour(&"c_bad")))
	box.add_child(head)
	box.add_child(_stat("UI_HP", &"HpBar", now.x, def.max_hp))
	box.add_child(_stat("UI_SP", &"SpBar", now.y, def.max_sp))
	return panel


func _stat(tag_key: String, kind: StringName, value: int, maximum: int) -> Control:
	var line := HBoxContainer.new()
	var tag: Label = Ui.label(Ui.text(tag_key), &"CaptionLabel")
	tag.custom_minimum_size.x = Ui.style().size(&"s_icon")
	line.add_child(tag)
	var bar := ProgressBar.new()
	bar.theme_type_variation = kind
	bar.show_percentage = false
	bar.max_value = maximum
	bar.value = value
	bar.custom_minimum_size.y = Ui.style().size(&"s_bar_h")
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	line.add_child(Ui.label("%d/%d" % [value, maximum], &"NumberLabel"))
	return line


## "Zayd: Anvil hilt, Curved blade, Arc arm" from what GameState.equipment holds (a missing slot = the start kit).
func _gear_line(hero: StringName) -> String:
	var def := ContentDB.get_def("combatant", hero) as CombatantDef
	var names := PackedStringArray()
	for slot: StringName in GameState.equipment:
		if String(slot).begins_with(String(hero) + "."):
			var item: EquipDef = _equipment.items.get(GameState.equipment[slot])
			names.append(Ui.text(item.name_key) if item != null else String(GameState.equipment[slot]))
	return "%s: %s" % [Ui.text(def.name_key) if def != null else String(hero), ", ".join(names)]


func _footer() -> Control:
	var style: UiStyleDef = Ui.style()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_margin"))
	var area := ContentDB.get_def("area", GameState.area_id) as AreaDef
	var place: String = Ui.text(area.name_key) if area != null else ""
	row.add_child(Ui.label("%s: %s" % [Ui.text("PAUSE_AREA"), place], &"SmallLabel"))
	row.add_child(Ui.label("%s %s" % [Ui.text("PAUSE_TIME"), PauseLogic.clock(GameState.get(&"play_seconds"))],
			&"SmallLabel"))
	var money: Label = Ui.label(Ui.text("PAUSE_MONEY") % str(PauseLogic.money_of(GameState.get(&"money"))),
			&"NumberLabel", style.colour(&"c_brass"))
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(money)
	return row
