class_name TestColdOpen
extends TestCase
## purpose: The Roya cold open: its content loads (three shots, real textures, caption keys in TextDB), the timeline
## orders fade, alert, lock, cut and end, `done` fires exactly once, input is ignored until it was seen once, then a key
## skips to the cut, and a full play remembers it was seen.

const SEEN: String = "user://test_neon_seen.cfg"


func _def() -> NeonColdOpenDef:
	return ContentDB.get_def("neon_cold_open", &"default") as NeonColdOpenDef


func _cold(seen: bool) -> ColdOpen:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SEEN))
	if seen:
		var cfg := ConfigFile.new()
		cfg.set_value("cold_open", "seen", true)
		cfg.save(SEEN)
	var cold := (load("res://features/neon/cold_open/cold_open.tscn") as PackedScene).instantiate() as ColdOpen
	cold.autostart = false
	cold.seen_path = SEEN
	tree.root.add_child(cold)
	cold.start()
	return cold


func _key() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key


func test_def_loads_three_shots_with_real_art_and_text() -> void:
	var def: NeonColdOpenDef = _def()
	check(def != null, "cold open content loads")
	check_eq(def.shots.size(), 3, "three shots")
	for shot: Dictionary in def.shots:
		check(ResourceLoader.exists(shot["texture"] as String), "%s exists" % shot["texture"])
		var key: String = shot["caption"]
		check(TranslationServer.translate(key) != key, "%s has text" % key)
	for key: String in ["NEON_COLD_ALERT", "NEON_COLD_ALERT_LOCKED", "NEON_COLD_SKIP"]:
		check(TranslationServer.translate(key) != key, "%s has text" % key)


func test_timeline_orders_alert_lock_cut_and_end() -> void:
	var def: NeonColdOpenDef = _def()
	check_eq(ColdOpenTimeline.shot_alpha(def, 1, ColdOpenTimeline.shot_start(def, 1) - 0.1), 0.0, "shot 2 waits")
	check_eq(ColdOpenTimeline.alert_fill(def, ColdOpenTimeline.alert_begin(def) - 0.1), -1.0, "no alert before")
	check(ColdOpenTimeline.alert_begin(def) > ColdOpenTimeline.shot_start(def, 2), "the alert comes on Roya's shot")
	check(ColdOpenTimeline.lock_time(def) < ColdOpenTimeline.cut_time(def), "it locks before the cut")
	check(ColdOpenTimeline.cut_time(def) < ColdOpenTimeline.end_time(def), "black holds before the end")
	var total: float = ColdOpenTimeline.end_time(def)
	check(total > 30.0 and total < 45.0, "about 40 seconds (%.1f)" % total)


func test_done_fires_once() -> void:
	var cold := _cold(false)
	var count: Array[int] = [0]
	cold.done.connect(func() -> void: count[0] += 1)
	var end: float = ColdOpenTimeline.end_time(cold.def)
	for i: int in int(end / 0.5) + 4:
		cold._process(0.5)
	check_eq(count[0], 1, "done fires once after the end")
	var cfg := ConfigFile.new()
	cfg.load(SEEN)
	check(cfg.get_value("cold_open", "seen", false) as bool, "a full play remembers it was seen")
	cold.queue_free()


func test_input_before_seen_does_nothing() -> void:
	var cold := _cold(false)
	cold._process(2.0)
	cold._unhandled_input(_key())
	check(cold.time < ColdOpenTimeline.cut_time(cold.def), "the first play cannot be skipped")
	check(not cold.skip_hint.visible, "no skip hint on the first play")
	cold.queue_free()


func test_a_key_skips_once_seen() -> void:
	var cold := _cold(true)
	var count: Array[int] = [0]
	cold.done.connect(func() -> void: count[0] += 1)
	cold._process(2.0)
	check(cold.skip_hint.visible, "the skip hint shows")
	cold._unhandled_input(_key())
	for i: int in 4:
		cold._process(0.5)
	check_eq(count[0], 1, "done within 2 s of the key")
	cold.queue_free()
