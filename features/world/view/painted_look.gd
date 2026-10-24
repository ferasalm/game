class_name PaintedLook
extends RefCounted
## Turns a scene painted when its look has a "paint" recipe (PaintDef): begin() before the world is built (world
## materials go through PaintedMaterials), finish() once it stands: the ink outline quad on the camera, the grade
## (split-tone LUT, contrast and saturation on the Environment; vignette and canvas grain on screen), the
## anti-aliasing mode, the shared light on every character, the camera cut-away (OcclusionFade, on the party node)
## and the painted figure in place of the player's sprite.
## A look without paint changes nothing.

const OUTLINE_SHADER: Shader = preload("res://features/world/view/shaders/ink_outline.gdshader")
const SCREEN_SHADER: Shader = preload("res://features/world/view/shaders/painted_screen.gdshader")
const LUT_SIZE: int = 16
const SCREEN_LAYER: int = -1  ## above the 3D picture, under every menu and HUD layer
const AA: Dictionary = {
	&"none": [Viewport.SCREEN_SPACE_AA_DISABLED, Viewport.MSAA_DISABLED],
	&"fxaa": [Viewport.SCREEN_SPACE_AA_FXAA, Viewport.MSAA_DISABLED],
	&"smaa": [Viewport.SCREEN_SPACE_AA_SMAA, Viewport.MSAA_DISABLED],
	&"msaa2": [Viewport.SCREEN_SPACE_AA_DISABLED, Viewport.MSAA_2X],
}

static var override_look: StringName = &""


## The look to build: a "look=<id>" user argument (after "--") overrides the scene's own look id.
static func pick(default_id: StringName) -> StringName:
	if override_look != &"":
		return override_look
	return user_arg("look=", default_id)


## The value of a "<prefix><value>" user argument (after "--"), or default_value when there is none.
static func user_arg(prefix: String, default_value: StringName) -> StringName:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return StringName(arg.substr(prefix.length()))
	return default_value


static func begin(look: LookDef) -> void:
	PaintedMaterials.use(look.paint)


static func finish(root: Node, look: LookDef, env: Environment, camera: Camera3D, figure_host: Node3D) -> void:
	var paint: PaintDef = look.paint
	if paint == null:
		return
	if paint.outline_width > 0.0:
		camera.add_child(make_outline(paint, look.fog_density))
	grade(env, paint)
	root.add_child(make_screen(paint))
	var modes: Array = AA.get(user_arg("aa=", paint.aa), AA[paint.aa])  # "aa=msaa2" compares modes in a probe
	root.get_viewport().screen_space_aa = modes[0] as Viewport.ScreenSpaceAA
	root.get_viewport().msaa_3d = modes[1] as Viewport.MSAA
	paint_characters(root, paint)
	if figure_host != null and paint.occlude_radius > 0.0:
		OcclusionFade.attach(root, camera, figure_host, paint)
	if paint.figure and figure_host != null:
		PaintedFigure.replace_sprite(figure_host, paint)


static func make_outline(paint: PaintDef, fog_density: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	mat.render_priority = Material.RENDER_PRIORITY_MIN
	mat.set_shader_parameter(&"ink_color", paint.outline_color)
	mat.set_shader_parameter(&"strength", paint.outline_strength)
	mat.set_shader_parameter(&"width", paint.outline_width)
	mat.set_shader_parameter(&"depth_threshold", paint.outline_depth)
	mat.set_shader_parameter(&"normal_threshold", paint.outline_normal)
	mat.set_shader_parameter(&"threshold_grow", paint.outline_grow)
	mat.set_shader_parameter(&"fog_density", fog_density)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.extra_cull_margin = 16384.0
	mesh.position = Vector3(0.0, 0.0, -1.0)
	return mesh


## The colour grade on the Environment: split tones as a 3D LUT, then contrast and saturation.
static func grade(env: Environment, paint: PaintDef) -> void:
	env.adjustment_enabled = true
	env.adjustment_contrast = paint.lut_contrast
	env.adjustment_saturation = paint.lut_saturation
	if paint.lut_amount > 0.0:
		env.adjustment_color_correction = make_lut(paint)


## A LUT_SIZE^3 colour LUT: shadows pulled toward lut_shadows, highlights toward lut_highlights (soft light).
static func make_lut(paint: PaintDef) -> ImageTexture3D:
	var layers: Array[Image] = []
	for b: int in LUT_SIZE:
		var img := Image.create_empty(LUT_SIZE, LUT_SIZE, false, Image.FORMAT_RGB8)
		for g: int in LUT_SIZE:
			for r: int in LUT_SIZE:
				var c := Color(r, g, b) / float(LUT_SIZE - 1)
				img.set_pixel(r, g, split_tone(c, paint))
		layers.append(img)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, LUT_SIZE, LUT_SIZE, LUT_SIZE, false, layers)
	return tex


static func split_tone(c: Color, paint: PaintDef) -> Color:
	var lum: float = c.get_luminance()
	var tone: Color = paint.lut_shadows.lerp(paint.lut_highlights, smoothstep(0.15, 0.85, lum))
	var out := Color(_soft_light(c.r, tone.r), _soft_light(c.g, tone.g), _soft_light(c.b, tone.b))
	return c.lerp(out, paint.lut_amount)


static func make_screen(paint: PaintDef) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = SCREEN_LAYER
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SCREEN_SHADER
	mat.set_shader_parameter(&"vignette", paint.vignette)
	mat.set_shader_parameter(&"vignette_color", paint.vignette_color)
	mat.set_shader_parameter(&"softness", paint.vignette_softness)
	mat.set_shader_parameter(&"grain", paint.grain)
	rect.material = mat
	layer.add_child(rect)
	return layer


## Every character sprite under root gets the shared painted light (by type, not by path).
static func paint_characters(root: Node, paint: PaintDef) -> void:
	for child: Node in root.get_children():
		if child is CharacterVisual:
			for mat: ShaderMaterial in (child as CharacterVisual).source.materials():
				paint.apply_light(mat, true)
		paint_characters(child, paint)


static func _soft_light(a: float, b: float) -> float:
	return (1.0 - 2.0 * b) * a * a + 2.0 * b * a
