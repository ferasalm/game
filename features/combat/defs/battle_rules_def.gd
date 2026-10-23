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
## Timeline speed: weight slows a unit by weight x speed_weight_factor, never below speed_min_mult.
var speed_weight_factor: float = 0.015
var speed_min_mult: float = 0.5
## Melee row bonus/penalty (Formation) and the clamp on the product.
var melee_front_bonus: float = 0.15
var melee_back_penalty: float = 0.15
var melee_min: float = 0.5
var melee_max: float = 1.5
## Hit roll (docs/design/rpg-systems.md): chance before dodge.
var hit_base: float = 0.95
var hit_agi_k: float = 0.006
var hit_min: float = 0.60
var hit_max: float = 0.99
## Crit roll.
var crit_base: float = 0.05
var crit_lck_k: float = 0.004
var crit_max: float = 0.40
var crit_mult: float = 1.5
var crit_knockback: float = 1.25
## Resist roll.
var resist_base: float = 0.10
var resist_lck_k: float = 0.01
var resist_max: float = 0.75
## Flee roll.
var flee_base: float = 0.50
var flee_agi_k: float = 0.01
var flee_step: float = 0.15
var flee_ambushed: float = -0.20
var flee_ambusher: float = 0.20
var flee_min: float = 0.10
var flee_max: float = 0.95


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
	speed_weight_factor = r.number("speed_weight_factor", 0.0, 0.1, 0.015, false)
	speed_min_mult = r.number("speed_min_mult", 0.1, 1.0, 0.5, false)
	melee_front_bonus = r.number("melee_front_bonus", 0.0, 1.0, 0.15, false)
	melee_back_penalty = r.number("melee_back_penalty", 0.0, 1.0, 0.15, false)
	melee_min = r.number("melee_min", 0.1, 1.0, 0.5, false)
	melee_max = r.number("melee_max", 1.0, 5.0, 1.5, false)
	hit_base = r.number("hit_base", 0.0, 1.0, 0.95, false)
	hit_agi_k = r.number("hit_agi_k", 0.0, 0.05, 0.006, false)
	hit_min = r.number("hit_min", 0.0, 1.0, 0.60, false)
	hit_max = r.number("hit_max", 0.0, 1.0, 0.99, false)
	crit_base = r.number("crit_base", 0.0, 1.0, 0.05, false)
	crit_lck_k = r.number("crit_lck_k", 0.0, 0.05, 0.004, false)
	crit_max = r.number("crit_max", 0.0, 1.0, 0.40, false)
	crit_mult = r.number("crit_mult", 0.5, 5.0, 1.5, false)
	crit_knockback = r.number("crit_knockback", 0.5, 5.0, 1.25, false)
	resist_base = r.number("resist_base", 0.0, 1.0, 0.10, false)
	resist_lck_k = r.number("resist_lck_k", 0.0, 0.05, 0.01, false)
	resist_max = r.number("resist_max", 0.0, 1.0, 0.75, false)
	flee_base = r.number("flee_base", 0.0, 1.0, 0.50, false)
	flee_agi_k = r.number("flee_agi_k", 0.0, 0.05, 0.01, false)
	flee_step = r.number("flee_step", 0.0, 1.0, 0.15, false)
	flee_ambushed = r.number("flee_ambushed", -1.0, 1.0, -0.20, false)
	flee_ambusher = r.number("flee_ambusher", -1.0, 1.0, 0.20, false)
	flee_min = r.number("flee_min", 0.0, 1.0, 0.10, false)
	flee_max = r.number("flee_max", 0.0, 1.0, 0.95, false)
	if party_start_min > party_start_max or enemy_start_min > enemy_start_max:
		r.problem("party_start_min", "a start range has min above max")
