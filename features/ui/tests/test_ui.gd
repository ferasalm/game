extends TestCase
## The shared UI look: the style loads completely, the theme builds with all three fonts (Arabic glyphs
## included), every rarity has a colour, the painted frames have the right size, and the text server can shape
## right-to-left Arabic.


func test_style_is_complete_and_its_fonts_exist() -> void:
	var style: UiStyleDef = Ui.style()
	check(style != null, "ui_style default exists")
	for key: StringName in UiStyleDef.FONTS:
		check(ResourceLoader.exists(style.fonts[key]), "font file for " + key)
	for key: StringName in UiStyleDef.COLOURS:
		check(style.colour(key) != Color.MAGENTA, "colour set: " + key)
	for key: StringName in UiStyleDef.SIZES:
		check(style.size(key) > 0, "size set: " + key)


func test_theme_builds_with_every_font_and_variation() -> void:
	Ui.clear_cache()
	var theme: Theme = Ui.theme()
	check(theme.default_font != null, "a default font")
	for variant: StringName in UiTheme.LABEL_VARIANTS:
		check(theme.has_font(&"font", variant) or theme.get_type_variation_base(variant) == &"Label", "label variation " + variant)
	var title: Font = theme.get_font(&"font", &"TitleLabel")
	check(title != null and title.has_char(0x0642), "Reem Kufi draws Arabic (qaf)")
	check(theme.default_font.has_char(0x0642) and theme.default_font.has_char(0x41), "Amiri draws Arabic and Latin")
	check(theme.has_stylebox(&"panel", &"PanelContainer") and theme.has_stylebox(&"normal", &"Button"), "panel and button styles")
	check(theme.has_stylebox(&"fill", &"HpBar") and theme.has_stylebox(&"fill", &"SpBar"), "bar fills")


func test_every_rarity_has_a_colour_from_its_def() -> void:
	var seen: Dictionary[Color, bool] = {}
	for rarity_id: StringName in ContentDB.ids("rarity"):
		var tier := ContentDB.get_def("rarity", rarity_id) as RarityDef
		check_eq(UiRarity.colour(rarity_id), tier.colour, "colour of " + rarity_id)
		check(not UiRarity.tier_name(rarity_id).is_empty(), "a name for " + rarity_id)
		seen[tier.colour] = true
	check_eq(seen.size(), 6, "six different tier colours")
	check_eq(UiRarity.item_colour(&"arc_arm"), UiRarity.colour(&"epic"), "an item takes its tier's colour")


func test_painted_frames_are_nine_patches_with_the_style_cell() -> void:
	var style: UiStyleDef = Ui.style()
	var cell: int = style.size(&"s_frame_cell")
	for kind: StringName in [&"panel", &"plate", &"inset"]:
		var frame: Texture2D = UiOrnament.frame(style, kind)
		check_eq(frame.get_width(), cell * 3, "frame width " + kind)
		check_eq(frame.get_height(), cell * 3, "frame height " + kind)
	var box: StyleBoxTexture = UiBoxes.panel(style)
	check_eq(box.get_texture_margin(SIDE_LEFT), float(cell), "slice margin is one cell")
	var frieze: Texture2D = UiOrnament.frieze(style)
	check_eq(frieze.get_width(), style.size(&"s_frieze_period"), "frieze period")


func test_arabic_is_shaped_right_to_left() -> void:
	var server: TextServer = TextServerManager.get_primary_interface()
	check(server.has_feature(TextServer.FEATURE_BIDI_LAYOUT), "bidi layout available")
	check(server.has_feature(TextServer.FEATURE_SHAPING), "glyph shaping (joined letters) available")
	check_eq(Ui.text("TITLE_GAME_AR"), "قرناو", "the Arabic title text")
	check_eq(Ui.text("AREA_SOUQ_NAME_AR"), "سطوح سوق الملح", "the Arabic area name")
	var label: Label = Ui.label(Ui.text("TITLE_GAME_AR"), &"TitleLabel")
	label.language = "ar"
	check(label.get_minimum_size().x > 0.0, "Arabic title has a width")
	label.free()


func test_speaker_portrait_flip_comes_from_data() -> void:
	check((ContentDB.get_def("speaker", &"bilqis") as SpeakerDef).portrait_flip, "Bilqis's real portrait faces away: flipped")
	check(not (ContentDB.get_def("speaker", &"zayd") as SpeakerDef).portrait_flip, "Zayd's faces front: not flipped")
	var box := DialogueBox.new()
	tree.root.add_child(box)
	box.play(&"workshop_first")
	var guard: int = 0
	while box.is_playing() and guard < 40:
		var line: DialogueLine = box._run.current()
		var flip: bool = (ContentDB.get_def("speaker", line.speaker) as SpeakerDef).portrait_flip and Portraits.has_real(line.speaker, line.expression)
		check_eq(box._layout.portrait.flip_h, flip, "portrait flip of %s" % line.speaker)
		box.advance()
		box.advance()
		guard += 1
	box.free()
