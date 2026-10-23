class_name ActionDef
extends Def
## One battle technique: its cost, power, who it targets, and what it does to the timeline (cast speed,
## recovery, knockback, cancel). Timeline numbers are in timeline units (Timeline.ACT_POINT = 10000).
## Foe moves hit (power); ally moves heal (heal) and/or apply a status. Tech moves from prosthetics use these.

const TARGETS: Array[StringName] = [&"foe", &"ally", &"self", &"all_foes", &"all_allies"]
## The effect a later VFX phase draws; empty lets the view pick by melee / ranged.
const VFX_KINDS: Array[StringName] = [
	&"slash", &"heavy_slash", &"stab", &"piston", &"beam", &"bolt", &"arc_all", &"burst", &"heal", &"shield",
	&"overclock", &"net", &"drone_shot", &"baton", &"none"]

var name_key: String = ""
var desc_key: String = ""
var sp_cost: int = 0
var power: int = 0
var hit_count: int = 1
var is_melee: bool = true
var ignores_cover: bool = false
var cast_speed: float = 1.0
var recovery: int = 0
var knockback: int = 0
var cancels_cast: bool = false
var applies_status: StringName = &""
## foe (default) | ally | self | all_foes | all_allies. All-target moves resolve once per living target.
var target: StringName = &"foe"
## HP restored to a friendly target (plus the actor's attack times the rules' heal_attack_factor).
var heal: int = 0
## A heal that may also target a downed ally and stand it up.
var revive: bool = false
var vfx: StringName = &""
## Status ids removed from each target this move reaches (friendly moves only).
var cures: Array[StringName] = []
## Maximum times this move can be chosen per battle (0 = unlimited).
var uses_per_battle: int = 0
## Never dodged (e.g. reverse stab skips dodge anyway; a forced sure_hit always lands).
var sure_hit: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key", "", false)
	sp_cost = r.integer("sp_cost", 0, 999)
	power = r.integer("power", 0, 9999)
	hit_count = r.integer("hit_count", 1, 9, 1, false)
	is_melee = r.flag("is_melee", true)
	ignores_cover = r.flag("ignores_cover")
	cast_speed = r.number("cast_speed", 0.1, 5.0)
	recovery = r.integer("recovery", 0, 5000)
	knockback = r.integer("knockback", 0, 10000)
	cancels_cast = r.flag("cancels_cast")
	applies_status = StringName(r.text("applies_status", "", false))
	heal = r.integer("heal", 0, 9999, 0, false)
	revive = r.flag("revive")
	cures = r.id_list("cures")
	uses_per_battle = r.integer("uses_per_battle", 0, 99, 0, false)
	sure_hit = r.flag("sure_hit")
	_read_target_and_vfx(r)


## True for moves that strike foes (foe, all_foes); false for moves on the actor's own side.
func is_hostile() -> bool:
	return target == &"foe" or target == &"all_foes"


## True when the player (or AI) picks one unit: foe and ally moves. Self and all-moves need no pick.
func needs_picker() -> bool:
	return target == &"foe" or target == &"ally"


func references() -> Array[Array]:
	var out: Array[Array] = []
	if applies_status != &"":
		out.append(["status", applies_status])
	for status_id: StringName in cures:
		out.append(["status", status_id])
	return out


func _read_target_and_vfx(r: DefReader) -> void:
	target = StringName(r.text("target", "foe", false))
	if not TARGETS.has(target):
		r.problem("target", "'%s' is not one of %s" % [target, TARGETS])
	vfx = StringName(r.text("vfx", "", false))
	if vfx != &"" and not VFX_KINDS.has(vfx):
		r.problem("vfx", "'%s' is not one of %s" % [vfx, VFX_KINDS])
	if is_hostile() and (heal > 0 or revive):
		r.problem("heal", "a move on foes cannot heal or revive")
	if is_hostile() and not cures.is_empty():
		r.problem("cures", "a move on foes cannot cure statuses")
	if not is_hostile() and (power > 0 or cancels_cast):
		r.problem("power", "a move on the actor's side cannot hurt or cancel (power 0)")
	if revive and (heal <= 0 or target != &"ally"):
		r.problem("revive", "needs heal above 0 and target ally")
