class_name MusicLogic
extends RefCounted
## Pure rules for music playback: fallback resolution when audio files are missing, and mapping screen ids.


## Resolves which MusicDef to play: if the track's file exists, returns it. If missing and it has a fallback,
## checks the fallback (and chains). Returns null if the track and its fallbacks are missing or cycle.
static func resolve_track(
	track_id: StringName,
	defs: Dictionary,
	exists_check: Callable
) -> MusicDef:
	var current_id: StringName = track_id
	var visited: Array[StringName] = []
	while current_id != &"" and not visited.has(current_id):
		visited.append(current_id)
		var def: MusicDef = defs.get(current_id) as MusicDef
		if def == null:
			return null
		if exists_check.call(def.path):
			return def
		current_id = def.fallback
	return null
