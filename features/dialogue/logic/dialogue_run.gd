class_name DialogueRun
extends RefCounted
## Steps through a DialogueDef one line at a time. Pure: it knows the position, not the box or the text.

var _def: DialogueDef
var _index: int = 0


func _init(def: DialogueDef) -> void:
	_def = def


## The line now shown, or null when the dialogue is empty or finished.
func current() -> DialogueLine:
	return null if is_finished() else _def.lines[_index]


func index() -> int:
	return _index


func line_count() -> int:
	return _def.lines.size()


func is_finished() -> bool:
	return _index >= _def.lines.size()


## Moves to the next line; returns true while a line remains to show, false once the dialogue is finished.
func advance() -> bool:
	if not is_finished():
		_index += 1
	return not is_finished()
