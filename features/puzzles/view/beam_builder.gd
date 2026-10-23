class_name PuzzleBeams
extends RefCounted
## purpose: Draws one thin additive box per traced light segment, including the open-ended mirror ray.

const OPEN_DIR: Vector3 = Vector3(0.0, 0.0, 1.0)


static func draw(parent: Node3D, def: LightLockDef, state: LightLockState, yard: PuzzleYardDef) -> int:
	for child: Node in parent.get_children():
		child.queue_free()
	var count: int = 0
	for window: LightLockWindow in def.windows:
		if not state.shutters.get(window.id, false):
			continue
		count += _trace(parent, def, state, yard, window)
	return count


static func _trace(parent: Node3D, def: LightLockDef, state: LightLockState, yard: PuzzleYardDef,
		window: LightLockWindow) -> int:
	var path: Array[StringName] = LightLock.trace(def, state, window.id)
	var from: Vector3 = window.at
	var color: Color = yard.color(window.id)
	var count: int = 0
	for i: int in range(1, path.size()):
		var id: StringName = path[i]
		var to: Vector3
		if id == &"lens":
			to = def.lens_at
		elif id == &"":
			to = from + _open_dir(def, state, path[i - 1]) * yard.beam_open_length
		else:
			var mirror: LightLockMirror = def.get_mirror(id)
			to = mirror.at if mirror != null else def.lens_at
		PuzzleGeometry.segment(parent, from, to, yard.beam_width, PuzzleMaterials.additive(color, yard.beam_alpha))
		count += 1
		from = to
		if id == &"":
			break
	return count


static func _open_dir(def: LightLockDef, state: LightLockState, id: StringName) -> Vector3:
	if def.get_mirror(id) == null:
		return OPEN_DIR
	var yaw: float = deg_to_rad(90.0 * float(state.turns.get(id, 0)))
	return OPEN_DIR.rotated(Vector3.UP, yaw)
