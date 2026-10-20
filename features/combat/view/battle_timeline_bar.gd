class_name BattleTimelineBar
extends Control
## The timeline along the top: a track from 0 to ACT_POINT with a COMMAND mark and a tinted cast zone, and one
## head icon per living unit at its timeline position (enemies above the track, the party below it).

var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _icons: Dictionary[StringName, Panel] = {}
var _track: ColorRect
var _zone: ColorRect
var _mark: ColorRect
var _gap: float = 0.0
var _track_height: float = 0.0


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	_gap = view.bar_height / 2.0
	_track_height = view.font_size + view.margin / 4.0
	var total: float = view.icon_size * 2.0 + _gap * 2.0 + _track_height
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = view.margin
	offset_right = -view.margin
	offset_top = view.margin
	offset_bottom = view.margin + total
	_build_track()
	for unit: UnitState in sim.timeline.units:
		_add_icon(unit)


func height() -> float:
	return offset_bottom


## How many unit icons are showing (living units).
func visible_icons() -> int:
	var count: int = 0
	for icon: Panel in _icons.values():
		count += 1 if icon.visible else 0
	return count


func icon_count() -> int:
	return _icons.size()


func _process(_delta: float) -> void:
	if _sim == null:
		return
	var width: float = size.x
	_track.size = Vector2(width, _track_height)
	var mark_x: float = float(Timeline.COMMAND_POINT) / Timeline.ACT_POINT * width
	_mark.position.x = mark_x - _mark.size.x / 2.0
	_zone.position.x = mark_x
	_zone.size.x = width - mark_x
	for unit: UnitState in _sim.timeline.units:
		_place(unit, width)


func _place(unit: UnitState, width: float) -> void:
	var icon: Panel = _icons[unit.unit_id]
	var shown: int = _shown_hp.get(unit.unit_id, 0)
	icon.visible = shown > 0
	var x: float = float(unit.pos) / Timeline.ACT_POINT * width - _view.icon_size / 2.0
	var y: float = 0.0
	if unit.side == 0:
		y = _view.icon_size + _gap * 2.0 + _track_height
	icon.position = Vector2(clampf(x, 0.0, width - _view.icon_size), y)


func _build_track() -> void:
	_track = ColorRect.new()
	_track.color = _view.panel_color
	_track.position.y = _view.icon_size + _gap
	add_child(_track)
	_zone = ColorRect.new()
	_zone.color = _view.cast_color
	_zone.size.y = _track_height
	_track.add_child(_zone)
	_mark = ColorRect.new()
	_mark.color = _view.highlight_color
	_mark.size = Vector2(_view.margin / 6.0, _track_height)
	_track.add_child(_mark)
	_caption(BattleStyle.text("UI_COMMAND"), _mark, true)
	_caption(BattleStyle.text("UI_CAST"), _zone, false)


func _caption(content: String, parent: Control, left_of: bool) -> void:
	var label: Label = BattleStyle.label(content, _view.highlight_color)
	parent.add_child(label)
	var pad: float = _view.margin / 4.0
	label.position = Vector2(pad, 0.0)
	if left_of:
		label.position.x = -label.get_minimum_size().x - pad
	label.size.y = _track_height
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _add_icon(unit: UnitState) -> void:
	var icon := Panel.new()
	icon.size = Vector2(_view.icon_size, _view.icon_size)
	var border: Color = _view.party_color if unit.side == 0 else _view.enemy_color
	icon.add_theme_stylebox_override("panel", BattleStyle.panel(_view, border))
	var face := TextureRect.new()
	face.texture = BattleStyle.head_icon(unit.def.id)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: float = _view.margin / 8.0
	face.offset_left = inset
	face.offset_top = inset
	face.offset_right = -inset
	face.offset_bottom = -inset
	icon.add_child(face)
	add_child(icon)
	_icons[unit.unit_id] = icon
