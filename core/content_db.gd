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
	"talk": preload("res://features/dialogue/defs/talk_def.gd"),
	"look": preload("res://features/world/defs/look_def.gd"),
	"tile": preload("res://features/world/defs/tile_def.gd"),
	"area": preload("res://features/world/defs/area_def.gd"),
	"explore_rules": preload("res://features/world/defs/explore_rules_def.gd"),
	"sky": preload("res://features/world/defs/sky_def.gd"),
	"mist": preload("res://features/world/defs/mist_def.gd"),
	"storm": preload("res://features/world/weather/defs/storm_def.gd"),
	"camera_rig": preload("res://features/world/defs/camera_rig_def.gd"),
	"battle_rules": preload("res://features/combat/defs/battle_rules_def.gd"),
	"encounter": preload("res://features/combat/defs/encounter_def.gd"),
	"battle_view": preload("res://features/combat/defs/battle_view_def.gd"),
	"hilt": preload("res://features/jambiyah/defs/hilt_def.gd"),
	"blade": preload("res://features/jambiyah/defs/blade_def.gd"),
	"loadout": preload("res://features/jambiyah/defs/loadout_def.gd"),
	"sound": preload("res://features/audio/defs/sound_def.gd"),
	"music": preload("res://features/audio/defs/music_def.gd"),
	"screen_music": preload("res://features/audio/defs/screen_music_def.gd"),
	"audio_rules": preload("res://features/audio/defs/audio_rules_def.gd"),
	"building": preload("res://features/world/defs/building_def.gd"),
	"skyline": preload("res://features/world/defs/skyline_def.gd"),
	"prop": preload("res://features/world/defs/prop_def.gd"),
	"rarity": preload("res://features/items/defs/rarity_def.gd"),
	"perk": preload("res://features/items/defs/perk_def.gd"),
	"chest": preload("res://features/items/defs/chest_def.gd"),
	"prosthetic": preload("res://features/prosthetics/defs/prosthetic_def.gd"),
	"vfx": preload("res://features/combat/defs/vfx_def.gd"),
	"battle_juice": preload("res://features/combat/defs/juice_def.gd"),
	"battle_camera": preload("res://features/combat/defs/battle_camera_def.gd"),
	"ui_style": preload("res://features/ui/defs/ui_style_def.gd"),
	"consumable": preload("res://features/items/defs/consumable_def.gd"),
	"economy_rules": preload("res://features/items/defs/economy_rules_def.gd"),
	"shop": preload("res://features/items/defs/shop_def.gd"),
	"arena": preload("res://features/combat/defs/arena_def.gd"),
	"transition": preload("res://core/defs/transition_def.gd"),
	"model": preload("res://features/art/defs/model_def.gd"),
	"clip": preload("res://features/art/defs/clip_def.gd"),
	"camera_preset": preload("res://features/world/defs/camera_preset_def.gd"),
	"place": preload("res://features/world/defs/place_def.gd"),
	"flow_rules": preload("res://core/defs/flow_rules_def.gd"),
	"levels": preload("res://features/progression/defs/levels_def.gd"),
	"class": preload("res://features/progression/defs/class_def.gd"),
	"armor": preload("res://features/items/defs/armor_def.gd"),
	"stone": preload("res://features/jambiyah/defs/stone_def.gd"),
	"heirloom": preload("res://features/jambiyah/defs/heirloom_def.gd"),
	"backdrop": preload("res://features/ui/defs/backdrop_def.gd"),
	"material": preload("res://features/items/defs/material_def.gd"),
	"upgrade_costs": preload("res://features/workshop/defs/upgrade_costs_def.gd"),
	"recipe": preload("res://features/workshop/defs/recipe_def.gd"),
	"light_lock": preload("res://features/puzzles/defs/light_lock_def.gd"),
	"water_net": preload("res://features/puzzles/defs/water_net_def.gd"),
}
## Equippable kinds share one id namespace; get_def("item", id) finds any of them.
const ITEM_KINDS: Array[String] = ["hilt", "blade", "prosthetic", "armor"]

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
	if kind == "item":
		for item_kind: String in ITEM_KINDS:
			var found: Def = get_def(item_kind, def_id)
			if found != null:
				return found
		return null
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
