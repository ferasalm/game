class_name UpgradeCostsDef
extends Def
## purpose: Defines upgrade progression costs (riyal, rarity multipliers, and materials per level).

var max_level: int = 3
var riyal: Array[int] = []
var rarity_factor: Dictionary[StringName, float] = {}
var materials: Array[Dictionary] = []


func read(r: DefReader) -> void:
	id = r.id()
	max_level = r.integer("max_level", 1, 10, 3, false)
	riyal = r.int_list("riyal", 0, 99999)
	rarity_factor.clear()
	if r.has("rarity_factor"):
		var raw: Dictionary[String, String] = r.text_map("rarity_factor")
		for r_key: String in raw:
			rarity_factor[StringName(r_key)] = raw[r_key].to_float()
	materials.clear()
	if r.has("materials"):
		for obj: DefReader in r.objects("materials"):
			var step: Dictionary[StringName, int] = {}
			for mat_key: Variant in obj._data:
				step[StringName(str(mat_key))] = int(obj._data[mat_key])
			materials.append(step)


func references() -> Array[Array]:
	var out: Array[Array] = []
	for r_id: StringName in rarity_factor:
		out.append(["rarity", r_id])
	for step: Dictionary in materials:
		for mat_id: Variant in step:
			out.append(["material", mat_id as StringName])
	return out
