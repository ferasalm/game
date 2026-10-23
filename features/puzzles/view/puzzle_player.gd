class_name PuzzlePlayer
extends Node3D
## purpose: Stand-in player capsule that walks at a fixed speed on the yard floor and the R4 ledge.

var yard: PuzzleYardDef


func setup(def: PuzzleYardDef) -> void:
	yard = def
	var capsule := CapsuleMesh.new()
	capsule.radius = def.player_radius
	capsule.height = def.player_height
	var mesh := MeshInstance3D.new()
	mesh.mesh = capsule
	mesh.position.y = def.player_height * 0.5
	mesh.material_override = PuzzleMaterials.stone(def.player_color)
	add_child(mesh)


func move(direction: Vector3, delta: float) -> void:
	position = walkable(position + direction * yard.walk_speed * delta)


func walkable(pos: Vector3) -> Vector3:
	var half_x: float = yard.floor_size.x * 0.5
	var half_z: float = yard.floor_size.y * 0.5
	var z: float = clampf(pos.z, -half_z, half_z)
	var min_x: float = -half_x
	if z >= yard.ledge_z_min and z <= yard.ledge_z_max:
		min_x = yard.ledge_x_min
	var x: float = clampf(pos.x, min_x, half_x)
	var y: float = yard.ledge_top if _on_ledge(x, z) else 0.0
	return Vector3(x, y, z)


func _on_ledge(x: float, z: float) -> bool:
	return x >= yard.ledge_x_min and x <= yard.ledge_x_max \
		and z >= yard.ledge_z_min and z <= yard.ledge_z_max
