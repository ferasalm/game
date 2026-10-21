class_name PropDef
extends Def
## A rooftop prop as data (content/world/props.json): a list of simple parts (PropPart), an optional practical
## light it carries, an optional box that blocks walking (collide = width, height, depth, centred on the
## prop's base) and, for a chest, the lid's hinge (lid_hinge x, y, z) so the "lid" part group can swing open.

var parts: Array[PropPart] = []
var light: LightSpec = null
var splash: PropSplash = null
var collide: Vector3 = Vector3.ZERO
var chest: bool = false
var lid_hinge: Vector3 = Vector3.ZERO
## Blinks per second of the parts marked blink.
var blink_rate: float = 0.8


func read(r: DefReader) -> void:
	id = r.id()
	for part_reader: DefReader in r.objects("parts"):
		var part := PropPart.new()
		part.read(part_reader)
		parts.append(part)
	if r.has("light"):
		light = LightSpec.new()
		light.read(r.child("light"))
	if r.has("splash"):
		splash = PropSplash.new()
		splash.read(r.child("splash"))
	var box: Array[float] = r.float_list("collide", 0.0, 50.0)
	if box.size() == 3:
		collide = Vector3(box[0], box[1], box[2])
	chest = r.flag("chest")
	blink_rate = r.number("blink_rate", 0.05, 10.0, 0.8, false)
	var hinge: Array[float] = r.float_list("lid_hinge", -10.0, 10.0)
	if hinge.size() == 3:
		lid_hinge = Vector3(hinge[0], hinge[1], hinge[2])


func has_group(group: StringName) -> bool:
	for part: PropPart in parts:
		if part.group == group:
			return true
	return false
