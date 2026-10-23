class_name PuzzleHintsView
extends Node
## purpose: Tracks each puzzle's stall time and shows every due hint once for a few seconds in a bottom label.

const RETURN_KEY: StringName = &"PUZZLE_WATER_RETURN"

var yard: PuzzleYardDef
var light_def: LightLockDef
var water_def: WaterNetDef
var label: Label

var _light_stall: float = 0.0
var _water_stall: float = 0.0
var _shown_light: int = 0
var _shown_water: int = 0
var _queue: Array[StringName] = []
var _timer: float = 0.0
var _grate_watered: bool = false


func setup(def_yard: PuzzleYardDef, def_light: LightLockDef, def_water: WaterNetDef) -> void:
	yard = def_yard
	light_def = def_light
	water_def = def_water
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -90.0
	label.offset_bottom = -30.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	layer.add_child(label)


func advance(delta: float, light_done: bool, water_done: bool) -> void:
	if not light_done:
		_light_stall += delta
	elif not water_done:
		_water_stall += delta


func due(light_done: bool, water_done: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	if not light_done:
		var count: int = PuzzleHints.hints_due(light_def.hint_secs, _light_stall)
		out.append_array(_new_keys(light_def.hint_keys, count, true))
	elif not water_done:
		var water_count: int = PuzzleHints.hints_due(water_def.hint_secs, _water_stall)
		out.append_array(_new_keys(water_def.hint_keys, water_count, false))
	return out


func queue_hint(key: StringName) -> void:
	_queue.append(key)


func check_return(active: bool, share: float) -> void:
	if not active:
		return
	if share > 0.0 and not _grate_watered:
		_grate_watered = true
		queue_hint(RETURN_KEY)
	elif share <= 0.0:
		_grate_watered = false


func update_label(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			label.visible = false
		return
	if _queue.is_empty():
		return
	label.text = tr(_queue.pop_front())
	label.visible = true
	_timer = yard.hint_show_secs


func _new_keys(keys: Array[StringName], count: int, is_light: bool) -> Array[StringName]:
	var shown: int = _shown_light if is_light else _shown_water
	var upto: int = mini(count, keys.size())
	var out: Array[StringName] = []
	for i: int in range(shown, upto):
		out.append(keys[i])
	if is_light:
		_shown_light = upto
	else:
		_shown_water = upto
	return out
