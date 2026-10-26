class_name MapBattleFoeBars
extends Control
## purpose: Small HP bars over the foes' heads on the iso map (docs/design/first-playable.md section 3), kept on
## their feet point through the canvas transform and hidden once a foe is down.

var _view: NeonBattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _actors: Dictionary[StringName, IsoActor]
var _bars: Dictionary[StringName, Dictionary] = {}


func setup(sim: BattleSim, view: NeonBattleViewDef, shown_hp: Dictionary[StringName, int],
		actors: Dictionary[StringName, IsoActor]) -> void:
	_view = view
	_shown_hp = shown_hp
	_actors = actors
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for unit: UnitState in sim.timeline.units:
		if unit.side != 1:
			continue
		var back := ColorRect.new()
		back.color = view.ink_color
		back.size = Vector2(view.foe_bar_w + 2, view.foe_bar_h + 2)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(back)
		var fill := ColorRect.new()
		fill.color = view.foe_color
		fill.size = Vector2(view.foe_bar_w, view.foe_bar_h)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
		_bars[unit.unit_id] = {"unit": unit, "back": back, "fill": fill}


func refresh() -> void:
	for unit_id: StringName in _bars:
		var entry: Dictionary = _bars[unit_id]
		var unit: UnitState = entry["unit"]
		var fill: ColorRect = entry["fill"]
		var back: ColorRect = entry["back"]
		var alive: bool = _shown_hp.get(unit_id, 0) > 0
		back.visible = alive
		fill.visible = alive
		fill.size.x = float(_view.foe_bar_w) * clampf(
			float(_shown_hp.get(unit_id, 0)) / float(unit.def.max_hp), 0.0, 1.0)


func _process(_delta: float) -> void:
	var transform: Transform2D = get_viewport().get_canvas_transform()
	for unit_id: StringName in _bars:
		var actor: IsoActor = _actors.get(unit_id)
		if actor == null or not is_instance_valid(actor):
			continue
		var entry: Dictionary = _bars[unit_id]
		var spot: Vector2 = transform * (actor.position + Vector2(0.0,
			-actor.height() - float(_view.foe_bar_offset)))
		var origin: Vector2 = spot - Vector2(float(_view.foe_bar_w) * 0.5, 0.0)
		(entry["back"] as ColorRect).position = origin
		(entry["fill"] as ColorRect).position = origin
