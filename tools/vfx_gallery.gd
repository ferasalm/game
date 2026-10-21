extends Node3D
## Effect gallery: plays every battle effect kind one after another (one per second) on a night stage, for the
## movie writer. Run (not headless): "$(tools/godot.sh)" --path . --resolution 960x540 --write-movie DIR/f.png
## --fixed-fps 30 --quit-after 480 -s res://tools/shot_scene.gd -- res://tools/vfx_gallery.gd

const KINDS: Array[StringName] = [
	&"slash", &"heavy_slash", &"stab", &"piston", &"beam", &"bolt", &"arc_all", &"burst", &"heal", &"shield",
	&"overclock", &"net", &"drone_shot", &"baton", &"break"]
const ALLY_KINDS: Array[StringName] = [&"heal", &"shield", &"overclock"]
const EVERY: float = 1.0

var _vfx: VfxPlayer
var _actor: CharacterVisual
var _foes: Array[CharacterVisual] = []
var _ally: CharacterVisual
var _clock: float = 0.0
var _next: int = 0


func _ready() -> void:
	var look := ContentDB.get_def("look", &"night") as LookDef
	add_child(Diorama.make_environment(look))
	add_child(Diorama.make_sun(look))
	var floor_block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(30.0, 0.5, 30.0)
	floor_block.mesh = mesh
	floor_block.material_override = Diorama.material(Color(0.5, 0.45, 0.4))
	floor_block.position.y = -0.25
	add_child(floor_block)
	var def := ContentDB.get_def("battle_camera", &"default") as BattleCameraDef
	var camera := Diorama.make_camera(look)
	add_child(camera)
	camera.position = def.pos
	camera.look_at(def.look)
	camera.fov = def.fov
	camera.current = true
	_vfx = VfxPlayer.new()
	add_child(_vfx)
	_actor = _person(&"zayd", Vector3(-2.2, 0.0, 0.5), 1.0)
	_ally = _person(&"bilqis", Vector3(-3.6, 0.0, -0.6), 1.0)
	for i: int in 3:
		_foes.append(_person(&"concession_enforcer", Vector3(1.4 + i * 1.5, 0.0, 0.8 - i * 0.7), -1.0))


func _person(sprite: StringName, at: Vector3, dir: float) -> CharacterVisual:
	var visual := CharacterVisual.new()
	visual.set_sprite(sprite)
	add_child(visual)
	visual.position = at
	visual.face(dir)
	return visual


func _process(delta: float) -> void:
	_clock += delta
	_poses()
	if _next >= KINDS.size() or _clock < _next * EVERY:
		return
	var kind: StringName = KINDS[_next]
	_next += 1
	var targets: Array[CharacterVisual] = []
	var who: CharacterVisual = _actor
	if kind == &"break":
		who = _foes[0]
	elif ALLY_KINDS.has(kind):
		targets.append(_ally)
	elif kind == &"arc_all":
		targets.assign(_foes)
	else:
		targets.append(_foes[0])
	_vfx.play(ContentDB.get_def("vfx", kind) as VfxDef, who, targets)


## After the effects: a hurt flinch, a knock-out and revive, a victory hop and a few steps of walking.
func _poses() -> void:
	if _next < KINDS.size():
		return
	var t: float = _clock - KINDS.size() * EVERY
	if _beat(t, 0.5):
		_foes[1].hurt(0.6)
	if _beat(t, 1.5):
		_foes[2].set_down(true, true)
	if _beat(t, 3.0):
		_foes[2].set_down(false, true)
	if _beat(t, 4.5):
		_actor.victory_hop()
		_ally.victory_hop()
	if _beat(t, 6.5):
		_actor.set_moving(true)
		_ally.set_moving(true)


func _beat(t: float, at: float) -> bool:
	var fired: bool = t >= at and t - get_process_delta_time() < at
	return fired
