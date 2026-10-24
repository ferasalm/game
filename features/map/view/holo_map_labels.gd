class_name HoloMapLabels
extends RefCounted
## purpose: Place 2D map labels apart from each other, keep them inside bounds, and draw them with leader lines.

const FONT_SIZE: int = 16
const STEP: float = 4.0
const MAX_RINGS: int = 60
const LEADER_MIN: float = 20.0


static func make(font: Font, pos: Vector2, text: String, color: Color, font_size: int = FONT_SIZE) -> HoloMapLabel:
	var label := HoloMapLabel.new()
	label.text = text
	label.anchor = pos
	label.pos = pos
	label.size = font.get_string_size(text, font_size)
	label.color = color
	label.font_size = font_size
	return label


## Pushes every label away from the ones already placed, searching outward in rings around its anchor.
static func resolve(labels: Array[HoloMapLabel], bounds: Rect2) -> Array[HoloMapLabel]:
	var placed: Array[HoloMapLabel] = []
	for label: HoloMapLabel in labels:
		label.pos = _clamp_label(label, label.anchor, bounds)
		if _fits(label, placed):
			placed.append(label)
			continue
		if not _search(label, placed, bounds):
			_push_down(label, placed, bounds)
		placed.append(label)
	return labels


static func draw_all(canvas: Control, labels: Array[HoloMapLabel], font: Font) -> void:
	for label: HoloMapLabel in labels:
		if label.anchor.distance_to(label.pos) > LEADER_MIN:
			var end: Vector2 = _closest_on_rect(label.rect, label.anchor)
			canvas.draw_line(label.anchor, end, Color(label.color.r, label.color.g, label.color.b, 0.45), 1.0)
			canvas.draw_circle(label.anchor, 2.0, Color(label.color.r, label.color.g, label.color.b, 0.6))
		var ascent: float = font.get_ascent(label.font_size)
		var descent: float = font.get_descent(label.font_size)
		var baseline: Vector2 = label.pos + Vector2(-label.size.x * 0.5, (ascent - descent) * 0.5)
		canvas.draw_string(font, baseline, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size, label.color)


static func _search(label: HoloMapLabel, placed: Array[HoloMapLabel], bounds: Rect2) -> bool:
	for ring: int in range(1, MAX_RINGS + 1):
		for direction: Vector2 in _ring(ring):
			label.pos = _clamp_label(label, label.anchor + direction * STEP, bounds)
			if _fits(label, placed):
				return true
	return false


static func _ring(ring: int) -> Array[Vector2]:
	var r: float = float(ring)
	return [
		Vector2(0.0, -r), Vector2(r, -r), Vector2(r, 0.0), Vector2(r, r),
		Vector2(0.0, r), Vector2(-r, r), Vector2(-r, 0.0), Vector2(-r, -r),
	]


static func _fits(label: HoloMapLabel, placed: Array[HoloMapLabel]) -> bool:
	for other: HoloMapLabel in placed:
		if label.rect.intersects(other.rect):
			return false
	return true


static func _push_down(label: HoloMapLabel, placed: Array[HoloMapLabel], bounds: Rect2) -> void:
	var y: float = label.pos.y
	while y <= bounds.end.y - label.size.y * 0.5:
		label.pos = Vector2(label.pos.x, y)
		if _fits(label, placed):
			return
		y += STEP


static func _clamp_label(label: HoloMapLabel, pos: Vector2, bounds: Rect2) -> Vector2:
	var half: Vector2 = label.size * 0.5
	return pos.clamp(bounds.position + half, bounds.end - half)


static func _closest_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y))
