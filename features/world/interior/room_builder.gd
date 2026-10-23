class_name RoomBuilder
extends RefCounted
## purpose: Builds room view: shell geometry, painted qamariya arches, and props via PropBuilder.


## Builds room geometry: shell (floor, ceiling, walls, qamariya) and props.
static func build(spec: RoomDef, palette: PaletteDef) -> Node3D:
	var root := Node3D.new()
	root.name = "Room"
	var shell := RoomMeshBuilder.build(spec, palette)
	root.add_child(shell)
	var props := PropBuilder.build_props(spec.props, palette, 0.0)
	root.add_child(props)
	return root


## Real lights carried by the room's props.
static func light_specs(spec: RoomDef) -> Array[LightSpec]:
	return PropBuilder.light_specs_from_props(spec.props, 0.0)
