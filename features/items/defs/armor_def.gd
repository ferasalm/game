class_name ArmorDef
extends EquipDef
## Armor worn in slot "<hero>.armor": raises HP, DEF, alters AGI and WT (content/items/armor.json).

var max_hp: int = 0
var defense: int = 0
var agility: int = 0
var weight: float = 0.0
var heroes: Array[StringName] = []


func read(r: DefReader) -> void:
	read_gear(r)
	max_hp = r.integer("max_hp", 0, 9999, 0, false)
	defense = r.integer("defense", 0, 999, 0, false)
	agility = r.integer("agility", -99, 99, 0, false)
	weight = r.number("weight", 0.0, 30.0, 0.0, false)
	heroes = r.id_list("heroes")


func references() -> Array[Array]:
	var out: Array[Array] = gear_references()
	for hero_id: StringName in heroes:
		out.append(["combatant", hero_id])
	return out
