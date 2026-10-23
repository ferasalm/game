class_name PuzzleWaterView
extends Node3D
## purpose: Draws stone channels, flowing water strips, gates, spouts, outlets and the canyon gauge.

var _def: WaterNetDef
var _yard: PuzzleYardDef
var _state: WaterNetState
var _flow: Dictionary[StringName, float] = {}
var _strips: Dictionary[String, MeshInstance3D] = {}
var _strip_materials: Dictionary[String, ShaderMaterial] = {}
var _edge_from: Dictionary[String, StringName] = {}
var _edge_to: Dictionary[String, StringName] = {}
var _gates: Dictionary[StringName, MeshInstance3D] = {}
var _spouts: Dictionary[StringName, Node3D] = {}
var _outlets: PuzzleOutletView


func setup(def: WaterNetDef, yard: PuzzleYardDef) -> void:
	_def = def
	_yard = yard
	_build_channels()
	_build_gates()
	_build_spouts()
	_outlets = PuzzleOutletView.new()
	add_child(_outlets)
	_outlets.setup(def, yard)


func sync(state: WaterNetState, valve_open: bool) -> void:
	_state = state
	_flow = WaterNet.flow(_def, _state)
	if not valve_open:
		_flow.clear()
	_update_strips()
	_update_gates()
	_update_spouts()
	_outlets.sync(_flow)


func edge_share(from: StringName, to: StringName) -> float:
	var target: WaterNodeDef = _def.node_def(to)
	if target == null or target.kind != &"outlet":
		return _flow.get(to, 0.0)
	var source: WaterNodeDef = _def.node_def(from)
	if source == null:
		return 0.0
	if source.kind == &"gate" and not _state.open.get(from, false):
		return 0.0
	if source.kind == &"spout" and _spout_target(source) != to:
		return 0.0
	if source.kind == &"split":
		var active: Array[StringName] = _active_children(source)
		if active.is_empty() or not active.has(to):
			return 0.0
		return _flow.get(from, 0.0) / float(active.size())
	return _flow.get(from, 0.0)


func water_strip_visible(from: StringName, to: StringName) -> bool:
	var key: String = _key(from, to)
	return _strips.has(key) and _strips[key].visible


func canyon_gauge() -> float:
	return _outlets.canyon_gauge()


func canyon_at() -> Vector3:
	for node: WaterNodeDef in _def.nodes:
		if node.kind == &"outlet" and node.reaction == &"goal":
			return node.at
	return Vector3.ZERO


func grate_share() -> float:
	return _outlets.grate_share()


func _key(from: StringName, to: StringName) -> String:
	return "%s>%s" % [from, to]


func _build_channels() -> void:
	for node: WaterNodeDef in _def.nodes:
		for target_id: StringName in node.to:
			var target: WaterNodeDef = _def.node_def(target_id)
			if target == null:
				continue
			var key: String = _key(node.id, target_id)
			var channel_size := Vector3(_yard.channel_width, _yard.channel_depth, 1.0)
			PuzzleGeometry.edge(self, node.at, target.at, channel_size,
				PuzzleMaterials.stone(_yard.channel_color), -_yard.channel_depth * 0.5)
			var mat := PuzzleMaterials.water(_yard.color(&"water"), 0.0, _yard.water_scroll_speed)
			var strip_size := Vector3(_yard.channel_width * 0.9, _yard.strip_height, 1.0)
			var strip := PuzzleGeometry.edge(self, node.at, target.at, strip_size, mat, _yard.strip_height * 0.5)
			strip.visible = false
			_strips[key] = strip
			_strip_materials[key] = mat
			_edge_from[key] = node.id
			_edge_to[key] = target_id


func _build_gates() -> void:
	for node: WaterNodeDef in _def.nodes:
		if node.kind != &"gate":
			continue
		var at := node.at + Vector3(0.0, _yard.gate_size.y * 0.5, 0.0)
		_gates[node.id] = PuzzleGeometry.box(self, _yard.gate_size, at,
			PuzzleMaterials.stone(_yard.color(&"wood")))


func _build_spouts() -> void:
	for node: WaterNodeDef in _def.nodes:
		if node.kind != &"spout":
			continue
		var pivot := Node3D.new()
		pivot.position = node.at
		add_child(pivot)
		PuzzleGeometry.box(pivot, Vector3(_yard.spout_width, _yard.spout_width, _yard.spout_length),
			Vector3(0.0, 0.0, _yard.spout_length * 0.5), PuzzleMaterials.stone(_yard.color(&"wood")))
		_spouts[node.id] = pivot


func _update_strips() -> void:
	for key: String in _strips:
		var share: float = edge_share(_edge_from[key], _edge_to[key])
		var alpha: float = _yard.water_alpha_base + _yard.water_alpha_share * share
		_strip_materials[key].set_shader_parameter(&"alpha", alpha)
		_strips[key].visible = share > 0.0


func _update_gates() -> void:
	for node: WaterNodeDef in _def.nodes:
		if node.kind != &"gate":
			continue
		var gate: MeshInstance3D = _gates[node.id]
		var open: bool = _state.open.get(node.id, false)
		var freed: bool = _state.freed.get(node.id, false)
		var jammed: bool = node.jammed and not freed
		gate.position.y = node.at.y + _yard.gate_size.y * 0.5 + (_yard.gate_open_raise if open else 0.0)
		gate.rotation.z = deg_to_rad(_yard.gate_jam_tilt) if jammed else 0.0
		gate.material_override = PuzzleMaterials.stone(_yard.color(&"rust") if jammed else _yard.color(&"wood"))


func _update_spouts() -> void:
	for node: WaterNodeDef in _def.nodes:
		if node.kind != &"spout":
			continue
		var target: WaterNodeDef = _def.node_def(_spout_target(node))
		if target == null:
			continue
		var dir: Vector3 = target.at - node.at
		dir.y = 0.0
		if dir.length() > 0.001:
			_spouts[node.id].rotation.y = atan2(dir.x, dir.z)


func _spout_target(node: WaterNodeDef) -> StringName:
	if node.to.size() < 2:
		return node.to[0] if not node.to.is_empty() else &""
	var pos: int = _state.spout.get(node.id, node.start)
	if pos == 0:
		if not node.spill_unless_shut.is_empty() and _state.open.get(node.spill_unless_shut, false):
			return node.to[1]
		return node.to[0]
	return node.to[1]


func _active_children(node: WaterNodeDef) -> Array[StringName]:
	var active: Array[StringName] = []
	for child_id: StringName in node.to:
		var child: WaterNodeDef = _def.node_def(child_id)
		if child == null:
			continue
		if child.kind == &"gate":
			if _state.open.get(child_id, false):
				active.append(child_id)
		else:
			active.append(child_id)
	return active
