class_name UiSweep
extends RefCounted
## The qamariya focus sweep: a thin line under a focused control runs red, amber, green, blue, violet (stained glass)
## from left to right, then rests on brass. Restarting it on the same control replaces the earlier line.

const META: StringName = &"ui_sweep_line"
const TEXTURE_WIDTH: int = 80  ## texels of the five-colour strip (engine value)


## Starts the sweep on target (a child line is added under it); returns the tween that grows the line.
static func start(target: Control) -> Tween:
	clear(target)
	var style: UiStyleDef = Ui.style()
	var line := Control.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	line.offset_top = -style.size(&"s_sweep_h")
	line.offset_bottom = 0.0
	var rest := ColorRect.new()
	rest.color = style.colour(&"c_brass")
	rest.set_anchors_preset(Control.PRESET_FULL_RECT)
	rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(rest)
	var bands := TextureRect.new()
	bands.texture = _gradient(style)
	bands.stretch_mode = TextureRect.STRETCH_SCALE
	bands.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bands.set_anchors_preset(Control.PRESET_FULL_RECT)
	bands.anchor_right = 0.0
	bands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(bands)
	target.add_child(line)
	target.set_meta(META, line)
	var out: Tween = UiMotion.tween(line)
	out.tween_property(bands, "anchor_right", 1.0, style.time(&"t_focus_sweep"))
	out.tween_property(bands, "modulate:a", 0.0, style.time(&"t_focus_sweep"))
	return out


## Removes the sweep line from target, if any.
static func clear(target: Control) -> void:
	if target.has_meta(META):
		var line: Variant = target.get_meta(META)
		if is_instance_valid(line):
			(line as Node).queue_free()
		target.remove_meta(META)


static func _gradient(style: UiStyleDef) -> GradientTexture2D:
	var count: int = UiMotion.QAM_KEYS.size()
	var gradient := Gradient.new()
	gradient.set_color(0, style.colour(UiMotion.QAM_KEYS[0]))
	gradient.set_color(1, style.colour(UiMotion.QAM_KEYS[count - 1]))
	for i: int in range(1, count - 1):
		gradient.add_point(float(i) / float(count - 1), style.colour(UiMotion.QAM_KEYS[i]))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = TEXTURE_WIDTH
	texture.height = 1
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(1.0, 0.0)
	return texture
