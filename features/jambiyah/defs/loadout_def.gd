class_name LoadoutDef
extends Def
## A hero's starting gear: which weapon parts, prosthetic and accessory they own and wear at the start
## (each optional). Rydan's loadout is the jambiyah pair plus his prosthetic and ring; Bilqis has the rivet
## pistol pair, her prosthetic and a ring.

var hero: StringName = &"rydan"
var hilt: StringName = &""
var blade: StringName = &""
var prosthetic: StringName = &""
var frame: StringName = &""
var barrel: StringName = &""
var accessory: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	hero = StringName(r.text("hero", "rydan", false))
	hilt = StringName(r.text("hilt", "", false))
	blade = StringName(r.text("blade", "", false))
	prosthetic = StringName(r.text("prosthetic", "", false))
	frame = StringName(r.text("frame", "", false))
	barrel = StringName(r.text("barrel", "", false))
	accessory = StringName(r.text("accessory", "", false))


## The ids of the items in this loadout.
func item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for item_id: StringName in [hilt, blade, prosthetic, frame, barrel, accessory]:
		if item_id != &"":
			out.append(item_id)
	return out


func references() -> Array[Array]:
	var out: Array[Array] = [["combatant", hero]]
	for item_id: StringName in item_ids():
		out.append(["item", item_id])
	return out
