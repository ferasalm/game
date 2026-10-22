extends TestCase
## Tests for music contexts: pure stack resolution across all branches, missing file fallback resolution,
## validation of screen_music definitions, pause process mode, and track resume positions.


func test_stack_empty_and_mapped_push_pop() -> void:
	var mappings: Dictionary[StringName, StringName] = {
		&"pause": &"menu_bag",
		&"items": &"menu_bag",
		&"shop": &"merchant_stall",
	}
	var stack := MusicStack.new(mappings, &"explore_souq")
	check_eq(stack.current_track(), &"explore_souq", "empty stack returns base track")

	stack.push(&"pause")
	check_eq(stack.current_track(), &"menu_bag", "mapped screen wins")
	check_eq(stack.depth(), 1, "depth is 1")
	check_eq(stack.top(), &"pause", "top is pause")

	stack.push(&"shop")
	check_eq(stack.current_track(), &"merchant_stall", "higher mapped screen wins")

	stack.pop(&"shop")
	check_eq(stack.current_track(), &"menu_bag", "popping restores lower screen")

	stack.pop(&"pause")
	check_eq(stack.current_track(), &"explore_souq", "empty returns to base")


func test_stack_unmapped_screens_and_defeat_keep_what_plays() -> void:
	var mappings: Dictionary[StringName, StringName] = {
		&"pause": &"menu_bag",
	}
	var stack := MusicStack.new(mappings, &"battle")

	stack.push(&"defeat")
	check_eq(stack.current_track(), &"battle", "unmapped defeat screen keeps battle track")

	stack.pop()
	check_eq(stack.current_track(), &"battle", "popping defeat leaves battle track")

	stack.push(&"pause")
	check_eq(stack.current_track(), &"menu_bag", "pause plays menu_bag")

	stack.push(&"confirm")
	check_eq(stack.current_track(), &"menu_bag", "unmapped confirm over pause keeps menu_bag")

	stack.push(&"dialog")
	check_eq(stack.current_track(), &"menu_bag", "second unmapped screen keeps menu_bag")

	stack.pop()
	check_eq(stack.current_track(), &"menu_bag", "popping first unmapped keeps menu_bag")

	stack.pop()
	check_eq(stack.current_track(), &"menu_bag", "back to pause keeps menu_bag")

	stack.pop()
	check_eq(stack.current_track(), &"battle", "popping pause returns to base")


func test_stack_base_track_changes_and_out_of_order_pop() -> void:
	var mappings: Dictionary[StringName, StringName] = {
		&"pause": &"menu_bag",
		&"shop": &"merchant_stall",
	}
	var stack := MusicStack.new(mappings, &"explore_souq")
	stack.push(&"pause")
	stack.push(&"shop")
	stack.set_base_track(&"battle")
	check_eq(stack.current_track(), &"merchant_stall", "stack top overrides new base track")

	stack.pop(&"pause")
	check_eq(stack.current_track(), &"merchant_stall", "removing buried pause keeps shop")

	stack.pop(&"shop")
	check_eq(stack.current_track(), &"battle", "popping last returns to updated base track")

	stack.push(&"unmapped")
	stack.push(&"shop")
	check_eq(stack.current_track(), &"merchant_stall", "shop on top of unmapped wins")
	stack.clear()
	check_eq(stack.current_track(), &"battle", "clear returns to base track")


