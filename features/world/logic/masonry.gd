class_name Masonry
extends RefCounted
## Brick courses and stone slabs painted with palette letters. Shared by facades and surface textures. Pure.

const BRICK_H: int = 4


## Staggered brick courses over a rectangle. Brick tones b (mid), s (dark), t (light); mortar r.
static func bricks(c: PixelCanvas, x0: int, y0: int, rw: int, rh: int, brick_w: int, rng: RandomNumberGenerator) -> void:
	var row: int = 0
	var y: int = y0
	while y < y0 + rh:
		var x: int = x0 - (row % 2) * (brick_w / 2)
		while x < x0 + rw:
			_brick(c, x, y, brick_w, rng)
			x += brick_w
		y += BRICK_H
		row += 1


static func _brick(c: PixelCanvas, x: int, y: int, brick_w: int, rng: RandomNumberGenerator) -> void:
	var roll: float = rng.randf()
	var body: String = "b"
	if roll < 0.15:
		body = "s"
	elif roll < 0.25:
		body = "t"
	c.rect(x, y, brick_w - 1, BRICK_H - 1, body)
	c.hline(x, y, brick_w - 1, "t" if body == "b" else "b")
	c.vline(x + brick_w - 1, y, BRICK_H, "r")
	c.hline(x, y + BRICK_H - 1, brick_w, "r")


## Rows of slabs. body is a string of tone letters picked at random per slab, mortar fills the joints and hi
## lights the top and left edges. With c.wrap on and rw = canvas width the rows tile.
static func slabs(c: PixelCanvas, x0: int, y0: int, rw: int, rh: int, row_h: int, body: String, mortar: String,
		hi: String, rng: RandomNumberGenerator) -> void:
	c.rect(x0, y0, rw, rh, mortar)
	var y: int = y0
	while y < y0 + rh:
		var x: int = x0
		var widths: Array[int] = _partition(rw, rng)
		var shift: int = rng.randi_range(0, 7)
		for slab_w: int in widths:
			_slab(c, x - shift, y, slab_w, row_h, body[rng.randi_range(0, body.length() - 1)], mortar, hi, rng)
			x += slab_w
		y += row_h


## Splits total into widths of 16..40 that add up to exactly total (so wrapped rows close).
static func _partition(total: int, rng: RandomNumberGenerator) -> Array[int]:
	var out: Array[int] = []
	var left: int = total
	while left > 40:
		var take: int = rng.randi_range(2, 5) * 8
		out.append(take)
		left -= take
	if left < 16 and not out.is_empty():
		out[out.size() - 1] += left
	else:
		out.append(left)
	return out


static func _slab(c: PixelCanvas, x: int, y: int, sw: int, sh: int, body: String, mortar: String, hi: String,
		rng: RandomNumberGenerator) -> void:
	c.rect(x, y, sw, sh, mortar)
	c.rect(x + 1, y + 1, sw - 2, sh - 2, body)
	c.hline(x + 1, y + 1, sw - 2, hi)
	c.vline(x + 1, y + 2, sh - 3, hi)
	for i: int in 3:
		var tone: String = hi if rng.randf() < 0.5 else mortar
		c.px(x + rng.randi_range(2, sw - 3), y + rng.randi_range(2, sh - 3), tone)
