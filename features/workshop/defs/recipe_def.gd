class_name RecipeDef
extends Def
## purpose: Defines a workshop crafting recipe producing consumables or gemstones.

var output: StringName = &""
var count: int = 1
var riyal: int = 0
var materials: Dictionary[StringName, int] = {}


func read(r: DefReader) -> void:
	id = r.id()
	output = r.id("output")
	count = r.integer("count", 1, 99, 1, false)
	riyal = r.integer("riyal", 0, 99999, 0, false)
	materials = CountMap.read(r, "materials")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for mat_id: StringName in materials:
		out.append(["material", mat_id])
	if ContentDB.get_def("consumable", output) != null:
		out.append(["consumable", output])
	elif ContentDB.get_def("stone", output) != null:
		out.append(["stone", output])
	elif ContentDB.get_def("item", output) != null:
		out.append(["item", output])
	else:
		out.append(["consumable", output])
	return out
