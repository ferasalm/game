class_name StartFlowDef
extends Def
## Authored timings, colours, and sizes for the Neon Glitch start flow.

var title_clip: String = "res://assets/video/title_loop.ogv"
var window_push_clip: String = "res://assets/video/window_push.ogv"
var hero_pick_clip: String = "res://assets/video/hero_pick.ogv"
var rydan_panel_clip: String = "res://assets/video/rydan_panel.ogv"
var rydan_reaction_clip: String = "res://assets/video/rydan_reaction.ogv"
var launch_clip: String = "res://assets/video/launch.ogv"

var glitch_interval: float = 3.0
var glitch_duration: float = 0.15
var blink_period: float = 1.2
var crossfade_duration: float = 0.25
var push_blur_duration: float = 1.2
var blur_zoom_duration: float = 0.4
var reaction_fade_duration: float = 0.5
var hud_boot_duration: float = 2.0

var font_title_size: int = 72
var font_press_size: int = 28
var font_menu_size: int = 32
var font_hero_name_size: int = 42
var font_panel_name_size: int = 56
var font_panel_role_size: int = 18
var font_panel_body_size: int = 18
var font_diff_title_size: int = 22
var font_diff_button_size: int = 22
var font_hint_size: int = 17
var font_musnad_title_size: int = 24
var font_musnad_accent_size: int = 20
var font_musnad_name_size: int = 28

var cyan: Color = Color(0.43, 0.93, 1.0, 1.0)
var magenta: Color = Color(1.0, 0.27, 0.59, 1.0)
var white: Color = Color(0.91, 0.93, 0.96, 1.0)
var gray: Color = Color(0.46, 0.49, 0.55, 1.0)
var dim_gray: Color = Color(0.25, 0.27, 0.32, 1.0)
var panel_bg: Color = Color(0.035, 0.031, 0.086, 0.88)
var selection_bg: Color = Color(0.12, 0.08, 0.24, 0.9)


func read(r: DefReader) -> void:
	id = r.id()
	title_clip = r.text("title_clip", title_clip, false)
	window_push_clip = r.text("window_push_clip", window_push_clip, false)
	hero_pick_clip = r.text("hero_pick_clip", hero_pick_clip, false)
	rydan_panel_clip = r.text("rydan_panel_clip", rydan_panel_clip, false)
	rydan_reaction_clip = r.text("rydan_reaction_clip", rydan_reaction_clip, false)
	launch_clip = r.text("launch_clip", launch_clip, false)

	glitch_interval = r.number("glitch_interval", 0.1, 30.0, glitch_interval, false)
	glitch_duration = r.number("glitch_duration", 0.01, 5.0, glitch_duration, false)
	blink_period = r.number("blink_period", 0.1, 10.0, blink_period, false)
	crossfade_duration = r.number("crossfade_duration", 0.01, 5.0, crossfade_duration, false)
	push_blur_duration = r.number("push_blur_duration", 0.1, 10.0, push_blur_duration, false)
	blur_zoom_duration = r.number("blur_zoom_duration", 0.1, 5.0, blur_zoom_duration, false)
	reaction_fade_duration = r.number("reaction_fade_duration", 0.1, 5.0, reaction_fade_duration, false)
	hud_boot_duration = r.number("hud_boot_duration", 0.1, 10.0, hud_boot_duration, false)

	font_title_size = r.integer("font_title_size", 10, 140, font_title_size, false)
	font_press_size = r.integer("font_press_size", 10, 80, font_press_size, false)
	font_menu_size = r.integer("font_menu_size", 10, 80, font_menu_size, false)
	font_hero_name_size = r.integer("font_hero_name_size", 10, 90, font_hero_name_size, false)
	font_panel_name_size = r.integer("font_panel_name_size", 10, 100, font_panel_name_size, false)
	font_panel_role_size = r.integer("font_panel_role_size", 8, 50, font_panel_role_size, false)
	font_panel_body_size = r.integer("font_panel_body_size", 8, 50, font_panel_body_size, false)
	font_diff_title_size = r.integer("font_diff_title_size", 8, 50, font_diff_title_size, false)
	font_diff_button_size = r.integer("font_diff_button_size", 8, 50, font_diff_button_size, false)
	font_hint_size = r.integer("font_hint_size", 8, 40, font_hint_size, false)
	font_musnad_title_size = r.integer("font_musnad_title_size", 8, 60, font_musnad_title_size, false)
	font_musnad_accent_size = r.integer("font_musnad_accent_size", 8, 50, font_musnad_accent_size, false)
	font_musnad_name_size = r.integer("font_musnad_name_size", 8, 60, font_musnad_name_size, false)

	cyan = _color(r, "cyan", cyan)
	magenta = _color(r, "magenta", magenta)
	white = _color(r, "white", white)
	gray = _color(r, "gray", gray)
	dim_gray = _color(r, "dim_gray", dim_gray)
	panel_bg = _color(r, "panel_bg", panel_bg)
	selection_bg = _color(r, "selection_bg", selection_bg)


static func _color(r: DefReader, key: String, fallback: Color) -> Color:
	var list: Array[float] = r.float_list(key, 0.0, 1.0)
	if list.size() == 4:
		return Color(list[0], list[1], list[2], list[3])
	if list.size() == 3:
		return Color(list[0], list[1], list[2], 1.0)
	return fallback
