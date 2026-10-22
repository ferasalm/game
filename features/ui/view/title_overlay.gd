class_name TitleOverlay
extends CanvasLayer
## The game's title over the opening sky: "Qarnaw" in Musnad (big) and Latin with a pulsing "Press any key".
## Any key, click or pad button dismisses it (emitting dismissed at once, then fading out), which is the cue for
## the opening camera to leave the moon. The overlay itself never touches the camera.

## The player pressed something (or dismiss() was called). Emitted once.
signal dismissed

const BLOCK_DROP: float = 0.22  ## the title block sits this fraction of the screen height below centre, clear of the moon

var _root: Control
var _block: VBoxContainer
var _done: bool = false
var _pulse: Tween = null


func _ready() -> void:
	layer = UiLayers.TITLE
	_root = Ui.screen_root()
	add_child(_root)
	_block = VBoxContainer.new()
	_block.set_anchors_preset(Control.PRESET_CENTER)
	_block.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_block.grow_vertical = Control.GROW_DIRECTION_BOTH
	_block.alignment = BoxContainer.ALIGNMENT_CENTER
	_block.offset_top = get_viewport().get_visible_rect().size.y * BLOCK_DROP
	_block.offset_bottom = _block.offset_top
	_root.add_child(_shade())
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


## A soft dark ellipse behind the title block so the words read over the bright neon signs.
func _shade() -> TextureRect:
	var tint: Color = Ui.style().colour(&"c_title_shade")
	var gradient := Gradient.new()
	gradient.set_color(0, tint)
	gradient.set_color(1, Color(tint, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5 + BLOCK_DROP)
	texture.fill_to = Vector2(1.0, 0.5 + BLOCK_DROP)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _fill() -> void:
	var style: UiStyleDef = Ui.style()
	var latin: Label = Ui.label(Ui.text("TITLE_GAME"), &"BannerLabel")
	latin.add_theme_font_size_override("font_size", style.size(&"s_font_big") * 2)
	var musnad: Label = Ui.label(Ui.text("TITLE_GAME_MUSNAD"), &"MusnadLabel", style.colour(&"c_gypsum"))
	musnad.add_theme_font_size_override("font_size", style.size(&"s_font_big") * 2)
	for title: Label in [musnad, latin]:
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
