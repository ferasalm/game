class_name ChestDef
extends Def
## A chest holding one item (an id of a hilt, blade or prosthetic). "place" tells which spot opens it, e.g.
## "workshop" (the bench stock, given when the workshop first opens) or "rooftop" (placed on the map later).

var item: StringName = &""
var place: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	item = r.id("item")
	place = r.id("place")


func references() -> Array[Array]:
	return [["item", item]]
