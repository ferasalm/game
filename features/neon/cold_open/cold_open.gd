class_name ColdOpen
extends Control
## purpose: The Roya cold open, watch only (docs/briefs/neon-cold-open.md): three painted shots with a slow push, rain,
## captions, an IDENTIFYING alert that fills and locks on her, a cut to black, then `done`. After the first full play
## (remembered in seen_path) any key skips to the cut.

signal done

const MUTE_DB: float = -60.0

@export var autostart: bool = true
@export var seen_path: String = "user://neon_seen.cfg"

var def: NeonColdOpenDef
var time: float = 0.0
var running: bool = false
var seen: bool = false
## Per shot: [main TextureRect, parallax TextureRect or null].
var layers: Array[Array] = []
var caption: Label
var alert: ColorRect
var alert_bar: ColorRect
var alert_label: Label
var vignette: TextureRect
var skip_hint: Label
var black: ColorRect
var music: AudioStreamPlayer
var _locked: bool = false
var _cut: bool = false
var _finished: bool = false


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	def = ContentDB.get_def("neon_cold_open", &"default") as NeonColdOpenDef
	if def == null:
		push_error("ColdOpen: no neon_cold_open 'default'")
		return
	ColdOpenBuild.build(self)
	done.connect(func() -> void: print("cold open done"))
	if autostart:
		start()


## Plays from the top.
func start() -> void:
	seen = _read_seen()
	time = 0.0
	running = true
	_locked = false
	_cut = false
	_finished = false
	alert_label.text = tr("NEON_COLD_ALERT")
	if music.stream != null:
		music.volume_db = def.music_db
		music.play()
	_apply()


func _process(delta: float) -> void:
	if not running:
		return
	time += delta
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if not running or not seen or _cut:
		return
	var button: bool = event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton
	if button and event.is_pressed() and not event.is_echo():
		time = ColdOpenTimeline.cut_time(def)
		get_viewport().set_input_as_handled()
		_apply()


func _apply() -> void:
	_apply_shots()
	_apply_caption()
	_apply_alert()
	if not _cut and time >= ColdOpenTimeline.cut_time(def):
		_cut = true
		if music.playing:
			create_tween().tween_property(music, "volume_db", MUTE_DB, maxf(def.black_hold, 0.01))
	black.visible = _cut
	skip_hint.visible = seen and not _cut and time >= def.skip_hint_delay
	if not _finished and time >= ColdOpenTimeline.end_time(def):
		_finish()


func _apply_shots() -> void:
	var last: int = def.shots.size() - 1
	for i: int in def.shots.size():
		var a: float = ColdOpenTimeline.shot_alpha(def, i, time)
		var covered: bool = i < last and ColdOpenTimeline.shot_alpha(def, i + 1, time) >= 1.0
		var p: float = ColdOpenTimeline.shot_progress(def, i, time)
		var main: TextureRect = layers[i][0]
		main.visible = a > 0.0 and not covered
		main.modulate.a = a
		_push(main, def.shots[i], p)
		var par: TextureRect = layers[i][1]
		if par != null:
			par.visible = main.visible
			par.modulate.a = a * def.parallax_alpha
			_push(par, def.shots[i], p * def.parallax_speed)


func _push(rect: TextureRect, shot: Dictionary, p: float) -> void:
	rect.pivot_offset = size * 0.5
	rect.scale = Vector2.ONE * lerpf(shot["scale_from"] as float, shot["scale_to"] as float, p)
	rect.position = (shot["pan_from"] as Vector2).lerp(shot["pan_to"] as Vector2, p)


func _apply_caption() -> void:
	var best: float = 0.0
	for i: int in def.shots.size():
		var a: float = ColdOpenTimeline.caption_alpha(def, i, time)
		if a > best:
			best = a
			caption.text = tr(def.shots[i]["caption"] as String)
	caption.modulate.a = 0.0 if _cut else best


func _apply_alert() -> void:
	var fill: float = ColdOpenTimeline.alert_fill(def, time)
	alert.visible = fill >= 0.0 and not _cut
	alert_bar.size = Vector2(def.alert_size.x * maxf(fill, 0.0), def.alert_size.y)
	if fill >= 1.0 and not _locked:
		_lock()


## The alert finds her: LOCKED text, the bar flashes, the red vignette pulses once.
func _lock() -> void:
	_locked = true
	alert_label.text = tr("NEON_COLD_ALERT_LOCKED")
	var flash: Tween = create_tween()
	for i: int in def.alert_flashes:
		flash.tween_property(alert, "modulate", Color(2.0, 0.6, 0.6), def.alert_flash_seconds)
		flash.tween_property(alert, "modulate", Color.WHITE, def.alert_flash_seconds)
	var pulse: Tween = create_tween()
	pulse.tween_property(vignette, "modulate:a", def.vignette_alpha, def.cut_after_lock * 0.4)
	pulse.tween_property(vignette, "modulate:a", 0.0, def.cut_after_lock * 0.6)


func _finish() -> void:
	_finished = true
	running = false
	if not seen:
		var cfg := ConfigFile.new()
		cfg.load(seen_path)
		cfg.set_value("cold_open", "seen", true)
		cfg.save(seen_path)
	done.emit()


func _read_seen() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(seen_path) != OK:
		return false
	return cfg.get_value("cold_open", "seen", false) as bool
