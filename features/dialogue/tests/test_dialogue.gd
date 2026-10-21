extends TestCase
## Dialogue: T8 (every line has a known speaker, one of 4 expressions, a translating text key), DialogueRun
## stepping, the object-list reader, the stand-in portraits, and DialogueBox playing to the end once.

var _finished_ids: Array[StringName] = []


func _first_dialogue() -> DialogueDef:
	return ContentDB.get_def("dialogue", &"workshop_first") as DialogueDef


func test_t8_every_line_is_valid() -> void:
	check(ContentDB.ids("dialogue").size() > 0, "a dialogue exists")
	for dialogue_id: StringName in ContentDB.ids("dialogue"):
		var def := ContentDB.get_def("dialogue", dialogue_id) as DialogueDef
		check(def.lines.size() > 0, "%s has lines" % dialogue_id)
		for line: DialogueLine in def.lines:
			var speaker := ContentDB.get_def("speaker", line.speaker) as SpeakerDef
			check(speaker != null, "%s: known speaker %s" % [dialogue_id, line.speaker])
			check(DialogueLine.EXPRESSIONS.has(line.expression), "%s: expression %s" % [dialogue_id, line.expression])
			check(tr(line.text_key) != line.text_key, "%s: key %s translates" % [dialogue_id, line.text_key])
			if speaker != null:
				check(tr(speaker.name_key) != speaker.name_key, "name %s translates" % speaker.name_key)
				check(Portraits.texture(line.speaker, line.expression) != null, "portrait for %s" % line.speaker)


func test_workshop_dialogue_shape() -> void:
	var def: DialogueDef = _first_dialogue()
	check_eq(def.lines.size(), 4, "four lines")
	var seen: Dictionary[StringName, bool] = {}
	for line: DialogueLine in def.lines:
		seen[line.expression] = true
	check(seen.size() >= 3, "uses several expressions")


func test_run_steps_and_finishes() -> void:
	var run := DialogueRun.new(_first_dialogue())
	check_eq(run.line_count(), 4, "count")
	check_eq(run.index(), 0, "starts at 0")
	check_eq(run.current().speaker, &"bilqis", "first speaker")
	for step: int in 3:
		check(run.advance(), "advance %d has a next line" % step)
	check(not run.is_finished(), "still on the last line")
	check(not run.advance(), "advancing past the last line reports finished")
	check(run.is_finished() and run.current() == null, "finished has no current line")
	check(not run.advance() and run.index() == 4, "advance after the end does nothing")


func test_run_on_empty_dialogue_is_finished() -> void:
	var run := DialogueRun.new(DialogueDef.new())
	check(run.is_finished() and run.current() == null, "empty is finished")


func test_reader_objects_and_one_of_report_problems() -> void:
	var errors := PackedStringArray()
	var def := DialogueDef.new()
	var data: Dictionary = {"id": "bad", "lines": [{"speaker": "zayd", "expression": "sleepy", "text": "K"}, 5]}
	def.read(DefReader.new(data, "t", errors))
	var text: String = "\n".join(errors)
	check(text.contains("t.lines[0].expression"), "bad expression names the line: " + text)
	check(text.contains("lines[1]: not an object"), "non-object element reported")
	var missing := PackedStringArray()
	DialogueDef.new().read(DefReader.new({"id": "x"}, "t", missing))
	check(missing.size() == 1 and missing[0].contains("lines: missing"), "missing list reported")


func test_standins_exist_and_differ_per_expression() -> void:
	for speaker: StringName in ContentDB.ids("speaker"):
		var images: Array[Image] = []
		for expression: StringName in DialogueLine.EXPRESSIONS:
			var image: Image = Portraits.standin_image(speaker, expression)
			check(image != null, "stand-in %s_%s" % [speaker, expression])
			images.append(image)
		for a: int in images.size():
			for b: int in range(a + 1, images.size()):
				check(images[a].get_data() != images[b].get_data(), "%s: expressions %d and %d differ" % [speaker, a, b])


func test_real_portraits_load_and_standins_remain() -> void:
	for speaker: StringName in [&"zayd", &"bilqis"]:
		for expression: StringName in [&"neutral", &"happy", &"angry", &"surprised"]:
			check(Portraits.has_real(speaker, expression), "owner portrait %s_%s is shipped" % [speaker, expression])
	var texture: Texture2D = Portraits.texture(&"zayd", &"happy")
	check(texture != null and texture.get_height() > 0, "real portrait texture")
	check(Portraits.standin_image(&"zayd", &"happy") != null, "the stand-in still builds for speakers without art")
	check(Portraits.texture(&"nobody", &"happy") == null, "unknown speaker gives null")


func _on_finished(dialogue_id: StringName) -> void:
	_finished_ids.append(dialogue_id)


func test_box_plays_to_the_end_and_finishes_once() -> void:
	var box := DialogueBox.new()
	tree.root.add_child(box)
	box.finished.connect(_on_finished)
	check(not box.is_playing() and not box.visible, "idle and hidden at first")
	box.play(&"workshop_first")
	check(box.is_playing() and box.visible, "playing and visible")
	box.advance()
	check(box.is_playing(), "first advance only completes the typing")
	var presses: int = 1
	while box.is_playing() and presses < 30:
		box.advance()
		presses += 1
	check_eq(presses, 8, "4 lines need 2 presses each (complete, next)")
	check_eq(_finished_ids, [&"workshop_first"] as Array[StringName], "finished emitted once with the id")
	check(not box.is_playing() and not box.visible, "hidden after the end")
	box.advance()
	check_eq(_finished_ids.size(), 1, "advance when idle does nothing")
	box.free()


func test_box_with_unknown_dialogue_does_not_play() -> void:
	var box := DialogueBox.new()
	tree.root.add_child(box)
	box.play(&"no_such_dialogue")
	check(not box.is_playing(), "unknown id is ignored")
	box.free()
