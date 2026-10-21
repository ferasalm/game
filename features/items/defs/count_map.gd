class_name CountMap
extends RefCounted
## Reads an optional {"id": count} JSON object (rewards, the start bag) as {StringName: int}, each count 1 or more.


static func read(r: DefReader, key: String) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	if not r.has(key):
		return out
	var raw: Dictionary[String, String] = r.text_map(key)
	for item_id: String in raw:
		var count: float = raw[item_id].to_float()  # JSON numbers arrive as floats
		if not raw[item_id].is_valid_float() or count < 1.0 or count != floorf(count):
			r.problem(key, "'%s' needs a whole count of 1 or more" % item_id)
		else:
			out[StringName(item_id)] = roundi(count)
	return out


## [["consumable", id], ...] for ContentDB's dangling-id check.
static func references(counts: Dictionary[StringName, int]) -> Array[Array]:
	var out: Array[Array] = []
	for item_id: StringName in counts:
		out.append(["consumable", item_id])
	return out
