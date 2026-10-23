class_name PuzzleSave
extends RefCounted
## purpose: Reads the two puzzle save flags and builds the canonical solved states they stand for.

const FLAG_LOCK: StringName = &"puzzle_valve_lock"
const FLAG_WATER: StringName = &"puzzle_valve_water"


static func has_lock() -> bool:
	return GameState.flags.get(FLAG_LOCK, false)


static func has_water() -> bool:
	return GameState.flags.get(FLAG_WATER, false)


static func solved_light(def: LightLockDef) -> LightLockState:
	var state: LightLockState = LightLockState.start(def)
	state.shutters[&"yellow"] = true
	state.shutters[&"blue"] = true
	state.turns[&"m1"] = 1
	state.turns[&"m2"] = 2
	return state


static func solved_water(def: WaterNetDef) -> WaterNetState:
	var state: WaterNetState = WaterNetState.start(def)
	state.freed[&"g3"] = true
	state.open[&"g1"] = false
	state.open[&"g3"] = false
	state.open[&"g4"] = false
	state.spout[&"s1"] = 0
	state.spout[&"s2"] = 0
	return state
