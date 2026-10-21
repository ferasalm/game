class_name PaintDef
extends RefCounted
## The painted-diorama recipe of a look (the "paint" object of a look entry): the shared painted light (bands,
## tints, rim, min_light floor), which offline painterly bake the world textures use, the ink outline pass, the
## grade (a colour LUT made from split tones, vignette, canvas grain), anti-aliasing and the painted figure.
## A look without "paint" is unpainted and builds exactly as before.

const BAKES: Array[StringName] = [&"", &"wash", &"oil"]
const AA_MODES: Array[StringName] = [&"none", &"smaa", &"msaa2", &"fxaa"]

# Light (painted_light.gdshaderinc uniforms).
var bands: float = 3.0
var band_soft: float = 0.08
var light_tint: Color = Color.WHITE
var shadow_tint: Color = Color("#524cc6")
var shadow_lift: float = 0.15
var rim: float = 0.0
var rim_color: Color = Color("#9ab8ff")
var rim_power: float = 3.0
var min_light: float = 0.05
var figure_min_light: float = 0.35
# World textures: "" = the code-painted atlas (linear filtered), else a baked recipe from tools/art/painterly_bake.py.
var bake: StringName = &""
# Ink outline (ink_outline.gdshader); width 0 = no outline pass.
var outline_width: float = 1.0
var outline_color: Color = Color("#1a1420")
var outline_strength: float = 0.85
var outline_depth: float = 0.04
var outline_normal: float = 0.5
var outline_grow: float = 0.04
# Grade: the LUT tints shadows and highlights and sets saturation and contrast; then vignette and grain on screen.
var lut_shadows: Color = Color("#3d3a73")
var lut_highlights: Color = Color("#f0b83a")
var lut_amount: float = 0.0
var lut_saturation: float = 1.0
var lut_contrast: float = 1.0
var vignette: float = 0.0
var vignette_color: Color = Color("#05040c")
var vignette_softness: float = 0.6
var grain: float = 0.0
var aa: StringName = &"smaa"
# The painted spike figure (a static painted billboard of Zayd); height in metres.
var figure: bool = false
var figure_height: float = 1.8
# Mist painted in flat brush-stroke steps (0 = smooth) and how far it is pulled toward the shadow tint.
var mist_bands: float = 0.0
var mist_tint: float = 0.0
# Cut-away (OcclusionFade): whatever stands in a tube from the camera to the party dithers away. Radius and soft
# edge of the tube in metres, how far short of the party it stops, ease speed (per second), the smallest height
# above the floor that counts as a blocker, and the point on the party the camera looks at.
var occlude_radius: float = 2.4
var occlude_soft: float = 1.4
var occlude_margin: float = 2.5
var occlude_speed: float = 6.0
var occlude_min_height: float = 1.2
var occlude_focus: float = 1.2


func read(r: DefReader) -> void:
	_read_light(r)
	bake = StringName(r.text("bake", "", false))
	if not BAKES.has(bake):
		r.problem("bake", "'%s' is not one of %s" % [bake, BAKES])
	_read_outline(r)
	_read_grade(r)
	aa = StringName(r.text("aa", String(aa), false))
	if not AA_MODES.has(aa):
		r.problem("aa", "'%s' is not one of %s" % [aa, AA_MODES])
	figure = r.flag("figure", figure)
	figure_height = r.number("figure_height", 0.5, 4.0, figure_height, false)
	mist_bands = r.number("mist_bands", 0.0, 8.0, mist_bands, false)
	mist_tint = r.number("mist_tint", 0.0, 1.0, mist_tint, false)
	_read_occlusion(r)


func _read_light(r: DefReader) -> void:
	bands = r.number("bands", 1.0, 8.0, bands, false)
	band_soft = r.number("band_soft", 0.0, 0.5, band_soft, false)
	light_tint = r.color("light_tint", light_tint, false)
	shadow_tint = r.color("shadow_tint", shadow_tint, false)
	shadow_lift = r.number("shadow_lift", 0.0, 1.0, shadow_lift, false)
	rim = r.number("rim", 0.0, 2.0, rim, false)
	rim_color = r.color("rim_color", rim_color, false)
	rim_power = r.number("rim_power", 0.5, 8.0, rim_power, false)
	min_light = r.number("min_light", 0.0, 1.0, min_light, false)
	figure_min_light = r.number("figure_min_light", 0.0, 1.0, figure_min_light, false)


func _read_occlusion(r: DefReader) -> void:
	occlude_radius = r.number("occlude_radius", 0.1, 20.0, occlude_radius, false)
	occlude_soft = r.number("occlude_soft", 0.05, 20.0, occlude_soft, false)
	occlude_margin = r.number("occlude_margin", 0.0, 20.0, occlude_margin, false)
	occlude_speed = r.number("occlude_speed", 0.1, 60.0, occlude_speed, false)
	occlude_min_height = r.number("occlude_min_height", 0.0, 20.0, occlude_min_height, false)
	occlude_focus = r.number("occlude_focus", 0.0, 4.0, occlude_focus, false)


func _read_outline(r: DefReader) -> void:
	outline_width = r.number("outline_width", 0.0, 4.0, outline_width, false)
	outline_color = r.color("outline_color", outline_color, false)
	outline_strength = r.number("outline_strength", 0.0, 1.0, outline_strength, false)
	outline_depth = r.number("outline_depth", 0.001, 1.0, outline_depth, false)
	outline_normal = r.number("outline_normal", 0.01, 2.0, outline_normal, false)
	outline_grow = r.number("outline_grow", 0.0, 1.0, outline_grow, false)


func _read_grade(r: DefReader) -> void:
	lut_shadows = r.color("lut_shadows", lut_shadows, false)
	lut_highlights = r.color("lut_highlights", lut_highlights, false)
	lut_amount = r.number("lut_amount", 0.0, 1.0, lut_amount, false)
	lut_saturation = r.number("lut_saturation", 0.0, 2.0, lut_saturation, false)
	lut_contrast = r.number("lut_contrast", 0.5, 2.0, lut_contrast, false)
	vignette = r.number("vignette", 0.0, 1.0, vignette, false)
	vignette_color = r.color("vignette_color", vignette_color, false)
	vignette_softness = r.number("vignette_softness", 0.05, 1.0, vignette_softness, false)
	grain = r.number("grain", 0.0, 0.3, grain, false)


## Feeds the shared light uniforms (painted_light.gdshaderinc) into a material; figures get their own floor.
func apply_light(mat: ShaderMaterial, is_figure: bool = false) -> void:
	mat.set_shader_parameter(&"paint_mix", 1.0)
	mat.set_shader_parameter(&"paint_bands", bands)
	mat.set_shader_parameter(&"paint_band_soft", band_soft)
	mat.set_shader_parameter(&"paint_light_tint", light_tint)
	mat.set_shader_parameter(&"paint_shadow_tint", shadow_tint)
	mat.set_shader_parameter(&"paint_shadow_lift", shadow_lift)
	mat.set_shader_parameter(&"paint_rim", rim)
	mat.set_shader_parameter(&"paint_rim_color", rim_color)
	mat.set_shader_parameter(&"paint_rim_power", rim_power)
	mat.set_shader_parameter(&"paint_min_light", figure_min_light if is_figure else min_light)
