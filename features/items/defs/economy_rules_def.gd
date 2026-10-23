class_name EconomyRulesDef
extends Def
## The money and rest numbers (content/economy/rules.json, id "default"): start purse and bag, the cap, the
## repeat-win payout share, the HP a downed hero stands up with after a victory, the patrol respawn guards.

var start_money: int = 0
var start_bag: Dictionary[StringName, int] = {}
## Who is in the party at the start of a new game, in party order.
var start_party: Array[StringName] = []
var money_cap: int = 9999
var repeat_payout: float = 0.5
var repeat_xp_share: float = 0.5
var ko_stand_hp: int = 1
var grace_seconds: float = 3.0
var spawn_min_distance_m: float = 10.0


func read(r: DefReader) -> void:
	id = r.id()
	start_money = r.integer("start_money", 0, 9999)
	money_cap = r.integer("money_cap", 1, 999999)
	repeat_payout = r.number("repeat_payout", 0.0, 1.0)
	repeat_xp_share = r.number("repeat_xp_share", 0.0, 1.0, 0.5, false)
	ko_stand_hp = r.integer("ko_stand_hp", 1, 9999)
	grace_seconds = r.number("grace_seconds", 0.0, 60.0)
	spawn_min_distance_m = r.number("spawn_min_distance_m", 0.0, 100.0)
	start_bag = CountMap.read(r, "start_bag")
	start_party = r.id_list("start_party")
	if start_party.is_empty():
		r.problem("start_party", "needs at least one hero")


func references() -> Array[Array]:
	var out: Array[Array] = CountMap.references(start_bag)
	for hero: StringName in start_party:
		out.append(["combatant", hero])
	return out
