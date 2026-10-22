class_name ModelDef
extends Def
## One live 3D character model (docs/design/characters-3d.md 5): a skinned glTF (or a rigid model built in code) with
## its height, footprint, anchors (bone names), the facade state -> ClipDef map, stride and turn speed, skin tint,
## and the parts it wears. Everything a ModelSource needs; the shared animation library is not per model.

const KINDS: Array[StringName] = [&"skinned", &"rigid"]

var kind: StringName = &"skinned"
var scene: String = ""
var skin: String = ""  ## the body's albedo texture
var eye_texture: String = ""
var hair_texture: String = ""  ## the brows' (and hair parts') albedo, tinted by the colour below
var brow_color: Color = Color("#1c1410")
var height_m: float = 2.0
var radius: float = 0.3
## Positive non-uniform widening of the body node for a silhouette (never negative: it would break winding).
var girth: float = 1.0
var tint: Color = Color.WHITE
var outline_hull: bool = false
## Bone names for the anchors &"hand", &"head", &"belt" (feet = the origin).
var anchors: Dictionary[String, String] = {}
## Facade state -> ClipDef id (a skinned model) or motion name (a rigid one).
var states: Dictionary[String, String] = {}
## Metres one full cycle of the walk / run clip covers at rate 1; below idle_speed (m/s) it stands, from run_speed it runs.
var stride_m: float = 1.4
var run_stride_m: float = 3.6
var idle_speed: float = 0.1
var run_speed: float = 2.6
var turn_speed: float = 900.0  ## degrees per second
var lean_gain: float = 1.2  ## degrees of lean per m/s^2 of acceleration (capped by the rules' lean_degrees)
var parts: Array[ModelPartDef] = []
## Rigid models: hover bob (metres, per second) and the speed of the spinning ring (turns per second).
var bob: float = 0.0
var bob_speed: float = 0.0
var spin: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	scene = r.text("scene", "", kind == &"skinned")
	skin = r.text("skin", "", false)
	eye_texture = r.text("eye_texture", "", false)
	hair_texture = r.text("hair_texture", "", false)
	brow_color = r.color("brow_color", brow_color, false)
	height_m = r.number("height_m", 0.1, 20.0, 2.0)
	radius = r.number("radius", 0.05, 5.0, 0.3)
	girth = r.number("girth", 0.5, 2.0, 1.0, false)
	tint = r.color("tint", Color.WHITE, false)
	outline_hull = r.flag("outline_hull")
	anchors = r.text_map("anchors")
	states = r.text_map("states")
	for state: StringName in CharacterVisual.STATES:
		if not states.has(String(state)):
			r.problem("states", "no entry for state '%s'" % state)
	stride_m = r.number("stride_m", 0.1, 10.0, 1.4, false)
	run_stride_m = r.number("run_stride_m", 0.1, 20.0, 3.6, false)
	idle_speed = r.number("idle_speed", 0.0, 2.0, 0.1, false)
	run_speed = r.number("run_speed", 0.1, 20.0, 2.6, false)
	turn_speed = r.number("turn_speed", 30.0, 3600.0, 900.0, false)
	lean_gain = r.number("lean_gain", 0.0, 20.0, 1.2, false)
	for part: DefReader in r.optional_objects("parts"):
		var made := ModelPartDef.new()
		made.read(part)
		parts.append(made)
	bob = r.number("bob", 0.0, 1.0, 0.0, false)
	bob_speed = r.number("bob_speed", 0.0, 30.0, 0.0, false)
	spin = r.number("spin", 0.0, 20.0, 0.0, false)


func references() -> Array[Array]:
	var out: Array[Array] = []
	if kind == &"skinned":
		for clip: String in states.values():
			out.append(["clip", StringName(clip)])
	return out
