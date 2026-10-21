class_name BattleOutcome
extends RefCounted
## What a finished battle hands back: result (victory, defeat, retry), the party's vitals and bag after the fight,
## and the rewards (money, equippable items, consumables) still to be applied to GameState by the Router.

const VICTORY: StringName = &"victory"
const DEFEAT: StringName = &"defeat"
const RETRY: StringName = &"retry"

var encounter_id: StringName = &""
var result: StringName = &""
var vitals: Dictionary = {}
var bag: Dictionary = {}
var money: int = 0
var items: Array[StringName] = []
var consumables: Dictionary = {}
