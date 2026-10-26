class_name MapBattleVitals
extends Control
## purpose: Rydan's slanted Hades-like HP/SP bar bottom-left (docs/design/first-playable.md section 3): an ink
## border, a dark back, red HP above and teal SP below, both cut on the iso diagonal.

var _sim: BattleSim
var _view: NeonBattleViewDef
var _shown_hp: Dictionary[StringName, int]


func setup(sim: BattleSim, view: NeonBattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = float(view.hero_bar_margin)
	offset_top = -float(view.hero_bar_margin + view.hero_bar_h * 2 + view.bar_gap)
	offset_right = float(view.hero_bar_margin + view.hero_bar_w)
	offset_bottom = -float(view.hero_bar_margin)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var hero: UnitState = null
	for unit: UnitState in _sim.timeline.units:
		if unit.side == 0:
			hero = unit
			break
	if hero == null:
		return
	var hp: float = clampf(float(_shown_hp.get(hero.unit_id, 0)) / float(hero.def.max_hp), 0.0, 1.0)
	var sp: float = clampf(float(hero.sp) / float(hero.def.max_sp), 0.0, 1.0)
	_draw_bar(Rect2(0.0, 0.0, float(_view.hero_bar_w), float(_view.hero_bar_h)), hp, _view.hp_color)
	_draw_bar(Rect2(0.0, float(_view.hero_bar_h + _view.bar_gap), float(_view.hero_bar_w),
		float(_view.hero_bar_h)), sp, _view.sp_color)


func _draw_bar(rect: Rect2, ratio: float, colour: Color) -> void:
	draw_colored_polygon(_slanted(rect.grow(3.0), float(_view.bar_slant)), _view.ink_color)
	draw_colored_polygon(_slanted(rect, float(_view.bar_slant)), _view.bar_back)
	if ratio > 0.0:
		var fill := Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y))
		draw_colored_polygon(_slanted(fill, float(_view.bar_slant) * ratio), colour)


func _slanted(rect: Rect2, slant: float) -> PackedVector2Array:
	return PackedVector2Array([rect.position + Vector2(slant, 0.0), rect.position + Vector2(rect.size.x, 0.0),
		rect.end, rect.position + Vector2(0.0, rect.size.y)])
