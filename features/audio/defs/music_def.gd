class_name MusicDef
extends Def
## One music track (content/audio/music.json): its file, volume, whether it loops, and an optional fallback track.

var path: String = ""
var volume_db: float = 0.0
var loop: bool = true
var fallback: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	path = r.text("path")
	if not path.begins_with("res://assets/audio/music/"):
		r.problem("path", "must be under res://assets/audio/music/")
	volume_db = r.number("volume_db", -60.0, 12.0)
	loop = r.flag("loop", true)
	if r.has("fallback"):
		fallback = r.id("fallback")


func references() -> Array:
	if fallback != &"":
		return [["music", fallback]]
	return []
