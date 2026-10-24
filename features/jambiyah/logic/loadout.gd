class_name Loadout
extends RefCounted
## Which gear a hero wears: the saved choice per slot ("<hero>.<part>" in GameState.equipment), else the
## starting gear. Pure.


## Returns [hilt_id, blade_id]; a missing or empty slot falls back to the start loadout.
static func current(equipment: Dictionary[StringName, StringName], start: LoadoutDef) -> Array[StringName]:
	var out: Array[StringName] = []
	out.append(worn(equipment, start, &"hilt"))
	out.append(worn(equipment, start, &"blade"))
	return out


## The item worn in one part slot ("hilt", "blade", "frame", "barrel", "accessory", "prosthetic") or
## &"" when neither saved nor in the start gear.
static func worn(equipment: Dictionary[StringName, StringName], start: LoadoutDef, part: StringName) -> StringName:
	var saved: StringName = equipment.get(Inventory.slot_key(start.hero, part), &"")
	if saved != &"":
		return saved
	match part:
		&"hilt":
			return start.hilt
		&"blade":
			return start.blade
		&"frame":
			return start.frame
		&"barrel":
			return start.barrel
		&"accessory":
			return start.accessory
		&"prosthetic":
			return start.prosthetic
	return &""
