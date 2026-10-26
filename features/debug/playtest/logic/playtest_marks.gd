class_name PlaytestMarks
extends RefCounted
## purpose: Stamps a capture's strokes onto the screenshot as square marks one pixel apart along every segment.

const STAMP_STEP: float = 1.0


## Paints `strokes` (overlay space) onto `image` through `xform`, a square of `width_px` every pixel; a lone
## point becomes one dot and anything outside the image is clipped away.
static func paint(image: Image, strokes: Array[PackedVector2Array], xform: Transform2D, color: Color,
		width_px: int) -> void:
	if image == null or image.is_empty():
		return
	var size: int = maxi(width_px, 1)
	var half: int = size / 2
	var bounds := Rect2i(0, 0, image.get_width(), image.get_height())
	for stroke: PackedVector2Array in strokes:
		if stroke.is_empty():
			continue
		if stroke.size() == 1:
			_stamp(image, bounds, xform * stroke[0], half, size, color)
			continue
		for i: int in stroke.size() - 1:
			_line(image, bounds, xform * stroke[i], xform * stroke[i + 1], half, size, color)


static func _line(image: Image, bounds: Rect2i, a: Vector2, b: Vector2, half: int, size: int,
		color: Color) -> void:
	var delta: Vector2 = b - a
	var steps: int = maxi(1, ceili(delta.length() / STAMP_STEP))
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		_stamp(image, bounds, a + delta * t, half, size, color)


static func _stamp(image: Image, bounds: Rect2i, point: Vector2, half: int, size: int, color: Color) -> void:
	var rect := Rect2i(roundi(point.x) - half, roundi(point.y) - half, size, size)
	var clipped: Rect2i = rect.intersection(bounds)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return
	image.fill_rect(clipped, color)
