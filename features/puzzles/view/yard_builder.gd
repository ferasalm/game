class_name PuzzleYardBuilder
extends RefCounted
## purpose: Builds the grey-box floor, back wall, parapet, R4 ledge and far tower of the puzzle yard.


static func build(parent: Node3D, def: PuzzleYardDef) -> void:
	var floor_size := Vector3(def.floor_size.x, 0.1, def.floor_size.y)
	PuzzleGeometry.box(parent, floor_size, Vector3(0.0, -0.05, 0.0), PuzzleMaterials.stone(def.floor_color))
	var wall := Vector3(def.floor_size.x, def.back_wall_height, def.back_wall_thickness)
	var wall_at := Vector3(0.0, def.back_wall_height * 0.5, def.back_wall_z - def.back_wall_thickness * 0.5)
	PuzzleGeometry.box(parent, wall, wall_at, PuzzleMaterials.stone(def.back_wall_color))
	var side := Vector3(def.parapet_thickness, def.parapet_height, def.floor_size.y)
	var side_at := Vector3(def.floor_size.x * 0.5 + def.parapet_thickness * 0.5, def.parapet_height * 0.5, 0.0)
	PuzzleGeometry.box(parent, side, side_at, PuzzleMaterials.stone(def.parapet_color))
	var back := Vector3(def.floor_size.x, def.parapet_height, def.parapet_thickness)
	var back_at := Vector3(0.0, def.parapet_height * 0.5, def.floor_size.y * 0.5 + def.parapet_thickness * 0.5)
	PuzzleGeometry.box(parent, back, back_at, PuzzleMaterials.stone(def.parapet_color))
	var ledge_size := Vector3(def.ledge_x_max - def.ledge_x_min, def.ledge_top, def.ledge_z_max - def.ledge_z_min)
	var ledge_at := Vector3((def.ledge_x_min + def.ledge_x_max) * 0.5, def.ledge_top * 0.5,
		(def.ledge_z_min + def.ledge_z_max) * 0.5)
	PuzzleGeometry.box(parent, ledge_size, ledge_at, PuzzleMaterials.stone(def.ledge_color))
	PuzzleGeometry.box(parent, def.tower_size, def.tower_at, PuzzleMaterials.stone(def.tower_color))
