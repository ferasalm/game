class_name ItemPolicy
extends RefCounted
## The balance harness's opt-in herb use (docs/design/economy.md section 9): a white herb on a downed hero, a pink
## herb on the living hero below 40% HP, a yellow herb when a hero cannot pay for his cheapest move. Enemies never
## use items. Returns true when it committed the waiting hero to a herb.

const HURT_BELOW: float = 0.4  ## a harness policy number, not a game rule


static func try_use(sim: BattleSim, hero: UnitState) -> bool:
	var allies: Array[UnitState] = []
	for unit: UnitState in sim.timeline.units:
		if unit.side == hero.side:
			allies.append(unit)
	for ally: UnitState in allies:
		if not ally.is_alive() and sim.choose_item(hero.unit_id, &"white_herb", ally.unit_id).is_empty():
			return true
	var weakest: UnitState = null
	for ally: UnitState in allies:
		if ally.is_alive() and float(ally.hp) / float(ally.def.max_hp) < HURT_BELOW:
			weakest = weakest if weakest != null and weakest.hp < ally.hp else ally
	if weakest != null and sim.choose_item(hero.unit_id, &"pink_herb", weakest.unit_id).is_empty():
		return true
	for ally: UnitState in allies:
		if ally.is_alive() and ally.sp < _cheapest(sim, ally) and sim.choose_item(hero.unit_id, &"yellow_herb", ally.unit_id).is_empty():
			return true
	return false


static func _cheapest(sim: BattleSim, unit: UnitState) -> int:
	var lowest: int = 9999
	for action: ActionDef in BattleTargets.moves_of(unit, sim.actions):
		lowest = mini(lowest, action.sp_cost)
	return lowest if lowest != 9999 else 0
