class_name ModelMaterials
extends RefCounted
## The materials of live 3D characters: every surface (body, eyes, brows, hair, garments, the hilt) is a
## ShaderMaterial of character_skin.gdshader, so the painted light of the look reaches all of them through
## `materials()` (PaintedLook feeds the shared light uniforms), and one `set_all` call drives the flash, desat and
## glow of the whole character. The ink hull is an optional second pass.

const SKIN: Shader = preload("res://features/art/view/character_skin.gdshader")
const HULL: Shader = preload("res://features/art/view/character_hull.gdshader")
const HULL_INK: Color = Color("#1a1420")


## A painted material: `texture_path` ("" = plain white) times `tint`; `hull` adds the inverted-hull ink pass.
static func skin(texture_path: String, tint: Color, hull: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SKIN
	mat.set_shader_parameter(&"tint", tint)
	if not texture_path.is_empty():
		var texture := load(texture_path) as Texture2D
		if texture != null:
			mat.set_shader_parameter(&"albedo_tex", texture)
	if hull:
		var ink := ShaderMaterial.new()
		ink.shader = HULL
		ink.set_shader_parameter(&"ink_color", HULL_INK)
		mat.next_pass = ink
	return mat


## Sets one shader parameter on every material.
static func set_all(list: Array[ShaderMaterial], parameter: StringName, value: Variant) -> void:
	for mat: ShaderMaterial in list:
		mat.set_shader_parameter(parameter, value)


## Makes a material glow `amount` in `color` everywhere (a lens, a lantern).
static func make_glow(mat: ShaderMaterial, color: Color, amount: float) -> void:
	var white := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	mat.set_shader_parameter(&"emit_tex", ImageTexture.create_from_image(white))
	mat.set_shader_parameter(&"emit_color", color)
	mat.set_shader_parameter(&"emit_amount", amount)
