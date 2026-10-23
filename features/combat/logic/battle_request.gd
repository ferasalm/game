class_name BattleRequest
extends RefCounted
## What the Router hands to a battle: encounter, arena, ambush, seed, party order, and the pre-battle snapshot
## (vitals, bag, money) that "Retry fight" restores. Plain data; built by the area, read by the Router and BattleRunner.

const OPENING_EVEN: StringName = &"even"
const OPENING_PARTY_FIRST: StringName = &"party_first"
const OPENING_ENEMY_FIRST: StringName = &"enemy_first"

var encounter_id: StringName = &""
var arena_id: StringName = &""
## 0 none, 1 the party was ambushed, 2 the party ambushed the enemy (BattleSim.ambush).
var ambush: int = 0
var seed: int = 0
## Hero ids in party order; empty means GameState.party.
var party: Array[StringName] = []
var vitals_before: Dictionary = {}
var bag_before: Dictionary = {}
var money_before: int = 0
## True once the Router copied GameState into the three snapshot fields (it does so once per fight, on the first
## launch, so every Retry restores the same state).
var snapshotted: bool = false
## How many times this fight was retried; it shifts the seed.
var retry_count: int = 0
var practice: bool = false
var opening: StringName = OPENING_EVEN:
	set(value):
		opening = value
		match value:
			OPENING_ENEMY_FIRST:
				ambush = 1
			OPENING_PARTY_FIRST:
				ambush = 2
			_:
				ambush = 0


## Copies the carried vitals, the bag and the purse. Does nothing the second time.
func take_snapshot(vitals: Dictionary, bag: Dictionary, money: int) -> void:
	if snapshotted:
		return
	vitals_before = Vitals.copy(vitals)
	bag_before = bag.duplicate()
	money_before = money
	snapshotted = true
