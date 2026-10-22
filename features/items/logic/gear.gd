class_name Gear
extends RefCounted
## Builds a hero's fighter from the shared base plus worn gear: base -> hilt -> blade -> prosthetic -> perks
## (caps are applied by each step). Pure; the shared CombatantDef is never mutated.


## hilt and blade go together (Zayd's jambiyah); either may be null for a hero without one. prosthetic may be null.
static func build(
		base: CombatantDef, hilt: HiltDef, blade: BladeDef, prosthetic: ProstheticDef,
		perks: Dictionary[StringName, PerkDef]) -> CombatantDef:
	var out: CombatantDef = base
	if hilt != null and blade != null:
		out = Jambiyah.equip(out, hilt, blade)
	if prosthetic != null:
		out = Prosthetics.equip(out, prosthetic)
	var worn: Array[EquipDef] = [hilt, blade, prosthetic]
	return Perks.apply(out, Perks.of_items(worn, perks))
