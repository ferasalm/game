extends Node
## All authored game data (autoload ContentDB). Loads every res://content/**/*.json once, builds typed and
## validated definitions, then checks that every id a definition points to exists. Read-only during play.
## A content file is {"kind": "<kind>", "items": [{...}, ...]}; KINDS maps each kind to its Def class.

const CONTENT_ROOT: String = "res://content"
const KINDS: Dictionary = {
	"action": preload("res://features/combat/defs/action_def.gd"),
	"status": preload("res://features/combat/defs/status_def.gd"),
	"combatant": preload("res://features/combat/defs/combatant_def.gd"),
	"palette": preload("res://features/art/defs/palette_def.gd"),
	"sprite": preload("res://features/art/defs/sprite_def.gd"),
	"visual_rules": preload("res://features/art/defs/visual_rules_def.gd"),
	"speaker": preload("res://features/dialogue/defs/speaker_def.gd"),
	"dialogue": preload("res://features/dialogue/defs/dialogue_def.gd"),
	"dialogue_style": preload("res://features/dialogue/defs/dialogue_style_def.gd"),
	"look": preload("res://features/world/defs/look_def.gd"),
	"tile": preload("res://features/world/defs/tile_def.gd"),
	"area": preload("res://features/world/defs/area_def.gd"),
	"explore_rules": preload("res://features/world/defs/explore_rules_def.gd"),
}

var _defs: Dictionary[String, Dictionary] = {}


func _ready() -> void:
	for problem: String in load_all():
		push_error("ContentDB: " + problem)


## Loads everything under root and returns every problem found (empty means valid).
func load_all(root: String = CONTENT_ROOT) -> PackedStringArray:
	_defs.clear()
	var errors := PackedStringArray()
	for path: String in _json_files(root):
		_load_file(path, errors)
	_check_references(errors)
	return errors


func get_def(kind: String, def_id: StringName) -> Def:
	return (_defs.get(kind, {}) as Dictionary).get(def_id) as Def


func ids(kind: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in (_defs.get(kind, {}) as Dictionary):
		out.append(key as StringName)
	return out


func _load_file(path: String, errors: PackedStringArray) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		errors.append("%s: not a JSON object" % path)
		return
	var kind: String = str((parsed as Dictionary).get("kind", ""))
	if not KINDS.has(kind):
		errors.append("%s: unknown kind '%s'" % [path, kind])
		return
	var items: Variant = (parsed as Dictionary).get("items")
	if not (items is Array):
		errors.append("%s: 'items' is not a list" % path)
		return
	var table: Dictionary = _defs.get_or_add(kind, {})
	for i: int in (items as Array).size():
		var where: String = "%s[%d]" % [path.get_file(), i]
		if not ((items as Array)[i] is Dictionary):
			errors.append(where + ": not an object")
			continue
		var def := (KINDS[kind] as GDScript).new() as Def
		def.read(DefReader.new((items as Array)[i] as Dictionary, where, errors))
		if table.has(def.id):
			errors.append("%s: duplicate %s id '%s'" % [where, kind, def.id])
		table[def.id] = def


func _check_references(errors: PackedStringArray) -> void:
	for kind: String in _defs:
		for def: Def in _defs[kind].values():
			for ref: Array in def.references():
				if get_def(str(ref[0]), ref[1] as StringName) == null:
					errors.append("%s '%s' needs missing %s '%s'" % [kind, def.id, ref[0], ref[1]])


func _json_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir_path):
		out.append_array(_json_files(dir_path.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".json"):
			out.append(dir_path.path_join(file))
	return out
