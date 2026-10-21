class_name FarLandmarks
extends RefCounted
## The far landmarks, built into an unshaded buffer (faces are shaded by a fake light so low-poly facets read):
## the ridge of Jabal Nuqum, the Haddah megacity of 2150 (slim towers with cyan and magenta neon edges) and the
## village of Bayt Baws on its rocky crag. Local origin: the ground at the landmark's centre.


## A low-poly mountain ridge of the given length along local x; peaks about a fifth of the length high.
static func ridge(buf: SurfaceBuffer, length: float, c: Dictionary[String, Color], rng: RandomNumberGenerator) -> void:
	buf.fake_light = LandmarkBuilder.SUN_DIR
	var cols: int = maxi(int(length / 18.0), 4)
	var rows: int = 6
	var depth: float = length * 0.16
	var peak: float = length * 0.2
	var phase: Array[float] = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var grid: Array[Vector3] = []
	for k: int in rows + 1:
		for i: int in cols + 1:
			var u: float = float(i) / cols
			var v: float = float(k) / rows * 2.0 - 1.0
			var spine: float = 0.5 + 0.22 * sin(u * 17.0 + phase[0]) + 0.16 * sin(u * 41.0 + phase[1]) + 0.1 * sin(u * 83.0 + phase[2])
			var edge: float = pow(maxf(1.0 - absf(v), 0.0), 1.2)
			var jitter: float = rng.randf_range(0.85, 1.1)
			grid.append(Vector3((u - 0.5) * length, peak * clampf(spine, 0.1, 1.0) * edge * jitter, v * depth))
	for k: int in rows:
		for i: int in cols:
			var a: Vector3 = grid[k * (cols + 1) + i]
			var b: Vector3 = grid[k * (cols + 1) + i + 1]
			var d: Vector3 = grid[(k + 1) * (cols + 1) + i]
			var e: Vector3 = grid[(k + 1) * (cols + 1) + i + 1]
			_tri(buf, a, b, d, peak, c)
			_tri(buf, b, e, d, peak, c)
	buf.fake_light = Vector3.ZERO


static func _tri(buf: SurfaceBuffer, a: Vector3, b: Vector3, d: Vector3, peak: float, c: Dictionary[String, Color]) -> void:
	var n: Vector3 = (b - a).cross(d - a)
	if n.y < 0.0:
		n = -n
	var t: float = clampf((a.y + b.y + d.y) / (3.0 * peak), 0.0, 1.0)
	var color: Color = c["n"].lerp(c["i"], clampf(t * 1.6, 0.0, 1.0))
	if t > 0.7:
		color = color.lerp(c["j"], (t - 0.7) * 2.0)
	buf.face([a, b, d], n, color)


## Slim dark towers in a loose arc with neon edge lines, ring lines and beacons; size is the tallest tower.
static func megacity(buf: SurfaceBuffer, tallest: float, count: int, c: Dictionary[String, Color],
		rng: RandomNumberGenerator) -> void:
	var xs: Array[float] = []
	var hs: Array[float] = []
	for i: int in count:
		var x: float = (i - count / 2.0) * 26.0 + rng.randf_range(-6.0, 6.0)
		var z: float = absf(i - count / 2.0) * 7.0 + rng.randf_range(-14.0, 14.0)
		var h: float = tallest * rng.randf_range(0.35, 1.0)
		var w: float = rng.randf_range(5.0, 9.0)
		var neon: Color = c["C"] if i % 2 == 0 else c["M"]
		buf.fake_light = LandmarkBuilder.SUN_DIR
		buf.box(Vector3(x, h / 2.0, z), Vector3(w, h, w), c["d"] if i % 3 == 0 else c["n"])
		buf.fake_light = Vector3.ZERO
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				buf.box(Vector3(x + sx * w / 2.0, h / 2.0, z + sz * w / 2.0), Vector3(0.4, h, 0.4), neon)
		for ring: int in 5:
			buf.box(Vector3(x, h * (0.25 + 0.15 * ring), z), Vector3(w + 0.3, 0.4, w + 0.3), neon)
		buf.box(Vector3(x, h + 1.5, z), Vector3(0.5, 3.0, 0.5), c["M"])
		xs.append(x)
		hs.append(h)
	for i: int in range(1, xs.size()):
		var bridge_y: float = minf(hs[i], hs[i - 1]) * 0.6
		buf.box(Vector3((xs[i] + xs[i - 1]) / 2.0, bridge_y, 0.0), Vector3(absf(xs[i] - xs[i - 1]), 1.2, 3.0), c["e"])


## A rocky crag with small tower-houses on its terraces and a few lit windows; size is the crag's height.
static func village(buf: SurfaceBuffer, crag_h: float, houses: int, c: Dictionary[String, Color],
		rng: RandomNumberGenerator) -> void:
	var radius: float = crag_h * 0.8
	buf.fake_light = LandmarkBuilder.SUN_DIR
	var rock: Array[String] = ["o", "p", "o", "d"]
	for ring: int in 5:
		var y0: float = crag_h * ring / 5.0
		var r0: float = lerpf(radius, radius * 0.25, float(ring) / 5.0)
		var r1: float = lerpf(radius, radius * 0.25, float(ring + 1) / 5.0)
		buf.frustum(Vector3(0.0, y0, 0.0), r0, r1, crag_h / 5.0, 7, c[rock[ring % rock.size()]], rng.randf() * 0.5)
	for i: int in houses:
		var t: float = rng.randf_range(0.15, 0.95)
		var ang: float = rng.randf_range(-PI, PI)
		var r: float = lerpf(radius, radius * 0.25, t) * 0.85
		var h: float = rng.randf_range(5.0, 9.0)
		var base := Vector3(cos(ang) * r, crag_h * t, sin(ang) * r)
		buf.box(base + Vector3(0.0, h / 2.0, 0.0), Vector3(4.0, h, 4.0), c["t"] if i % 2 == 0 else c["q"])
		buf.box(base + Vector3(0.0, h + 0.3, 0.0), Vector3(4.4, 0.6, 4.4), c["w"])
		buf.fake_light = Vector3.ZERO
		if i % 3 != 0:
			buf.box(base + Vector3(0.0, h * 0.6, -2.03), Vector3(0.7, 1.0, 0.1), c["Y"])
		buf.fake_light = LandmarkBuilder.SUN_DIR
	buf.fake_light = Vector3.ZERO
