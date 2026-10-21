class_name ArenaDressing
extends RefCounted
## The things standing on and around an arena's roof, built with the world's own helpers so the painted look
## applies: props (PropBuilder; no collision, nothing walks here), the lanterns' light (AreaLights, a few real
## OmniLights plus fake pools), and the city behind (SkylineBuilder) centred on the roof.


static func add_to(root: Node3D, def: ArenaDef, palette: PaletteDef) -> void:
	var area: AreaDef = def.as_area()
	var props: Node3D = PropBuilder.build(area, palette, 0.0)
	for child: Node in props.get_children():
		if child is StaticBody3D:
			props.remove_child(child)
			child.free()  # a fight has no walking: nothing to collide with
	root.add_child(props)
	root.add_child(_lights(area, def))
	var city: Node3D = SkylineBuilder.build(area, def.skyline)
	city.position = Vector3(-def.floor_size.x / 2.0, 0.0, -def.floor_size.z / 2.0)
	root.add_child(city)


static func _lights(area: AreaDef, def: ArenaDef) -> Node3D:
	var host := Node3D.new()
	host.name = "LightHost"
	var focus := Node3D.new()
	host.add_child(focus)
	var specs: Array[LightSpec] = PropBuilder.light_specs(area, 0.0)
	specs.append_array(def.lights)
	host.add_child(AreaLights.new(specs, focus, def.light_budget, def.light_fade))
	return host
