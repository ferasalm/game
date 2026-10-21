extends TestCase
## The restyled battle HUD keeps its behaviour and gains: tags on the command buttons, gradient bars in the party
## panel, the brass timeline track, and rarity-coloured spoils on the victory panel (only items not owned yet).


func _stage() -> BattleStage:
	GameState.reset()
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7), Vector3.ZERO)
	return stage


func _labels(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for label: Node in NodeWalk.all(node):
		if label is Label:
			out.append((label as Label).text)
	return out


func test_move_buttons_carry_their_tags() -> void:
	var stage: BattleStage = _stage()
	stage.run_to_end(30000)
	var texts: PackedStringArray = PackedStringArray()
	for button: Button in stage.hud.menu.move_buttons():
		texts.append_array(_labels(button))
	check(texts.has("[%s]" % Ui.text("UI_CANCELS")), "a cancel move shows its [cancels] tag")
	var costs: int = 0
	for text: String in texts:
		costs += 1 if text.ends_with(" " + Ui.text("UI_SP")) else 0
	check(costs > 0, "a costly move shows its SP cost")
	stage.free()


func test_party_bars_use_the_gradient_variations() -> void:
	var stage: BattleStage = _stage()
	var kinds: Array[StringName] = []
	for bar: Node in NodeWalk.all(stage.hud.party_panel):
		if bar is ProgressBar:
			kinds.append((bar as ProgressBar).theme_type_variation)
	check_eq(kinds, [&"HpBar", &"SpBar", &"HpBar", &"SpBar"] as Array[StringName], "HP and SP bars per hero")
	check(stage.hud.timeline_bar.get_child(0) is BattleTrackArt, "the brass track is painted")
	stage.free()


func test_victory_panel_lists_new_loot_in_rarity_colours() -> void:
	var stage: BattleStage = _stage()
	stage.hud.end_panel.set_loot([&"anvil_hilt", &"swift_hilt"] as Array[StringName])
	Inventory.add(GameState.inventory, &"swift_hilt")
	stage.hud.show_end(&"victory")
	check_eq(stage.hud.end_panel.shown_loot(), [&"anvil_hilt"] as Array[StringName], "owned items are not listed")
	var found: bool = false
	for label: Node in NodeWalk.all(stage.hud.end_panel):
		if label is Label and (label as Label).text == Ui.text((ContentDB.get_def("item", &"anvil_hilt") as EquipDef).name_key):
			found = true
			check_eq((label as Label).get_theme_color("font_color"), UiRarity.colour(&"rare"), "Rare is blue")
	check(found, "the item name is on the panel")
	stage.hud.show_end(&"defeat")
	check(stage.hud.end_panel.shown_loot().is_empty(), "a defeat lists nothing")
	stage.free()
	GameState.reset()
