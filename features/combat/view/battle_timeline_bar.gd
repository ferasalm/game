class_name BattleTimelineBar
extends Control
## The timeline along the top: an ornate brass track from 0 to ACT_POINT with a COMMAND mark and a tinted cast
## zone (BattleTrackArt), and one framed head icon per living unit at its timeline position (enemies above the
## track, the party below it, a small pointer in the team colour toward the track).

var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _icons: Dictionary[StringName, Panel] = {}
var _track: BattleTrackArt
var _gap: float = 0.0
var _track_height: float = 0.0
var _icon: float = 0.0


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	var style: UiStyleDef = Ui.style()
	_icon = style.size(&"s_icon")
	_gap = style.size(&"s_gap")
	_track_height = style.size(&"s_font_small") * 1.7 + style.size(&"s_frieze_h")
	var total: float = _icon * 2.0 + _gap * 2.0 + _track_height
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = view.margin
	offset_right = -view.margin
	offset_top = view.margin
	offset_bottom = view.margin + total
	_track = BattleTrackArt.new()
	_track.position.y = _icon + _gap
	add_child(_track)
	_track.setup(_track_height, float(Timeline.COMMAND_POINT) / Timeline.ACT_POINT)
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
	_track.size.x = width
	for unit: UnitState in _sim.timeline.units:
		_place(unit, width)


func _place(unit: UnitState, width: float) -> void:
	var icon: Panel = _icons[unit.unit_id]
	var shown: int = _shown_hp.get(unit.unit_id, 0)
	icon.visible = shown > 0
	var x: float = float(unit.pos) / Timeline.ACT_POINT * width - _icon / 2.0
	var y: float = 0.0
	if unit.side == 0:
		y = _icon + _gap * 2.0 + _track_height
	icon.position = Vector2(clampf(x, 0.0, width - _icon), y)


func _add_icon(unit: UnitState) -> void:
	var style: UiStyleDef = Ui.style()
	var icon := Panel.new()
	icon.size = Vector2(_icon, _icon)
	var team: Color = style.colour(&"c_party" if unit.side == 0 else &"c_enemy")
	icon.add_theme_stylebox_override("panel", UiBoxes.medallion(style, style.colour(&"c_brass")))
	var face := TextureRect.new()
	face.texture = BattleStyle.head_icon(unit.def.id)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: float = style.size(&"s_frame_gap")
	face.offset_left = inset
	face.offset_top = inset
	face.offset_right = -inset
	face.offset_bottom = -inset
	icon.add_child(face)
	icon.add_child(_pointer(unit.side == 0, team))
	add_child(icon)
	_icons[unit.unit_id] = icon


## The small team-coloured triangle on the edge of an icon that faces the track.
func _pointer(party: bool, team: Color) -> Polygon2D:
	var half: float = _gap * 0.8
	var tip: float = _gap * 1.1
	var pointer := Polygon2D.new()
	pointer.color = team
	var mid: float = _icon / 2.0
	if party:
		pointer.polygon = PackedVector2Array([Vector2(mid - half, 0.0), Vector2(mid + half, 0.0), Vector2(mid, -tip)])
	else:
		pointer.polygon = PackedVector2Array([
			Vector2(mid - half, _icon), Vector2(mid + half, _icon), Vector2(mid, _icon + tip)])
	return pointer
