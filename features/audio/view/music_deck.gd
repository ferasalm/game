class_name MusicDeck
extends Node
## The music side of the AudioDirector: two players so one track crossfades into the next, a duck under stingers,
## and a pure stack of screen music contexts (content/audio/screen_music.json). Remembers playback position.

const BUS: StringName = &"Music"
const SILENT_DB: float = -80.0

## The id of the track now playing (&"" when none).
var current: StringName = &""
## True: do everything except start the playback (headless runs).
var silent: bool = DisplayServer.get_name() == "headless"
var stack: MusicStack

var _rules: AudioRulesDef
var _players: Array[AudioStreamPlayer] = []
var _positions: Dictionary[StringName, float] = {}
var _streams: Dictionary[String, AudioStream] = {}
var _fade_tween: Tween
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_screens()


func setup(rules: AudioRulesDef) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rules = rules
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.finished.connect(_on_player_finished.bind(player))
		add_child(player)
		_players.append(player)
	_build_stack()


func _exit_tree() -> void:
	if Screens != null:
		if Screens.screen_opened.is_connected(_on_screen_opened):
			Screens.screen_opened.disconnect(_on_screen_opened)
		if Screens.screen_closed.is_connected(_on_screen_closed):
			Screens.screen_closed.disconnect(_on_screen_closed)


func set_base(track_id: StringName, from_top: bool = false) -> void:
	if from_top or track_id == &"battle":
		_positions.erase(track_id)
	stack.set_base_track(track_id)
	_apply_stack()


func play(def: MusicDef, stream: AudioStream) -> void:
	play_resolved(def, stream, def.id == &"battle")


func play_def(def: MusicDef) -> void:
	if def != null:
		play_resolved(def, _stream(def.path), def.id == &"battle")


func stop() -> void:
	_record_current_position()
	current = &""
	_fade(null, 0.0)


func stop_now() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null


func duck() -> void:
	if _duck_tween != null:
		_duck_tween.kill()
	var base: float = _rules.music_db
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_bus, base, base + _rules.duck_db, _rules.duck_attack)
	_duck_tween.tween_interval(_rules.duck_seconds)
	_duck_tween.tween_method(_set_bus, base + _rules.duck_db, base, _rules.music_fade)


func track_position(track_id: StringName) -> float:
	return _positions.get(track_id, 0.0)


func set_track_position(track_id: StringName, pos: float) -> void:
	_positions[track_id] = pos


func play_resolved(def: MusicDef, stream: AudioStream, from_top: bool = false) -> void:
	if stream == null or def.id == current:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = def.loop
	_record_current_position()
	current = def.id
	_players.reverse()
	var incoming: AudioStreamPlayer = _players[0]
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	var pos: float = 0.0 if (from_top or def.id == &"battle") else _positions.get(def.id, 0.0)
	if incoming.stream != null and incoming.stream.get_length() > 0.0:
		pos = fmod(pos, incoming.stream.get_length())
	if not silent:
		incoming.play(pos)
	_fade(incoming, def.volume_db)


func _on_screen_opened(screen_id: StringName) -> void:
	stack.push(screen_id)
	_apply_stack()


func _on_screen_closed(screen_id: StringName) -> void:
	stack.pop(screen_id)
	_apply_stack()


func _apply_stack() -> void:
	var target: StringName = stack.current_track()
	if target == &"":
		stop()
		return
	var def: MusicDef = _resolve_def(target)
	if def != null:
		play_resolved(def, _stream(def.path), def.id == &"battle")


func _resolve_def(track_id: StringName) -> MusicDef:
	var defs: Dictionary = {}
	for id: StringName in ContentDB.ids("music"):
		defs[id] = ContentDB.get_def("music", id) as MusicDef
	return MusicLogic.resolve_track(track_id, defs, ResourceLoader.exists)


func _record_current_position() -> void:
	if current != &"" and not _players.is_empty():
		_positions[current] = _players[0].get_playback_position()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player == _players[0] and current == &"victory":
		var flow := ContentDB.get_def("flow_rules", &"default") as FlowRulesDef
		var base: StringName = flow.explore_music if flow != null else &"explore_souq"
		set_base(base)


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	_streams[path] = s
	return s


func _build_stack() -> void:
	var mappings: Dictionary[StringName, StringName] = {}
	for id: StringName in ContentDB.ids("screen_music"):
		var sm := ContentDB.get_def("screen_music", id) as ScreenMusicDef
		if sm != null:
			mappings[sm.id] = sm.music
	stack = MusicStack.new(mappings)


func _connect_screens() -> void:
	if Screens != null:
		if not Screens.screen_opened.is_connected(_on_screen_opened):
			Screens.screen_opened.connect(_on_screen_opened)
		if not Screens.screen_closed.is_connected(_on_screen_closed):
			Screens.screen_closed.connect(_on_screen_closed)


func _fade(incoming: AudioStreamPlayer, target_db: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
	var fading_out: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _players:
		if player != incoming and player.playing:
			fading_out.append(player)
	if incoming == null and fading_out.is_empty():
		return
	_fade_tween = create_tween().set_parallel(true)
	var seconds: float = _rules.music_fade
	if incoming != null:
		_fade_tween.tween_property(incoming, "volume_db", target_db, seconds)
	for player: AudioStreamPlayer in fading_out:
		_fade_tween.tween_property(player, "volume_db", SILENT_DB, seconds)
		_fade_tween.tween_callback(player.stop).set_delay(seconds)


func _set_bus(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS), db)
