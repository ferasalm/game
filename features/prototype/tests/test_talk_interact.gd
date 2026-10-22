extends TestCase
## Interaction test: walking up to herb_seller and confirming plays abu_nabil_first on the first visit,
## and abu_nabil_chat_1 on the next visit; sabil plays party_sabil_first before opening screen.

const DT: float = 1.0 / 60.0


func _make() -> PrototypeMain:
	GameState.reset()
	var main := (load("res://features/prototype/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	main.stage_created.connect(func(stage: BattleStage) -> void:
		stage.auto_play = true
		stage.instant = true)
	tree.root.add_child(main)
	return main


func _visit_herb_seller(main: PrototypeMain) -> void:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	var spot: TalkSpot = null
	for s: TalkSpot in main.rooftop.talk_spots:
		if s.place_id == &"herb_seller":
			spot = s
			break
	if spot != null:
		main.rooftop.player.position = spot.position + Vector3(0.5, 0.0, 0.0)
		spot._physics_process(DT)
		spot._unhandled_input(press)


func _talk_through(main: PrototypeMain) -> int:
	var presses: int = 0
	while main.dialogue.is_playing() and presses < 50:
		main.dialogue.advance()
		presses += 1
	return presses


func test_confirm_on_herb_seller_plays_first_then_chat() -> void:
	var main: PrototypeMain = _make()
	var played: Array[StringName] = []
	main.dialogue.finished.connect(func(id: StringName) -> void: played.append(id))

	_visit_herb_seller(main)
	check(main.dialogue.is_playing(), "dialogue is playing on first visit")
	check_eq(main.dialogue.dialogue_id(), &"abu_nabil_first", "first visit plays abu_nabil_first")
	_talk_through(main)
	check(not main.dialogue.is_playing(), "dialogue finished")
	check_eq(played, [&"abu_nabil_first"] as Array[StringName], "first finished recorded")
	check(bool(GameState.flags.get(TalkPicker.flag_first(&"herb_seller"), false)), "first talk flag set")

	_visit_herb_seller(main)
	check(main.dialogue.is_playing(), "dialogue is playing on second visit")
	check_eq(main.dialogue.dialogue_id(), &"abu_nabil_chat_1", "second visit plays first chat")
	_talk_through(main)
	check(not main.dialogue.is_playing(), "second dialogue finished")
	check_eq(played.size(), 2, "two dialogues played")

	main.free()
	GameState.reset()


func test_sabil_plays_party_dialogue_before_first_drink() -> void:
	var main: PrototypeMain = _make()
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	main.rooftop.player.position = main.rooftop.sabil.position + Vector3(0.5, 0.0, 0.0)
	main.rooftop.sabil._physics_process(DT)
	main.rooftop.sabil._unhandled_input(press)
	check(main.dialogue.is_playing(), "party_sabil_first plays before sabil screen")
	check_eq(main.dialogue.dialogue_id(), &"party_sabil_first", "dialogue is party_sabil_first")
	_talk_through(main)
	check(bool(GameState.flags.get(&"party_sabil_first_done", false)), "party_sabil_first_done set")
	check(Screens.is_open(), "sabil screen opened after dialogue")
	Screens.clear()
	main.free()
	GameState.reset()


func test_first_victory_plays_party_dialogue() -> void:
	var main: PrototypeMain = _make()
	main.rooftop.patrol.position = main.rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	main.rooftop.patrol._physics_process(DT)
	check(main.stage != null, "stage started")
	main.stage.ended.emit(&"victory")
	check(main.dialogue.is_playing(), "dialogue is playing after first victory")
	check_eq(main.dialogue.dialogue_id(), &"party_after_first_win", "dialogue is party_after_first_win")
	_talk_through(main)
	check(not main.dialogue.is_playing(), "party dialogue finished")
	check(bool(GameState.flags.get(&"party_after_first_win_done", false)), "first win flag set")
	check(main.rooftop.player.visible, "exploring resumed after dialogue")
	main.free()
	GameState.reset()
