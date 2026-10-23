class_name CityDistrictDef
extends Def
## purpose: Defines a city district with polygon boundaries in metres.

var name_key: String = ""
var polygon: PackedVector2Array = PackedVector2Array()
var is_old_city: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	is_old_city = r.flag("is_old_city", false)
	polygon = PackedVector2Array()
	var raw_data: Dictionary = r.get("_data") as Dictionary
	if raw_data.has("polygon") and raw_data["polygon"] is Array:
		for pt: Variant in (raw_data["polygon"] as Array):
			if pt is Array and (pt as Array).size() >= 2:
				polygon.append(Vector2(float((pt as Array)[0]), float((pt as Array)[1])))
	if polygon.size() < 3:
		r.problem("polygon", "needs at least 3 points")


func references() -> Array[Array]:
	return []
