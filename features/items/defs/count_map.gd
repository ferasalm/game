class_name CountMap
extends RefCounted
## Reads an optional {"id": count} JSON object (rewards, the start bag) as {StringName: int}, each count 1 or more.


static func read(r: DefReader, key: String) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	if not r.has(key):
		return out
	var raw: Dictionary[String, String] = r.text_map(key)
	for item_id: String in raw:
		if not raw[item_id].is_valid_int() or int(raw[item_id]) < 1:
			r.problem(key, "'%s' needs a whole count of 1 or more" % item_id)
		else:
			out[StringName(item_id)] = int(raw[item_id])
	return out


## [["consumable", id], ...] for ContentDB's dangling-id check.
static func references(counts: Dictionary[StringName, int]) -> Array[Array]:
	var out: Array[Array] = []
	for item_id: StringName in counts:
		out.append(["consumable", item_id])
	return out
