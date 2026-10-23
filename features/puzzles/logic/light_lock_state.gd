class_name LightLockState
extends RefCounted
## purpose: Runtime state of a light lock puzzle (shutter open/closed and mirror turn angles).

var shutters: Dictionary[StringName, bool] = {}
var turns: Dictionary[StringName, int] = {}


static func start(def: LightLockDef) -> LightLockState:
	var state := LightLockState.new()
	for window: LightLockWindow in def.windows:
		state.shutters[window.id] = false
	for mirror: LightLockMirror in def.mirrors:
		state.turns[mirror.id] = mirror.start
	return state
