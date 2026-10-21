class_name MistBuilder
extends RefCounted
## Builds one mist layer from a MistDef: a big flat plane over the area at the def's height, with the scrolling
## noise shader and a seamless noise texture made once here. No shadows; the shader fades it at geometry.

const SHADER: Shader = preload("res://features/world/view/shaders/mist.gdshader")
const NOISE_FREQUENCY: float = 0.012
const NOISE_OCTAVES: int = 3


## Every mist layer the area lists, under one node.
static func build_area(area: AreaDef) -> Node3D:
	var root := Node3D.new()
	root.name = "Mist"
	for mist_id: StringName in area.mist:
		var def := ContentDB.get_def("mist", mist_id) as MistDef
		if def != null:
			for layer: MeshInstance3D in build_stack(def, Vector2(area.width(), area.depth())):
				root.add_child(layer)
	return root


## The def's planes (stack of them, step metres apart), each with its own noise offset.
static func build_stack(def: MistDef, area_size: Vector2) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for i: int in def.stack:
		var plane: MeshInstance3D = build(def, area_size)
		plane.position.y += def.step * i
		var mat := plane.material_override as ShaderMaterial
		mat.set_shader_parameter(&"offset", Vector2(0.37, 0.61) * i)
		out.append(plane)
	return out


## area_size is the area's width and depth in metres (its corner is the world origin).
static func build(def: MistDef, area_size: Vector2) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	var centre: Vector2 = area_size / 2.0
	mesh.size = area_size + Vector2.ONE * def.margin * 2.0
	if def.rect.has_area():
		mesh.size = def.rect.size
		centre = def.rect.get_center()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = Vector3(centre.x, def.height, centre.y)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.material_override = material(def)
	return instance


static func material(def: MistDef) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"noise_tex", noise_texture(def))
	mat.set_shader_parameter(&"mist_color", def.color)
	mat.set_shader_parameter(&"opacity", def.opacity)
	mat.set_shader_parameter(&"noise_scale", def.noise_scale)
	mat.set_shader_parameter(&"speed", def.speed)
	mat.set_shader_parameter(&"low", def.low)
	mat.set_shader_parameter(&"high", def.high)
	mat.set_shader_parameter(&"depth_fade", def.depth_fade)
	mat.set_shader_parameter(&"near_fade", def.near_fade)
	mat.set_shader_parameter(&"edge_fade", def.edge_fade)
	mat.set_shader_parameter(&"hole", Vector4(def.hole.position.x, def.hole.position.y, def.hole.end.x, def.hole.end.y))
	mat.set_shader_parameter(&"hole_fade", def.hole_fade)
	return mat


static func noise_texture(def: MistDef) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = NOISE_OCTAVES
	noise.frequency = NOISE_FREQUENCY
	noise.seed = def.noise_seed
	return ImageTexture.create_from_image(noise.get_seamless_image(def.noise_size, def.noise_size))
