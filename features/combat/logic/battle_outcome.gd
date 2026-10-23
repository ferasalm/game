class_name BattleOutcome
extends RefCounted
## What a finished battle hands back: result (victory, defeat, retry, load, title), the party's vitals and bag after the fight,
## and the rewards (money, equippable items, consumables) still to be applied to GameState by the Router.

const VICTORY: StringName = &"victory"
const DEFEAT: StringName = &"defeat"
const RETRY: StringName = &"retry"
const FLED: StringName = &"fled"
## The Defeat screen's other picks: leave the fight for the last save, or for the title.
const LOAD: StringName = &"load"
const TITLE: StringName = &"title"

var encounter_id: StringName = &""
var result: StringName = &""
var vitals: Dictionary = {}
var bag: Dictionary = {}
var money: int = 0
var items: Array[StringName] = []
var consumables: Dictionary = {}
## True once the Router paid money / items / consumables into GameState (so a second apply pays nothing).
var rewarded: bool = false
var practice: bool = false
var level_ups: Array[LevelUp] = []


## The outcome of a finished (or abandoned) sim: result, each hero's HP/SP after (a downed hero stands up at
## the setup's ko_stand_hp after a victory, never above max) and the bag after. Rewards are filled in by the Router.
static func from_sim(sim: BattleSim, final_result: StringName = &"") -> BattleOutcome:
	var out := BattleOutcome.new()
	out.encounter_id = sim.setup.encounter_id if sim.setup != null else &""
	out.result = final_result if final_result != &"" else sim.result
	for unit: UnitState in sim.timeline.units:
		if unit.side != 0:
			continue
		var hp: int = unit.hp
		if hp <= 0 and (out.result == VICTORY or out.result == FLED):  # rpg-systems.md 3
			hp = mini(sim.setup.ko_stand_hp, unit.def.max_hp)
		Vitals.store(out.vitals, unit.unit_id, hp, unit.sp)
	out.bag = sim.bag.snapshot()
	return out
