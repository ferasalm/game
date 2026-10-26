class_name StartFlow
extends Control
## Full-screen controller for the Neon Glitch start flow over video clips.

signal done(difficulty: StringName)

const ASPECT_RATIO: float = 16.0 / 9.0

@onready var video_player: VideoStreamPlayer = %VideoPlayer
@onready var fade_overlay: TextureRect = %FadeOverlay
@onready var blur_overlay: ColorRect = %BlurOverlay
@onready var ui: StartUI = %UI

var steps: StartSteps = StartSteps.new()
var def: StartFlowDef
var _blur_mat: ShaderMaterial
var _current_clip: String = ""


func _ready() -> void:
	if ContentDB != null:
		def = ContentDB.get_def("start_flow", &"start_flow") as StartFlowDef
	if def == null:
		def = StartFlowDef.new()
	_blur_mat = blur_overlay.material as ShaderMaterial
	if ui != null:
		ui.setup(def)
	if video_player != null:
		video_player.finished.connect(_on_video_finished)
	done.connect(_on_done)
	_update_video_layout()
	_apply_state(steps.state)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_video_layout()


func _unhandled_input(event: InputEvent) -> void:
	if steps.state == StartSteps.STATE_DONE:
		return
	if steps.state == StartSteps.STATE_TITLE:
		if event.is_pressed() and not event.is_echo():
			_on_title_press()
		return
	if event.is_action_pressed("interact"):
		_on_confirm()
	elif event.is_action_pressed("back"):
		_on_back()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		_on_vertical_move(1 if event.is_action_pressed("move_down") else -1)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_on_horizontal_move(1 if event.is_action_pressed("move_right") else -1)


func _on_title_press() -> void:
	ui.play_title_glitch(def.glitch_duration)
	var tw: Tween = create_tween()
	tw.tween_interval(def.glitch_duration)
	tw.tween_callback(func() -> void:
		steps.confirm()
		_apply_state(steps.state)
	)


func _on_confirm() -> void:
	if steps.state == StartSteps.STATE_PICK and steps.hero != StartSteps.HERO_RYDAN:
		return
	if steps.state == StartSteps.STATE_MENU and steps.menu_cursor == StartSteps.MENU_QUIT:
		get_tree().quit()
		return
	var prev: StringName = steps.state
	if steps.confirm():
		if prev == StartSteps.STATE_PICK:
			StartFlowFX.blur_zoom(_blur_mat, def.blur_zoom_duration, self, func() -> void: _apply_state(steps.state))
		else:
			_apply_state(steps.state)


func _on_back() -> void:
	if steps.back():
		_apply_state(steps.state)


func _on_vertical_move(delta: int) -> void:
	if steps.state == StartSteps.STATE_MENU:
		steps.move_menu(delta)
		ui.update_menu_cursor(steps.menu_cursor)


func _on_horizontal_move(_delta: int) -> void:
	if steps.state == StartSteps.STATE_PICK:
		steps.toggle_hero()
		ui.update_hero_selection(steps.hero)
	elif steps.state == StartSteps.STATE_PANEL:
		steps.toggle_difficulty()
		ui.update_difficulty(steps.difficulty)


func _apply_state(state: StringName) -> void:
	match state:
		StartSteps.STATE_TITLE:
			_switch_clip(def.title_clip, true)
		StartSteps.STATE_MENU:
			if _current_clip != def.title_clip:
				_switch_clip(def.title_clip, true)
		StartSteps.STATE_WINDOW_PUSH:
			_switch_clip(def.window_push_clip, false)
			StartFlowFX.push_blur(_blur_mat, def.push_blur_duration, self)
		StartSteps.STATE_PICK:
			_switch_clip(def.hero_pick_clip, true)
		StartSteps.STATE_PANEL:
			if _current_clip != def.rydan_panel_clip:
				_switch_clip(def.rydan_panel_clip, true)
		StartSteps.STATE_REACTION:
			if ui != null:
				ui.fade_panel(def.reaction_fade_duration)
			_switch_clip(def.rydan_reaction_clip, false)
		StartSteps.STATE_LAUNCH:
			_switch_clip(def.launch_clip, false)
			if ui != null:
				ui.start_hud_boot(def.hud_boot_duration)
		StartSteps.STATE_DONE:
			done.emit(steps.difficulty)
	if ui != null:
		ui.set_state(state, steps)


func _switch_clip(clip_path: String, loop_clip: bool) -> void:
	if _current_clip == clip_path:
		if video_player != null:
			video_player.loop = loop_clip
		return
	if video_player != null and fade_overlay != null and def != null:
		StartFlowFX.crossfade(fade_overlay, video_player.get_video_texture(), def.crossfade_duration, self)
	_current_clip = clip_path
	if video_player != null:
		video_player.stream = load(clip_path) as VideoStream
		video_player.loop = loop_clip
		video_player.play()


func _on_video_finished() -> void:
	if steps.state in [StartSteps.STATE_WINDOW_PUSH, StartSteps.STATE_REACTION, StartSteps.STATE_LAUNCH]:
		steps.clip_done()
		_apply_state(steps.state)


func _update_video_layout() -> void:
	var vp: Vector2 = size if (size.x > 0.0 and size.y > 0.0) else get_viewport_rect().size
	StartFlowFX.fit_cover(video_player, vp, ASPECT_RATIO)


func _on_done(diff: StringName) -> void:
	print("StartFlow: chosen difficulty = ", diff)


func set_state_for_shot(target_state: String) -> void:
	steps.state = StringName(target_state)
	if steps.state == StartSteps.STATE_PICK:
		steps.hero = StartSteps.HERO_RYDAN
	elif steps.state == StartSteps.STATE_PANEL:
		steps.difficulty = StartSteps.DIFF_NORMAL
	_apply_state(steps.state)
