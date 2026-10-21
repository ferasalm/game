class_name MusicDeck
extends Node
## The music side of the AudioDirector: two players so one track crossfades into the next, and a duck of the
## Music bus under stingers. All times and levels come from AudioRulesDef.

const BUS: StringName = &"Music"
const SILENT_DB: float = -80.0

## The id of the track now playing (&"" when none).
var current: StringName = &""
## True: do everything except start the playback (headless runs).
var silent: bool = false

var _rules: AudioRulesDef
var _players: Array[AudioStreamPlayer] = []
var _fade_tween: Tween
var _duck_tween: Tween


func setup(rules: AudioRulesDef) -> void:
	_rules = rules
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)


## Crossfades to this track. The same track again, or no stream, does nothing.
func play(def: MusicDef, stream: AudioStream) -> void:
	if stream == null or def.id == current:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = def.loop
	current = def.id
	_players.reverse()
	var incoming: AudioStreamPlayer = _players[0]
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	if not silent:
		incoming.play()
	_fade(incoming, def.volume_db)


func stop() -> void:
	current = &""
	_fade(null, 0.0)


## Silences both players at once (shutdown), so no playback still holds a stream.
func stop_now() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null


## Lowers the Music bus under a stinger, holds, then brings it back.
func duck() -> void:
	if _duck_tween != null:
		_duck_tween.kill()
	var base: float = _rules.music_db
	_duck_tween = create_tween()
	_duck_tween.tween_method(_set_bus, base, base + _rules.duck_db, _rules.duck_attack)
	_duck_tween.tween_interval(_rules.duck_seconds)
	_duck_tween.tween_method(_set_bus, base + _rules.duck_db, base, _rules.music_fade)


## Fades incoming up to target_db and every other playing player out, then stops it.
func _fade(incoming: AudioStreamPlayer, target_db: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	var seconds: float = _rules.music_fade
	for player: AudioStreamPlayer in _players:
		if player == incoming:
			_fade_tween.tween_property(player, "volume_db", target_db, seconds)
		elif player.playing:
			_fade_tween.tween_property(player, "volume_db", SILENT_DB, seconds)
			_fade_tween.tween_callback(player.stop).set_delay(seconds)


func _set_bus(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS), db)
