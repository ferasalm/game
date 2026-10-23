class_name BattleSetup
extends RefCounted
## Everything BattleSim.create_from needs for one fight, in one object: the built party (in party order, one
## CombatantDef per hero) and the enemies with their formation slots, the rules and move tables, the carried
## vitals and bag, the gear snapshot, the seed, the ambush, which encounter and arena, and the stage anchor.
## Plain data. BattleLoader builds it from content and GameState; tests build it by hand.

var rules: BattleRulesDef
var party: Array[CombatantDef] = []
var party_slots: Array[int] = []
var enemies: Array[CombatantDef] = []
var enemy_slots: Array[int] = []
var actions: Dictionary[StringName, ActionDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
## Every consumable by id (the Items command reads the battle-usable ones).
var consumables: Dictionary[StringName, ConsumableDef] = {}
## Carried HP/SP per hero id (Vitals); a missing hero starts at full.
var vitals: Dictionary = {}
## Consumable counts {id: count} the party carries into the fight.
var bag: Dictionary = {}
## GameState.equipment as it was when the fight began (the stage and the retry snapshot read it).
var equipment: Dictionary[StringName, StringName] = {}
var seed: int = 0
## 0 none, 1 the party was ambushed, 2 the party ambushed the enemy (BattleSim).
var ambush: int = 0
var encounter_id: StringName = &""
var arena_id: StringName = &""
## The floor point the fighters are placed around.
var anchor: Vector3 = Vector3.ZERO
## HP a downed hero stands up with after a victory (EconomyRulesDef.ko_stand_hp).
var ko_stand_hp: int = 1
## Whether this battle allows a flee attempt (false for boss encounters like abu_nabil_duel).
var can_flee: bool = true


## The hero ids in party order.
func party_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for def: CombatantDef in party:
		out.append(def.id)
	return out
