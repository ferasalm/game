class_name BattleViewDef
extends Def
## Layout and pacing numbers of the battle screen (content/combat/view.json): camera, where each formation slot
## stands, ticks per frame, hit-stop and banner times, floating-text sizes, HUD sizes and colours.

var camera_offset: Vector3 = Vector3.ZERO
var camera_fov: float = 30.0
var look_height: float = 0.0
var party_stage: Array[Vector2] = []
var enemy_stage: Array[Vector2] = []
var ticks_per_frame: int = 1
## How far a fighter's facing leans toward the camera (z share of the sideways facing; 0 = pure side view).
var face_bias: float = 0.0
var hit_stop: float = 0.0
var banner_seconds: float = 0.0
var damage_gap: float = 0.0
var tip_seconds: float = 0.0
var end_delay: float = 0.0
var number_rise: float = 0.0
var number_seconds: float = 0.0
## Brightness multiplier on 3D text (damage numbers, BREAK!, intents): above 1 it cuts through the night fog and blooms.
var label_energy: float = 1.0
var number_font_size: int = 64
var text_font_size: int = 40
var label_pixel_size: float = 0.01
var intent_offset: float = 0.0
var marker_offset: float = 0.0
var marker_size: float = 0.25
var banner_anchor_y: float = 0.3
var marker_bounce: float = 0.0
var marker_speed: float = 0.0
var shake_distance: float = 0.0
var shake_time: float = 0.0
var font_size: int = 28
var banner_font_size: int = 96
var margin: int = 24
var icon_size: int = 44
var bar_height: int = 16
var party_color: Color = Color.WHITE
var enemy_color: Color = Color.WHITE
var cast_color: Color = Color.WHITE
var panel_color: Color = Color.BLACK
var highlight_color: Color = Color.WHITE
var hp_color: Color = Color.WHITE
var sp_color: Color = Color.WHITE
## HUD v3 (all in pixels at 1920x1080 unless noted): the thin timeline, the strips under the fighters' feet, the
## turn panel (card + compact menu), the info card and the end panel.
var timeline_icon: int = 24
var timeline_track: int = 10
var timeline_top: int = 4
var timeline_width: int = 1100
var timeline_raise: int = 4
var ring_width: int = 2
var letter_font: int = 14
var target_font: int = 24
var strip_w: int = 150
var strip_h: int = 18
var strip_gap: int = 6
var strip_initial: int = 18
var hp_h: int = 9
var sp_h: int = 5
var foe_strip_w: int = 100
var foe_strip_h: int = 8
var foe_strip_seconds: float = 1.8
var strip_fade: float = 0.4
var pulse_scale: float = 1.4
var pulse_seconds: float = 0.35
var turn_menu_w: int = 380
var turn_row_h: int = 34
var turn_gap: int = 16
var card_bar_h: int = 12
var info_w: int = 230
var info_delay: float = 1.2
var info_fade: float = 0.35
var info_gap: int = 12
var rect_pad: int = 4
var tip_w: int = 560
var end_panel_w: int = 420
var end_title_font: int = 48
var letter_offset: float = 0.15
var menu_font: int = 20
var menu_pad_v: int = 3
var card_font: int = 18
var card_name_font: int = 22
var panel_margin: int = 10


func read(r: DefReader) -> void:
	id = r.id()
	camera_offset = Vector3(r.number("camera_x", -50.0, 50.0), r.number("camera_y", 0.0, 50.0),
		r.number("camera_z", -50.0, 50.0))
	camera_fov = r.number("camera_fov", 5.0, 120.0)
	look_height = r.number("look_height", 0.0, 5.0)
	party_stage = _slots(r, "party_stage")
	enemy_stage = _slots(r, "enemy_stage")
	_read_pacing(r)
	_read_hud(r)
	_read_hud_v3(r)


