class_name LandmarkBuilder
extends RefCounted
## Builds all landmarks of a SkylineDef into one ArrayMesh with two surfaces: 0 lit (minarets, Bab al-Yaman:
## vertex colours shaded by the scene lights) and 1 glow (ridge, megacity, village: unshaded, boosted above 1 so
## neon and lit windows bloom). The shapes live here (minaret, gate) and in FarLandmarks (ridge, megacity, village).

const SUN_DIR: Vector3 = Vector3(-0.5, 0.8, 0.3)


static func build(def: SkylineDef, palette: PaletteDef) -> ArrayMesh:
	var lit := SurfaceBuffer.new()
	var far := SurfaceBuffer.new()
	var colors: Dictionary[String, Color] = palette.colors
	for mark: SkylineLandmark in def.landmarks:
		var at := Transform3D(Basis(Vector3.UP, deg_to_rad(mark.yaw)), Vector3(mark.x, def.ground_y, mark.z))
		lit.xf = at
		far.xf = at
		far.fake_light = Vector3.ZERO
		var rng := RandomNumberGenerator.new()
		rng.seed = mark.seed_value
		match mark.kind:
			&"minaret":
				minaret(lit, far, mark.size, colors)
			&"gate":
				gate(lit, far, mark.size, colors)
			&"ridge":
				FarLandmarks.ridge(far, mark.size, colors, rng)
			&"megacity":
				FarLandmarks.megacity(far, mark.size, mark.count, colors, rng)
			&"village":
				FarLandmarks.village(far, mark.size, mark.count, colors, rng)
	var out := ArrayMesh.new()
	lit.commit(out, SurfaceMaterials.trim())
	far.commit(out, SurfaceMaterials.glow())
	return out


## A minaret in the style of the Great Mosque of Sana'a: a tall ochre brick shaft with white bands, a balcony,
## two narrower octagonal stages, a white dome and a brass finial. height is the total height in metres.
static func minaret(lit: SurfaceBuffer, glow: SurfaceBuffer, height: float, c: Dictionary[String, Color]) -> void:
	var base_h: float = height * 0.5
	lit.frustum(Vector3.ZERO, 2.6, 2.1, base_h, 4, c["t"], PI / 4.0)
	for band: float in [0.25, 0.48]:
		lit.frustum(Vector3(0.0, base_h * band / 0.5 - 0.4, 0.0), 2.5, 2.5, 0.8, 4, c["w"], PI / 4.0)
	_slits(lit, glow, base_h, 2.6, 2.1, c)
	lit.frustum(Vector3(0.0, base_h, 0.0), 2.5, 2.3, 0.5, 8, c["w"])
	var y: float = base_h + 0.5
	lit.frustum(Vector3(0.0, y, 0.0), 1.7, 1.5, height * 0.2, 8, c["t"])
	y += height * 0.2
	lit.frustum(Vector3(0.0, y, 0.0), 1.9, 1.9, 0.4, 8, c["w"])
	y += 0.4
	lit.frustum(Vector3(0.0, y, 0.0), 1.1, 0.9, height * 0.1, 8, c["g"])
	y += height * 0.1
	for ring: int in 4:
		lit.frustum(Vector3(0.0, y + ring * 0.3, 0.0), 1.1 - ring * 0.25, 0.85 - ring * 0.25, 0.3, 8, c["w"])
	y += 1.2
	lit.frustum(Vector3(0.0, y, 0.0), 0.08, 0.02, 2.2, 6, c["y"])
	glow.fake_light = Vector3.ZERO
	glow.box(Vector3(0.0, y + 2.3, 0.0), Vector3(0.14, 0.14, 0.14), c["O"])


## Window slits on the four faces of the tapered square shaft; some glow amber.
static func _slits(lit: SurfaceBuffer, glow: SurfaceBuffer, shaft_h: float, r_bottom: float, r_top: float,
		c: Dictionary[String, Color]) -> void:
	for level: int in 3:
		var t: float = 0.18 + 0.2 * level
		var r: float = lerpf(r_bottom, r_top, t) * 0.7071 + 0.03
		for face_i: int in 4:
			var dir := Vector3(cos(face_i * PI / 2.0), 0.0, sin(face_i * PI / 2.0))
			var side := Vector3(-dir.z, 0.0, dir.x)
			var mid: Vector3 = dir * r + Vector3(0.0, shaft_h * t, 0.0)
			var pts: Array[Vector3] = [mid + side * 0.25 + Vector3(0, 1.0, 0), mid - side * 0.25 + Vector3(0, 1.0, 0),
				mid - side * 0.25 - Vector3(0, 1.0, 0), mid + side * 0.25 - Vector3(0, 1.0, 0)]
			var amber: bool = (face_i + level) % 3 == 0
			if amber:
				glow.face(pts, dir, c["Y"])
			else:
				lit.face(pts, dir, c["k"])


## Bab al-Yaman: two crenellated towers with a pointed gate arch between them, facing north (-z).
static func gate(lit: SurfaceBuffer, glow: SurfaceBuffer, height: float, c: Dictionary[String, Color]) -> void:
	for sx: float in [-1.0, 1.0]:
		lit.box(Vector3(sx * 8.0, height / 2.0, 0.0), Vector3(6.0, height, 6.0), c["b"])
		lit.box(Vector3(sx * 8.0, height * 0.55, 0.0), Vector3(6.4, 0.7, 6.4), c["w"])
		lit.box(Vector3(sx * 8.0, height + 0.5, 0.0), Vector3(6.6, 1.0, 6.6), c["w"])
		for k: int in 5:
			var mx: float = sx * 8.0 - 2.6 + k * 1.3
			lit.box(Vector3(mx, height + 1.3, -3.0), Vector3(0.8, 0.8, 0.5), c["w"])
			lit.box(Vector3(mx, height + 1.3, 3.0), Vector3(0.8, 0.8, 0.5), c["w"])
		glow.box(Vector3(sx * 8.0, height * 0.78, -3.04), Vector3(0.7, 1.6, 0.1), c["Y"])
	var wall_h: float = height * 0.72
	lit.box(Vector3(0.0, wall_h / 2.0, 0.0), Vector3(10.0, wall_h, 4.0), c["b"])
	lit.box(Vector3(0.0, wall_h + 0.4, 0.0), Vector3(10.2, 0.8, 4.2), c["w"])
	_arch(lit, Vector3(0.0, 0.0, -2.0), 3.1, wall_h * 0.62, c["w"], -0.02)
	_arch(lit, Vector3(0.0, 0.0, -2.0), 2.5, wall_h * 0.62, c["k"], -0.05)


## A flat arch-shaped polygon (rectangle topped by a half circle) on a wall face at z = origin.z + dz.
static func _arch(buf: SurfaceBuffer, origin: Vector3, half: float, spring_y: float, color: Color, dz: float) -> void:
	var pts: Array[Vector3] = [origin + Vector3(-half, 0.0, dz), origin + Vector3(half, 0.0, dz)]
	for i: int in range(0, 9):
		var a: float = i * PI / 8.0
		pts.append(origin + Vector3(half * cos(a), spring_y + half * sin(a), dz))
	buf.face(pts, Vector3.FORWARD, color)
