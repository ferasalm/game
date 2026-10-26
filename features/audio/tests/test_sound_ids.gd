extends TestCase
## Sound ids: every id the code asks the AudioDirector for exists in sounds.json with existing files, and the
## synthesized Arc Discharge files are 44.1 kHz mono, 0.6-0.9 s long and peak under -1 dBFS.

const SOURCE_ROOTS: Array[String] = ["res://core", "res://features"]
const CALL_PATTERN: String = "(?:play_sfx|play_ui|step)\\([^)]*?&\"([a-z_0-9]+)\""
const ARC_FILES: int = 3
const ARC_PATH: String = "res://assets/audio/sfx/qarnaw/arc_discharge_0%d.wav"
const ARC_RATE: int = 44100
const ARC_MIN_SECONDS: float = 0.6
const ARC_MAX_SECONDS: float = 0.9
const PEAK_LIMIT: float = 0.8912  # -1 dBFS
const WAV_HEADER_BYTES: int = 44  # the plain PCM header the synth script writes
const SAMPLE_MAX: float = 32768.0


func _gd_files(dir_path: String, out: Array[String]) -> void:
	for name: String in DirAccess.get_files_at(dir_path):
		if name.ends_with(".gd"):
			out.append(dir_path.path_join(name))
	for sub: String in DirAccess.get_directories_at(dir_path):
		if sub != "tests" and not sub.begins_with("."):
			_gd_files(dir_path.path_join(sub), out)


func _requested_ids() -> Dictionary:
	var regex := RegEx.new()
	regex.compile(CALL_PATTERN)
	var files: Array[String] = []
	for root: String in SOURCE_ROOTS:
		_gd_files(root, files)
	var ids: Dictionary = {}
	for path: String in files:
		for found: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
			ids[StringName(found.get_string(1))] = path
	return ids


func test_every_sound_the_code_asks_for_exists() -> void:
	var ids: Dictionary = _requested_ids()
	check(ids.size() >= 6, "the scan found the call sites, got " + str(ids.size()))
	for sound_id: StringName in ids:
		var def := ContentDB.get_def("sound", sound_id) as SoundDef
		check(def != null, "%s (asked in %s) is in sounds.json" % [sound_id, ids[sound_id]])
		if def != null:
			for path: String in def.files:
				check(ResourceLoader.exists(path), "%s: %s exists" % [sound_id, path])


func test_content_sound_ids_exist() -> void:
	var rules := ContentDB.get_def("audio_rules", &"default") as AudioRulesDef
	for sound_id: StringName in [rules.fallback_melee, rules.fallback_ranged]:
		check(ContentDB.get_def("sound", sound_id) != null, "rules fallback " + sound_id)
	for action_id: StringName in rules.action_vfx:
		var sound_id := StringName("vfx_" + String(rules.action_vfx[action_id]))
		check(ContentDB.get_def("sound", sound_id) != null, "%s -> %s" % [action_id, sound_id])


func test_arc_discharge_files_are_clean() -> void:
	var def := ContentDB.get_def("sound", &"vfx_arc_all") as SoundDef
	check_eq(def.files.size(), ARC_FILES, "three variations")
	for i: int in range(1, ARC_FILES + 1):
		var wav := load(ARC_PATH % i) as AudioStreamWAV
		check(wav != null, "arc %d loads" % i)
		if wav == null:
			continue
		check_eq(wav.mix_rate, ARC_RATE, "44.1 kHz")
		check_eq(wav.stereo, false, "mono")
		var length: float = wav.get_length()
		check(length >= ARC_MIN_SECONDS and length <= ARC_MAX_SECONDS, "arc %d length %f" % [i, length])
		var peak: float = 0.0
		var raw: PackedByteArray = FileAccess.get_file_as_bytes(ARC_PATH % i)
		for s: int in range(WAV_HEADER_BYTES, raw.size() - 1, 2):
			peak = maxf(peak, absf(raw.decode_s16(s)) / SAMPLE_MAX)
		check(peak > 0.0 and peak < PEAK_LIMIT, "arc %d peak %f is under -1 dBFS" % [i, peak])
