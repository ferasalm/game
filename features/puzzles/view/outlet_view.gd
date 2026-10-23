class_name PuzzleOutletView
extends Node3D
## purpose: Draws the return grate, the drone dock and the canyon gauge, reacting to their water shares.

var _def: WaterNetDef
var _yard: PuzzleYardDef
var _drones: Array[MeshInstance3D] = []
var _drone_base: Color = Color.WHITE
var _drone_rest_y: float = 0.25
var _gauge: MeshInstance3D
var _grate_share: float = 0.0
var _canyon_share: float = 0.0


func setup(def: WaterNetDef, yard: PuzzleYardDef) -> void:
	_def = def
	_yard = yard
	for node: WaterNodeDef in def.nodes:
		if node.kind != &"outlet":
			continue
		match node.reaction:
			&"return":
				_build_grate(node)
			&"dock":
				_build_dock(node)
			&"goal":
				_build_canyon(node)


func sync(flow: Dictionary[StringName, float]) -> void:
	_grate_share = flow.get(&"grate", 0.0)
	_canyon_share = flow.get(&"canyon", 0.0)
	var wet: bool = flow.get(&"dock", 0.0) > 0.0
	for drone: MeshInstance3D in _drones:
		drone.position.y = _drone_rest_y - (_yard.drone_sag if wet else 0.0)
		drone.material_override = PuzzleMaterials.stone(_drone_base * (0.45 if wet else 1.0))
	_gauge.scale.y = _canyon_share
	_gauge.position.y = -_yard.gauge_height * 0.5 + _canyon_share * _yard.gauge_height * 0.5


func grate_share() -> float:
	return _grate_share


func canyon_gauge() -> float:
	return _canyon_share


func _build_grate(node: WaterNodeDef) -> void:
	var at := node.at + Vector3(0.0, _yard.grate_height * 0.5, 0.0)
	PuzzleGeometry.box(self, Vector3(_yard.grate_size.x, _yard.grate_height, _yard.grate_size.y), at,
		PuzzleMaterials.stone(_yard.color(&"grate")))


func _build_dock(node: WaterNodeDef) -> void:
	var at := node.at + Vector3(0.0, _yard.dock_height * 0.5, 0.0)
	PuzzleGeometry.box(self, Vector3(_yard.dock_size.x, _yard.dock_height, _yard.dock_size.y), at,
		PuzzleMaterials.stone(_yard.color(&"stone")))
	_drone_base = _yard.color(&"stone").darkened(0.35)
	_drone_rest_y = _yard.dock_height + _yard.drone_size * 0.5
	for side: float in [-1.0, 1.0]:
		var drone := PuzzleGeometry.box(self, Vector3.ONE * _yard.drone_size,
			node.at + Vector3(side * _yard.dock_size.x * 0.25, _drone_rest_y, 0.0),
			PuzzleMaterials.stone(_drone_base))
		_drones.append(drone)


func _build_canyon(node: WaterNodeDef) -> void:
	var root := Node3D.new()
	root.position = node.at
	add_child(root)
	PuzzleGeometry.box(root, Vector3(0.12, _yard.gauge_height, 0.12), Vector3.ZERO,
		PuzzleMaterials.stone(_yard.color(&"stone")))
	_gauge = PuzzleGeometry.box(root, Vector3(0.1, _yard.gauge_height, 0.1), Vector3.ZERO,
		PuzzleMaterials.stone(_yard.color(&"water")))
	_gauge.scale.y = 0.0
