extends TestCase
## The shared UI look: the style loads completely, the theme builds with every font (Reem Kufi and
## Amiri for English, Noto Old South Arabian for Musnad), every rarity has a colour, the painted frames have the right
## size, and the text server lays Musnad out right to left.


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
	check(title != null and title.has_char(0x41), "Reem Kufi draws Latin")
	check(theme.default_font.has_char(0x41), "Amiri draws Latin")
	var musnad: Font = theme.get_font(&"font", &"MusnadLabel")
	check(musnad != null and musnad.has_char(0x10A64) and musnad.has_char(0x10A7A), "the Musnad label font draws Musnad letters")
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


func test_musnad_is_laid_out_right_to_left() -> void:
	var server: TextServer = TextServerManager.get_primary_interface()
	check(server.has_feature(TextServer.FEATURE_BIDI_LAYOUT), "bidi layout available")
	check_eq(Ui.text("TITLE_GAME_MUSNAD"), "𐩤𐩧𐩬𐩱𐩥", "the Musnad title text")
	check_eq(Ui.text("AREA_SOUQ_NAME_MUSNAD"), "𐩦𐩷𐩥𐩢 𐩦𐩥𐩤 𐩱𐩡𐩣𐩡𐩢", "the Musnad area name")
	var label: Label = Ui.label(Ui.text("TITLE_GAME_MUSNAD"), &"MusnadLabel")
	check(label.get_minimum_size().x > 0.0, "the Musnad title has a width")
	label.free()
