class_name VfxLayer
extends RefCounted
## One layer of a VfxDef: `count` sprites of one texture that start at an anchor (plus an offset), grow from
## size to size_end, drift or travel, spin and fade. Offsets in x mirror with the attack direction.

var tex: StringName = &"glow"
var from: StringName = &"target"
## Set: the sprite moves to this anchor (travel) or stretches from `from` to it (span).
var to: StringName = &""
var offset: Vector2 = Vector2.ZERO
var to_offset: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ONE
var size_end: Vector2 = Vector2.ONE
var color: Color = Color.WHITE
var energy: float = 1.0
var delay: float = 0.0
var time: float = 0.3
var count: int = 1
## Extra delay per sprite, scatter radius at the start, drift (metres over the life), random start roll.
var stagger: float = 0.0
var spread: float = 0.0
var move: Vector2 = Vector2.ZERO
var roll: float = 0.0
## Start rotation and total spin in degrees; aim turns the sprite along its travel / span direction.
var rot: float = 0.0
var spin: float = 0.0
var aim: bool = false
var span: bool = false
var chain: bool = false
var radial: bool = false
## Fraction of the life it stays fully visible before fading.
var hold: float = 0.3


func read(r: DefReader) -> void:
	tex = r.one_of("tex", VfxDef.TEXTURES)
	from = r.one_of("from", VfxDef.ANCHORS)
	to = StringName(r.text("to", "", false))
	if to != &"" and not VfxDef.ANCHORS.has(to):
		r.problem("to", "'%s' is not one of %s" % [to, VfxDef.ANCHORS])
	offset = _vec(r, "x", "y")
	to_offset = _vec(r, "to_x", "to_y")
	size = Vector2(r.number("w", 0.01, 20.0), r.number("h", 0.01, 20.0))
	size_end = Vector2(r.number("w_end", 0.0, 20.0, size.x, false), r.number("h_end", 0.0, 20.0, size.y, false))
	color = r.color("color")
	energy = r.number("energy", 0.0, 20.0, 1.0, false)
	delay = r.number("delay", 0.0, 3.0, 0.0, false)
	time = r.number("time", 0.02, 4.0)
	count = r.integer("count", 1, 40, 1, false)
	stagger = r.number("stagger", 0.0, 1.0, 0.0, false)
	spread = r.number("spread", 0.0, 5.0, 0.0, false)
	move = _vec(r, "move_x", "move_y")
	roll = r.number("roll", 0.0, 180.0, 0.0, false)
	rot = r.number("rot", -360.0, 360.0, 0.0, false)
	spin = r.number("spin", -720.0, 720.0, 0.0, false)
	hold = r.number("hold", 0.0, 1.0, 0.3, false)
	aim = r.flag("aim")
	span = r.flag("span")
	chain = r.flag("chain")
	radial = r.flag("radial")
	if (span or chain) and to == &"":
		r.problem("span", "span and chain need a 'to' anchor")


## True when the layer is painted once per target (it starts or ends on a target-side anchor).
func per_target() -> bool:
	return _target_side(from) or (to != &"" and _target_side(to))


static func _target_side(anchor: StringName) -> bool:
	return anchor != &"actor" and anchor != &"hand"


func _vec(r: DefReader, kx: String, ky: String) -> Vector2:
	return Vector2(r.number(kx, -20.0, 20.0, 0.0, false), r.number(ky, -20.0, 20.0, 0.0, false))
