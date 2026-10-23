class_name PuzzleLightView
extends Node3D
## purpose: Draws qamariya windows, shutters, mirrors and delegates the lens and light beams to their builders.

var _def: LightLockDef
var _yard: PuzzleYardDef
var _state: LightLockState
var _shutters: Dictionary[StringName, MeshInstance3D] = {}
var _mirrors: Dictionary[StringName, Node3D] = {}
var _beam_root: Node3D
var _lens: PuzzleLensView
var _beam_count: int = 0


func setup(def: LightLockDef, yard: PuzzleYardDef) -> void:
	_def = def
	_yard = yard
	_build_windows()
	_build_mirrors()
	_lens = PuzzleLensView.new()
	add_child(_lens)
	_lens.setup(def.lens_at, yard)
	_beam_root = Node3D.new()
	_beam_root.name = "Beams"
	add_child(_beam_root)


func sync(state: LightLockState) -> void:
	_state = state
	for id: StringName in _shutters:
		_shutters[id].visible = not state.shutters.get(id, false)
	for id: StringName in _mirrors:
		_mirrors[id].rotation.y = deg_to_rad(90.0 * float(state.turns.get(id, 0)))
	var bits: int = LightLock.lens_bits(_def, state)
	_lens.sync(bits)
	_beam_count = PuzzleBeams.draw(_beam_root, _def, state, _yard)


func beam_count() -> int:
	return _beam_count


func lens_color() -> Color:
	return _lens.lens_color()


func is_solved() -> bool:
	return _lens.is_solved()


func _build_windows() -> void:
	for window: LightLockWindow in _def.windows:
		var node := Node3D.new()
		node.position = window.at
		add_child(node)
		var quad := QuadMesh.new()
		quad.size = _yard.window_size
		var glass := MeshInstance3D.new()
		glass.mesh = quad
		glass.material_override = PuzzleMaterials.emissive(_yard.color(window.id), 1.6)
		node.add_child(glass)
		var shutter := PuzzleGeometry.box(node, Vector3(_yard.window_size.x * 1.04, _yard.window_size.y * 1.04, 0.06),
			Vector3(0.0, 0.0, 0.05), PuzzleMaterials.stone(_yard.color(&"wood")))
		_shutters[window.id] = shutter


func _build_mirrors() -> void:
	for mirror: LightLockMirror in _def.mirrors:
		var pivot := Node3D.new()
		pivot.position = mirror.at
		add_child(pivot)
		var post_height: float = maxf(mirror.at.y, 0.1)
		PuzzleGeometry.box(pivot, Vector3(_yard.mirror_post, post_height, _yard.mirror_post),
			Vector3(0.0, -post_height * 0.5, 0.0), PuzzleMaterials.stone(_yard.color(&"brass")))
		var box := PuzzleGeometry.box(pivot, _yard.mirror_size, Vector3.ZERO,
			PuzzleMaterials.stone(_yard.color(&"brass")))
		_mirrors[mirror.id] = box
