class_name FacadeDetails
extends RefCounted
## Sana'a facade parts painted with palette letters at 32 px/m: gypsum friezes (zigzag, triangles, rosettes),
## windows with thick white gypsum frames, the qamariya (a semicircle of coloured glass over the window) and
## arched wooden doors. Lit things also write the emission layer. Pure.

const DARK: int = 0
const LIT: int = 1
const SHUTTER: int = 2
const FRIEZE_H: int = 10
const FRAME: int = 3
const WIN_W: int = 20
const WIN_H: int = 34
const WIDE: int = WIN_W + 2 * FRAME
const HIGH: int = WIN_H + 2 * FRAME
const WINDOW_TOP: int = 29
const DOOR_HALF: int = 13
const DOOR_STRAIGHT: int = 54


static func frieze(c: PixelCanvas, x0: int, y0: int, rw: int, style: StringName) -> void:
	c.rect(x0, y0, rw, FRIEZE_H, "w")
	c.hline(x0, y0 + FRIEZE_H - 1, rw, "g")
	c.hline(x0, y0 + FRIEZE_H, rw, "h")
	for i: int in rw:
		if style == &"zigzag":
			var yy: int = y0 + 2 + absi((i % 12) - 6) * 5 / 6
			c.px(x0 + i, yy, "h")
			c.px(x0 + i, yy + 1, "g")
	var k: int = 0
	while style == &"triangles" and k * 10 < rw:
		_triangle(c, x0 + k * 10 + 5, y0 + 2)
		k += 1
	k = 0
	while style == &"rosettes" and k * 11 < rw:
		_rosette(c, x0 + k * 11 + 5, y0 + 4)
		k += 1


static func _triangle(c: PixelCanvas, cx: int, y: int) -> void:
	for row: int in 7:
		for dx: int in range(-row, row + 1):
			c.px(cx + dx, y + row, "r" if dx == -row else "b")


static func _rosette(c: PixelCanvas, cx: int, cy: int) -> void:
	for dy: int in range(-3, 4):
		for dx: int in range(-3, 4):
			var d2: int = dx * dx + dy * dy
			if d2 <= 9:
				c.px(cx + dx, cy + dy, "h" if d2 >= 5 or d2 == 0 else "g")


## A window with its gypsum frame; (x, y) is the frame's top-left, wide x high its outer size.
static func window(c: PixelCanvas, x: int, y: int, wide: int, high: int, state: int, rng: RandomNumberGenerator) -> void:
	c.rect(x, y, wide, high, "w")
	c.vline(x + wide - 1, y, high, "g")
	c.hline(x, y + high - 1, wide, "g")
	c.rect(x - 2, y + high, wide + 4, 2, "w")
	c.hline(x - 2, y + high + 1, wide + 4, "g")
	var ix: int = x + FRAME
	var iy: int = y + FRAME
	var iw: int = wide - 2 * FRAME
	var ih: int = high - 2 * FRAME
	if state == LIT:
		_lit_glass(c, ix, iy, iw, ih)
	elif state == SHUTTER:
		_shutters(c, ix, iy, iw, ih, rng)
	else:
		c.rect(ix, iy, iw, ih, "n")
		c.hline(ix, iy, iw, "k")
		c.vline(ix, iy, ih, "k")
		c.px(ix + iw - 3, iy + 4, "j")
		c.px(ix + iw - 4, iy + 5, "i")


static func _lit_glass(c: PixelCanvas, ix: int, iy: int, iw: int, ih: int) -> void:
	c.rect(ix, iy, iw, ih, "Y")
	c.rect(ix, iy, iw, ih / 3, "O")
	c.glow_rect(ix, iy, iw, ih, "Y")
	c.hline(ix, iy, iw, "k")
	c.unglow_rect(ix, iy, iw, 1)
	c.vline(ix + iw / 2, iy, ih, "o")
	c.unglow_rect(ix + iw / 2, iy, 1, ih)
	var bar_y: int = iy + ih * 2 / 5
	c.hline(ix, bar_y, iw, "o")
	c.unglow_rect(ix, bar_y, iw, 1)


static func _shutters(c: PixelCanvas, ix: int, iy: int, iw: int, ih: int, rng: RandomNumberGenerator) -> void:
	c.rect(ix, iy, iw, ih, "p")
	for i: int in range(0, iw, 4):
		c.vline(ix + i, iy, ih, "o")
	c.hline(ix, iy, iw, "k")
	if rng.randf() < 0.4:
		c.rect(ix + iw - 5, iy + 1, 5, ih - 1, "n")


## The qamariya over a window of outer width wide whose frame top is at base_y. Tracery is white; the glass
## segments take the letters in turn, dark when unlit.
static func qamariya(c: PixelCanvas, x: int, base_y: int, wide: int, letters: Array[String], lit: bool,
		rng: RandomNumberGenerator) -> void:
	var r: float = wide / 2.0
	var ri: float = r - 2.5
	var sector: float = PI / 5.0
	var shift: int = rng.randi_range(0, letters.size() - 1)
	for dy: int in int(r):
		for i: int in wide:
			var fx: float = i + 0.5 - r
			var fy: float = dy + 0.5
			var d: float = sqrt(fx * fx + fy * fy)
			if d > r:
				continue
			var angle: float = atan2(fy, fx)
			var k: int = clampi(int(angle / sector), 0, 4)
			var tracery: bool = d > ri - 1.0 or absf(d - ri * 0.4) < 0.6 or d < 1.0
			tracery = tracery or minf(absf(angle - k * sector), absf((k + 1) * sector - angle)) * d < 0.8
			var letter: String = letters[(k + shift) % letters.size()] if d >= ri * 0.4 else letters[shift]
			var yy: int = base_y - 1 - dy
			if d > ri:
				c.px(x + i, yy, "g" if fx > r * 0.4 else "w")
			elif tracery:
				c.px(x + i, yy, "w")
			elif lit:
				c.px(x + i, yy, letter)
				c.glow_px(x + i, yy, letter)
			else:
				c.px(x + i, yy, "i" if (i + dy) % 7 == 0 else "n")


## True when pixel (x, y) is inside an arch of half-width half over straight rows, resting on bottom.
static func in_arch(x: int, y: int, cx: float, bottom: int, half: float, straight: int) -> bool:
	var fx: float = x + 0.5 - cx
	var top: float = bottom - straight
	if y + 0.5 >= top:
		return absf(fx) <= half and y <= bottom
	var up: float = top - (y + 0.5)
	return sqrt(fx * fx + up * up) <= half


## An arched wooden door in a gypsum frame, centred on the line x = cx, standing on row bottom.
static func door(c: PixelCanvas, cx: int, bottom: int) -> void:
	var half: float = DOOR_HALF
	var inner: float = half - FRAME
	for y: int in range(bottom - DOOR_STRAIGHT - DOOR_HALF - 1, bottom + 1):
		for x: int in range(cx - DOOR_HALF - 1, cx + DOOR_HALF + 1):
			if not in_arch(x, y, cx, bottom, half, DOOR_STRAIGHT):
				continue
			if not in_arch(x, y, cx, bottom, inner, DOOR_STRAIGHT):
				c.px(x, y, "g" if x >= cx + 4 else "w")
			else:
				var col: int = (x - (cx - int(inner))) % 5
				c.px(x, y, "o" if col == 0 else ("s" if col == 3 else "p"))
	for stud: int in 2:
		c.rect(cx - 6 + stud * 10, bottom - 28, 2, 2, "y")
	c.hline(cx - int(inner), bottom, int(inner) * 2, "n")
