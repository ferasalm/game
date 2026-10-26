class_name ColdOpenBuild
extends RefCounted
## purpose: Builds the cold open's nodes from its NeonColdOpenDef: the painted shots (cover-fit, a faint parallax copy on
## flagged shots), the rain overlay, a red vignette, the caption, the IDENTIFYING alert bar, the skip hint, the black cut
## and the music player.

const FONT_PATH: String = "res://assets/fonts/reem_kufi.ttf"
const RAIN_SHADER: String = "res://features/neon/cold_open/cold_open_rain.gdshader"


static func build(co: ColdOpen) -> void:
	var def: NeonColdOpenDef = co.def
	co.add_child(_rect(Color.BLACK))
	for shot: Dictionary in def.shots:
		var tex: Texture2D = load(shot["texture"] as String) as Texture2D
		var main: TextureRect = _shot(tex)
		co.add_child(main)
		var par: TextureRect = null
		if shot["parallax"] as bool:
			par = _shot(tex)
			co.add_child(par)
		co.layers.append([main, par])
	co.add_child(_rain(def))
	co.vignette = _vignette(def)
	co.add_child(co.vignette)
	co.caption = _label(def.caption_font_size, Color.WHITE)
	co.caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	co.caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	co.caption.position.y -= def.caption_font_size * 3
	co.add_child(co.caption)
	_build_alert(co, def)
	co.skip_hint = _label(def.caption_font_size / 2, Color(1, 1, 1, 0.7))
	co.skip_hint.text = co.tr("NEON_COLD_SKIP")
	co.skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	co.skip_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	co.skip_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	co.add_child(co.skip_hint)
	co.black = _rect(Color.BLACK)
	co.add_child(co.black)
	co.music = AudioStreamPlayer.new()
	if ResourceLoader.exists(def.music):
		co.music.stream = load(def.music) as AudioStream
	co.add_child(co.music)


static func _build_alert(co: ColdOpen, def: NeonColdOpenDef) -> void:
	co.alert = ColorRect.new()
	co.alert.color = Color(0, 0, 0, 0.6)
	co.alert.anchor_left = 0.5
	co.alert.anchor_right = 0.5
	co.alert.offset_left = -def.alert_size.x * 0.5
	co.alert.offset_right = def.alert_size.x * 0.5
	co.alert.offset_top = def.alert_top
	co.alert.offset_bottom = def.alert_top + def.alert_size.y
	var frame := ReferenceRect.new()
	frame.border_color = def.alert_color
	frame.editor_only = false
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	co.alert.add_child(frame)
	co.alert_bar = ColorRect.new()
	co.alert_bar.color = Color(def.alert_color, 0.55)
	co.alert_bar.size = Vector2(0.0, def.alert_size.y)
	co.alert.add_child(co.alert_bar)
	co.alert_label = _label(def.alert_font_size, Color.WHITE)
	co.alert_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	co.alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	co.alert.add_child(co.alert_label)
	co.add_child(co.alert)


static func _rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _shot(tex: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _rain(def: NeonColdOpenDef) -> ColorRect:
	var rain: ColorRect = _rect(Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = load(RAIN_SHADER) as Shader
	mat.set_shader_parameter("tint", def.rain_tint)
	mat.set_shader_parameter("speed", def.rain_speed)
	mat.set_shader_parameter("density", def.rain_density)
	mat.set_shader_parameter("slant", def.rain_slant)
	rain.material = mat
	return rain


static func _vignette(def: NeonColdOpenDef) -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, Color(def.alert_color, 0.0))
	grad.set_color(1, Color(def.alert_color, 1.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	return rect


static func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load(FONT_PATH) as Font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", maxi(2, font_size / 6))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
