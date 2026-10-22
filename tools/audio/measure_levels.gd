extends SceneTree
## Plays every sfx file of content/audio/sounds.json one after another at 0 dB for the movie writer's audio
## capture; prints "SLOT <path> <start seconds> <seconds>" lines for tools/audio/levels.py. Run (not headless):
## "$(tools/godot.sh)" --path . --write-movie out.avi --resolution 64x64 --fixed-fps 60 -s res://tools/audio/measure_levels.gd

const GAP: float = 0.3
const LONGEST: float = 4.0
const SFX_ROOT: String = "res://assets/audio/sfx/"

var _queue: Array[String] = []
var _player: AudioStreamPlayer
var _clock: float = 0.0
var _slot_end: float = 0.0


func _initialize() -> void:
	var seen: Dictionary = {}
	var text: String = FileAccess.get_file_as_string("res://content/audio/sounds.json")
	for item: Dictionary in (JSON.parse_string(text) as Dictionary)["items"]:
		for name: String in item["files"]:
			seen[SFX_ROOT + name] = true
	var only: PackedStringArray = OS.get_cmdline_user_args()  # optional: only paths containing one of these
	for path: String in seen:
		if only.is_empty() or _matches(path, only):
			_queue.append(path)
	_queue.sort()
	_player = AudioStreamPlayer.new()
	root.add_child(_player)


func _matches(path: String, parts: PackedStringArray) -> bool:
	for part: String in parts:
		if path.contains(part):
			return true
	return false


func _process(delta: float) -> bool:
	_clock += delta
	if _clock < _slot_end:
		return false
	if _queue.is_empty():
		return true
	var path: String = _queue.pop_front()
	var stream: AudioStream = load(path) as AudioStream
	var seconds: float = minf(stream.get_length(), LONGEST)
	print("SLOT %s %.4f %.4f" % [path, _clock, seconds])
	_player.stream = stream
	_player.play()
	_slot_end = _clock + seconds + GAP
	return false
