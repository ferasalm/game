class_name VisualRulesDef
extends Def
## Numbers for how a CharacterVisual looks and moves: art scale, idle breathing, walking (bob, squash and
## stretch, lean, dust), turning, the blob shadow, and the battle motions (anticipation, lunge with afterimages,
## recoil, hurt, knocked out, revive, victory hop).

## True: a painted puppet draws this character (PuppetSource) instead of a pixel sprite.
var puppet: bool = false
## False for puppets: their limbs move, so the whole-body squash and stretch (CharacterVisual.pulse) stays off.
var pulse_squash: bool = true
var pixels_per_metre: float = 16.0
var placeholder_width: int = 16
var placeholder_height: int = 32
## Guaranteed share of the albedo that shows whatever the light does, and the cool rim light on top edges.
var min_light: float = 0.4
var rim_color: Color = Color.WHITE
var rim_amount: float = 0.5
# idle and walking
var breath_amount: float = 0.0
var breath_speed: float = 0.0
var bob_height: float = 0.0
var bob_speed: float = 0.0
var walk_squash: float = 0.0
var lean_degrees: float = 0.0
var lean_speed: float = 8.0
var dust_size: float = 0.2
var dust_rise: float = 0.2
var dust_time: float = 0.4
var dust_energy: float = 1.0
var dust_color: Color = Color.WHITE
var turn_squash: float = 0.0
var turn_time: float = 0.1
var shadow_size: float = 1.0
var shadow_alpha: float = 0.4
# battle
var anticipate_pull: float = 0.0
var anticipate_squash: float = 0.0
var anticipate_time: float = 0.1
var lunge_distance: float = 0.0
var lunge_time: float = 0.1
var impact_stretch: float = 0.0
var ghost_count: int = 0
var ghost_time: float = 0.2
var ghost_alpha: float = 0.4
var ghost_color: Color = Color.WHITE
var recoil_time: float = 0.2
var flash_time: float = 0.1
var hurt_shake: float = 0.0
var hurt_time: float = 0.2
var down_squash: float = 1.0
var ko_time: float = 0.3
var ko_desat: float = 0.0
var revive_time: float = 0.4
var revive_glow: float = 0.0
var revive_color: Color = Color.WHITE
var hop_height: float = 0.0
var hop_time: float = 0.3
var hop_count: int = 1


func read(r: DefReader) -> void:
	id = r.id()
	puppet = r.flag("puppet")
	pulse_squash = r.flag("pulse_squash", true)
	pixels_per_metre = r.number("pixels_per_metre", 1.0, 64.0)
	placeholder_width = r.integer("placeholder_width", 1, 128)
	placeholder_height = r.integer("placeholder_height", 1, 128)
	min_light = r.number("min_light", 0.0, 1.0)
	rim_color = r.color("rim_color")
	rim_amount = r.number("rim_amount", 0.0, 5.0)
	_read_walk(r)
	_read_battle(r)


func _read_walk(r: DefReader) -> void:
	breath_amount = r.number("breath_amount", 0.0, 0.2)
	breath_speed = r.number("breath_speed", 0.0, 20.0)
	bob_height = r.number("bob_height", 0.0, 1.0)
	bob_speed = r.number("bob_speed", 0.0, 30.0)
	walk_squash = r.number("walk_squash", 0.0, 0.5)
	lean_degrees = r.number("lean_degrees", 0.0, 30.0)
	lean_speed = r.number("lean_speed", 0.1, 60.0)
	dust_size = r.number("dust_size", 0.02, 2.0)
	dust_rise = r.number("dust_rise", 0.0, 2.0)
	dust_time = r.number("dust_time", 0.05, 3.0)
	dust_energy = r.number("dust_energy", 0.0, 10.0)
	dust_color = r.color("dust_color")
	turn_squash = r.number("turn_squash", 0.0, 0.6)
	turn_time = r.number("turn_time", 0.01, 1.0)
	shadow_size = r.number("shadow_size", 0.1, 5.0)
	shadow_alpha = r.number("shadow_alpha", 0.0, 1.0)


func _read_battle(r: DefReader) -> void:
	anticipate_pull = r.number("anticipate_pull", 0.0, 3.0)
	anticipate_squash = r.number("anticipate_squash", 0.0, 0.6)
	anticipate_time = r.number("anticipate_time", 0.01, 2.0)
	lunge_distance = r.number("lunge_distance", 0.0, 5.0)
	lunge_time = r.number("lunge_time", 0.01, 2.0)
	impact_stretch = r.number("impact_stretch", 0.0, 0.6)
	ghost_count = r.integer("ghost_count", 0, 8)
	ghost_time = r.number("ghost_time", 0.02, 2.0)
	ghost_alpha = r.number("ghost_alpha", 0.0, 1.0)
	ghost_color = r.color("ghost_color")
	recoil_time = r.number("recoil_time", 0.01, 2.0)
	flash_time = r.number("flash_time", 0.01, 2.0)
	hurt_shake = r.number("hurt_shake", 0.0, 1.0)
	hurt_time = r.number("hurt_time", 0.01, 2.0)
	down_squash = r.number("down_squash", 0.1, 1.0)
	ko_time = r.number("ko_time", 0.01, 3.0)
	ko_desat = r.number("ko_desat", 0.0, 1.0)
	revive_time = r.number("revive_time", 0.01, 3.0)
	revive_glow = r.number("revive_glow", 0.0, 10.0)
	revive_color = r.color("revive_color")
	hop_height = r.number("hop_height", 0.0, 3.0)
	hop_time = r.number("hop_time", 0.05, 2.0)
	hop_count = r.integer("hop_count", 1, 6)
