class_name Def
extends RefCounted
## Base of every content definition: an id, how it reads itself from JSON, and which other ids it needs.
## Definitions are read-only after loading; anything that changes during play lives in a state object.

var id: StringName = &""


func read(_r: DefReader) -> void:
	pass


## Other definitions this one points to, as [kind, id] pairs, so ContentDB can report dangling ids.
func references() -> Array[Array]:
	return []
