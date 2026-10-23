class_name PuzzleMaterials
extends RefCounted
## purpose: Shared materials for the grey-box puzzle yard (stone, emissive, additive beams, flowing water).

const WATER_SHADER: Shader = preload("res://features/puzzles/view/shaders/water_strip.gdshader")

static var _cache: Dictionary[String, Material] = {}


static func stone(color: Color) -> StandardMaterial3D:
	var key: String = "stone:" + color.to_html()
	if not _cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 1.0
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


static func emissive(color: Color, energy: float = 1.0) -> StandardMaterial3D:
	var key: String = "glow:%s:%.2f" % [color.to_html(), energy]
	if not _cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


static func additive(color: Color, alpha: float) -> StandardMaterial3D:
	var key: String = "beam:%s:%.2f" % [color.to_html(), alpha]
	if not _cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.albedo_color = Color(color.r, color.g, color.b, alpha)
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


static func water(color: Color, alpha: float, speed: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter(&"water_color", color)
	mat.set_shader_parameter(&"alpha", alpha)
	mat.set_shader_parameter(&"scroll_speed", speed)
	return mat
