class_name PuzzleLensView
extends Node3D
## purpose: Draws the lens sphere and the seal torus, with the wrong-mix flicker and the solved seal turn.

var _yard: PuzzleYardDef
var _material: StandardMaterial3D
var _seal_pivot: Node3D
var _seal_material: StandardMaterial3D
var _color: Color = Color.BLACK
var _flicker: bool = false
var _solved: bool = false
var _seal_solved: bool = false
var _seal_turn: float = 0.0
var _time: float = 0.0


func setup(lens_at: Vector3, yard: PuzzleYardDef) -> void:
	_yard = yard
	var sphere := SphereMesh.new()
	sphere.radius = yard.lens_radius
	sphere.height = yard.lens_radius * 2.0
	var lens := MeshInstance3D.new()
	lens.mesh = sphere
	_material = _glow(yard.color(&"lens_off"), 1.0)
	lens.material_override = _material
	lens.position = lens_at
	add_child(lens)
	var torus := TorusMesh.new()
	torus.outer_radius = yard.seal_radius
	torus.inner_radius = yard.seal_radius * 0.84
	torus.rings = 24
	torus.ring_segments = 8
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	_seal_material = _glow(yard.color(&"red"), 1.4)
	ring.material_override = _seal_material
	ring.rotation.x = PI * 0.5
	_seal_pivot = Node3D.new()
	_seal_pivot.position = lens_at
	_seal_pivot.add_child(ring)
	add_child(_seal_pivot)


func sync(bits: int) -> void:
	_color = _color_for_bits(bits)
	_material.albedo_color = _color
	_material.emission = _color
	_flicker = bits != 0 and bits != 7
	_solved = bits == 7
	if _solved and not _seal_solved:
		_seal_solved = true
		_seal_turn = 0.0
		_paint_seal(_yard.color(&"white"))
	elif not _solved:
		_seal_solved = false
		_seal_turn = 0.0
		_seal_pivot.rotation.y = 0.0
		_paint_seal(_yard.color(&"red"))


func lens_color() -> Color:
	return _color


func is_solved() -> bool:
	return _solved


func _process(delta: float) -> void:
	_time += delta
	if _material == null:
		return
	if _flicker:
		var wave: float = 0.5 + 0.5 * sin(_time * TAU * _yard.flicker_hz)
		_material.emission_energy_multiplier = lerpf(_yard.flicker_min, _yard.flicker_max, wave)
	else:
		_material.emission_energy_multiplier = 1.4 if _solved else 1.0
	if _seal_solved and _seal_turn < 1.0:
		_seal_turn = minf(1.0, _seal_turn + delta / _yard.seal_turn_secs)
		_seal_pivot.rotation.y = deg_to_rad(90.0) * _seal_turn


func _paint_seal(color: Color) -> void:
	_seal_material.albedo_color = color
	_seal_material.emission = color


func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


func _color_for_bits(bits: int) -> Color:
	match bits:
		1:
			return _yard.color(&"red")
		2:
			return _yard.color(&"green")
		3:
			return _yard.color(&"yellow")
		4:
			return _yard.color(&"blue")
		5:
			return _yard.color(&"magenta")
		6:
			return _yard.color(&"cyan")
		7:
			return _yard.color(&"white")
		_:
			return _yard.color(&"lens_off")
