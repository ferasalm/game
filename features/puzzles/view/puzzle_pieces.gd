class_name PuzzlePieces
extends RefCounted
## purpose: Lists the interactive pieces of both puzzles and returns their world positions.


static func ids(light_def: LightLockDef, water_def: WaterNetDef) -> Array[StringName]:
	var out: Array[StringName] = []
	for window: LightLockWindow in light_def.windows:
		out.append(window.id)
	for mirror: LightLockMirror in light_def.mirrors:
		out.append(mirror.id)
	for node: WaterNodeDef in water_def.nodes:
		if node.kind == &"gate" or node.kind == &"spout":
			out.append(node.id)
	return out


static func is_water(water_def: WaterNetDef, id: StringName) -> bool:
	var node: WaterNodeDef = water_def.node_def(id)
	return node != null and (node.kind == &"gate" or node.kind == &"spout")


static func place_marker(marker: MeshInstance3D, id: StringName, light_def: LightLockDef,
		water_def: WaterNetDef, yard: PuzzleYardDef) -> void:
	if marker == null:
		return
	marker.visible = id != &""
	if marker.visible:
		marker.position = position(light_def, water_def, id) + Vector3(0.0, yard.marker_height, 0.0)


static func position(light_def: LightLockDef, water_def: WaterNetDef, id: StringName) -> Vector3:
	var window: LightLockWindow = light_def.get_window(id)
	if window != null:
		return window.at
	var mirror: LightLockMirror = light_def.get_mirror(id)
	if mirror != null:
		return mirror.at
	var node: WaterNodeDef = water_def.node_def(id)
	return node.at if node != null else Vector3.ZERO
