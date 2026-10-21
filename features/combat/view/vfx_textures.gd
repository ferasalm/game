class_name VfxTextures
extends RefCounted
## Procedurally painted effect textures (no files): crisp hard-edged pixel shapes (a bright core and a darker
## rim, one-bit alpha) plus one soft glow. Each is painted once on first use and cached. White shapes: the
## layer's colour tints them.

const SIZES: Dictionary = {
	&"arc": Vector2i(96, 96), &"ring": Vector2i(96, 96), &"glow": Vector2i(48, 48), &"streak": Vector2i(128, 24),
	&"hex": Vector2i(96, 96), &"spark": Vector2i(32, 32), &"mote": Vector2i(12, 12), &"line": Vector2i(64, 8),
	&"net": Vector2i(80, 80), &"bolt0": Vector2i(128, 48), &"bolt1": Vector2i(128, 48), &"bolt2": Vector2i(128, 48),
}
const RIM: float = 0.55
static var _cache: Dictionary[StringName, ImageTexture] = {}


static func texture(tex: StringName) -> ImageTexture:
	if not _cache.has(tex):
		_cache[tex] = ImageTexture.create_from_image(_paint(tex))
	return _cache[tex]


## Pixels across the longer side, so a layer can turn metres into a sprite scale.
static func pixels(tex: StringName) -> Vector2:
	var size: Vector2i = SIZES.get(tex, Vector2i(16, 16)) as Vector2i
	return Vector2(size)


static func is_soft(tex: StringName) -> bool:
	return tex == &"glow"


static func _paint(tex: StringName) -> Image:
	var size: Vector2i = SIZES.get(tex, Vector2i(16, 16)) as Vector2i
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var path: PackedVector2Array = _bolt_path(tex, size) if String(tex).begins_with("bolt") else PackedVector2Array()
	for y: int in size.y:
		for x: int in size.x:
			var u: float = (float(x) + 0.5) / size.x * 2.0 - 1.0
			var v: float = (float(y) + 0.5) / size.y * 2.0 - 1.0
			var c: Vector2 = _bolt_pixel(path, Vector2(x, y)) if not path.is_empty() else _pixel(tex, u, v)
			image.set_pixel(x, y, Color(c.x, c.x, c.x, c.y))
	return image


## (shade, alpha) of one pixel; alpha 0 is empty.
static func _pixel(tex: StringName, u: float, v: float) -> Vector2:
	var r: float = sqrt(u * u + v * v)
	match tex:
		&"arc":
			var cut: float = sqrt((u - 0.12) * (u - 0.12) + (v + 0.42) * (v + 0.42))
			return _edged(minf(1.0 - r, cut - 1.0), 0.07)
		&"ring":
			return _edged(minf(1.0 - r, r - 0.84), 0.04)
		&"glow":
			var fall: float = clampf(1.0 - r, 0.0, 1.0)
			return Vector2(1.0, fall * fall)
		&"streak":
			var half: float = 1.0 - absf(u) * absf(u)
			return Vector2(1.0, 1.0) if absf(v) < half * 0.35 else (Vector2(RIM, 0.7) if absf(v) < half else Vector2.ZERO)
		&"hex":
			return _hex(u, v)
		&"spark":
			var star: float = 1.0 - (sqrt(absf(u)) + sqrt(absf(v)))
			return _edged(star, 0.18)
		&"mote":
			return _edged(1.0 - r, 0.35)
		&"line":
			var taper: float = 1.0 - absf(u)
			return Vector2(1.0, 1.0) if absf(v) < taper * 0.8 else Vector2.ZERO
		&"net":
			return _net(u, v, r)
	return Vector2(1.0, 1.0)


## Core inside, a thin rim near the edge, nothing outside (m = distance inside the shape).
static func _edged(m: float, rim: float) -> Vector2:
	if m < 0.0:
		return Vector2.ZERO
	return Vector2(RIM, 1.0) if m < rim else Vector2(1.0, 1.0)


## A hexagonal bubble: bright outline, faint fill, triangular lattice lines.
static func _hex(u: float, v: float) -> Vector2:
	var d: float = maxf(absf(v), absf(u) * 0.866 + absf(v) * 0.5)
	if d > 1.0:
		return Vector2.ZERO
	if d > 0.9:
		return Vector2(1.0, 1.0)
	for angle: float in [0.0, 1.0472, 2.0944]:
		var along: float = u * cos(angle) + v * sin(angle)
		if absf(fposmod(along * 3.0 + 0.5, 1.0) - 0.5) < 0.05:
			return Vector2(RIM, 0.6)
	return Vector2(RIM, 0.16)


static func _net(u: float, v: float, r: float) -> Vector2:
	if r > 1.0:
		return Vector2.ZERO
	for ring: float in [0.38, 0.7, 0.96]:
		if absf(r - ring) < 0.045:
			return Vector2(1.0, 1.0)
	var spoke: float = absf(fposmod(atan2(v, u) / TAU * 10.0 + 0.5, 1.0) - 0.5) * r
	return Vector2(RIM, 1.0) if spoke < 0.035 else Vector2.ZERO


## A jagged line from the left edge to the right (a seeded random walk), as points in pixels.
static func _bolt_path(tex: StringName, size: Vector2i) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + int(String(tex).substr(4))
	var path := PackedVector2Array()
	var mid: float = size.y * 0.5
	var y: float = mid
	for i: int in 9:
		path.append(Vector2(float(i) / 8.0 * (size.x - 1), y))
		y = clampf(mid + rng.randf_range(-size.y * 0.32, size.y * 0.32), 3.0, size.y - 4.0)
	path[0].y = mid
	path.append(Vector2(size.x - 1, mid))
	return path


static func _bolt_pixel(path: PackedVector2Array, p: Vector2) -> Vector2:
	var best: float = 99.0
	for i: int in path.size() - 1:
		var seg: Vector2 = path[i + 1] - path[i]
		var t: float = clampf((p - path[i]).dot(seg) / seg.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(path[i] + seg * t))
	if best < 1.4:
		return Vector2(1.0, 1.0)
	return Vector2(RIM, 1.0) if best < 2.6 else Vector2.ZERO
