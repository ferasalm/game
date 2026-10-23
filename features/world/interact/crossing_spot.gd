class_name CrossingSpot
extends Node3D
## Interactive rooftop crossing: stand-in mesh, interact prompt at usable ends, and instant party teleport with fade.

var place: PlaceDef
var crossing_kind: StringName = &"board"
var from_3d: Vector3 = Vector3.ZERO
var to_3d: Vector3 = Vector3.ZERO
var one_way: bool = false
var start_end: CrossingEnd
var end_end: CrossingEnd = null

var prompt: Label3D:
	get:
		return start_end.prompt if start_end != null else null

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _rooftop: Rooftop
var _player: Player
var _rules: ExploreRulesDef


func _init(rules: ExploreRulesDef, player: Player, p: PlaceDef, p_from_3d: Vector3, p_to_3d: Vector3,
		rooftop: Rooftop = null) -> void:
	_rules = rules
	_player = player
	place = p
	crossing_kind = p.crossing_kind
	from_3d = p_from_3d
	to_3d = p_to_3d
	one_way = p.one_way
	_rooftop = rooftop
	_build_mesh()
	_build_ends()
	_setup_fade()


func cross_to(target_pos: Vector3) -> void:
	if _rooftop == null:
		if _player != null:
			_player.position = target_pos
		return
	_rooftop.freeze_actors(true)
	if not is_inside_tree() or _fade_rect == null:
		_rooftop.teleport_party(target_pos)
		_rooftop.freeze_actors(false)
		return
	var half_fade: float = _rules.crossing_fade / 2.0
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, half_fade)
	tween.tween_callback(func() -> void: _rooftop.teleport_party(target_pos))
	tween.tween_property(_fade_rect, "color:a", 0.0, half_fade)
	tween.tween_callback(func() -> void: _rooftop.freeze_actors(false))


func set_active(on: bool) -> void:
	if start_end != null:
		start_end.set_active(on)
	if end_end != null:
		end_end.set_active(on)


func _build_ends() -> void:
	var prompt_key: String = "WORLD_PROMPT_CROSS_" + String(crossing_kind).to_upper()
	var lift: float = _rules.prompt_height + _rules.capsule_height
	start_end = CrossingEnd.new(_rules, _player, prompt_key, lift, to_3d, cross_to)
	start_end.position = from_3d
	add_child(start_end)
	if not one_way:
		end_end = CrossingEnd.new(_rules, _player, prompt_key, lift, from_3d, cross_to)
		end_end.position = to_3d
		add_child(end_end)


func _setup_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = UiLayers.TRANSITION
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)
	add_child(_fade_layer)


func _build_mesh() -> void:
	var mid: Vector3 = (from_3d + to_3d) / 2.0
	var delta: Vector3 = to_3d - from_3d
	var length: float = delta.length()
	var standin := Node3D.new()
	if length > 0.01:
		var up: Vector3 = Vector3.FORWARD if absf(delta.normalized().y) > 0.9 else Vector3.UP
		standin.transform = Transform3D.IDENTITY.looking_at(delta, up)
	standin.position = mid
	add_child(standin)
	match crossing_kind:
		&"bridge":
			_mesh_bridge(standin, length)
		&"zipline":
			_mesh_zipline(standin, length)
		&"leap":
			_mesh_leap(length)
		&"cable":
			_mesh_cable(standin, length)
		_:
			_mesh_board(standin, length)


func _mesh_board(parent: Node3D, length: float) -> void:
	_add_box(parent, Vector3(0.6, 0.08, length), Vector3.ZERO, Color(0.55, 0.35, 0.17))


func _mesh_bridge(parent: Node3D, length: float) -> void:
	_add_box(parent, Vector3(1.0, 0.1, length), Vector3.ZERO, Color(0.5, 0.35, 0.2))
	_add_box(parent, Vector3(0.06, 0.06, length), Vector3(-0.48, 0.7, 0.0), Color(0.7, 0.6, 0.45))
	_add_box(parent, Vector3(0.06, 0.06, length), Vector3(0.48, 0.7, 0.0), Color(0.7, 0.6, 0.45))


func _mesh_zipline(parent: Node3D, length: float) -> void:
	_add_box(parent, Vector3(0.04, 0.04, length), Vector3(0.0, 2.2, 0.0), Color(0.6, 0.6, 0.65))
	_add_box(parent, Vector3(0.25, 0.25, 0.08), Vector3(0.0, 2.0, -length * 0.4), Color(0.9, 0.7, 0.1))


func _mesh_leap(_length: float) -> void:
	_add_box(self, Vector3(0.8, 0.02, 0.4), from_3d + Vector3(0.0, 0.02, 0.0), Color(0.95, 0.92, 0.85))
	if not one_way:
		_add_box(self, Vector3(0.8, 0.02, 0.4), to_3d + Vector3(0.0, 0.02, 0.0), Color(0.95, 0.92, 0.85))


func _mesh_cable(parent: Node3D, length: float) -> void:
	_add_box(parent, Vector3(0.2, 0.15, length), Vector3.ZERO, Color(0.13, 0.13, 0.15))


func _add_box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	parent.add_child(mi)


class CrossingEnd extends InteractSpot:
	var target_point: Vector3
	var on_cross: Callable

	func _init(rules: ExploreRulesDef, player: Player, prompt_key: String, lift: float,
			target_pos: Vector3, callback: Callable) -> void:
		super(rules, player, prompt_key, lift)
		prompt.text = tr(prompt_key)
		target_point = target_pos
		on_cross = callback

	func _interact() -> void:
		if on_cross.is_valid():
			on_cross.call(target_point)
