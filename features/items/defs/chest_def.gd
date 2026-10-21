class_name ChestDef
extends Def
## A chest holding an equippable (an id of a hilt, blade or prosthetic), riyal and/or consumables; at least one.
## "place" tells which spot opens it, e.g. "workshop" (the bench stock, given when the workshop first opens) or
## "rooftop" (placed on the map).

var item: StringName = &""
var money: int = 0
var consumables: Dictionary[StringName, int] = {}
var place: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	item = r.id("item") if r.has("item") else &""
	money = r.integer("money", 0, 9999, 0, false)
	consumables = CountMap.read(r, "consumables")
	place = r.id("place")
	if item == &"" and money == 0 and consumables.is_empty():
		r.problem("item", "a chest needs an item, money or consumables")


func references() -> Array[Array]:
	var out: Array[Array] = CountMap.references(consumables)
	if item != &"":
		out.append(["item", item])
	return out
