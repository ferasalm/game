class_name PixelArt
extends RefCounted
## Turns a palette-indexed sprite (rows of letters) into an Image or texture. Pure: no nodes, no scene tree.

const TRANSPARENT: String = "."
const UNKNOWN: Color = Color(1.0, 0.0, 1.0)


static func image(sprite: SpriteDef, palette: PaletteDef) -> Image:
	var out := Image.create_empty(maxi(sprite.width(), 1), maxi(sprite.height(), 1), false, Image.FORMAT_RGBA8)
	out.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y: int in sprite.height():
		var row: String = sprite.rows[y]
		for x: int in mini(row.length(), out.get_width()):
			var letter: String = row[x]
			if letter != TRANSPARENT:
				out.set_pixel(x, y, palette.colors.get(letter, UNKNOWN))
	return out


static func texture(sprite: SpriteDef, palette: PaletteDef) -> ImageTexture:
	return ImageTexture.create_from_image(image(sprite, palette))


## A solid magenta block, shown when a sprite id is missing.
static func placeholder(width: int, height: int) -> Image:
	var out := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	out.fill(UNKNOWN)
	return out
