class_name TitleOverlay
extends CanvasLayer
## The game's title over the opening sky: "Qarnaw" in Latin and Arabic in Reem Kufi with a pulsing "Press any key".
## Any key, click or pad button dismisses it (emitting dismissed at once, then fading out), which is the cue for
## the opening camera to leave the moon. The overlay itself never touches the camera.

## The player pressed something (or dismiss() was called). Emitted once.
signal dismissed

var _root: Control
var _block: VBoxContainer
var _done: bool = false
var _pulse: Tween = null


func _ready() -> void:
	layer = 30
	_root = Ui.screen_root()
	add_child(_root)
	_block = VBoxContainer.new()
	_block.set_anchors_preset(Control.PRESET_CENTER)
	_block.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_block.grow_vertical = Control.GROW_DIRECTION_BOTH
	_block.alignment = BoxContainer.ALIGNMENT_CENTER
	_block.offset_top = get_viewport().get_visible_rect().size.y * 0.22
	_block.offset_bottom = _block.offset_top
	_root.add_child(_block)
	_fill()


func is_showing() -> bool:
	return not _done


func dismiss() -> void:
	if _done:
		return
	_done = true
	if _pulse != null:
		_pulse.kill()
	dismissed.emit()
	var fade: Tween = create_tween()
	fade.tween_property(_block, "modulate:a", 0.0, Ui.style().time(&"t_title_fade"))
	fade.tween_callback(queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var pressed: bool = false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		dismiss()
		get_viewport().set_input_as_handled()


func _fill() -> void:
	var style: UiStyleDef = Ui.style()
	var latin: Label = Ui.label(Ui.text("TITLE_GAME"), &"BannerLabel")
	latin.add_theme_font_size_override("font_size", style.size(&"s_font_big") * 2)
	var arabic: Label = Ui.label(Ui.text("TITLE_GAME_AR"), &"TitleLabel", style.colour(&"c_gypsum"))
	arabic.add_theme_font_size_override("font_size", style.size(&"s_font_big"))
	arabic.language = "ar"
	for title: Label in [latin, arabic]:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_block.add_child(title)
	var band: TextureRect = Ui.divider()
	band.custom_minimum_size.x = style.size(&"s_frieze_period") * 22.0
	band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_block.add_child(band)
	var prompt: Label = Ui.label(Ui.text("TITLE_PRESS_KEY"), &"CaptionLabel")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_block.add_child(prompt)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(prompt, "modulate:a", 0.25, style.time(&"t_pulse"))
	_pulse.tween_property(prompt, "modulate:a", 1.0, style.time(&"t_pulse"))
