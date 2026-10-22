class_name MusicStack
extends RefCounted
## Pure stack of open screen ids deciding which music track plays (content/audio/screen_music.json).
## Top screen wins; unmapped screens keep what is playing; an empty stack falls back to the base track.

var base_track: StringName = &""
var _stack: Array[StringName] = []
var _mappings: Dictionary[StringName, StringName] = {}


func _init(mappings: Dictionary[StringName, StringName] = {}, base: StringName = &"") -> void:
	_mappings = mappings.duplicate()
	base_track = base


func set_base_track(track_id: StringName) -> void:
	base_track = track_id


func set_mapping(screen_id: StringName, music_id: StringName) -> void:
	_mappings[screen_id] = music_id


func push(screen_id: StringName) -> void:
	_stack.append(screen_id)


func pop(screen_id: StringName = &"") -> void:
	if _stack.is_empty():
		return
	if screen_id.is_empty() or _stack[-1] == screen_id:
		_stack.pop_back()
	else:
		var index: int = _stack.rfind(screen_id)
		if index != -1:
			_stack.remove_at(index)


func clear() -> void:
	_stack.clear()


func depth() -> int:
	return _stack.size()


func top() -> StringName:
	return _stack[-1] if not _stack.is_empty() else &""


func current_track() -> StringName:
	for i: int in range(_stack.size() - 1, -1, -1):
		var screen_id: StringName = _stack[i]
		if _mappings.has(screen_id) and _mappings[screen_id] != &"":
			return _mappings[screen_id]
	return base_track
