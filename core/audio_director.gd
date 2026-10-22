extends Node
## All game audio (autoload AudioDirector). Builds the buses Master > Music, Ambience, SFX, UI, plays sounds
## from a small player pool with random variant and pitch, crossfades music, and ducks music under stingers.
## Sounds and music come from content (sound, music, audio_rules); a missing file is skipped quietly.
## Views call one-liners: play_sfx, play_ui, play_hit, step, text_blip, play_music, stop_music.

const BUS_MUSIC: StringName = MusicDeck.BUS
const BUS_AMBIENCE: StringName = &"Ambience"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"
const BUS_MASTER: StringName = &"Master"
const SILENT_DB: float = -80.0
const HEAVY_HIT: StringName = &"hit_heavy"
const LIGHT_HIT: StringName = &"hit_light"
const ITEM_SOUND: StringName = &"item_obtained"
const RULES_ID: StringName = &"default"

var _rules: AudioRulesDef
var _rng := RandomNumberGenerator.new()
var _pool: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _last_variant: Dictionary[StringName, int] = {}
var _streams: Dictionary[String, AudioStream] = {}
var _deck: MusicDeck
## Headless runs (tests, servers) go through every step but never start a playback.
var silent: bool = DisplayServer.get_name() == "headless"
var _blip_last: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_rules = ContentDB.get_def("audio_rules", RULES_ID) as AudioRulesDef
	if _rules == null:
		return
	_build_buses()
	for i: int in _rules.voices:
		_pool.append(_new_player())
	_deck = MusicDeck.new()
	_deck.silent = silent
	_deck.setup(_rules)
	add_child(_deck)
	EventBus.item_gained.connect(_on_item_gained)


func _exit_tree() -> void:
	for voice: AudioStreamPlayer in _pool:
		voice.stop()
		voice.stream = null
	if _deck != null:
		_deck.stop_now()


## Plays a sound effect by id (one random variant, random pitch). boost_db adds to its volume. Unknown ids and
## missing files are skipped.
func play_sfx(sound_id: StringName, boost_db: float = 0.0) -> void:
	var def := ContentDB.get_def("sound", sound_id) as SoundDef
	if def == null or _pool.is_empty():
		return
	var last: int = _last_variant.get(sound_id, -1)
	var pick: int = SoundLogic.pick_variant(def.files.size(), last, _rng)
	_last_variant[sound_id] = pick
	var stream: AudioStream = _stream(def.files[pick])
	if stream == null:
		return
	var voice: AudioStreamPlayer = _free_voice()
	voice.stream = stream
	voice.bus = def.bus
	voice.volume_db = def.volume_db + boost_db
	voice.pitch_scale = _rng.randf_range(def.pitch_min, def.pitch_max)
	if not silent:
		voice.play()
	if def.ducks_music:
		_deck.duck()


## Same as play_sfx; the sound's own bus (UI) decides the mix. Reads better at menu call sites.
func play_ui(sound_id: StringName) -> void:
	play_sfx(sound_id)


## The swing, shot or cast sound of a move (its vfx, else the rules map, else melee/ranged).
func play_action(action: ActionDef) -> void:
	if _rules == null:
		return
	play_sfx(SoundLogic.action_sound(action.id, _vfx_of(action), action.is_melee, _rules))


## A move landing for this much damage: its sound, then a light or heavy impact.
func play_hit(action: ActionDef, amount: int) -> void:
	if _rules == null:
		return
	if action != null:
		play_action(action)
	play_sfx(HEAVY_HIT if amount >= _rules.heavy_hit_damage else LIGHT_HIT)


## The item chime, louder for higher rarity (0 = common).
func play_item(rarity: int) -> void:
	if _rules != null:
		play_sfx(ITEM_SOUND, SoundLogic.rarity_boost(rarity, _rules))


## Dialogue typing: call each frame with the number of characters shown; blips every few characters.
func text_blip(shown: int) -> void:
	if _rules == null:
		return
	if shown < _blip_last:
		_blip_last = 0
	if shown > _blip_last and shown % _rules.blip_every == 0:
		play_sfx(&"dialogue_blip")
	_blip_last = shown


## Crossfades to a music track by id. Same track again does nothing; a missing file falls back or keeps what plays.
func play_music(music_id: StringName, from_top: bool = false) -> void:
	if _deck != null:
		_deck.silent = silent
		_deck.set_base(music_id, from_top)


func play_music_def(def: MusicDef) -> void:
	if _deck != null and _rules != null:
		_deck.silent = silent
		_deck.play_def(def)


func stop_music() -> void:
	if _deck != null:
		_deck.stop()


## The id of the music now playing (&"" when none).
func current_music() -> StringName:
	return _deck.current if _deck != null else &""


func music_deck() -> MusicDeck:
	return _deck


## The move's own vfx field when ActionDef has one (added by the VFX builder), else empty.
func _vfx_of(action: ActionDef) -> StringName:
	var value: Variant = action.get(&"vfx")
	return StringName(str(value)) if value != null else &""


func _free_voice() -> AudioStreamPlayer:
	for voice: AudioStreamPlayer in _pool:
		if not voice.playing:
			return voice
	_next_voice = (_next_voice + 1) % _pool.size()
	return _pool[_next_voice]


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	_streams[path] = stream
	return stream


func _new_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	return player


func _build_buses() -> void:
	var volumes: Dictionary[StringName, float] = {
		BUS_MUSIC: _rules.music_db, BUS_AMBIENCE: _rules.ambience_db, BUS_SFX: _rules.sfx_db, BUS_UI: _rules.ui_db}
	for bus_name: StringName in volumes:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, BUS_MASTER)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), volumes[bus_name])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), _rules.master_db)


func _on_item_gained(_item_id: StringName, _count: int) -> void:
	play_item(0)
