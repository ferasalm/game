class_name TayramanaFlow
extends RefCounted
## purpose: Manages transitions into and out of Tayramana room, fade overlays, sit flow and workshop inside room.

signal room_entered(room: TayramanaRoom)
signal room_exited
signal workshop_opened

const FADE_TIME: float = 0.4

var room: TayramanaRoom
var host: Node
var rooftop: Rooftop
var port: RooftopPort
var dialogue_box: DialogueBox

var _layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_tween: Tween


func setup(p_host: Node, p_rooftop: Rooftop, p_port: RooftopPort, p_dialogue: DialogueBox) -> void:
	host = p_host
	rooftop = p_rooftop
	port = p_port
	dialogue_box = p_dialogue
	_setup_fade()


func _setup_fade() -> void:
	if host == null:
		return
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade_rect)
	host.add_child(_layer)


func is_in_room() -> bool:
	return room != null


func freeze_room(freeze: bool) -> void:
	if room != null:
		room.freeze_actors(freeze)


func enter_room(target: StringName, fade_duration: float = FADE_TIME) -> void:
	if target != &"tayramana" or room != null:
		return
	Router.set_busy(true)
	if rooftop != null:
		rooftop.freeze_actors(true)
	if fade_duration > 0.0:
		await _fade_to(1.0, fade_duration)
	if port != null:
		port.suspend()
	_instantiate_room()
	if fade_duration > 0.0:
		await _fade_to(0.0, fade_duration)
	if room != null:
		room.freeze_actors(false)
	Router.set_busy(false)
	room_entered.emit(room)


func exit_room(fade_duration: float = FADE_TIME) -> void:
	if room == null:
		return
	Router.set_busy(true)
	room.freeze_actors(true)
	if fade_duration > 0.0:
		await _fade_to(1.0, fade_duration)
	var exit_pos: Vector3 = room.spec.exit_pos
	room.queue_free()
	room = null
	if port != null:
		port.resume()
		port.teleport_party(exit_pos)
		port.restore_camera()
	if rooftop != null:
		rooftop.freeze_actors(true)
	if fade_duration > 0.0:
		await _fade_to(0.0, fade_duration)
	if rooftop != null:
		rooftop.freeze_actors(false)
	Router.set_busy(false)
	room_exited.emit()


func on_sit_interacted(_spot_id: StringName) -> void:
	if room == null:
		return
	Router.set_busy(true)
	room.freeze_actors(true)
	room.sit_party(true)
	if not bool(GameState.flags.get(&"tayramana_qishr_rewarded", false)):
		GameState.flags[&"tayramana_qishr_rewarded"] = true
		ItemService.add_to_bag(&"qishr_cup", 2)
	var talk_def := ContentDB.get_def("talk", &"tayramana_qishr") as TalkDef
	var dialogue_id: StringName = TalkPicker.pick(talk_def, GameState.flags)
	dialogue_box.play(dialogue_id)


func handle_dialogue_finished(dialogue_id: StringName) -> bool:
	if dialogue_id == &"tayramana_qishr_first" or dialogue_id == &"tayramana_qishr_later":
		if room != null:
			room.sit_party(false)
			room.freeze_actors(false)
		Router.set_busy(false)
		return true
	return false


func _instantiate_room() -> void:
	var spec := ContentDB.get_def("room", &"tayramana") as RoomDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	room = TayramanaRoom.new(rules, spec, palette, rig)
	host.add_child(room)
	room.freeze_actors(true)
	room.camera.make_current()
	room.door_exited.connect(exit_room)
	room.workshop_opened.connect(workshop_opened.emit)
	room.sit_interacted.connect(on_sit_interacted)


func _fade_to(target_alpha: float, duration: float) -> void:
	if _fade_rect == null or not _fade_rect.is_inside_tree():
		return
	if duration <= 0.0:
		_fade_rect.color.a = target_alpha
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = _fade_rect.create_tween()
	_fade_tween.tween_property(_fade_rect, "color:a", target_alpha, duration)
	await _fade_tween.finished


## Opens the bench inside the room (camera ease + workshop menu); false outside it. on_closed runs once it closes.
func open_bench(on_closed: Callable) -> bool:
	if not is_in_room():
		return false
	_focus_bench(on_closed)
	return true


func _focus_bench(on_closed: Callable) -> void:
	var screen: UiScreen = await room.focus_workbench()
	if screen == null:
		on_closed.call()
		return
	screen.closed.connect(func(_result: Variant) -> void: on_closed.call(), CONNECT_ONE_SHOT)
