class_name BattleTrackArt
extends Control
## The painted brass track of the timeline bar: dark glass, brass rails, tick marks, the tinted cast zone, a
## gypsum zigzag frieze along the bottom, the COMMAND mark (a brass line with diamonds) and an end cap at ACT.
## Captions are child labels. mark_fraction is where COMMAND sits on the track (0..1). Compact: a thin track with
## no captions and no frieze (the HUD v3 timeline).

var mark_fraction: float = 0.5
var _style: UiStyleDef
var _command: Label
var _cast: Label
var _compact: bool = false


func setup(content_height: float, fraction: float, compact: bool = false) -> void:
	_compact = compact
	_style = Ui.style()
	mark_fraction = fraction
	custom_minimum_size.y = content_height
	size.y = content_height
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if compact:
		resized.connect(queue_redraw)
		return
	_command = Ui.label(Ui.text("UI_COMMAND"), &"CaptionLabel")
	_cast = Ui.label(Ui.text("UI_CAST"), &"CaptionLabel", _style.colour(&"c_magenta"))
	for caption: Label in [_command, _cast]:
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.size.y = content_height - _style.size(&"s_frieze_h")
		add_child(caption)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var pad: float = _style.size(&"s_gap")
	var mark_x: float = mark_fraction * size.x
	_command.position = Vector2(mark_x - _command.get_minimum_size().x - pad, 0.0)
	_cast.position = Vector2(mark_x + pad, 0.0)
	queue_redraw()


func _draw() -> void:
	if _style == null:
		return
	var rail: float = _style.size(&"s_frame_line")
	var mark_x: float = mark_fraction * size.x
	draw_rect(Rect2(Vector2.ZERO, size), _style.colour(&"c_glass_deep"))
	draw_rect(Rect2(mark_x, 0.0, size.x - mark_x, size.y), _style.colour(&"c_cast"))
	for i: int in range(1, 10):
		var x: float = size.x * i / 10.0
		draw_line(Vector2(x, 0.0), Vector2(x, rail * 2.0), _style.colour(&"c_brass_dim"), 1.0)
	var fh: float = 0.0 if _compact else _style.size(&"s_frieze_h")
	if not _compact:
		draw_texture_rect(UiOrnament.frieze(_style), Rect2(0.0, size.y - fh - rail, size.x, fh), true)
	for y: float in [0.0, size.y - rail]:
		draw_rect(Rect2(0.0, y, size.x, rail), _style.colour(&"c_brass"))
	draw_line(Vector2(mark_x, 0.0), Vector2(mark_x, size.y), _style.colour(&"c_brass"), rail * 1.5)
	_diamond(Vector2(mark_x, 0.0), &"c_brass")
	_diamond(Vector2(mark_x, size.y), &"c_brass")
	_diamond(Vector2(size.x - 1.0, size.y / 2.0), &"c_gypsum")


func _diamond(at: Vector2, colour_key: StringName) -> void:
	var radius: float = _style.size(&"s_ornament")
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -radius), at + Vector2(radius, 0.0), at + Vector2(0.0, radius), at + Vector2(-radius, 0.0)]),
		_style.colour(colour_key))
