class_name ModelPartDef
extends RefCounted
## One part worn by a model on a bone (a "part" of a ModelDef): hair or brows from a glTF, a garment lathed around
## the bone's up axis from a radius profile (skirt, coat, head wrap), a sleeve (capsule from the bone to its child), or
## the grandfather's jambiyah hilt. Stand-ins are built in code from these numbers; a real scene replaces them later.

const KINDS: Array[StringName] = [&"hair", &"lathe", &"limb", &"hilt"]

var id: StringName = &""
var kind: StringName = &"lathe"
## The bone it rides on (a skeleton bone name) and where it sits from that bone (metres, in the bone's own frame).
var bone: String = ""
var offset: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO  ## degrees (x, y, z)
var scene: String = ""  ## hair: the glTF scene
var texture: String = ""  ## hair: its albedo
var color: Color = Color.WHITE
## lathe: the radius at evenly spaced stations from top to bottom over `length` metres, with `depth` squashing its z.
var profile: Array[float] = []
var length: float = 0.5
var depth: float = 1.0
var sweep: float = 360.0  ## degrees of the ring that exist, centred on the back (a hood leaves the face open)
## limb: the child bone it runs to and its radius. hilt: the bone it moves to for a strike.
var to_bone: String = ""
var radius: float = 0.05
var draw_bone: String = ""
var draw_offset: Vector3 = Vector3.ZERO  ## hilt: where and how it sits in the hand while drawn
var draw_rotation: Vector3 = Vector3.ZERO
var accent: Color = Color.WHITE  ## hilt: the carnelian stone
var metal: Color = Color.WHITE  ## hilt: silver bands
var sheath_color: Color = Color.WHITE
var glow: float = 0.0  ## emission strength in `accent` (a lens, a lantern): 0 = none


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	bone = r.text("bone")
	offset = _vector(r, "offset", 5.0)
	rotation = _vector(r, "rotation", 360.0)
	draw_offset = _vector(r, "draw_offset", 5.0)
	draw_rotation = _vector(r, "draw_rotation", 360.0)
	scene = r.text("scene", "", kind == &"hair")
	texture = r.text("texture", "", false)
	color = r.color("color", Color.WHITE, false)
	profile = r.float_list("profile", 0.0, 2.0)
	length = r.number("length", 0.01, 3.0, 0.5, false)
	depth = r.number("depth", 0.2, 3.0, 1.0, false)
	sweep = r.number("sweep", 30.0, 360.0, 360.0, false)
	to_bone = r.text("to_bone", "", kind == &"limb")
	radius = r.number("radius", 0.005, 1.0, 0.05, false)
	draw_bone = r.text("draw_bone", "", kind == &"hilt")
	accent = r.color("accent", Color.WHITE, false)
	metal = r.color("metal", Color.WHITE, false)
	sheath_color = r.color("sheath_color", Color.WHITE, false)
	glow = r.number("glow", 0.0, 8.0, 0.0, false)
	if kind == &"lathe" and profile.size() < 2:
		r.problem("profile", "a lathe needs at least two radii")


static func _vector(r: DefReader, key: String, limit: float) -> Vector3:
	var list: Array[float] = r.float_list(key, -limit, limit)
	return Vector3(list[0], list[1], list[2]) if list.size() == 3 else Vector3.ZERO
