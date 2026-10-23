class_name DialogueRun
extends RefCounted
## Steps through a DialogueDef one line at a time. Pure: it knows the position, not the box or the text.

var _def: DialogueDef
var _index: int = 0
var _chosen: DialogueChoice = null


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


## The choices offered on the current line, or an empty list if none.
func choices() -> Array[DialogueChoice]:
	var line: DialogueLine = current()
	return line.choices if line != null else []


## True if the current line offers player choices.
func has_choices() -> bool:
	return not choices().is_empty()


## The choice selected via choose(), or null if none made yet.
func chosen() -> DialogueChoice:
	return _chosen


## Selects a choice by index, records it, and finishes the dialogue run.
func choose(choice_index: int) -> DialogueChoice:
	var list: Array[DialogueChoice] = choices()
	if choice_index < 0 or choice_index >= list.size():
		return null
	_chosen = list[choice_index]
	_index = _def.lines.size()
	return _chosen


## Moves to the next line; returns true while a line remains to show, false once the dialogue is finished.
## Does not advance past a line that has unpicked choices.
func advance() -> bool:
	if has_choices():
		return false
	if not is_finished():
		_index += 1
	return not is_finished()
