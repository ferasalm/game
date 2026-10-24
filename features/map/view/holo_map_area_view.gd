class_name HoloMapAreaView
extends RefCounted
## purpose: Draws the area floor plan with merged roof runs, a 45-degree hatch, crossings, markers and labels.

const HATCH_SPACING: float = 32.0
const HATCH_ALPHA: float = 0.25
const LABEL_FONT_SIZE: int = 16
const LABEL_LIFT: float = 22.0


static func draw(canvas: Control, plan: Dictionary, fit: Dictionary, markers: Array[Dictionary],
		player_world_pos: Vector3, colors: Dictionary, font: Font) -> void:
	if plan.is_empty() or not fit.has("scale"):
		return
	var scale_val: float = float(fit["scale"])
	var offset: Vector2 = fit["offset"] as Vector2
	var cyan: Color = colors.get(&"default", Color.CYAN)
	var runs: Array[Rect2i] = plan.get("runs", [])
	for run: Rect2i in merged_runs(runs):
		var r := Rect2(Vector2(run.position) * scale_val + offset, Vector2(run.size) * scale_val)
		canvas.draw_rect(r, HoloMapStyle.alpha(cyan, 0.06), true)
		canvas.draw_rect(r, cyan, false, 1.5)
		for seg: PackedVector2Array in HoloMapStyle.hatch_rect(r, HATCH_SPACING):
			canvas.draw_line(seg[0], seg[1], HoloMapStyle.alpha(cyan, HATCH_ALPHA), 1.0)
	for seg: PackedVector2Array in plan.get("crossings", []):
		if seg.size() >= 2:
			var a: Vector2 = seg[0] * scale_val + offset
			var b: Vector2 = seg[1] * scale_val + offset
			HoloMapStyle.glow_line(canvas, a, b, cyan, 2.0, 4.0)
	var labels: Array[HoloMapLabel] = label_set(font, plan, fit, colors.get(&"muted", cyan))
	HoloMapLabels.draw_all(canvas, HoloMapLabels.resolve(labels, Rect2(Vector2.ZERO, canvas.size)), font)
	for m: Dictionary in markers:
		var pos: Vector2 = m.get("pos", Vector2.ZERO) * scale_val + offset
		HoloMapMarkers.draw_icon(canvas, pos, StringName(m.get("kind", "")), colors)
	var p_screen: Vector2 = Vector2(player_world_pos.x, player_world_pos.z) * scale_val + offset
	HoloMapMarkers.draw_icon(canvas, p_screen, &"player", colors)


static func label_set(font: Font, plan: Dictionary, fit: Dictionary, color: Color) -> Array[HoloMapLabel]:
	var out: Array[HoloMapLabel] = []
	if plan.is_empty() or not fit.has("scale"):
		return out
	var scale_val: float = float(fit["scale"])
	var offset: Vector2 = fit["offset"] as Vector2
	for pl: Dictionary in plan.get("places", []):
		var name_key: String = pl.get("name_key", "")
		if not name_key.is_empty():
			var pos: Vector2 = pl.get("pos", Vector2.ZERO) * scale_val + offset
			out.append(HoloMapLabels.make(font, pos + Vector2(0.0, -LABEL_LIFT), Ui.text(name_key), color, LABEL_FONT_SIZE))
	return out


## Joins runs of the same x and width across consecutive rows so the roof reads as one block, not ladder rungs.
static func merged_runs(runs: Array[Rect2i]) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var open: Dictionary = {}
	for run: Rect2i in runs:
		var key := Vector2i(run.position.x, run.size.x)
		if open.has(key):
			var idx: int = open[key]
			var last: Rect2i = out[idx]
			if last.position.y + last.size.y == run.position.y:
				out[idx] = Rect2i(last.position, Vector2i(last.size.x, last.size.y + run.size.y))
				continue
		open[key] = out.size()
		out.append(run)
	return out
