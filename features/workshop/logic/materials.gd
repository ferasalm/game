class_name Materials
extends RefCounted
## purpose: Pure inventory math for crafting and upgrade materials, capped at 99.

const CAP: int = 99


## Adds n of material id into the materials dictionary, clamped between 0 and CAP (99).
static func add(materials: Dictionary, id: StringName, n: int) -> int:
	var cur: int = int(materials.get(id, 0))
	var next: int = clampi(cur + n, 0, CAP)
	materials[id] = next
	return next


## Deducts n of material id from the materials dictionary if sufficient, returns true on success.
static func remove(materials: Dictionary, id: StringName, n: int) -> bool:
	var cur: int = int(materials.get(id, 0))
	if cur < n:
		return false
	materials[id] = cur - n
	return true


## Current quantity of material id held in the dictionary.
static func count(materials: Dictionary, id: StringName) -> int:
	return int(materials.get(id, 0))
