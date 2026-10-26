class_name RoofScene
extends Node2D
## purpose: prison roof exploration scene (iso plate, hero, patrol guards, occluders, fuse box, exit).

signal battle_requested(foes: Array[IsoActor], contact: Vector2, ambush: bool)
signal exited

@export var room_id: StringName = &"prison_roof"

@onready var _world: Node2D = %World
@onready var _camera: Camera2D = %Camera2D
@onready var _plate: Sprite2D = %Plate
@onready var _hud: RoofHud = %RoofHud
@onready var _floodlight: RoofFloodlight = %Floodlight
@onready var _rain: RoofRain = %RoofRain

var _room: NeonRoomDef
var _rules: NeonRoofRulesDef
var _hero: IsoActor
var _guards: Array[IsoActor] = []
var _patrols: Array[RoofPatrol] = []
var _exploring: bool = true
var _battle_triggered: bool = false
var _won: bool = false
var _fuse_done: bool = false
var _shake_timer: float = 0.0


func _ready() -> void:
	_room = ContentDB.get_def("neon_room", room_id) as NeonRoomDef
	_rules = ContentDB.get_def("neon_roof_rules", room_id) as NeonRoofRulesDef
	if _rules == null:
		_rules = NeonRoofRulesDef.new()
	if _room == null:
		return
	_setup_plate_and_camera()
	_setup_actors()
	RoofOccluders.build(_room.occluders, _plate.texture, _world)
	_floodlight.setup_shape(_room.floodlight)
	_rain.setup(_room.size)
	_burst_opening()


func hero() -> IsoActor:
	return _hero


func room() -> NeonRoomDef:
	return _room


func guards() -> Array[IsoActor]:
	return _guards


## The y-sorted node holding every actor (MapBattle places the fighters in it).
func world() -> Node2D:
	return _world


func set_exploring(on: bool) -> void:
	_exploring = on


func mark_won() -> void:
	_won = true


func _setup_plate_and_camera() -> void:
	if ResourceLoader.exists(_room.plate):
		_plate.texture = load(_room.plate) as Texture2D
	_plate.centered = false
	_plate.position = Vector2.ZERO
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_room.size.x)
	_camera.limit_bottom = int(_room.size.y)
	_camera.position_smoothing_enabled = true


func _setup_actors() -> void:
	_hero = IsoActor.new()
	_hero.name = "Hero"
	_world.add_child(_hero)
	_hero.setup(&"rydan")
	_hero.position = _room.spawn

	for g_data: Dictionary in _room.guards:
		var guard := IsoActor.new()
		guard.name = String(g_data["id"])
		_world.add_child(guard)
		guard.setup(&"guard")
		_guards.append(guard)
		var patrol := RoofPatrol.new(guard, g_data["path"] as PackedVector2Array, _rules.guard_speed, _rules.guard_pause)
		_patrols.append(patrol)


func _burst_opening() -> void:
	_hero.visible = false
	_shake_timer = _rules.burst_shake_time
	RoofBurst.flash(_world, _room.spawn, _rules.flash_time)
	_hero.visible = true
	_hud.show_move_hint(_rules.move_hint_seconds)


func _process(delta: float) -> void:
	if _hero != null and _camera != null:
		_camera.position = _hero.position
	_update_shake(delta)
	if not _exploring:
		return
	_process_hero_input(delta)
	_process_guards(delta)
	_process_interactables()


func _update_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _rules.burst_shake_intensity
	else:
		_camera.offset = Vector2.ZERO


func _process_hero_input(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var vel: Vector2 = IsoWalk.velocity(move_input, _rules.hero_speed)
	if vel != Vector2.ZERO:
		_hero.position = IsoWalk.step(_hero.position, vel * delta, _room.walk, _room.holes)
		_hero.face(vel)
		_hero.play(&"run")
	else:
		_hero.play(&"idle")


func _process_guards(delta: float) -> void:
	if _battle_triggered:
		return  # the guards fought (and lie down after a win): no more patrols
	for patrol: RoofPatrol in _patrols:
		patrol.step(delta)
	for guard: IsoActor in _guards:
		if ContactRules.touching(_hero.position, guard.position, _rules.touch_radius):
			_battle_triggered = true
			set_exploring(false)
			var contact: Vector2 = (_hero.position + guard.position) * 0.5
			var ambush: bool = ContactRules.is_ambush(guard.position, IsoDir.vector(guard.facing), _hero.position)
			battle_requested.emit(_guards.duplicate(), contact, ambush)
			break


func _process_interactables() -> void:
	var nearest_prompt: String = ""
	for item: Dictionary in _room.interactables:
		var pos: Vector2 = item["pos"]
		var rad: float = item["radius"]
		if _hero.position.distance_to(pos) <= rad:
			var id_name: StringName = item["id"]
			if id_name == &"fuse_box" and not _fuse_done:
				nearest_prompt = item["prompt"]
			elif id_name == &"cable_line" and _won:
				nearest_prompt = item["prompt"]
	if nearest_prompt.is_empty():
		_hud.hide_interact()
	else:
		_hud.show_interact(nearest_prompt)
	if Input.is_action_just_pressed("interact"):
		interact()


func interact() -> void:
	for item: Dictionary in _room.interactables:
		var pos: Vector2 = item["pos"]
		var rad: float = item["radius"]
		if _hero.position.distance_to(pos) <= rad:
			var id_name: StringName = item["id"]
			if id_name == &"fuse_box" and not _fuse_done:
				_on_fuse_interact()
				return
			elif id_name == &"cable_line" and _won:
				exited.emit()
				return


func _on_fuse_interact() -> void:
	_fuse_done = true
	_hud.hide_interact()
	set_exploring(false)
	var box := DialogueBox.new()
	add_child(box)
	box.finished.connect(func(_id: StringName) -> void:
		box.queue_free()
		set_exploring(true)
		_floodlight.kill_light(_rules.floodlight_fade_seconds)
	)
	box.play(&"neon_roof_fuse")
