class_name InteractionPrompt
extends PanelContainer
## A small glass pill above an object in the world: the interact glyph and a verb ("Drink", "Talk", "Open"). It
## follows a Node3D through the active camera and fades out with the viewer's distance (s_prompt_near .. s_prompt_far).
## Put it under any Control or CanvasLayer root (UiLayers.HUD). Use: Ui.interaction_prompt("SABIL_PROMPT").bind_world(...)

var _target: Node3D = null
var _viewer: Node3D = null
var _lift: float = 0.0
var _verb: Label


func setup(verb_key: String) -> InteractionPrompt:
	var style: UiStyleDef = Ui.style()
	theme_type_variation = &"PlatePanel"
	custom_minimum_size.y = style.size(&"s_prompt_h")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_gap"))
	add_child(row)
	var glyph: String = Ui.text(PromptGlyph.key(&"interact", PromptStrip.gamepad))
	row.add_child(Ui.label(glyph, &"CaptionLabel"))
	_verb = Ui.label(Ui.text(verb_key), &"NameLabel")
	row.add_child(_verb)
	modulate.a = 0.0
	return self


## Follow target (lift metres above its origin) and fade by the distance to viewer.
func bind_world(target: Node3D, viewer: Node3D, lift: float) -> InteractionPrompt:
	_target = target
	_viewer = viewer
	_lift = lift
	return self


## The alpha for a viewer distance in metres (what _process applies).
func alpha_for(distance: float) -> float:
	var style: UiStyleDef = Ui.style()
	return PromptGlyph.fade(distance, style.size(&"s_prompt_near"), style.size(&"s_prompt_far"))


func verb_text() -> String:
	return _verb.text


func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not is_instance_valid(_viewer):
		modulate.a = 0.0
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var point: Vector3 = _target.global_position + Vector3.UP * _lift
	var shown: float = alpha_for(_viewer.global_position.distance_to(_target.global_position))
	if camera == null or camera.is_position_behind(point):
		shown = 0.0
	else:
		position = camera.unproject_position(point) - size * 0.5
	modulate.a = move_toward(modulate.a, shown, get_process_delta_time() / maxf(Ui.style().time(&"t_prompt_fade"), 0.001))
