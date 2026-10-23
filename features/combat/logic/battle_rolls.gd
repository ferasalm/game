class_name BattleRolls
extends RefCounted
## Pure roll calculations (no timeline dependency): hit, crit, resist, flee.

## Hit chance (before dodge): docs/design/rpg-systems.md.
static func hit_chance(att: UnitState, tgt: UnitState, rules: BattleRulesDef) -> float:
	var chance: float = rules.hit_base + rules.hit_agi_k * (att.def.agility - tgt.def.agility) - tgt.def.dodge_bonus
	return clampf(chance, rules.hit_min, rules.hit_max)

## Crit chance: docs/design/rpg-systems.md.
static func crit_chance(att: UnitState, rules: BattleRulesDef) -> float:
	var chance: float = rules.crit_base + rules.crit_lck_k * att.def.luck + att.def.crit_bonus
	return clampf(chance, 0.0, rules.crit_max)

## Resist chance (hostile status about to land): docs/design/rpg-systems.md.
static func resist_chance(att: UnitState, tgt: UnitState, rules: BattleRulesDef) -> float:
	var chance: float = rules.resist_base + rules.resist_lck_k * (tgt.def.luck - att.def.luck) - att.def.status_pierce
	return clampf(chance, 0.0, rules.resist_max)

## Flee chance: docs/design/rpg-systems.md.
static func flee_chance(party: Array[UnitState], foes: Array[UnitState], fails: int, ambush: int, rules: BattleRulesDef) -> float:
	var mean_agi_party: float = 0.0
	var mean_agi_foe: float = 0.0
	var party_alive: int = 0
	var foe_alive: int = 0
	for u: UnitState in party:
		if u.is_alive():
			mean_agi_party += u.def.agility
			party_alive += 1
	for u: UnitState in foes:
		if u.is_alive():
			mean_agi_foe += u.def.agility
			foe_alive += 1
	if party_alive > 0:
		mean_agi_party /= party_alive
	if foe_alive > 0:
		mean_agi_foe /= foe_alive
	var ambush_mod: float = 0.0
	if ambush == 1:
		ambush_mod = rules.flee_ambushed
	elif ambush == 2:
		ambush_mod = rules.flee_ambusher
	var chance: float = rules.flee_base + rules.flee_agi_k * (mean_agi_party - mean_agi_foe) + rules.flee_step * fails + ambush_mod
	return clampf(chance, rules.flee_min, rules.flee_max)
