class_name HoloMapLabels
extends RefCounted
## purpose: Resolve overlapping 2D map labels by iterative repulsion, keeping them inside bounds.

const ITERATIONS: int = 6
const FONT_SIZE: int = 16


static func make(font: Font, pos: Vector2, text: String, color: Color, font_size: int = FONT_SIZE) -> HoloMapLabel:
	var label := HoloMapLabel.new()
	label.text = text
	label.anchor = pos
	label.pos = pos
	label.size = font.get_string_size(text, font_size)
	label.color = color
	label.font_size = font_size
	return label


static func resolve(labels: Array[HoloMapLabel], bounds: Rect2) -> Array[HoloMapLabel]:
	for _i: int in range(ITERATIONS):
		var moved: bool = false
		for a: int in range(labels.size()):
			for b: int in range(a + 1, labels.size()):
				var la: HoloMapLabel = labels[a]
				var lb: HoloMapLabel = labels[b]
				if la.rect.intersects(lb.rect):
					_resolve_pair(la, lb, bounds)
					moved = true
		if not moved:
			break
	return labels


static func _resolve_pair(a: HoloMapLabel, b: HoloMapLabel, bounds: Rect2) -> void:
	var dx: float = (a.size.x + b.size.x) * 0.5 - absf(a.pos.x - b.pos.x) + 2.0
	var dy: float = (a.size.y + b.size.y) * 0.5 - absf(a.pos.y - b.pos.y) + 2.0
	var sx: float = -1.0 if a.pos.x < b.pos.x else 1.0
	var sy: float = -1.0 if a.pos.y < b.pos.y else 1.0
	var move_x: float = maxf(dx, 0.0) * 0.5 * sx
	var move_y: float = maxf(dy, 0.0) * 0.5 * sy
	a.pos = _clamp_label(a, a.pos + Vector2(move_x, move_y), bounds)
	b.pos = _clamp_label(b, b.pos - Vector2(move_x, move_y), bounds)


static func _clamp_label(label: HoloMapLabel, pos: Vector2, bounds: Rect2) -> Vector2:
	var half: Vector2 = label.size * 0.5
	return pos.clamp(bounds.position + half, bounds.end - half)
