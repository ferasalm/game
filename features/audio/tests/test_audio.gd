extends TestCase
## Audio: every sound and music entry is well formed, every sfx file exists, every vfx id has a sound, the
## pure sound rules hold, and the AudioDirector builds its buses, plays headless and skips missing music.

const VFX_IDS: Array[StringName] = [&"slash", &"heavy_slash", &"stab", &"piston", &"beam", &"bolt", &"arc_all",
	&"burst", &"heal", &"shield", &"overclock", &"net", &"drone_shot", &"baton"]
const GAME_SOUNDS: Array[StringName] = [&"footstep_rydan", &"footstep_follower", &"menu_move", &"menu_confirm",
	&"menu_cancel", &"menu_open", &"dialogue_blip", &"dialogue_advance", &"hit_light", &"hit_heavy", &"interrupt",
	&"knock_out", &"status_apply", &"victory", &"defeat", &"item_obtained"]

const MIXER_SETTLE_MS: int = 300


func _rules() -> AudioRulesDef:
	return ContentDB.get_def("audio_rules", &"default") as AudioRulesDef


func _director() -> Node:
	var director: Node = load("res://core/audio_director.gd").new()
	tree.root.add_child(director)
	return director


func test_every_sound_is_well_formed_and_its_files_exist() -> void:
	check(ContentDB.ids("sound").size() >= 30, "sounds are loaded")
	for sound_id: StringName in ContentDB.ids("sound"):
		var def := ContentDB.get_def("sound", sound_id) as SoundDef
		for path: String in def.files:
			check(FileAccess.file_exists(path), "%s: file %s exists" % [sound_id, path])
			check(ResourceLoader.exists(path), "%s: file %s imports" % [sound_id, path])


func test_game_sounds_exist() -> void:
	for sound_id: StringName in GAME_SOUNDS:
		check(ContentDB.get_def("sound", sound_id) != null, "sound " + sound_id)
	check((ContentDB.get_def("sound", &"victory") as SoundDef).ducks_music, "stingers duck music")


func test_every_vfx_id_has_a_sound() -> void:
	for vfx: StringName in VFX_IDS:
		check(ContentDB.get_def("sound", StringName("vfx_" + vfx)) != null, "sound for vfx " + vfx)


func test_every_move_has_a_sound() -> void:
	for action_id: StringName in ContentDB.ids("action"):
		var action := ContentDB.get_def("action", action_id) as ActionDef
		var sound_id: StringName = SoundLogic.action_sound(action_id, &"", action.is_melee, _rules())
		check(ContentDB.get_def("sound", sound_id) != null, "move %s -> %s" % [action_id, sound_id])


func test_music_entries_are_well_formed() -> void:
	var music_ids: Array[StringName] = ContentDB.ids("music")
	check(music_ids.size() >= 8, "at least 8 music tracks loaded")
	for music_id: StringName in music_ids:
		var def := ContentDB.get_def("music", music_id) as MusicDef
		var want_loop: bool = (music_id != &"victory")
		check(def != null and def.loop == want_loop, "music " + music_id)


func test_bad_sound_content_is_reported() -> void:
	var errors := PackedStringArray()
	var def := SoundDef.new()
	var data: Dictionary = {"id": "x", "files": [], "bus": "Nope", "volume_db": 0, "pitch_min": 2, "pitch_max": 1}
	def.read(DefReader.new(data, "t", errors))
	var text: String = "\n".join(errors)
	check(text.contains("needs at least one file") and text.contains("is not one of") and text.contains("above pitch_max"), text)


func test_variant_never_repeats_the_last() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var last: int = -1
	for i: int in 200:
		var pick: int = SoundLogic.pick_variant(3, last, rng)
		check(pick >= 0 and pick < 3 and pick != last, "variant %d after %d" % [pick, last])
		last = pick
	check_eq(SoundLogic.pick_variant(1, 0, rng), 0, "one variant")


func test_action_sound_prefers_own_vfx_then_map_then_fallback() -> void:
	var rules: AudioRulesDef = _rules()
	check_eq(SoundLogic.action_sound(&"breaker", &"", true, rules), &"vfx_piston", "map")
	check_eq(SoundLogic.action_sound(&"breaker", &"beam", true, rules), &"vfx_beam", "own vfx wins")
	check_eq(SoundLogic.action_sound(&"unknown_move", &"", true, rules), rules.fallback_melee, "melee fallback")
	check_eq(SoundLogic.action_sound(&"unknown_move", &"", false, rules), rules.fallback_ranged, "ranged fallback")


func test_rarity_boost_is_louder_and_clamped() -> void:
	var rules: AudioRulesDef = _rules()
	check(SoundLogic.rarity_boost(2, rules) > SoundLogic.rarity_boost(0, rules), "rarer is louder")
	check_eq(SoundLogic.rarity_boost(99, rules), SoundLogic.rarity_boost(rules.item_rarity_db.size() - 1, rules), "clamped")


func test_director_builds_buses_and_plays_headless() -> void:
	var director: Node = _director()
	director.set("silent", false)
	for bus_name: String in ["Music", "Ambience", "SFX", "UI"]:
		check(AudioServer.get_bus_index(bus_name) != -1, "bus " + bus_name)
	director.call("play_sfx", &"menu_move")
	director.call("play_sfx", &"no_such_sound")
	director.call("play_ui", &"menu_confirm")
	director.call("play_sfx", &"victory")
	var action := ContentDB.get_def("action", &"breaker") as ActionDef
	director.call("play_hit", action, 99)
	director.call("play_hit", null, 1)
	director.call("play_item", 3)
	director.call("play_sfx", &"footstep_rydan")
	for shown: int in 6:
		director.call("text_blip", shown)
	_retire(director)


func test_missing_music_is_skipped_and_present_music_crossfades() -> void:
	var director: Node = _director()
	director.set("silent", false)
	director.call("play_music", &"night_rooftops")
	director.call("play_music", &"no_such_track")
	director.call("stop_music")
	if not ResourceLoader.exists("res://assets/audio/music/night_rooftops.ogg"):
		check_eq(director.call("current_music"), &"", "silent while the file is missing")
	var track := MusicDef.new()
	track.id = &"probe"
	track.path = (ContentDB.get_def("sound", &"hit_light") as SoundDef).files[0]
	director.call("play_music_def", track)
	check_eq(director.call("current_music"), &"probe", "a present file plays")
	director.call("stop_music")
	check_eq(director.call("current_music"), &"", "stopped")
	_retire(director)


## Stops everything and gives the mixer thread a moment to drop its playbacks, so no stream is leaked at exit.
func _retire(director: Node) -> void:
	director.free()
	OS.delay_msec(MIXER_SETTLE_MS)
