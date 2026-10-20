class_name ActionDef
extends Def
## One battle technique: its cost, power, and what it does to the timeline (cast speed, recovery,
## knockback, cancel). Timeline numbers are in timeline units (Timeline.ACT_POINT = 10000).

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


func references() -> Array[Array]:
	if applies_status == &"":
		return []
	return [["status", applies_status]]
