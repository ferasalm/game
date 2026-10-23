extends TestCase
## Dialogue v2 (Hades II style): nameplate with epithet, typed text, portrait slide on a speaker change, Cease,
## the layout sizes from the UI style, and stand-in portraits that no longer touch sprite pixels.


func _box() -> DialogueBox:
	var box := DialogueBox.new()
	tree.root.add_child(box)
	return box


func test_nameplate_shows_name_and_epithet() -> void:
	var box: DialogueBox = _box()
	box.play(&"workshop_first")
	check_eq(box._layout.name_label.text, "Bilqis", "speaker name")
	check_eq(box._layout.epithet_label.text, "Engineer behind the coffee stall", "epithet under the name")
	check_eq(box._layout.name_label.get_theme_color("font_color"), Ui.style().colour(&"c_brass"), "name in brass")
	box.free()


func test_every_speaker_has_an_epithet_that_translates() -> void:
	for id: StringName in ContentDB.ids("speaker"):
		var speaker := ContentDB.get_def("speaker", id) as SpeakerDef
		check(not speaker.epithet_key.is_empty() and Ui.text(speaker.epithet_key) != speaker.epithet_key, "epithet of " + id)


func test_text_is_typed_and_confirm_finishes_the_line() -> void:
	var box: DialogueBox = _box()
	box.play(&"workshop_first")
	check(box.is_typing(), "typing at first")
	check_eq(box._layout.text_label.visible_characters, 0, "nothing shown yet")
	box.advance()
	check(not box.is_typing() and box._layout.text_label.visible_characters == -1, "confirm shows the whole line")
	check(box.is_playing(), "and the conversation goes on")
	box.free()


func test_portrait_slides_in_only_when_the_speaker_changes() -> void:
	var box: DialogueBox = _box()
	box.play(&"workshop_first")
	var portrait: TextureRect = box._layout.portrait
	check_eq(portrait.offset_left, box._layout.portrait_rest_x - Ui.style().size(&"s_portrait_slide"), "starts off to the left")
	check_eq(portrait.modulate.a, 0.0, "and hidden")
	portrait.offset_left = box._layout.portrait_rest_x
	portrait.modulate.a = 1.0
	box.advance()
	box.advance()
	check_eq(portrait.offset_left, box._layout.portrait_rest_x, "same speaker: no new slide")
	box.advance()
	box.advance()
	check_eq(box._layout.name_label.text, "Zayd", "line 3 is Zayd")
	check_eq(portrait.modulate.a, 0.0, "a new speaker slides in again")
	box.free()


func test_cease_ends_the_conversation_at_once_once() -> void:
	var box: DialogueBox = _box()
	var done: Array[StringName] = []
	box.finished.connect(func(id: StringName) -> void: done.append(id))
	box.play(&"workshop_first")
	box.cease()
	check(not box.is_playing() and not box.visible, "ceased and hidden")
	box.cease()
	check_eq(done, [&"workshop_first"] as Array[StringName], "finished emitted once")
	box.free()


func test_layout_sizes_come_from_the_ui_style() -> void:
	var box: DialogueBox = _box()
	var style: UiStyleDef = Ui.style()
	var portrait: TextureRect = box._layout.portrait
	check_eq(portrait.offset_bottom - portrait.offset_top, float(style.size(&"s_portrait_h")), "portrait height")
	var frame: Control = box._layout.frame
	check_eq(frame.offset_right - frame.offset_left, float(style.size(&"s_dialog_w")), "box width")
	check_eq(frame.offset_bottom - frame.offset_top, float(style.size(&"s_dialog_h")), "box height")
	check_eq(box.layer, UiLayers.DIALOGUE, "dialogue layer")
	box.free()


func test_a_portrait_stands_on_the_bottom_edge() -> void:
	var box: DialogueBox = _box()
	box.play(&"workshop_first")
	var portrait: TextureRect = box._layout.portrait
	var texture: Texture2D = portrait.texture
	var width: float = portrait.offset_right - portrait.offset_left
	var height: float = portrait.offset_bottom - portrait.offset_top
	check_eq(portrait.offset_bottom, 0.0, "anchored on the screen's bottom edge")
	check(absf(height - minf(box._layout.portrait_max_h, width * texture.get_height() / texture.get_width())) < 0.5,
		"the box takes the picture's shape, so no gap floats under the body")
	box.free()


func test_standins_are_discs_not_sprite_crops() -> void:
	var style := ContentDB.get_def("dialogue_style", &"default") as DialogueStyleDef
	var image: Image = Portraits.standin_image(&"zayd", &"happy")
	check_eq(image.get_width(), style.standin_rows * style.standin_scale, "stand-in size from the style")
	var middle: Color = image.get_pixel(image.get_width() / 2, image.get_height() / 2)
	check(middle.a > 0.9, "a solid disc in the middle")
	check(image.get_pixel(0, 0).a < 0.05, "transparent corners")
