class_name PixelCanvas
extends RefCounted
## A pixel canvas painted with palette letters, with an optional emission layer (black = no glow). A clip
## rectangle limits drawing; in wrap mode coordinates wrap around so textures tile. Pure: Images only.

var img: Image
var emit: Image
var w: int
var h: int
var clip: Rect2i
var wrap: bool = false
var _colors: Dictionary[String, Color]


func _init(width: int, height: int, colors: Dictionary[String, Color]) -> void:
	w = width
	h = height
	_colors = colors
	img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	emit = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	emit.fill(Color.BLACK)
	clip = Rect2i(0, 0, width, height)


func color_of(letter: String) -> Color:
	return _colors.get(letter, Color.MAGENTA)


## One pixel; outside the clip it is ignored (wrapped into the canvas first in wrap mode).
func px(x: int, y: int, letter: String) -> void:
	if wrap:
		x = posmod(x, w)
		y = posmod(y, h)
	elif not clip.has_point(Vector2i(x, y)):
		return
	img.set_pixel(x, y, color_of(letter))


## Marks a pixel as glowing in the colour of letter (the picture itself is not changed).
func glow_px(x: int, y: int, letter: String) -> void:
	if clip.has_point(Vector2i(x, y)):
		emit.set_pixel(x, y, color_of(letter))


func rect(x: int, y: int, rw: int, rh: int, letter: String) -> void:
	if wrap:
		for yy: int in rh:
			for xx: int in rw:
				px(x + xx, y + yy, letter)
		return
	var r: Rect2i = clip.intersection(Rect2i(x, y, rw, rh))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, color_of(letter))


func glow_rect(x: int, y: int, rw: int, rh: int, letter: String) -> void:
	var r: Rect2i = clip.intersection(Rect2i(x, y, rw, rh))
	if r.size.x > 0 and r.size.y > 0:
		emit.fill_rect(r, color_of(letter))


## Switches the glow off again inside a rectangle (a window bar over lit glass).
func unglow_rect(x: int, y: int, rw: int, rh: int) -> void:
	var r: Rect2i = clip.intersection(Rect2i(x, y, rw, rh))
	if r.size.x > 0 and r.size.y > 0:
		emit.fill_rect(r, Color.BLACK)


func hline(x: int, y: int, length: int, letter: String) -> void:
	rect(x, y, length, 1, letter)


func vline(x: int, y: int, length: int, letter: String) -> void:
	rect(x, y, 1, length, letter)


## A filled ellipse centred at (cx, cy) with radii rx, ry.
func disc(cx: int, cy: int, rx: int, ry: int, letter: String) -> void:
	for dy: int in range(-ry, ry + 1):
		for dx: int in range(-rx, rx + 1):
			var nx: float = float(dx) / maxf(rx, 0.5)
			var ny: float = float(dy) / maxf(ry, 0.5)
			if nx * nx + ny * ny <= 1.0:
				px(cx + dx, cy + dy, letter)


## Mipmapped images ready for textures: [albedo, emission].
func finish() -> Array[Image]:
	img.generate_mipmaps()
	emit.generate_mipmaps()
	return [img, emit]
