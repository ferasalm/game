class_name MusicDef
extends Def
## One music track (content/audio/music.json): its file, volume and whether it loops. The file may not exist yet
## (the owner drops tracks in later); the AudioDirector then stays silent for it.

var path: String = ""
var volume_db: float = 0.0
var loop: bool = true


func read(r: DefReader) -> void:
	id = r.id()
	path = r.text("path")
	if not path.begins_with("res://assets/audio/music/"):
		r.problem("path", "must be under res://assets/audio/music/")
	volume_db = r.number("volume_db", -60.0, 12.0)
	loop = r.flag("loop", true)
