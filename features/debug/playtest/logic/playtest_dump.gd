class_name PlaytestDump
extends RefCounted
## purpose: The JSON record of one playtest capture: time, scene, game state, the recent log and the note.

const NOTE_CAP: int = 300
const LOG_CAP: int = 50
const EVENT_CAP: int = 10


## The state.json object; note, log and fight events are capped so one capture stays small.
static func build(note: String, stamp: String, scene: String, source: Dictionary, log_lines: Array) -> Dictionary:
	return {
		"time": stamp,
		"scene": scene,
		"stage": plain(source.get("stage", "")),
		"room": plain(source.get("room", "")),
		"hero": plain(source.get("hero", [])),
		"fight": plain(source.get("fight", {})),
		"log": _recent(log_lines, LOG_CAP),
		"note": note.left(NOTE_CAP),
	}


## The fight block: the sim tick, every fighter and the newest events.
static func fight(ticks: int, fighters: Array, events: Array) -> Dictionary:
	return {"ticks": ticks, "fighters": plain(fighters), "events": _recent(events, EVENT_CAP)}


## Vectors become [x, y] with one decimal and StringNames become Strings, recursively.
static func plain(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2:
			var v: Vector2 = value
			return [snappedf(v.x, 0.1), snappedf(v.y, 0.1)]
		TYPE_STRING_NAME:
			return String(value)
		TYPE_ARRAY:
			var list: Array = []
			for item: Variant in value:
				list.append(plain(item))
			return list
		TYPE_DICTIONARY:
			var table: Dictionary = {}
			for key: Variant in value:
				table[plain(key)] = plain(value[key])
			return table
		_:
			return value


## A folder name from a system datetime and its milliseconds, without the colons Windows rejects.
static func folder_name(datetime_string: String, msec: int) -> String:
	var base: String = datetime_string.replace("T", "_").replace(":", "-")
	return "%s_%03d" % [base, clampi(msec, 0, 999)]


static func _recent(lines: Array, cap: int) -> Array:
	var out: Array = []
	var start: int = maxi(0, lines.size() - cap)
	for i: int in range(start, lines.size()):
		out.append(str(lines[i]))
	return out
