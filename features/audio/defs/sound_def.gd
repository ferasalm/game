class_name SoundDef
extends Def
## One sound effect (content/audio/sounds.json): file variants (one is picked each play), the bus it plays on,
## its volume, a random pitch range so repeats differ and whether it ducks the music (stingers). Footsteps sound on
## the walk clips' foot contacts (ClipDef.contacts), not on a timer.

const SFX_ROOT: String = "res://assets/audio/sfx/"
const BUSES: Array[StringName] = [&"SFX", &"UI", &"Ambience"]

var files: PackedStringArray = PackedStringArray()
var bus: StringName = &"SFX"
var volume_db: float = 0.0
var pitch_min: float = 1.0
var pitch_max: float = 1.0
var ducks_music: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	for name: String in r.text_list("files"):
		files.append(SFX_ROOT + name)
	if files.is_empty():
		r.problem("files", "needs at least one file")
	bus = r.one_of("bus", BUSES)
	volume_db = r.number("volume_db", -60.0, 12.0)
	pitch_min = r.number("pitch_min", 0.25, 4.0, 1.0, false)
	pitch_max = r.number("pitch_max", 0.25, 4.0, 1.0, false)
	if pitch_min > pitch_max:
		r.problem("pitch_min", "is above pitch_max")
	ducks_music = r.flag("ducks_music")
