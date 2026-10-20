class_name BattleRulesDef
extends Def
## The tunable numbers of one battle ruleset: damage formula factors, SP gain and the stall guard.

var defense_factor: float = 0.5
var damage_variance: float = 0.1
var sp_per_act: int = 0
var max_ticks: int = 20000
var party_start_min: int = 0
var party_start_max: int = 0
var enemy_start_min: int = 0
var enemy_start_max: int = 0


func read(r: DefReader) -> void:
	id = r.id()
	defense_factor = r.number("defense_factor", 0.0, 5.0)
	damage_variance = r.number("damage_variance", 0.0, 0.5)
	sp_per_act = r.integer("sp_per_act", 0, 99)
	max_ticks = r.integer("max_ticks", 100, 1000000)
	party_start_min = r.integer("party_start_min", 0, 6999, 0, false)
	party_start_max = r.integer("party_start_max", 0, 6999, 0, false)
	enemy_start_min = r.integer("enemy_start_min", 0, 6999, 0, false)
	enemy_start_max = r.integer("enemy_start_max", 0, 6999, 0, false)
	if party_start_min > party_start_max or enemy_start_min > enemy_start_max:
		r.problem("party_start_min", "a start range has min above max")
