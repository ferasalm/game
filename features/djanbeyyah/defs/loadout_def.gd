class_name LoadoutDef
extends Def
## A hero's starting gear: which hilt, blade and prosthetic they own and wear at the start (each optional).
## Zayd's loadout is the djanbeyyah pair plus his prosthetic; Bilqis has only a prosthetic.

var hero: StringName = &"zayd"
var hilt: StringName = &""
var blade: StringName = &""
var prosthetic: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	hero = StringName(r.text("hero", "zayd", false))
	hilt = StringName(r.text("hilt", "", false))
	blade = StringName(r.text("blade", "", false))
	prosthetic = StringName(r.text("prosthetic", "", false))


## The ids of the items in this loadout.
func item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for item_id: StringName in [hilt, blade, prosthetic]:
		if item_id != &"":
			out.append(item_id)
	return out


func references() -> Array[Array]:
	var out: Array[Array] = [["combatant", hero]]
	for item_id: StringName in item_ids():
		out.append(["item", item_id])
	return out
