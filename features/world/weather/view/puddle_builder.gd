class_name PuddleBuilder
extends RefCounted
## Builds wet floor puddles with animated ripple shaders scattered across walkable floor tiles.

const PUDDLE_SHADER: Shader = preload("res://features/world/weather/view/shaders/puddle.gdshader")


static func build(area: AreaDef, def: StormDef, floor_y: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Puddles"
	var rng := RandomNumberGenerator.new()
	rng.seed = def.puddle_seed
	var count: int = rng.randi_range(def.puddle_count_min, def.puddle_count_max)
	var spots: Array[Vector2] = _puddle_spots(area, def.puddle_wall_margin, rng, count)
	for i: int in spots.size():
		var spot: Vector2 = spots[i]
		var puddle := MeshInstance3D.new()
		var pmesh := PlaneMesh.new()
		var psize: float = rng.randf_range(def.puddle_size_min, def.puddle_size_max)
		pmesh.size = Vector2(psize, psize * rng.randf_range(0.8, 1.2))
		puddle.mesh = pmesh
		var tile := ContentDB.get_def("tile", area.tile_id_at(floori(spot.x), floori(spot.y))) as TileDef
		var tile_y: float = tile.height if tile != null else floor_y
		var lift: float = def.puddle_height_offset + float(i) * 0.001
		puddle.position = Vector3(spot.x, tile_y + lift, spot.y)
		puddle.rotation.y = rng.randf_range(0.0, TAU)
		var smat := ShaderMaterial.new()
		smat.shader = PUDDLE_SHADER
		smat.render_priority = 1 + i
		smat.set_shader_parameter(&"darken_factor", def.puddle_darken)
		smat.set_shader_parameter(&"roughness", def.puddle_roughness)
		smat.set_shader_parameter(&"sky_ambient", def.puddle_sky_ambient)
		smat.set_shader_parameter(&"neon_magenta", def.puddle_neon_magenta)
		smat.set_shader_parameter(&"neon_cyan", def.puddle_neon_cyan)
		smat.set_shader_parameter(&"ripple_speed", def.puddle_ripple_speed)
		smat.set_shader_parameter(&"ripple_frequency", def.puddle_ripple_frequency)
		smat.set_shader_parameter(&"ripple_fade_in", def.puddle_ripple_fade_in)
		smat.set_shader_parameter(&"ripple_wave_speed", def.puddle_ripple_wave_speed)
		smat.set_shader_parameter(&"ripple_decay", def.puddle_ripple_decay)
		smat.set_shader_parameter(&"ripple_normal_weight", def.puddle_ripple_normal_weight)
		smat.set_shader_parameter(&"ripple_antialias", def.puddle_ripple_antialias)
		puddle.material_override = smat
		root.add_child(puddle)
	return root


static func _puddle_spots(area: AreaDef, margin: float, rng: RandomNumberGenerator, count: int) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for z: int in range(1, area.depth() - 1):
		for x: int in range(1, area.width() - 1):
			if not area.is_walkable(x, z):
				continue
			var p := Vector2(x + 0.5, z + 0.5)
			if min_wall_dist(area, p) >= margin:
				candidates.append(p)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x if a.x != b.x else a.y < b.y
	)
	var out: Array[Vector2] = []
	if candidates.is_empty():
		return out
	var step: float = float(candidates.size()) / float(maxi(1, count))
	for i: int in count:
		var idx: int = (roundi(i * step) + rng.randi_range(0, 1)) % candidates.size()
		if not out.has(candidates[idx]):
			out.append(candidates[idx])
	return out


static func min_wall_dist(area: AreaDef, p: Vector2) -> float:
	var min_d: float = 999.0
	var cx: int = floori(p.x)
	var cz: int = floori(p.y)
	for dz: int in range(-2, 3):
		for dx: int in range(-2, 3):
			var nx: int = cx + dx
			var nz: int = cz + dz
			if nx < 0 or nx >= area.width() or nz < 0 or nz >= area.depth() or not area.is_walkable(nx, nz):
				var min_x: float = float(nx)
				var max_x: float = float(nx + 1)
				var min_z: float = float(nz)
				var max_z: float = float(nz + 1)
				var d_x: float = maxf(0.0, maxf(min_x - p.x, p.x - max_x))
				var d_z: float = maxf(0.0, maxf(min_z - p.y, p.y - max_z))
				min_d = minf(min_d, sqrt(d_x * d_x + d_z * d_z))
	return min_d
