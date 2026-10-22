class_name ScreenMusicDef
extends Def
## Maps one screen id (from the Screens stack) to the music track id it plays while open.

var music: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	music = r.id("music")


func references() -> Array:
	return [["music", music]]
