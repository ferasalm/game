class_name ModelMaterials
extends RefCounted
## The materials of live 3D characters: every surface (body, eyes, brows, hair, garments, the hilt) is a
## ShaderMaterial of character_skin.gdshader, so the painted light of the look reaches all of them through
## `materials()` (PaintedLook feeds the shared light uniforms), and one `set_all` call drives the flash, desat and
## glow of the whole character. The ink hull is an optional second pass.

const SKIN: Shader = preload("res://features/art/view/character_skin.gdshader")
const HULL: Shader = preload("res://features/art/view/character_hull.gdshader")
const HULL_INK: Color = Color("#1a1420")

static var _baked: Dictionary = {}


## A painted material: `texture_path` ("" = plain white) times `tint`; `hull` adds the inverted-hull ink pass.
static func skin(texture_path: String, tint: Color, hull: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SKIN
	mat.set_shader_parameter(&"tint", tint)
	if not texture_path.is_empty():
		var texture: Texture2D = load_texture(texture_path)
		if texture != null:
			mat.set_shader_parameter(&"albedo_tex", texture)
	if hull:
		var ink := ShaderMaterial.new()
		ink.shader = HULL
		ink.set_shader_parameter(&"ink_color", HULL_INK)
		mat.next_pass = ink
	return mat


## A texture by path: imported files through load(); painted .webp bakes (assets/textures/painted/ is a .gdignore
## folder Godot never imports) are read from the file once, with mipmaps, and cached.
static func load_texture(path: String) -> Texture2D:
	if not path.ends_with(".webp"):
		return load(path) as Texture2D
	if not _baked.has(path):
		var image := Image.new()
		if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
			push_warning("ModelMaterials: cannot read %s" % path)
			return null
		image.generate_mipmaps()
		_baked[path] = ImageTexture.create_from_image(image)
	return _baked[path] as Texture2D


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
