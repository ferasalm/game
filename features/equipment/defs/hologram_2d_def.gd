class_name Hologram2dDef
extends Def
## purpose: Anchor points of a 2D menu hologram as fractions of its rect (0..1 from the left and the top).

const ANCHORS: Array[StringName] = [
	&"feet", &"hand", &"hand_left", &"head", &"chest", &"belt", &"hip", &"arm", &"arm_left",
]

var anchors: Dictionary[StringName, Vector2] = {}


func read(r: DefReader) -> void:
	id = r.id()
	for anchor_name: StringName in ANCHORS:
		var point: Array[float] = r.float_list(String(anchor_name), 0.0, 1.0)
		if point.size() == 2:
			anchors[anchor_name] = Vector2(point[0], point[1])
		else:
			r.problem(String(anchor_name), "needs two fractions")


## The anchor's fraction of the hologram rect (the centre when the content has no such anchor).
func anchor(anchor_name: StringName) -> Vector2:
	return anchors.get(anchor_name, Vector2(0.5, 0.5))
