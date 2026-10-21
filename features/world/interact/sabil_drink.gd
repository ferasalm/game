class_name SabilDrink
extends RefCounted
## What drinking at the sabil does to the game: the whole party is refilled (no carried vitals = full), the cleared
## patrols are forgotten (they return), the save point is the sabil and the game is written to a slot. If the write
## fails nothing changes. The only save in v0.3 (docs/design/economy.md section 6).


## Returns "" on success or the reason the save failed (the state is then as it was).
static func apply(place_id: StringName, slot: int) -> String:
	var vitals_before: Dictionary = GameState.vitals.duplicate(true)
	var cleared_before: Array = GameState.cleared_patrols.duplicate()
	var point_before: StringName = GameState.save_point
	GameState.vitals.clear()
	GameState.cleared_patrols.clear()
	GameState.save_point = place_id
	var problem: String = Router.save_slot(slot)
	if not problem.is_empty():
		GameState.set_vitals(vitals_before)
		GameState.cleared_patrols.assign(cleared_before)
		GameState.save_point = point_before
	return problem
