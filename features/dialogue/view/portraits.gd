class_name Portraits
extends RefCounted
## Finds the portrait texture for (speaker, expression): res://assets/portraits/<speaker>_<expression>.png when it
## exists (loaded straight from the file, the "keep" importer needs no import step), else a stand-in disc with the
## expression's brows and mouth (StandinPortrait). Sprite pixels are never cropped.

const FOLDER: String = "res://assets/portraits"

static var _cache: Dictionary[String, Texture2D] = {}


static func path_for(speaker: StringName, expression: StringName) -> String:
	return "%s/%s_%s.png" % [FOLDER, speaker, expression]


static func has_real(speaker: StringName, expression: StringName) -> bool:
	return FileAccess.file_exists(path_for(speaker, expression))


## Null only when the speaker, its sprite or the dialogue style is missing from ContentDB.
static func texture(speaker: StringName, expression: StringName) -> Texture2D:
	var key: String = "%s_%s" % [speaker, expression]
	if not _cache.has(key):
		var made: Texture2D = _load_real(speaker, expression)
		if made == null:
			made = _standin(speaker, expression)
		if made == null:
			return null
		_cache[key] = made
	return _cache[key]


static func clear_cache() -> void:
	_cache.clear()


static func standin_image(speaker: StringName, expression: StringName) -> Image:
	var def := ContentDB.get_def("speaker", speaker) as SpeakerDef
	var style := ContentDB.get_def("dialogue_style", &"default") as DialogueStyleDef
	if def == null or style == null:
		return null
	return StandinPortrait.image(def, expression, style)


static func _load_real(speaker: StringName, expression: StringName) -> Texture2D:
	if not has_real(speaker, expression):
		return null
	var loaded: Image = Image.load_from_file(path_for(speaker, expression))
	return null if loaded == null else ImageTexture.create_from_image(loaded)


static func _standin(speaker: StringName, expression: StringName) -> Texture2D:
	var made: Image = standin_image(speaker, expression)
	return null if made == null else ImageTexture.create_from_image(made)
