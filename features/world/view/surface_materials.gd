class_name SurfaceMaterials
extends RefCounted
## Cached textures and materials for the painted world, so 100+ buildings share a handful of draw materials:
## tile patterns (world-space triplanar, so texels stay square across tiles), tower-house facades (front and
## side painted side by side in one atlas, lit windows in an emission map), vertex-coloured trim, unshaded
## HDR glow, and the dotted far silhouettes.

const GLOW_BOOST: float = 1.6
static var _cache: Dictionary[String, Material] = {}


static func clear() -> void:
	_cache.clear()


static func tile(pattern: StringName, palette: PaletteDef) -> StandardMaterial3D:
	var key: String = "tile:" + pattern
	if not _cache.has(key):
		var mat := _base(ImageTexture.create_from_image(SurfacePainter.paint(pattern, palette.colors)[0]))
		_triplanar(mat, float(SurfacePainter.SIZE) / FacadePainter.PX_PER_M)
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


## The facade atlas material of a building: front on the left, side on the right (see atlas_split).
static func facade(def: BuildingDef, palette: PaletteDef) -> StandardMaterial3D:
	var key: String = "facade:" + def.id
	if not _cache.has(key):
		var front: Array[Image] = FacadePainter.paint(def.facade_spec(false), palette.colors)
		var side: Array[Image] = FacadePainter.paint(def.facade_spec(true), palette.colors)
		var mat := _base(ImageTexture.create_from_image(_atlas(front[0], side[0])))
		mat.emission_enabled = true
		mat.emission_texture = ImageTexture.create_from_image(_atlas(front[1], side[1]))
		mat.emission_energy_multiplier = def.glow
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


## Vertex-coloured gypsum, roofs and roof extras; lit by the scene.
static func trim() -> StandardMaterial3D:
	if not _cache.has("trim"):
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 1.0
		_cache["trim"] = mat
	return _cache["trim"] as StandardMaterial3D


## Unshaded vertex colours boosted above 1 so neon and lit windows bloom; for far landmarks and beacons.
static func glow() -> StandardMaterial3D:
	if not _cache.has("glow"):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.albedo_color = Color(GLOW_BOOST, GLOW_BOOST, GLOW_BOOST)
		_cache["glow"] = mat
	return _cache["glow"] as StandardMaterial3D


## Far city blocks: unshaded, window dots in world space, tinted per instance.
static func far(palette: PaletteDef, texture_m: float) -> StandardMaterial3D:
	var key: String = "far:%s" % texture_m
	if not _cache.has(key):
		var mat := _base(ImageTexture.create_from_image(SurfacePainter.paint(&"far_windows", palette.colors)[0]))
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		_triplanar(mat, texture_m)
		_cache[key] = mat
	return _cache[key] as StandardMaterial3D


## Fraction of the atlas width taken by the front facade (u runs 0..split for the front, split..1 for the side).
static func atlas_split(def: BuildingDef) -> float:
	return float(def.footprint_w) / float(def.footprint_w + def.footprint_d)


static func _atlas(front: Image, side: Image) -> Image:
	var out := Image.create_empty(front.get_width() + side.get_width(), front.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(front, Rect2i(Vector2i.ZERO, front.get_size()), Vector2i.ZERO)
	out.blit_rect(side, Rect2i(Vector2i.ZERO, side.get_size()), Vector2i(front.get_width(), 0))
	out.generate_mipmaps()
	return out


static func _base(texture: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness = 1.0
	return mat


static func _triplanar(mat: StandardMaterial3D, metres: float) -> void:
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / metres
	mat.uv1_triplanar_sharpness = 8.0
