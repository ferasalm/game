class_name SurfacePainter
extends RefCounted
## Seamless 128x128 surface textures (4 m at 32 px/m) for the playable tiles, painted with palette letters:
## lime-plaster roof floor, worn plaster, white gypsum, wooden planks, stone paving (al-Saila), basalt, brick,
## and the dotted window texture of far silhouettes. Deterministic for a seed. Pure.

const SIZE: int = 128
const PATTERNS: Array[StringName] = [&"roof_plaster", &"plaster_worn", &"gypsum", &"planks", &"paving", &"basalt",
	&"brick", &"far_windows"]


static func paint(pattern: StringName, colors: Dictionary[String, Color], seed_value: int = 1) -> Array[Image]:
	var c := PixelCanvas.new(SIZE, SIZE, colors)
	c.wrap = true
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + hash(String(pattern))
	match pattern:
		&"roof_plaster":
			_plaster(c, rng, "q", "p", "l", 16, 2)
		&"plaster_worn":
			_plaster(c, rng, "p", "q", "o", 34, 7)
			_bare_patches(c, rng)
		&"gypsum":
			_gypsum(c, rng)
		&"planks":
			_planks(c, rng)
		&"paving":
			Masonry.slabs(c, 0, 0, SIZE, SIZE, 16, "ddee", "n", "e", rng)
			_speckle(c, rng, "h", 40)
		&"basalt":
			Masonry.slabs(c, 0, 0, SIZE, SIZE, 16, "dddn", "k", "e", rng)
		&"brick":
			Masonry.bricks(c, 0, 0, SIZE, SIZE, 8, rng)
		&"far_windows":
			_far_windows(c, rng)
		_:
			c.rect(0, 0, SIZE, SIZE, "x")
	return c.finish()


static func _plaster(c: PixelCanvas, rng: RandomNumberGenerator, base: String, stain: String, spot: String, blobs: int,
		cracks: int) -> void:
	c.rect(0, 0, SIZE, SIZE, base)
	for i: int in blobs:
		c.disc(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), rng.randi_range(3, 11),
			rng.randi_range(2, 7), stain)
	_speckle(c, rng, spot, 90)
	_speckle(c, rng, "o" if base == "q" else "k", 10)
	for i: int in cracks:
		_crack(c, rng, "o")


static func _bare_patches(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	for i: int in 3:
		var x: int = rng.randi_range(0, SIZE - 1)
		var y: int = rng.randi_range(0, SIZE - 1)
		c.disc(x, y, rng.randi_range(4, 8), rng.randi_range(3, 5), "b")
		c.disc(x + 1, y + 1, 2, 2, "r")


static func _crack(c: PixelCanvas, rng: RandomNumberGenerator, letter: String) -> void:
	var x: int = rng.randi_range(0, SIZE - 1)
	var y: int = rng.randi_range(0, SIZE - 1)
	var dir: Vector2i = Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
	for step: int in rng.randi_range(14, 40):
		c.px(x, y, letter)
		if rng.randf() < 0.35:
			dir = Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		x += dir.x
		y += dir.y


static func _speckle(c: PixelCanvas, rng: RandomNumberGenerator, letter: String, count: int) -> void:
	for i: int in count:
		c.px(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), letter)


static func _gypsum(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	c.rect(0, 0, SIZE, SIZE, "w")
	for row: int in 4:
		c.hline(0, row * 32 + 31, SIZE, "g")
		var off: int = rng.randi_range(0, 31)
		for col: int in 4:
			c.vline((col * 32 + off) % SIZE, row * 32, 31, "g")
	for i: int in 14:
		c.disc(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), rng.randi_range(3, 9), rng.randi_range(2, 5), "g")
	_speckle(c, rng, "h", 30)
	for i: int in 2:
		_crack(c, rng, "h")


static func _planks(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	var tones: String = "opps"
	for plank: int in 16:
		var x: int = plank * 8
		var tone: String = tones[rng.randi_range(0, tones.length() - 1)]
		c.rect(x, 0, 7, SIZE, tone)
		c.vline(x + 7, 0, SIZE, "k")
		c.vline(x + 1, 0, SIZE, "s" if tone != "s" else "m")
		for i: int in 5:
			c.vline(x + rng.randi_range(2, 5), rng.randi_range(0, SIZE - 1), rng.randi_range(6, 24), "o")
		var joint: int = rng.randi_range(0, SIZE - 1)
		c.hline(x, joint, 8, "k")
		c.px(x + 2, (joint + 3) % SIZE, "e")
		c.px(x + 5, (joint + 3) % SIZE, "e")


static func _far_windows(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	c.rect(0, 0, SIZE, SIZE, "n")
	for gy: int in range(1, SIZE, 4):
		for gx: int in range(1, SIZE, 4):
			var roll: float = rng.randf()
			if roll < 0.10:
				c.rect(gx, gy, 2, 2, "Y")
			elif roll < 0.13:
				c.rect(gx, gy, 2, 2, "C")
			elif roll < 0.55:
				c.rect(gx, gy, 2, 2, "i")