func _read_pacing(r: DefReader) -> void:
	ticks_per_frame = r.integer("ticks_per_frame", 1, 30)
	face_bias = r.number("face_bias", 0.0, 2.0, 0.0, false)
	hit_stop = r.number("hit_stop", 0.0, 3.0)
	banner_seconds = r.number("banner_seconds", 0.0, 5.0)
	damage_gap = r.number("damage_gap", 0.0, 2.0)
	tip_seconds = r.number("tip_seconds", 0.0, 30.0)
	end_delay = r.number("end_delay", 0.0, 10.0)
	number_rise = r.number("number_rise", 0.0, 5.0)
	number_seconds = r.number("number_seconds", 0.05, 5.0)
	label_energy = r.number("label_energy", 1.0, 6.0, 1.0, false)
	number_font_size = r.integer("number_font_size", 8, 300)
	text_font_size = r.integer("text_font_size", 8, 300)
	label_pixel_size = r.number("label_pixel_size", 0.001, 0.1)
	intent_offset = r.number("intent_offset", 0.0, 3.0)
	marker_offset = r.number("marker_offset", 0.0, 3.0)
	marker_size = r.number("marker_size", 0.01, 2.0)
	banner_anchor_y = r.number("banner_anchor_y", 0.0, 1.0)
	marker_bounce = r.number("marker_bounce", 0.0, 2.0)
	marker_speed = r.number("marker_speed", 0.1, 30.0)
	shake_distance = r.number("shake_distance", 0.0, 2.0)
	shake_time = r.number("shake_time", 0.01, 2.0)


func _read_hud(r: DefReader) -> void:
	font_size = r.integer("font_size", 8, 120)
	banner_font_size = r.integer("banner_font_size", 8, 300)
	margin = r.integer("margin", 0, 200)
	icon_size = r.integer("icon_size", 8, 200)
	bar_height = r.integer("bar_height", 4, 80)
	party_color = _color(r, "party_color")
	enemy_color = _color(r, "enemy_color")
	cast_color = _color(r, "cast_color")
	panel_color = _color(r, "panel_color")
	highlight_color = _color(r, "highlight_color")
	hp_color = _color(r, "hp_color")
	sp_color = _color(r, "sp_color")


func _slots(r: DefReader, key: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for slot: DefReader in r.objects(key):
		out.append(Vector2(slot.number("x", -50.0, 50.0), slot.number("z", -50.0, 50.0)))
	if out.size() != 4:
		r.problem(key, "needs exactly 4 slot positions")
	return out


func _color(r: DefReader, key: String) -> Color:
	var value: String = r.text(key)
	if not Color.html_is_valid(value):
		r.problem(key, "'%s' is not a colour" % value)
		return Color.MAGENTA
	return Color.html(value)


func _read_hud_v3(r: DefReader) -> void:
	timeline_icon = r.integer("timeline_icon", 8, 120)
	timeline_track = r.integer("timeline_track", 2, 60)
	timeline_top = r.integer("timeline_top", 0, 60)
	timeline_width = r.integer("timeline_width", 200, 1900)
	timeline_raise = r.integer("timeline_raise", 0, 40)
	ring_width = r.integer("ring_width", 1, 12)
	letter_font = r.integer("letter_font", 6, 80)
	target_font = r.integer("target_font", 8, 80)
	strip_w = r.integer("strip_w", 40, 400)
	strip_h = r.integer("strip_h", 6, 80)
	strip_gap = r.integer("strip_gap", 0, 80)
	strip_initial = r.integer("strip_initial", 6, 60)
	hp_h = r.integer("hp_h", 2, 40)
	sp_h = r.integer("sp_h", 2, 40)
	foe_strip_w = r.integer("foe_strip_w", 40, 400)
	foe_strip_h = r.integer("foe_strip_h", 3, 40)
	foe_strip_seconds = r.number("foe_strip_seconds", 0.1, 20.0)
	strip_fade = r.number("strip_fade", 0.05, 5.0)
	pulse_scale = r.number("pulse_scale", 1.0, 3.0)
	pulse_seconds = r.number("pulse_seconds", 0.05, 3.0)
	turn_menu_w = r.integer("turn_menu_w", 160, 900)
	turn_row_h = r.integer("turn_row_h", 20, 90)
	turn_gap = r.integer("turn_gap", 0, 200)
	card_bar_h = r.integer("card_bar_h", 4, 40)
	info_w = r.integer("info_w", 100, 600)
	info_delay = r.number("info_delay", 0.0, 10.0)
	info_fade = r.number("info_fade", 0.05, 5.0)
	info_gap = r.integer("info_gap", 0, 100)
	rect_pad = r.integer("rect_pad", 0, 60)
	tip_w = r.integer("tip_w", 200, 1800)
	end_panel_w = r.integer("end_panel_w", 200, 1200)
	end_title_font = r.integer("end_title_font", 12, 200)
	letter_offset = r.number("letter_offset", 0.0, 3.0)
	menu_font = r.integer("menu_font", 8, 80)
	menu_pad_v = r.integer("menu_pad_v", 0, 30)
	card_font = r.integer("card_font", 8, 80)
	card_name_font = r.integer("card_name_font", 8, 80)
	panel_margin = r.integer("panel_margin", 0, 60)
