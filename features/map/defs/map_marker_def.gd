class_name MapMarkerDef
extends Def
## purpose: Defines a map marker pointing to a place (kind npc, vendor, quest) and optional quest flag.

const NPC: StringName = &"npc"
const VENDOR: StringName = &"vendor"
const QUEST: StringName = &"quest"
const KINDS: Array[StringName] = [NPC, VENDOR, QUEST]

var place: StringName = &""
var kind: StringName = &""
var flag: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	place = StringName(r.text("place", String(id), false))
	kind = r.one_of("kind", KINDS)
	flag = StringName(r.text("flag", "", false))


func references() -> Array[Array]:
	return []
