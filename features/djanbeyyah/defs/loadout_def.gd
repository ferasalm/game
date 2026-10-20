class_name LoadoutDef
extends Def
## A named djanbeyyah pair (hilt id + blade id), such as Zayd's starting gear.

var hilt: StringName = &""
var blade: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	hilt = r.id("hilt")
	blade = r.id("blade")


func references() -> Array[Array]:
	return [["hilt", hilt], ["blade", blade]]
