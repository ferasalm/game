class_name BattleRequest
extends RefCounted
## What the Router hands to a battle: encounter, arena, ambush, seed, party order, and the pre-battle snapshot
## (vitals, bag, money) that "Retry fight" restores. Plain data; built by the area, read by the Router and BattleSim.

var encounter_id: StringName = &""
var arena_id: StringName = &""
var ambush: bool = false
var seed: int = 0
var party: Array[StringName] = []
var vitals_before: Dictionary = {}
var bag_before: Dictionary = {}
var money_before: int = 0
