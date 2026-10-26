class_name NeonColdOpenDef
extends Def
## purpose: The Roya cold open (content/neon/cold_open.json, docs/briefs/neon-cold-open.md): its painted shots (texture,
## seconds, caption key, slow push and pan, parallax layer), crossfade, caption, alert, cut, music and rain numbers.

## One dictionary per shot: texture, seconds, caption, scale_from, scale_to, pan_from, pan_to (Vector2), parallax.
var shots: Array[Dictionary] = []
var crossfade: float = 1.0
var caption_delay: float = 0.6
var caption_fade: float = 0.6
var caption_font_size: int = 34
var parallax_alpha: float = 0.3
var parallax_speed: float = 1.5
var alert_start: float = 4.0
var alert_fill: float = 6.0
var alert_flashes: int = 3
var alert_flash_seconds: float = 0.12
var alert_size: Vector2 = Vector2(520.0, 44.0)
var alert_top: float = 40.0
var alert_font_size: int = 20
var alert_color: Color = Color.RED
var cut_after_lock: float = 1.5
var black_hold: float = 1.0
var vignette_alpha: float = 0.45
var music: String = ""
var music_db: float = -12.0
var skip_hint_delay: float = 1.0
var rain_tint: Color = Color.WHITE
var rain_speed: float = 1.6
var rain_density: float = 110.0
var rain_slant: float = 0.18


func read(r: DefReader) -> void:
	id = r.id()
	for s: DefReader in r.objects("shots"):
		var pan: Array[float] = s.float_list("pan", -2000.0, 2000.0)
		if pan.size() != 4:
			s.problem("pan", "needs from x, y and to x, y")
			pan = [0.0, 0.0, 0.0, 0.0]
		shots.append({"texture": s.text("texture"), "seconds": s.number("seconds", 1.0, 120.0),
			"caption": s.text("caption"), "scale_from": s.number("scale_from", 0.5, 3.0),
			"scale_to": s.number("scale_to", 0.5, 3.0), "pan_from": Vector2(pan[0], pan[1]),
			"pan_to": Vector2(pan[2], pan[3]), "parallax": s.flag("parallax")})
	crossfade = r.number("crossfade", 0.0, 10.0)
	caption_delay = r.number("caption_delay", 0.0, 10.0)
	caption_fade = r.number("caption_fade", 0.01, 10.0)
	caption_font_size = r.integer("caption_font_size", 8, 200)
	parallax_alpha = r.number("parallax_alpha", 0.0, 1.0)
	parallax_speed = r.number("parallax_speed", 0.0, 10.0)
	_read_alert(r)
	music = r.text("music")
	music_db = r.number("music_db", -80.0, 24.0)
	skip_hint_delay = r.number("skip_hint_delay", 0.0, 60.0)
	rain_tint = r.color("rain_tint")
	rain_speed = r.number("rain_speed", 0.0, 20.0)
	rain_density = r.number("rain_density", 1.0, 1000.0)
	rain_slant = r.number("rain_slant", -2.0, 2.0)


func _read_alert(r: DefReader) -> void:
	alert_start = r.number("alert_start", 0.0, 120.0)
	alert_fill = r.number("alert_fill", 0.1, 120.0)
	alert_flashes = r.integer("alert_flashes", 0, 20)
	alert_flash_seconds = r.number("alert_flash_seconds", 0.01, 2.0)
	var size: Array[float] = r.float_list("alert_size", 1.0, 4000.0)
	alert_size = Vector2(size[0], size[1]) if size.size() == 2 else alert_size
	alert_top = r.number("alert_top", 0.0, 2000.0)
	alert_font_size = r.integer("alert_font_size", 8, 200)
	alert_color = r.color("alert_color")
	cut_after_lock = r.number("cut_after_lock", 0.0, 60.0)
	black_hold = r.number("black_hold", 0.0, 60.0)
	vignette_alpha = r.number("vignette_alpha", 0.0, 1.0)


func references() -> Array[Array]:
	return []
