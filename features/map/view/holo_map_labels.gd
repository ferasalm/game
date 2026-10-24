class_name HoloMapLabels
extends RefCounted
## purpose: Place 2D map labels apart from each other and obstacles, and draw them with leader lines.

const FONT_SIZE: int = 16
const LEADER_MIN: float = 20.0
const MAX_PASSES: int = 64


static func make(font: Font, pos: Vector2, text: String, color: Color, font_size: int = FONT_SIZE) -> HoloMapLabel:
	var label := HoloMapLabel.new()
	label.text = text
	label.anchor = pos
	label.pos = pos
	label.size = font.get_string_size(text, font_size)
	label.color = color
	label.font_size = font_size
	return label


static func make_boxed(font: Font, musnad_font: Font, pos: Vector2, text: String, musnad_text: String,
		look: HoloCityLook) -> HoloMapLabel:
	var label := HoloMapLabel.new()
	label.text = text.to_upper()
	label.musnad_text = musnad_text
	label.anchor = pos
	label.pos = pos
	label.font_size = int(look.get_size("font_en"))
	label.musnad_font = musnad_font
	label.musnad_font_size = int(look.get_size("font_musnad"))
	label.is_boxed = true
	label.box_bg_color = look.get_color("label_box")
	label.box_border_color = look.get_color("cyan")
	label.box_bg_alpha = look.get_alpha("label_box")

	var pad_x: float = look.get_size("label_pad_x")
	var pad_y: float = look.get_size("label_pad_y")
	var gap: float = look.get_size("label_gap")

	var en_size: Vector2 = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, label.font_size)
	var mus_size: Vector2 = musnad_font.get_string_size(label.musnad_text, HORIZONTAL_ALIGNMENT_CENTER, -1, label.musnad_font_size)
	var content_w: float = maxf(en_size.x, mus_size.x)
	var content_h: float = en_size.y + mus_size.y + gap
	label.size = Vector2(content_w + pad_x * 2.0, content_h + pad_y * 2.0)
	return label


static func resolve(labels: Array[HoloMapLabel], bounds: Rect2, obstacles: Array[Rect2] = []) -> Array[HoloMapLabel]:
	for label: HoloMapLabel in labels:
		label.pos = _clamp_label(label, label.anchor, bounds)
	for _pass_idx: int in range(MAX_PASSES):
		var moved: bool = false
		for i: int in range(labels.size()):
			var push: Vector2 = _label_push(i, labels) + _obstacle_push(labels[i], obstacles)
			if push != Vector2.ZERO:
				moved = true
				labels[i].pos = _clamp_label(labels[i], labels[i].pos + push, bounds)
		if not moved:
			break
	return labels


static func _label_push(i: int, labels: Array[HoloMapLabel]) -> Vector2:
	var li: HoloMapLabel = labels[i]
	var ri: Rect2 = li.rect
	var push := Vector2.ZERO
	for j: int in range(labels.size()):
		if i == j:
			continue
		var rj: Rect2 = labels[j].rect
		if ri.intersects(rj):
			var diff: Vector2 = li.pos - labels[j].pos
			if diff.length_squared() < 0.01:
				diff = Vector2(0.0, -1.0 if i < j else 1.0)
			var ox: float = (ri.size.x + rj.size.x) * 0.5 - absf(diff.x)
			var oy: float = (ri.size.y + rj.size.y) * 0.5 - absf(diff.y)
			if ox > 0.0 and oy > 0.0:
				if oy <= ox:
					push.y += (1.0 if diff.y >= 0.0 else -1.0) * (oy * 0.5 + 1.0)
				else:
					push.x += (1.0 if diff.x >= 0.0 else -1.0) * (ox * 0.5 + 1.0)
	return push


static func _obstacle_push(label: HoloMapLabel, obstacles: Array[Rect2]) -> Vector2:
	var r: Rect2 = label.rect
	var push := Vector2.ZERO
	for obs: Rect2 in obstacles:
		if r.intersects(obs):
			var diff: Vector2 = label.pos - (obs.position + obs.size * 0.5)
			if diff.length_squared() < 0.01:
				diff = Vector2(0.0, -1.0)
			var ox: float = (r.size.x + obs.size.x) * 0.5 - absf(diff.x)
			var oy: float = (r.size.y + obs.size.y) * 0.5 - absf(diff.y)
			if ox > 0.0 and oy > 0.0:
				if oy <= ox:
					push.y += (1.0 if diff.y >= 0.0 else -1.0) * (oy + 1.0)
				else:
					push.x += (1.0 if diff.x >= 0.0 else -1.0) * (ox + 1.0)
	return push


static func draw_all(canvas: Control, labels: Array[HoloMapLabel], font: Font) -> void:
	for label: HoloMapLabel in labels:
		if label.is_boxed:
			_draw_boxed_label(canvas, label, font)
		else:
			_draw_plain_label(canvas, label, font)


static func _draw_boxed_label(canvas: Control, label: HoloMapLabel, font: Font) -> void:
	if label.anchor.distance_to(label.pos) > LEADER_MIN:
		var end: Vector2 = _closest_on_rect(label.glyph_rect, label.anchor)
		canvas.draw_line(label.anchor, end, Color(label.box_border_color.r, label.box_border_color.g,
			label.box_border_color.b, 0.45), 1.0)
		canvas.draw_circle(label.anchor, 2.0, Color(label.box_border_color.r, label.box_border_color.g,
			label.box_border_color.b, 0.6))
	var box: Rect2 = label.glyph_rect
	canvas.draw_rect(box, Color(label.box_bg_color.r, label.box_bg_color.g, label.box_bg_color.b,
		label.box_bg_alpha), true)
	canvas.draw_rect(box, label.box_border_color, false, 1.0)

	var en_y: float = box.position.y + 6.0 + font.get_ascent(label.font_size)
	canvas.draw_string(font, Vector2(box.position.x, en_y), label.text, HORIZONTAL_ALIGNMENT_CENTER,
		box.size.x, label.font_size, Color.WHITE)
	if label.musnad_font != null and not label.musnad_text.is_empty():
		var mus_y: float = en_y + font.get_descent(label.font_size) + 4.0 + label.musnad_font.get_ascent(label.musnad_font_size)
		canvas.draw_string(label.musnad_font, Vector2(box.position.x, mus_y), label.musnad_text,
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x, label.musnad_font_size, label.box_border_color)


static func _draw_plain_label(canvas: Control, label: HoloMapLabel, font: Font) -> void:
	if label.anchor.distance_to(label.pos) > LEADER_MIN:
		var end: Vector2 = _closest_on_rect(label.glyph_rect, label.anchor)
		canvas.draw_line(label.anchor, end, Color(label.color.r, label.color.g, label.color.b, 0.45), 1.0)
		canvas.draw_circle(label.anchor, 2.0, Color(label.color.r, label.color.g, label.color.b, 0.6))
	var ascent: float = font.get_ascent(label.font_size)
	var descent: float = font.get_descent(label.font_size)
	var baseline: Vector2 = label.pos + Vector2(-label.size.x * 0.5, (ascent - descent) * 0.5)
	canvas.draw_string(font, baseline, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size, label.color)


static func _clamp_label(label: HoloMapLabel, pos: Vector2, bounds: Rect2) -> Vector2:
	var half: Vector2 = label.rect.size * 0.5
	return Vector2(
		clampf(pos.x, bounds.position.x + half.x, bounds.end.x - half.x),
		clampf(pos.y, bounds.position.y + half.y, bounds.end.y - half.y))


static func _closest_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
