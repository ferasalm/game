class_name MaterialDef
extends Def
## purpose: Defines a crafting or upgrade material with rarity and display information.

var name_key: String = ""
var desc_key: String = ""
var rarity: StringName = &""
var icon: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	rarity = r.id("rarity")
	icon = StringName(r.text("icon", "", false))


func references() -> Array[Array]:
	return [["rarity", rarity]]
