class_name FacadePainter
extends RefCounted
## Paints one Sana'a tower-house facade at 32 px/m from a FacadeSpec: basalt stone floors at the bottom (door on
## the ground floor), fired-brick floors above, a gypsum frieze at the top of each brick floor, and on every
## brick floor windows with gypsum frames under qamariya arches. Deterministic for a seed.

const PX_PER_M: int = 32


## Returns [albedo, emission] images, mipmapped.
static func paint(spec: FacadeSpec, colors: Dictionary[String, Color]) -> Array[Image]:
	var c := PixelCanvas.new(spec.width_m * PX_PER_M, spec.floors * spec.floor_px, colors)
	var rng := RandomNumberGenerator.new()
	rng.seed = spec.seed_value
	for k: int in spec.floors:
		var y0: int = c.h - (k + 1) * spec.floor_px
		c.clip = Rect2i(0, y0, c.w, spec.floor_px)
		if k < spec.stone_floors:
			_stone_floor(c, spec, k, y0, rng)
		else:
			_brick_floor(c, spec, y0, rng)
	c.clip = Rect2i(0, 0, c.w, c.h)
	return c.finish()


static func _brick_floor(c: PixelCanvas, spec: FacadeSpec, y0: int, rng: RandomNumberGenerator) -> void:
	Masonry.bricks(c, 0, y0, c.w, spec.floor_px, 10, rng)
	if spec.frieze != &"none":
		FacadeDetails.frieze(c, 0, y0, c.w, spec.frieze)
	var cw: float = float(c.w) / spec.columns
	for j: int in spec.columns:
		var x: int = int(cw * (j + 0.5) - FacadeDetails.WIDE / 2.0)
		var top: int = y0 + FacadeDetails.WINDOW_TOP
		var state: int = _state(spec, rng)
		FacadeDetails.window(c, x, top, FacadeDetails.WIDE, FacadeDetails.HIGH, state, rng)
		FacadeDetails.qamariya(c, x, top, FacadeDetails.WIDE, spec.qamariya, state == FacadeDetails.LIT, rng)


static func _stone_floor(c: PixelCanvas, spec: FacadeSpec, k: int, y0: int, rng: RandomNumberGenerator) -> void:
	Masonry.slabs(c, 0, y0, c.w, spec.floor_px, 12, "ddde", "n", "e", rng)
	c.rect(0, y0, c.w, 4, "w")
	c.hline(0, y0 + 4, c.w, "g")
	var cw: float = float(c.w) / spec.columns
	for j: int in spec.columns:
		var cx: float = cw * (j + 0.5)
		if k == 0:
			if not spec.door or absf(cx - c.w / 2.0) > 24.0:
				FacadeDetails.window(c, int(cx) - 5, y0 + 14, 10, 22, FacadeDetails.DARK, rng)
		else:
			var state: int = _state(spec, rng)
			FacadeDetails.window(c, int(cx) - 9, y0 + 28, 18, 28, state, rng)
	if k == 0:
		c.rect(0, y0 + spec.floor_px - 3, c.w, 3, "n")
		if spec.door:
			FacadeDetails.door(c, c.w / 2, y0 + spec.floor_px - 4)


static func _state(spec: FacadeSpec, rng: RandomNumberGenerator) -> int:
	var roll: float = rng.randf()
	if roll < spec.lit_ratio:
		return FacadeDetails.LIT
	if roll < spec.lit_ratio + spec.shutter_ratio:
		return FacadeDetails.SHUTTER
	return FacadeDetails.DARK
