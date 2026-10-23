class_name BattleTimelineGhost
extends Panel
## Ghost landing marker on the timeline bar for previewing knockback (section 3 and 6).

var pos: int = -1
var unit_id: StringName = &""


static func create(view: BattleViewDef) -> BattleTimelineGhost:
	var ghost := BattleTimelineGhost.new()
	var gside: float = float(view.timeline_icon)
	ghost.size = Vector2(gside, gside)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate.a = 0.5
	var gbox := StyleBoxFlat.new()
	gbox.bg_color = Color(1.0, 1.0, 1.0, 0.25)
	gbox.border_color = view.highlight_color
	gbox.set_border_width_all(2)
	gbox.set_corner_radius_all(view.timeline_icon)
	ghost.add_theme_stylebox_override("panel", gbox)
	ghost.visible = false
	return ghost


func show_at(new_unit_id: StringName, new_pos: int) -> void:
	unit_id = new_unit_id
	pos = new_pos
	visible = pos >= 0


func hide_ghost() -> void:
	pos = -1
	unit_id = &""
	visible = false


func update_position(sim: BattleSim, view: BattleViewDef, track_x: float) -> void:
	if not visible or pos < 0 or sim == null:
		return
	var span: float = view.timeline_width - view.timeline_icon
	var gx: float = track_x + clampf(float(pos) / Timeline.ACT_POINT, 0.0, 1.0) * span
	var target_unit: UnitState = sim.timeline.find(unit_id) if unit_id != &"" else null
	var gy: float = float(view.timeline_top)
	if target_unit != null and target_unit.side == 0:
		gy += view.timeline_icon + view.timeline_track
	position = Vector2(gx, gy)
