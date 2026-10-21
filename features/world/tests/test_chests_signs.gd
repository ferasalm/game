extends TestCase
## Chests (prompt, one-time opening, the lid animation, the Rooftop signal) and the neon signs (localization keys,
## Arabic text from the CSV, text fitted to the board).

const DT: float = 1.0 / 60.0


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	tree.root.add_child(rooftop)
	return rooftop


func _press() -> InputEventAction:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	return press


func test_two_named_chests_exist() -> void:
	var rooftop: Rooftop = _make()
	check(rooftop.dressing.chest(&"chest_saila") != null, "chest_saila is on the roof")
	check(rooftop.dressing.chest(&"chest_mafraj") != null, "chest_mafraj is on the roof")
	check_eq(rooftop.dressing.chests.size(), 2, "exactly two chests")
	rooftop.free()


func test_chest_prompt_open_signal_and_lid() -> void:
	var rooftop: Rooftop = _make()
	var opened: Array[StringName] = []
	rooftop.chest_opened.connect(func(id: StringName) -> void: opened.append(id))
	var chest: Chest = rooftop.dressing.chest(&"chest_mafraj")
	chest._physics_process(DT)
	check(not chest.prompt.visible, "no prompt far from the chest")
	chest._unhandled_input(_press())
	check(opened.is_empty(), "interact does nothing far away")
	rooftop.player.position = chest.position + Vector3(0.6, 0.0, 0.0)
	chest._physics_process(DT)
	check(chest.prompt.visible, "the prompt shows near the chest")
	check_eq(chest.prompt.text, "E: open chest", "the prompt comes from a localization key")
	chest._unhandled_input(_press())
	check_eq(opened, [&"chest_mafraj"] as Array[StringName], "the Rooftop relays chest_opened with the chest's id")
	check(chest.is_open, "the chest is open")
	for i: int in 70:
		chest._process(DT)
	check(chest.lid_progress() >= 1.0, "the lid finished opening")
	check(chest.hinge.rotation.x < -1.0, "the lid swung up (%f)" % chest.hinge.rotation.x)
	chest._physics_process(DT)
	check(not chest.prompt.visible, "an open chest offers nothing")
	chest._unhandled_input(_press())
	check_eq(opened.size(), 1, "a chest opens once")
	rooftop.free()


func test_chests_obey_set_exploring() -> void:
	var rooftop: Rooftop = _make()
	var opened: Array[StringName] = []
	rooftop.chest_opened.connect(func(id: StringName) -> void: opened.append(id))
	var chest: Chest = rooftop.dressing.chest(&"chest_saila")
	rooftop.player.position = chest.position + Vector3(0.6, 0.0, 0.0)
	rooftop.set_exploring(false)
	chest._unhandled_input(_press())
	check(opened.is_empty(), "a chest ignores interact while a battle or menu runs")
	rooftop.set_exploring(true)
	chest._unhandled_input(_press())
	check_eq(opened.size(), 1, "and works again afterwards")
	rooftop.free()


func test_ease_out_runs_from_zero_to_one() -> void:
	check(is_equal_approx(Chest.ease_out(0.0), 0.0) and is_equal_approx(Chest.ease_out(1.0), 1.0), "ends at 0 and 1")
	check(Chest.ease_out(0.5) > 0.5, "fast start, slow end")


func test_signs_use_localization_and_arabic() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var wanted: Array[String] = ["Souq al-Milh", "Zubairi St.", "Sabil", "Haddah", "Qishr"]
	check_eq(area.signs.size(), wanted.size(), "five neon signs")
	for i: int in area.signs.size():
		var text: String = TranslationServer.translate(area.signs[i].key)
		check(text != area.signs[i].key, "sign key %s has text" % area.signs[i].key)
		check(text.contains(wanted[i]), "sign %d says %s" % [i, wanted[i]])
		check(_has_arabic(text), "sign %d has Arabic letters" % i)


func _has_arabic(text: String) -> bool:
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		if code >= 0x0600 and code <= 0x06FF:
			return true
	return false


func test_sign_text_is_fitted_to_its_board() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	for spec: SignSpec in area.signs:
		var node := NeonSign.new(spec, palette)
		tree.root.add_child(node)
		var width: float = NeonSign.FONT.get_string_size(node.label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, NeonSign.FONT_PX).x
		check(width * node.label.pixel_size <= spec.board.x * NeonSign.FIT + 0.01, "%s fits its board" % spec.key)
		check(node.label.shaded == false and node.label.modulate.r + node.label.modulate.g + node.label.modulate.b > 1.0,
			"%s is unshaded and bright enough to bloom" % spec.key)
		node.free()


func test_a_flickering_sign_dips() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var spec: SignSpec = area.signs[0]
	check(spec.flicker > 0.0, "the Souq sign flickers")
	var node := NeonSign.new(spec, palette)
	tree.root.add_child(node)
	var low: float = 99.0
	var high: float = 0.0
	for i: int in 400:
		node._process(0.05)
		low = minf(low, node.label.modulate.g)
		high = maxf(high, node.label.modulate.g)
	check(high - low > 0.1, "brightness varies over time (%f..%f)" % [low, high])
	node.free()
