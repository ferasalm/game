class_name ProstheticDef
extends EquipDef
## A high-tech prosthetic: one slot per hero. It adds to the wearer's stats and grants 1-2 tech moves (paid
## from SP), which replace "magic". The body part (arm, eye, spine, leg) is flavour only.

const PARTS: Array[StringName] = [&"arm", &"eye", &"spine", &"leg"]
const MAX_GRANTED: int = 2

## The combatant id that can wear it.
var wearer: StringName = &""
var part: StringName = &"arm"
var hp: int = 0
var sp: int = 0
var attack: int = 0
var defense: int = 0
var agility: int = 0
var weight: float = 0.0
var actions: Array[StringName] = []


func read(r: DefReader) -> void:
	read_gear(r)
	wearer = r.id("wearer")
	part = r.one_of("part", PARTS)
	hp = r.integer("hp", -999, 999, 0, false)
	sp = r.integer("sp", -99, 99, 0, false)
	attack = r.integer("attack", -99, 99, 0, false)
	defense = r.integer("defense", -99, 99, 0, false)
	agility = r.integer("agility", -50, 50, 0, false)
	weight = r.number("weight", -30.0, 30.0, 0.0, false)
	actions = r.id_list("actions")
	if actions.is_empty() or actions.size() > MAX_GRANTED:
		r.problem("actions", "needs 1 to %d moves" % MAX_GRANTED)


func references() -> Array[Array]:
	var out: Array[Array] = gear_references()
	out.append(["combatant", wearer])
	for action_id: StringName in actions:
		out.append(["action", action_id])
	return out
