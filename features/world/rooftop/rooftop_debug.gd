class_name RooftopDebug
extends CanvasLayer
## The F3 debug labels of an area: frames per second and the area name. Hidden until F3; the name also hides while
## the area is not exploring (the area card shows the name to players). Font size and positions come from the
## flow rules (content/prototype/flow.json).

var _fps_label: Label
var _name_label: Label


func setup(rules: FlowRulesDef, area_name: String) -> void:
	visible = false
	_fps_label = _label(rules, rules.debug_fps_pos)
	_name_label = _label(rules, rules.debug_name_pos)
	_name_label.text = area_name


func set_name_visible(on: bool) -> void:
	_name_label.visible = on


func _process(_delta: float) -> void:
	if visible:
		_fps_label.text = tr("UI_FPS") % Engine.get_frames_per_second()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		visible = not visible


func _label(rules: FlowRulesDef, pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", rules.debug_font_size)
	add_child(label)
	return label
