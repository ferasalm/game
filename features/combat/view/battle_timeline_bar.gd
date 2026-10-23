class_name BattleTimelineBar
extends Control
## The thin top bar of the battle: a slim brass track from 0 to ACT_POINT with a COMMAND mark and a tinted cast zone
## (BattleTrackArt, compact), one small head icon per living unit at its timeline position (foes above the track, the
## party below it), and at the left the name of the chosen target. A targeted unit's icon is ringed and raised; foes
## of one kind carry their letter. Under 6% of the screen height.

var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _icons: Dictionary[StringName, Panel] = {}
var _rings: Dictionary[StringName, Panel] = {}
var _track: BattleTrackArt
var _target_label: Label
var _target_id: StringName = &""
var _ghost: BattleTimelineGhost


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = height()
	_track = BattleTrackArt.new()
	_track.position.y = view.timeline_top + view.timeline_icon
	add_child(_track)
	_track.setup(view.timeline_track, float(Timeline.COMMAND_POINT) / Timeline.ACT_POINT, true)
	_target_label = BattleStyle.label("", &"NameLabel", view.highlight_color)
	_target_label.add_theme_font_size_override("font_size", view.target_font)
	_target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_target_label.clip_text = true
	_target_label.position = Vector2(view.margin, _track.position.y + view.timeline_track / 2.0 - view.target_font)
	_target_label.size = Vector2(0.0, view.target_font * 2.0)
	add_child(_target_label)
	_ghost = BattleTimelineGhost.create(view)
	add_child(_ghost)
	for unit: UnitState in sim.timeline.units:
		_add_icon(unit)


## The whole bar's height in pixels: top margin, the foe lane, the track and the party lane.
func height() -> float:
	return _view.timeline_top + _view.timeline_icon * 2.0 + _view.timeline_track


## How many unit icons are showing (living units).
func visible_icons() -> int:
	var count: int = 0
	for icon: Panel in _icons.values():
		count += 1 if icon.visible else 0
	return count


func icon_count() -> int:
	return _icons.size()


func icon_of(unit_id: StringName) -> Panel:
	return _icons.get(unit_id)


## The chosen target ("" for none): its name goes to the left of the track, its icon gets a ring and rises.
func set_target(unit_id: StringName, caption: String) -> void:
	_target_id = unit_id
	_target_label.text = caption if unit_id != &"" else ""
	for id: StringName in _rings:
		_rings[id].visible = id == unit_id
		_icons[id].scale = Vector2.ONE * (1.25 if id == unit_id else 1.0)


## The track and every showing icon (the bar's own full-width box is mostly empty).
func visible_rects() -> Array[Rect2]:
	var out: Array[Rect2] = [_track.get_global_rect()]
	for icon: Panel in _icons.values():
		if icon.is_visible_in_tree():
			out.append(icon.get_global_rect())
	return out


func target_id() -> StringName:
	return _target_id


func target_text() -> String:
	return _target_label.text


func is_ringed(unit_id: StringName) -> bool:
	return _rings.has(unit_id) and _rings[unit_id].visible


func show_ghost(unit_id: StringName, pos: int) -> void:
	if _ghost != null:
		_ghost.show_at(unit_id, pos)


func hide_ghost() -> void:
	if _ghost != null:
		_ghost.hide_ghost()


func has_ghost() -> bool:
	return _ghost != null and _ghost.visible


func ghost_pos() -> int:
	return _ghost.pos if _ghost != null else -1


func _process(_delta: float) -> void:
	if _sim == null:
		return
	var track_x: float = (size.x - _view.timeline_width) / 2.0
	_track.position.x = track_x
	_track.size.x = _view.timeline_width
	_target_label.size.x = maxf(0.0, track_x - _view.margin * 2.0)
	for unit: UnitState in _sim.timeline.units:
		_place(unit, track_x)
	if _ghost != null:
		_ghost.update_position(_sim, _view, track_x)


func _place(unit: UnitState, track_x: float) -> void:
	var icon: Panel = _icons[unit.unit_id]
	icon.visible = _shown_hp.get(unit.unit_id, 0) > 0
	var span: float = _view.timeline_width - _view.timeline_icon
	var x: float = track_x + clampf(float(unit.pos) / Timeline.ACT_POINT, 0.0, 1.0) * span
	var y: float = float(_view.timeline_top)
	if unit.side == 0:
		y += _view.timeline_icon + _view.timeline_track
	if unit.unit_id == _target_id:
		y += -_view.timeline_raise if unit.side == 1 else _view.timeline_raise
	icon.position = Vector2(x, y)


func _add_icon(unit: UnitState) -> void:
	var style: UiStyleDef = Ui.style()
	var side: float = float(_view.timeline_icon)
	var icon := Panel.new()
	icon.size = Vector2(side, side)
	icon.pivot_offset = icon.size / 2.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_theme_stylebox_override("panel", UiBoxes.medallion(style, style.colour(&"c_brass")))
	var face: Control = BattleStyle.head_icon(unit.def.id, unit.side)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: float = style.size(&"s_frame_line")
	face.offset_left = inset
	face.offset_top = inset
	face.offset_right = -inset
	face.offset_bottom = -inset
	for initial: Node in face.get_children():  # the disc's initial is sized for a big icon
		if initial is Label:
			(initial as Label).add_theme_font_size_override("font_size", _view.letter_font + 2)
			(initial as Label).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.add_child(face)
	icon.add_child(_ring(unit.unit_id))
	var letter: String = UnitLetters.of(_sim.timeline.units, unit)
	if not letter.is_empty():
		icon.add_child(_letter(letter, unit.side))
	add_child(icon)
	_icons[unit.unit_id] = icon


func _ring(unit_id: StringName) -> Panel:
	var ring := Panel.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = -_view.ring_width
	ring.offset_top = -_view.ring_width
	ring.offset_right = _view.ring_width
	ring.offset_bottom = _view.ring_width
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = _view.highlight_color
	box.set_border_width_all(_view.ring_width)
	box.set_corner_radius_all(_view.timeline_icon)
	ring.add_theme_stylebox_override("panel", box)
	ring.visible = false
	_rings[unit_id] = ring
	return ring


## The foe's letter in a corner of its icon.
func _letter(letter: String, side: int) -> Label:
	var tag: Label = BattleStyle.label(letter, &"CaptionLabel", Color.WHITE)
	tag.add_theme_font_size_override("font_size", _view.letter_font)
	tag.add_theme_color_override("font_outline_color", _view.party_color if side == 0 else _view.enemy_color)
	tag.add_theme_constant_override("outline_size", 4)
	tag.position = Vector2(_view.timeline_icon * 0.55, _view.timeline_icon * 0.35)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tag
