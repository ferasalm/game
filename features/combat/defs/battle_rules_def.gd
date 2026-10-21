class_name BattleRulesDef
extends Def
## The tunable numbers of one battle ruleset: damage and heal formula factors, SP gain, the stall guard,
## start ranges and the two thresholds BattleAI uses for heals and guards.

var defense_factor: float = 0.5
var damage_variance: float = 0.1
var sp_per_act: int = 0
var max_ticks: int = 20000
var party_start_min: int = 0
var party_start_max: int = 0
var enemy_start_min: int = 0
var enemy_start_max: int = 0
## A heal restores heal + attack * heal_attack_factor.
var heal_attack_factor: float = 0.0
## BattleAI heals a living ally below this share of max HP.
var ai_heal_below: float = 0.4
## BattleAI guards when a foe is casting a move with power x hits at or above this.
var ai_big_cast_power: int = 25


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
	heal_attack_factor = r.number("heal_attack_factor", 0.0, 5.0, 0.0, false)
	ai_heal_below = r.number("ai_heal_below", 0.0, 1.0, 0.4, false)
	ai_big_cast_power = r.integer("ai_big_cast_power", 0, 9999, 25, false)
	if party_start_min > party_start_max or enemy_start_min > enemy_start_max:
		r.problem("party_start_min", "a start range has min above max")
