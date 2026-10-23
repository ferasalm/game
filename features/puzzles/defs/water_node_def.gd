class_name WaterNodeDef
extends RefCounted
## purpose: One node in a water network puzzle (source, split, gate, spout, or outlet).

const KINDS: Array[StringName] = [&"source", &"split", &"gate", &"spout", &"outlet"]
const REACTIONS: Array[StringName] = [&"return", &"dock", &"goal"]

var id: StringName = &""
var kind: StringName = &""
var to: Array[StringName] = []
var open: bool = false
var jammed: bool = false
var start: int = 0
var spill_unless_shut: StringName = &""
var reaction: StringName = &""
var at: Vector3 = Vector3.ZERO


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	to = r.id_list("to")
	open = r.flag("open", false)
	jammed = r.flag("jammed", false)
	start = r.integer("start", 0, 1, 0, false)
	spill_unless_shut = StringName(r.text("spill_unless_shut", "", false))
	reaction = StringName(r.text("reaction", "", false))
	at = PuzzleDefCoords.vec3(r, "at")
	if kind == &"outlet" and not reaction.is_empty() and not REACTIONS.has(reaction):
		r.problem("reaction", "'%s' is not one of %s" % [reaction, REACTIONS])
