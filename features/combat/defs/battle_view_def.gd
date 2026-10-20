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
var hit_stop: float = 0.0
var banner_seconds: float = 0.0
var damage_gap: float = 0.0
var tip_seconds: float = 0.0
var end_delay: float = 0.0
var number_rise: float = 0.0
var number_seconds: float = 0.0
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
var party_panel_width: int = 520
var menu_width: int = 620
var party_color: Color = Color.WHITE
var enemy_color: Color = Color.WHITE
var cast_color: Color = Color.WHITE
var panel_color: Color = Color.BLACK
var highlight_color: Color = Color.WHITE
var hp_color: Color = Color.WHITE
var sp_color: Color = Color.WHITE


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


func _read_pacing(r: DefReader) -> void:
	ticks_per_frame = r.integer("ticks_per_frame", 1, 30)
	hit_stop = r.number("hit_stop", 0.0, 3.0)
	banner_seconds = r.number("banner_seconds", 0.0, 5.0)
	damage_gap = r.number("damage_gap", 0.0, 2.0)
	tip_seconds = r.number("tip_seconds", 0.0, 30.0)
	end_delay = r.number("end_delay", 0.0, 10.0)
	number_rise = r.number("number_rise", 0.0, 5.0)
	number_seconds = r.number("number_seconds", 0.05, 5.0)
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
	party_panel_width = r.integer("party_panel_width", 100, 1200)
	menu_width = r.integer("menu_width", 100, 1200)
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
