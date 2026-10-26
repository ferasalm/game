class_name RoofHud
extends CanvasLayer
## purpose: HUD prompts for roof exploration (movement hint strip and interact prompt).

var _move_label: Label
var _move_bg: PanelContainer
var _interact_label: Label
var _interact_bg: PanelContainer
var _move_timer: float = 0.0


func _ready() -> void:
	layer = 10
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_move_bg = PanelContainer.new()
	_move_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_move_bg.offset_top = -90.0
	_move_bg.offset_bottom = -45.0
	_move_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_move_bg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_move_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_move_label = Label.new()
	_move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_move_label.text = tr("NEON_ROOF_MOVE_HINT")
	_move_bg.add_child(_move_label)
	root.add_child(_move_bg)
	_move_bg.visible = false

	_interact_bg = PanelContainer.new()
	_interact_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interact_bg.offset_top = -150.0
	_interact_bg.offset_bottom = -110.0
	_interact_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_interact_bg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_interact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_interact_label = Label.new()
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interact_bg.add_child(_interact_label)
	root.add_child(_interact_bg)
	_interact_bg.visible = false


func show_move_hint(seconds: float = 4.0) -> void:
	_move_timer = seconds
	_move_bg.visible = true
	_move_bg.modulate.a = 1.0


func show_interact(prompt_key: String) -> void:
	_interact_label.text = tr("NEON_ROOF_INTERACT_KEY") + tr(prompt_key)
	_interact_bg.visible = true


func hide_interact() -> void:
	_interact_bg.visible = false


func _process(delta: float) -> void:
	if _move_timer > 0.0:
		_move_timer -= delta
		if _move_timer <= 0.0:
			_move_bg.visible = false
