extends TestCase
## Dialogue choices test: DialogueChoice def parsing, DialogueRun choice exposure and advance blocking,
## DialogueEffects execution, and DialogueBox button selection.


func _run_with_choices() -> DialogueRun:
	var def := DialogueDef.new()
	def.id = &"test_choice_dlg"
	var line1 := DialogueLine.new()
	line1.speaker = &"rydan"
	line1.text_key = "LINE_1"
	var line2 := DialogueLine.new()
	line2.speaker = &"abu_nabil"
	line2.text_key = "LINE_2"
	var c1 := DialogueChoice.new()
	c1.text_key = "CHOICE_A"
	c1.next = &"dlg_a"
	c1.effects = ["set_flag choice_a_picked"]
	var c2 := DialogueChoice.new()
	c2.text_key = "CHOICE_B"
	c2.next = &"end"
	line2.choices = [c1, c2]
	def.lines = [line1, line2]
	return DialogueRun.new(def)


func test_choice_def_and_line_parsing() -> void:
	var raw: Dictionary = {
		"text": "CHOICE_KEY",
		"next": "next_dlg",
		"effects": ["set_flag test_flag", "give_item pink_herb 2"]
	}
	var choice := DialogueChoice.new()
	choice.read(DefReader.new(raw, "test", PackedStringArray()))
	check_eq(choice.text_key, "CHOICE_KEY", "choice text key")
	check_eq(choice.next, &"next_dlg", "choice next id")
	check_eq(choice.effects.size(), 2, "choice effects count")


func test_dialogue_run_exposes_choices_and_blocks_advance() -> void:
	var run: DialogueRun = _run_with_choices()
	check(not run.has_choices(), "line 1 has no choices")
	check(run.choices().is_empty(), "choices empty on line 1")
	check(run.advance(), "advances to line 2")
	check(run.has_choices(), "line 2 has choices")
	check_eq(run.choices().size(), 2, "two choices exposed")
	check(not run.advance(), "advance blocked while choices pending")
	var chosen: DialogueChoice = run.choose(0)
	check_eq(chosen.text_key, "CHOICE_A", "chose choice A")
	check_eq(run.chosen(), chosen, "run records chosen choice")


func test_effects_set_flag_and_give_item() -> void:
	GameState.start_new()
	GameState.flags.clear()
	GameState.bag.clear()
	DialogueEffects.apply("set_flag flag_alpha")
	check(bool(GameState.flags.get(&"flag_alpha", false)), "set_flag executed")
	DialogueEffects.apply("give_item pink_herb 3")
	check_eq(GameState.bag.get(&"pink_herb", 0), 3, "give_item consumable fills bag")
	DialogueEffects.apply("give_item qishr_cup 1")
	check_eq(GameState.bag.get(&"qishr_cup", 0), 1, "give_item consumable fills bag")
	DialogueEffects.apply("give_item anvil_hilt 1")
	check(GameState.inventory.has(&"anvil_hilt"), "give_item unique gear fills inventory")


func test_effects_build_battle_request() -> void:
	GameState.start_new()
	var parts: PackedStringArray = PackedStringArray(["start_battle", "abu_nabil_duel", "party_first"])
	var request: BattleRequest = DialogueEffects.build_battle_request(parts)
	check(request != null, "battle request built")
	if request != null:
		check_eq(request.encounter_id, &"abu_nabil_duel", "encounter id")
		check_eq(request.opening, &"party_first", "party_first opening")
		check_eq(request.ambush, 2, "party_first maps to ambush 2")
		check(not request.practice, "practice false by default")


func test_effects_build_battle_request_spar() -> void:
	GameState.start_new()
	var parts: PackedStringArray = PackedStringArray(["start_battle", "abu_nabil_duel", "even", "practice"])
	var request: BattleRequest = DialogueEffects.build_battle_request(parts)
	check(request != null, "spar battle request built")
	if request != null:
		check_eq(request.encounter_id, &"abu_nabil_duel", "spar encounter id")
		check_eq(request.opening, &"even", "even opening")
		check_eq(request.ambush, 0, "even maps to ambush 0")
		check(request.practice, "practice true for spar")


func test_dialogue_box_shows_choice_buttons_and_picks() -> void:
	var box := DialogueBox.new()
	tree.root.add_child(box)
	box.play(&"abu_nabil_menu")
	# abu_nabil_menu has 1 line with 4 choices
	box.advance() # Finish typing
	check(box.is_showing_choices(), "choice buttons displayed")
	check_eq(box.choice_buttons().size(), 4, "four menu options: Shop, Spar, Chat, Leave")
	box.choose(3) # Leave -> next: end
	check(not box.is_playing(), "choosing Leave finishes conversation")
	box.free()
