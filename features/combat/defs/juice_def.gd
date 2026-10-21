class_name JuiceDef
extends Def
## The "feel" numbers of a battle (content/combat/juice.json): how hard hitstop freezes, how the BREAK flash and
## the damage numbers pop and bounce, how a camera shake decays. Per-move hitstop / shake / zoom live in VfxDef.

## Engine.time_scale during a freeze frame, and the freeze a cast break adds.
var freeze_scale: float = 0.02
var break_hitstop: float = 0.2
var break_shake: float = 0.3
var break_seconds: float = 0.9
var break_size: int = 120
var break_color: Color = Color.WHITE
## Damage numbers: pop-in overshoot, pop time, bounce height, heavy hit threshold and size factor, jitter.
var pop_scale: float = 1.6
var pop_time: float = 0.14
var bounce_height: float = 0.5
var bounce_time: float = 0.35
var heavy_damage: int = 30
var heavy_scale: float = 1.5
var number_jitter: float = 0.3
var damage_color: Color = Color.WHITE
var heal_color: Color = Color.WHITE
var shake_decay: float = 8.0
var shake_speed: float = 60.0
var anticipate_pause: float = 0.05
var cast_hold: float = 0.18
## The qamariya-glass shatter into the fight: cells across the screen, how far (screen heights) and sideways (cells)
## the shards drop, their spin (radians), the stagger share of the time, glass tint amount and crack width (cells).
var shatter_columns: int = 10
var shatter_fall: float = 1.5
var shatter_spread: float = 1.0
var shatter_spin: float = 2.5
var shatter_stagger: float = 0.45
var shatter_glass: float = 0.35
var shatter_crack: float = 0.02
## Per-character hit pause (CharacterVisual.hit_stop) on attacker and target at impact, light and heavy (seconds).
var hit_pause: float = 0.07
var hit_pause_heavy: float = 0.11
## How long a clip wait may last before the battle goes on without its event (a source that sends none), seconds.
var clip_timeout: float = 2.0
## Gap kept between two fighters at the end of a lunge, metres.
var contact_gap: float = 0.1


func read(r: DefReader) -> void:
	id = r.id()
	freeze_scale = r.number("freeze_scale", 0.0, 1.0)
	break_hitstop = r.number("break_hitstop", 0.0, 1.0)
	break_shake = r.number("break_shake", 0.0, 2.0)
	break_seconds = r.number("break_seconds", 0.1, 3.0)
	break_size = r.integer("break_size", 8, 400)
	break_color = r.color("break_color")
	pop_scale = r.number("pop_scale", 1.0, 4.0)
	pop_time = r.number("pop_time", 0.02, 1.0)
	bounce_height = r.number("bounce_height", 0.0, 3.0)
	bounce_time = r.number("bounce_time", 0.05, 2.0)
	heavy_damage = r.integer("heavy_damage", 1, 9999)
	heavy_scale = r.number("heavy_scale", 1.0, 4.0)
	number_jitter = r.number("number_jitter", 0.0, 2.0)
	damage_color = r.color("damage_color")
	heal_color = r.color("heal_color")
	shake_decay = r.number("shake_decay", 0.5, 60.0)
	shake_speed = r.number("shake_speed", 1.0, 200.0)
	anticipate_pause = r.number("anticipate_pause", 0.0, 1.0)
	cast_hold = r.number("cast_hold", 0.0, 2.0)
	shatter_columns = r.integer("shatter_columns", 3, 40)
	shatter_fall = r.number("shatter_fall", 0.0, 4.0)
	shatter_spread = r.number("shatter_spread", 0.0, 4.0)
	shatter_spin = r.number("shatter_spin", 0.0, 12.0)
	shatter_stagger = r.number("shatter_stagger", 0.0, 0.9)
	shatter_glass = r.number("shatter_glass", 0.0, 1.0)
	shatter_crack = r.number("shatter_crack", 0.0, 0.2)
	hit_pause = r.number("hit_pause", 0.0, 0.5)
	hit_pause_heavy = r.number("hit_pause_heavy", 0.0, 0.5)
	clip_timeout = r.number("clip_timeout", 0.2, 10.0)
	contact_gap = r.number("contact_gap", 0.0, 2.0)
