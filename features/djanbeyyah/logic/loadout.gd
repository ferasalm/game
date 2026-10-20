class_name Loadout
extends RefCounted
## Which hilt and blade Zayd wears: the saved choice per slot, else the starting pair. Pure.


## Returns [hilt_id, blade_id]; a missing or empty slot falls back to the start pair.
static func current(equipment: Dictionary[StringName, StringName], start: LoadoutDef) -> Array[StringName]:
	var hilt: StringName = equipment.get(&"hilt", &"")
	var blade: StringName = equipment.get(&"blade", &"")
	var out: Array[StringName] = []
	out.append(hilt if hilt != &"" else start.hilt)
	out.append(blade if blade != &"" else start.blade)
	return out
