class_name LightLock
extends RefCounted
## purpose: Pure logic for light lock beam tracing, shutter toggling, mirror rotation, and solution check.


static func toggle_shutter(state: LightLockState, id: StringName) -> void:
	state.shutters[id] = not state.shutters.get(id, false)


static func turn_mirror(state: LightLockState, id: StringName) -> void:
	state.turns[id] = (state.turns.get(id, 0) + 1) % 4


static func trace(def: LightLockDef, state: LightLockState, window_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = [window_id]
	var window: LightLockWindow = def.get_window(window_id)
	if window == null:
		return out
	var curr: StringName = window.target
	var guard: int = def.mirrors.size() + 2
	while out.size() < guard:
		if curr == &"" or curr == &"lens":
			out.append(curr)
			break
		if out.has(curr):
			out.append(curr)
			break
		out.append(curr)
		var mirror: LightLockMirror = def.get_mirror(curr)
		if mirror == null:
			break
		var turn: int = state.turns.get(curr, 0) % 4
		if turn < 0:
			turn += 4
		if turn >= mirror.targets.size():
			break
		curr = mirror.targets[turn]
	return out


static func lens_bits(def: LightLockDef, state: LightLockState) -> int:
	var bits: int = 0
	for window: LightLockWindow in def.windows:
		if state.shutters.get(window.id, false):
			var path: Array[StringName] = trace(def, state, window.id)
			if not path.is_empty() and path.back() == &"lens":
				bits |= window.bits
	return bits


static func solved(def: LightLockDef, state: LightLockState) -> bool:
	return lens_bits(def, state) == 7
