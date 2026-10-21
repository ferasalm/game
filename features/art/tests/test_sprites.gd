extends TestCase
## Prototype T7: every sprite is well formed and uses only palette letters; PixelArt and CharacterVisual work.

const REQUIRED: Array[StringName] = [
	&"zayd", &"bilqis", &"concession_enforcer", &"survey_drone", &"workshop_bench",
]


func _palette_of(sprite: SpriteDef) -> PaletteDef:
	return ContentDB.get_def("palette", sprite.palette) as PaletteDef


func test_required_sprites_exist() -> void:
	for sprite_id: StringName in REQUIRED:
		check(ContentDB.get_def("sprite", sprite_id) != null, "sprite %s exists" % sprite_id)


func test_every_sprite_is_well_formed() -> void:
	for sprite_id: StringName in ContentDB.ids("sprite"):
		var sprite := ContentDB.get_def("sprite", sprite_id) as SpriteDef
		var palette: PaletteDef = _palette_of(sprite)
		check(palette != null, "%s has a palette" % sprite_id)
		check(sprite.height() > 0, "%s has rows" % sprite_id)
		check(not sprite.source.is_empty() and not sprite.licence.is_empty(), "%s has source and licence" % sprite_id)
		for y: int in sprite.height():
			check_eq(sprite.rows[y].length(), sprite.width(), "%s row %d width" % [sprite_id, y])
			for letter: String in sprite.rows[y]:
				check(letter == "." or (palette != null and palette.colors.has(letter)),
					"%s row %d letter '%s' is in the palette" % [sprite_id, y, letter])


func test_palette_is_32_colours() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	check_eq(palette.colors.size(), 32, "palette size")


func test_pixel_art_colours() -> void:
	var sprite := SpriteDef.new()
	sprite.rows = PackedStringArray([".kQ", "k.."])
	var palette := PaletteDef.new()
	palette.colors["k"] = Color.html("#1a1420")
	var image: Image = PixelArt.image(sprite, palette)
	check_eq(image.get_size(), Vector2i(3, 2), "image size")
	check_eq(image.get_pixel(0, 0).a, 0.0, "dot is transparent")
	check_eq(image.get_pixel(1, 0), Color.html("#1a1420"), "palette letter colour")
	check_eq(image.get_pixel(2, 0), PixelArt.UNKNOWN, "unknown letter is magenta")
	check_eq(image.get_pixel(1, 1).a, 0.0, "dot in second row is transparent")


func test_character_visual_builds_with_real_and_missing_ids() -> void:
	var real := CharacterVisual.new()
	real.set_sprite(&"zayd")
	check_eq(real.height(), 2.0, "Zayd's real 64 px sprite at the default 32 px = 1 m")
	var standin := CharacterVisual.new()
	standin.set_sprite(&"workshop_bench")
	var bench := ContentDB.get_def("sprite", &"workshop_bench") as SpriteDef
	check_eq(standin.height(), float(bench.height()) / bench.pixels_per_metre, "a stand-in keeps its own density (16 px = 1 m)")
	standin.free()
	var missing := CharacterVisual.new()
	missing.set_sprite(&"no_such_sprite")
	check_eq(missing.height(), 2.0, "placeholder: 64 px at the default 32 px = 1 m")
	for visual: CharacterVisual in [real, missing]:
		visual.face(-1.0)
		visual.set_moving(true)
		visual.set_moving(false)
		visual.set_down(true)
		visual.set_down(false)
		visual.free()
