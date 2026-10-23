class_name MapInfoDef
extends Def
## purpose: Defines map metadata including coordinates and sector key.

var coordinates: String = ""
var sector_key: String = ""


func read(r: DefReader) -> void:
	id = r.id()
	coordinates = r.text("coordinates")
	sector_key = r.text("sector_key")


func references() -> Array[Array]:
	return []
