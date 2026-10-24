class_name PistolDef
extends EquipDef
## One part of Bilqis's rivet pistol (content/items/pistols.json): a frame (the grip: agility, cast speed,
## weight and an optional granted move, like a hilt) or a barrel (attack, knockback, weight, like a blade).

const PARTS: Array[StringName] = [&"frame", &"barrel"]

var part: StringName = &"frame"
var agility: int = 0
var cast_speed: float = 1.0
var attack: int = 0
var knockback: int = 0
var weight: float = 0.0
var ability: StringName = &""


func read(r: DefReader) -> void:
	read_gear(r)
	part = r.one_of("part", PARTS)
	agility = r.integer("agility", -50, 50, 0, false)
	cast_speed = r.number("cast_speed", CombatantDef.CAST_SPEED_MIN, CombatantDef.CAST_SPEED_MAX, 1.0, false)
	attack = r.integer("attack", -99, 999, 0, false)
	knockback = r.integer("knockback", 0, 10000, 0, false)
	weight = r.number("weight", -30.0, 30.0, 0.0, false)
	ability = StringName(r.text("ability", "", false))
	if part == &"frame" and (r.has("attack") or r.has("knockback")):
		r.problem("part", "a frame takes agility, cast_speed, weight and ability only")
	if part == &"barrel" and (r.has("agility") or r.has("cast_speed") or r.has("ability")):
		r.problem("part", "a barrel takes attack, knockback and weight only")


func references() -> Array[Array]:
	var out: Array[Array] = gear_references()
	if ability != &"":
		out.append(["action", ability])
	return out
