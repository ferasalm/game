class_name PlaytestLogRing
extends RefCounted
## purpose: The newest engine log lines of a playtest capture, capped so a long session stays small.

const CAP: int = 50

var _lines: Array[String] = []


func push(line: String) -> void:
	_lines.append(line)
	while _lines.size() > CAP:
		_lines.remove_at(0)


func lines() -> Array[String]:
	return _lines.duplicate()


func clear() -> void:
	_lines.clear()
