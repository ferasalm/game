class_name PaintedMaterials
extends RefCounted
## World materials of a painted look (painted_world.gdshader + the shared painted light): tiles, facades, trim and
## flat colours. Textures come from the offline painterly bake (assets/textures/painted/<bake>/<atlas>.webp, linear
## filtered with mipmaps; WebP) and fall back to the code-painted atlas when a bake is missing. SurfaceMaterials and
## Diorama route here while a painted look is in use (use()); with none in use nothing here runs.

const SHADER: Shader = preload("res://features/world/view/shaders/painted_world.gdshader")
const GLOW_SHADER: Shader = preload("res://features/world/view/shaders/painted_glow.gdshader")
const BAKED_DIR: String = "res://assets/textures/painted"

static var paint: PaintDef = null
static var _cache: Dictionary[String, Material] = {}
static var _textures: Dictionary[String, Texture2D] = {}
static var _baked_images: Dictionary[String, Image] = {}


## Starts (or, with null, ends) building with a painted recipe; clears every cached world material and the cached
## meshes that hold them (a tower or prop mesh built under another look would keep its old material).
static func use(recipe: PaintDef) -> void:
	paint = recipe
	_cache.clear()
	_textures.clear()
	SurfaceMaterials.clear()
	TowerHouse.clear()
	PropMesh.clear()


## A tile pattern, world-space triplanar with one repeat every metres (SurfaceMaterials caches it).
static func tile(pattern: StringName, image: Image, tint: Color, metres: float) -> ShaderMaterial:
	var mat := _material()
	mat.set_shader_parameter(&"albedo_tex", texture("tile_" + pattern, image))
	mat.set_shader_parameter(&"tint", tint)
	mat.set_shader_parameter(&"use_triplanar", true)
	mat.set_shader_parameter(&"triplanar_scale", 1.0 / metres)
	return mat


## A facade atlas (albedo, emission) of a building, times vertex colours, windows glowing at glow (cached there).
static func facade(building_id: StringName, images: Array[Image], glow: float) -> ShaderMaterial:
	var mat := _material()
	mat.set_shader_parameter(&"albedo_tex", texture("facade_" + building_id, images[0]))
	mat.set_shader_parameter(&"emission_tex", texture("facade_%s_emit" % building_id, images[1]))
	mat.set_shader_parameter(&"use_emission", true)
	mat.set_shader_parameter(&"emission_energy", glow)
	mat.set_shader_parameter(&"use_vertex_color", true)
	return mat


## Vertex-coloured gypsum, roofs and props.
static func trim() -> ShaderMaterial:
	if not _cache.has("trim"):
		var mat := _material()
		mat.set_shader_parameter(&"use_texture", false)
		mat.set_shader_parameter(&"use_vertex_color", true)
		_cache["trim"] = mat
	return _cache["trim"] as ShaderMaterial


## Unshaded vertex-colour glow (neon strips, far landmarks): the painted counterpart of SurfaceMaterials.glow().
static func glow() -> ShaderMaterial:
	if not _cache.has("glow"):
		var mat := ShaderMaterial.new()
		mat.shader = GLOW_SHADER
		_cache["glow"] = mat
	return _cache["glow"] as ShaderMaterial


## One flat colour (tiles without a pattern).
static func flat(color: Color) -> ShaderMaterial:
	var key: String = "flat:" + color.to_html()
	if not _cache.has(key):
		var mat := _material()
		mat.set_shader_parameter(&"use_texture", false)
		mat.set_shader_parameter(&"tint", color)
		_cache[key] = mat
	return _cache[key] as ShaderMaterial


## The baked painting of an atlas for the current recipe, or the code-painted fallback image when it is missing.
static func texture(atlas_id: String, fallback: Image) -> Texture2D:
	if not _textures.has(atlas_id):
		var image: Image = load_baked(paint.bake, atlas_id) if paint != null else null
		if image == null:
			image = fallback.duplicate() as Image
		if not image.has_mipmaps():
			image.generate_mipmaps()
		_textures[atlas_id] = ImageTexture.create_from_image(image)
	return _textures[atlas_id]


## The baked picture of an atlas for a recipe (read as bytes: the folder has a .gdignore, so it is not imported), or null.
static func load_baked(bake: StringName, atlas_id: String) -> Image:
	var path: String = baked_path(bake, atlas_id)
	if bake == &"" or not FileAccess.file_exists(path):
		return null
	if not _baked_images.has(path):
		var image := Image.new()
		if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
			return null
		image.generate_mipmaps()
		_baked_images[path] = image
	return _baked_images[path]


static func baked_path(bake: StringName, atlas_id: String) -> String:
	return BAKED_DIR.path_join(String(bake)).path_join(atlas_id + ".webp")


static func _material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	paint.apply_light(mat)
	return mat
