class_name PropMesh
extends RefCounted
## Builds one prop's ArrayMesh from its PropDef parts (palette-letter vertex colours, flat shaded). Surfaces, in
## order: lit trim, one per painted pattern, unshaded glow, pulsing blink. One mesh per prop id and part group is
## cached, so every placement of a prop shares it (and a MultiMesh can draw them all at once).

static var _cache: Dictionary[String, ArrayMesh] = {}


static func clear() -> void:
	_cache.clear()


static func mesh(def: PropDef, palette: PaletteDef, group: StringName = &"body") -> ArrayMesh:
	var key: String = "%s|%s" % [def.id, group]
	if not _cache.has(key):
		_cache[key] = _build(def, palette, group)
	return _cache[key]


static func _build(def: PropDef, palette: PaletteDef, group: StringName) -> ArrayMesh:
	var buffers: Dictionary[String, SurfaceBuffer] = {}
	for part: PropPart in def.parts:
		if part.group == group:
			var buf: SurfaceBuffer = _buffer(buffers, _surface_key(part))
			_add_part(buf, part, palette)
	var out := ArrayMesh.new()
	var keys: Array = buffers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return _order(a) < _order(b))
	for key: String in keys:
		buffers[key].commit(out, _material(key, def, palette))
	return out


static func _surface_key(part: PropPart) -> String:
	if part.blink:
		return "blink"
	if part.glow:
		return "glow"
	return "pat:" + part.pattern if part.pattern != &"" else "trim"


static func _order(key: String) -> int:
	return {"trim": 0, "glow": 2, "blink": 3}.get(key, 1)


static func _buffer(buffers: Dictionary[String, SurfaceBuffer], key: String) -> SurfaceBuffer:
	if not buffers.has(key):
		buffers[key] = SurfaceBuffer.new()
	return buffers[key]


static func _add_part(buf: SurfaceBuffer, part: PropPart, palette: PaletteDef) -> void:
	var colour: Color = palette.colors.get(part.color, Color.MAGENTA)
	var basis := Basis.from_euler(Vector3(deg_to_rad(part.tilt.x), deg_to_rad(part.yaw), deg_to_rad(part.tilt.z)), EULER_ORDER_YXZ)
	buf.xf = Transform3D(basis, part.at)
	if part.shape == &"frustum":
		buf.frustum(Vector3.ZERO, part.size.x, part.size.y, part.size.z, part.sides, colour)
	else:
		buf.box(Vector3.ZERO, part.size, colour)


static func _material(key: String, def: PropDef, palette: PaletteDef) -> Material:
	if key == "glow":
		return SurfaceMaterials.glow()
	if key == "blink":
		return SurfaceMaterials.blink(def.blink_rate)
	if key.begins_with("pat:"):
		return SurfaceMaterials.tile(StringName(key.substr(4)), palette)
	return SurfaceMaterials.trim()
