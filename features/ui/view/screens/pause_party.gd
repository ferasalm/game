class_name PauseParty
extends VBoxContainer
## The right half of the pause screen: a PartyCard per hero (portrait, name, HP and SP bars, KO tag), the worn gear of
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
	return Ui.party_card(hero)


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
	var money: MoneyCounter = Ui.money_counter()
	money.set_amount(PauseLogic.money_of(GameState.get(&"money")), false)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(money)
	return row