func test_fallback_resolution_chains_and_missing() -> void:
	var def_present := MusicDef.new()
	def_present.id = &"present"
	def_present.path = "res://present.ogg"

	var def_fallback := MusicDef.new()
	def_fallback.id = &"fallback"
	def_fallback.path = "res://fallback.ogg"

	var def_missing := MusicDef.new()
	def_missing.id = &"missing"
	def_missing.path = "res://missing.ogg"
	def_missing.fallback = &"fallback"

	var def_missing_nofallback := MusicDef.new()
	def_missing_nofallback.id = &"victory"
	def_missing_nofallback.path = "res://victory.ogg"

	var def_cycle_a := MusicDef.new()
	def_cycle_a.id = &"cycle_a"
	def_cycle_a.path = "res://cycle_a.ogg"
	def_cycle_a.fallback = &"cycle_b"

	var def_cycle_b := MusicDef.new()
	def_cycle_b.id = &"cycle_b"
	def_cycle_b.path = "res://cycle_b.ogg"
	def_cycle_b.fallback = &"cycle_a"

	var defs: Dictionary = {
		&"present": def_present,
		&"fallback": def_fallback,
		&"missing": def_missing,
		&"victory": def_missing_nofallback,
		&"cycle_a": def_cycle_a,
		&"cycle_b": def_cycle_b,
	}

	var exists_true: Callable = func(_path: String) -> bool: return true
	var exists_fallback_only: Callable = func(path: String) -> bool: return path == "res://fallback.ogg"
	var exists_none: Callable = func(_path: String) -> bool: return false

	check_eq(MusicLogic.resolve_track(&"present", defs, exists_true), def_present, "present file plays")
	check_eq(MusicLogic.resolve_track(&"missing", defs, exists_fallback_only), def_fallback, "missing file resolves fallback")
	check_eq(MusicLogic.resolve_track(&"missing", defs, exists_none), null, "missing fallback returns null")
	check_eq(MusicLogic.resolve_track(&"victory", defs, exists_none), null, "missing with no fallback returns null")
	check_eq(MusicLogic.resolve_track(&"cycle_a", defs, exists_none), null, "cycle terminates safely with null")
	check_eq(MusicLogic.resolve_track(&"unknown_id", defs, exists_true), null, "unknown track returns null")


func test_every_screen_music_entry_names_real_screen_and_music() -> void:
	var screen_ids: Array[StringName] = ContentDB.ids("screen_music")
	check(screen_ids.size() >= 3, "sabil, workshop and title have their own music")
	for sid: StringName in screen_ids:
		var sm := ContentDB.get_def("screen_music", sid) as ScreenMusicDef
		check(sm != null, "entry exists: " + sid)
		check(Screens.has_screen(sm.id), "real screen id: " + sm.id)
		check(ContentDB.get_def("music", sm.music) != null, "real music id: " + sm.music)

	check_eq((ContentDB.get_def("screen_music", &"sabil") as ScreenMusicDef).music, &"sabil_serenity", "sabil -> sabil_serenity")
	check_eq((ContentDB.get_def("screen_music", &"workshop") as ScreenMusicDef).music, &"workshop_bench", "workshop -> workshop_bench")
	check_eq((ContentDB.get_def("screen_music", &"title") as ScreenMusicDef).music, &"title_theme", "title -> title_theme")
	check(ContentDB.get_def("screen_music", &"defeat") == null, "defeat screen is unmapped")


func test_pause_keeps_music_process_mode() -> void:
	var rules: AudioRulesDef = ContentDB.get_def("audio_rules", &"default") as AudioRulesDef
	var deck := MusicDeck.new()
	deck.silent = true
	deck.setup(rules)
	tree.root.add_child(deck)
	check_eq(deck.process_mode, Node.PROCESS_MODE_ALWAYS, "deck runs during pause")
	for child: Node in deck.get_children():
		if child is AudioStreamPlayer:
			check_eq(child.process_mode, Node.PROCESS_MODE_ALWAYS, "player runs during pause")
	check_eq(AudioDirector.process_mode, Node.PROCESS_MODE_ALWAYS, "AudioDirector runs during pause")
	deck.queue_free()


func test_resume_position_and_battle_starts_from_top() -> void:
	var rules: AudioRulesDef = ContentDB.get_def("audio_rules", &"default") as AudioRulesDef
	var deck := MusicDeck.new()
	deck.silent = true
	deck.setup(rules)
	tree.root.add_child(deck)

	deck.set_track_position(&"night_rooftops", 14.5)
	check_eq(deck.track_position(&"night_rooftops"), 14.5, "position recorded")

	var explore_def := ContentDB.get_def("music", &"night_rooftops") as MusicDef
	deck.play_def(explore_def)
	check_eq(deck.current, &"night_rooftops", "exploring track starts")

	deck.set_base(&"battle")
	check_eq(deck.track_position(&"battle"), 0.0, "battle track starts from top (0.0)")

	deck.queue_free()
