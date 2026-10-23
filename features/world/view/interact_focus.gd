class_name InteractFocus
extends Node
## purpose: Manages camera ease-in framing shots on spot interaction and ease-out restore on menu close.

static var current: InteractFocus = null

var _easing: bool = false
var _focus_cam: Camera3D = null
var _world_cam: Camera3D = null
var _player: Player = null
var _spot: Node3D = null
var _active_screen: UiScreen = null
var _current_tween: Tween = null


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


static func open_spot(spot: Node3D, shot_id: StringName, player: Player,
		screen_id: StringName, args: Dictionary = {}) -> UiScreen:
	var shot := ContentDB.get_def("focus_shot", shot_id) as FocusShotDef
	if current != null:
		return await current.focus_open(spot, shot, player, screen_id, args)
	return Screens.open(screen_id, args)


func _input(event: InputEvent) -> void:
	if _easing:
		get_viewport().set_input_as_handled()


func focus_open(spot: Node3D, shot: FocusShotDef, player: Player,
		screen_id: StringName, args: Dictionary = {}) -> UiScreen:
	if _easing or _focus_cam != null:
		return null
	if shot == null:
		return Screens.open(screen_id, args)
	var viewport: Viewport = spot.get_viewport() if spot != null else null
	var world_cam: Camera3D = viewport.get_camera_3d() if viewport != null else null
	if world_cam == null:
		return Screens.open(screen_id, args)
	_easing = true
	_world_cam = world_cam
	_spot = spot
	_player = player
	if player != null:
		player.set_active(false)
	_setup_focus_cam()
	await _ease_in(shot)
	_easing = false
	var screen: UiScreen = Screens.open(screen_id, args)
	if screen == null:
		await _ease_back()
		return null
	_active_screen = screen
	screen.closed.connect(_on_screen_closed)
	return screen


func _setup_focus_cam() -> void:
	_focus_cam = Camera3D.new()
	_focus_cam.name = "FocusCamera"
	if is_inside_tree():
		add_child(_focus_cam)
	elif _spot != null and _spot.is_inside_tree():
		_spot.add_sibling(_focus_cam)
	_focus_cam.top_level = true
	_focus_cam.global_transform = _world_cam.global_transform
	_focus_cam.fov = _world_cam.fov
	_focus_cam.make_current()


func _ease_in(shot: FocusShotDef) -> void:
	var target_pos: Vector3 = _spot.global_position + shot.offset
	var target_look: Vector3 = _spot.global_position + shot.look_at
	var look_dir: Vector3 = target_look - target_pos
	var target_basis: Basis = Basis.looking_at(look_dir)
	var target_transform := Transform3D(target_basis, target_pos)
	var style: UiStyleDef = Ui.style()
	var zoom_time: float = style.time(&"t_focus_zoom")
	if zoom_time <= 0.0:
		zoom_time = 0.6
	var tween: Tween = create_tween()
	_current_tween = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_focus_cam, "global_transform", target_transform, zoom_time)
	tween.parallel().tween_property(_focus_cam, "fov", shot.fov, zoom_time)
	await tween.finished
	_current_tween = null


func _on_screen_closed(_result: Variant) -> void:
	if Screens.is_open():
		var next_screen: UiScreen = Screens.top()
		if next_screen != null and not next_screen.closed.is_connected(_on_screen_closed):
			next_screen.closed.connect(_on_screen_closed)
			return
	_ease_back()


func _ease_back() -> void:
	if _focus_cam == null:
		_cleanup()
		return
	_easing = true
	var style: UiStyleDef = Ui.style()
	var zoom_time: float = style.time(&"t_focus_zoom")
	if zoom_time <= 0.0:
		zoom_time = 0.6
	if _world_cam != null and is_instance_valid(_world_cam):
		var tween: Tween = create_tween()
		_current_tween = tween
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_focus_cam, "global_transform", _world_cam.global_transform, zoom_time)
		tween.parallel().tween_property(_focus_cam, "fov", _world_cam.fov, zoom_time)
		await tween.finished
		_current_tween = null
	_cleanup()


func advance(delta: float) -> void:
	if _current_tween != null and _current_tween.is_valid():
		_current_tween.custom_step(delta)


func _cleanup() -> void:
	if _world_cam != null and is_instance_valid(_world_cam):
		_world_cam.make_current()
	if _focus_cam != null and is_instance_valid(_focus_cam):
		_focus_cam.queue_free()
		_focus_cam = null
	if _player != null and is_instance_valid(_player):
		_player.set_active(true)
	_easing = false
	_world_cam = null
	_player = null
	_spot = null
	_active_screen = null
