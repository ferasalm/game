class_name StartFlow
extends Control
## Full-screen controller for the Neon Glitch start flow over video clips.

signal done(difficulty: StringName)

@onready var video_player: VideoStreamPlayer = %VideoPlayer
@onready var fade_overlay: TextureRect = %FadeOverlay
@onready var blur_overlay: ColorRect = %BlurOverlay
@onready var ui: StartUI = %UI

var steps: StartSteps = StartSteps.new()
var def: StartFlowDef
var _current_clip: String = ""
var _busy_left: float = 0.0
var _done_emitted: bool = false
var _transition_token: int = 0


func _ready() -> void:
	if ContentDB != null:
		def = ContentDB.get_def("start_flow", &"start_flow") as StartFlowDef
	if def == null:
		def = StartFlowDef.new()
	if ui != null:
		ui.setup(def)
		StartFlowSelection.connect_ui(ui, steps, handle_action, _is_busy)
	if video_player != null:
		video_player.finished.connect(_on_video_finished)
	done.connect(func(diff: StringName) -> void: print("StartFlow: chosen difficulty = ", diff))
	if blur_overlay != null:
		blur_overlay.visible = false
	_update_video_layout()
	_apply_state(steps.state)


func _process(delta: float) -> void:
	if _busy_left > 0.0:
		_busy_left = maxf(0.0, _busy_left - delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_video_layout()


func _unhandled_input(event: InputEvent) -> void:
	if _is_busy() or steps.state == StartSteps.STATE_DONE:
		return
	var action: StringName = StartFlowInput.action_for(event, steps.state)
	if not action.is_empty():
		handle_action(action)


func handle_action(action: StringName) -> void:
	if _is_busy() or steps.state == StartSteps.STATE_DONE:
		return
	if steps.state == StartSteps.STATE_TITLE:
		if action in [&"press_any", &"confirm", &"interact"]:
			_start_title_transition()
		return
	var prev: StringName = steps.state
	var target: StringName = steps.next_state(action)
	if steps.quit_requested:
		get_tree().quit()
		return
	if target == prev:
		if ui != null:
			ui.set_state(steps.state, steps)
		return
	_transition(prev, target)


func _transition(prev: StringName, target: StringName) -> void:
	if prev == StartSteps.STATE_PICK and target == StartSteps.STATE_PANEL:
		_transition_token += 1
		var token: int = _transition_token
		_begin_busy(def.blur_zoom_duration)
		StartFlowFX.blur_zoom(blur_overlay, def.blur_zoom_duration, def.zoom_blur_peak, self, func() -> void:
			if token == _transition_token and steps.state == StartSteps.STATE_PANEL:
				_apply_state(steps.state)
		)
		return
	_apply_state(target)


func _start_title_transition() -> void:
	_transition_token += 1
	var token: int = _transition_token
	_begin_busy(def.glitch_duration)
	if ui != null:
		ui.play_title_glitch(def.glitch_duration)
	var tw: Tween = create_tween()
	tw.tween_interval(def.glitch_duration)
	tw.tween_callback(func() -> void:
		if token == _transition_token:
			steps.next_state(&"press_any")
			_apply_state(steps.state)
	)


func _apply_state(state: StringName) -> void:
	if ui != null:
		ui.set_state(state, steps)
	match state:
		StartSteps.STATE_TITLE:
			_switch_clip(def.title_clip, true)
		StartSteps.STATE_MENU:
			if _current_clip != def.title_clip:
				_switch_clip(def.title_clip, true)
		StartSteps.STATE_WINDOW_PUSH:
			_switch_clip(def.window_push_clip, false)
			_begin_busy(def.push_blur_duration)
			StartFlowFX.push_blur(blur_overlay, def.push_blur_duration, def.push_blur_peak, self)
		StartSteps.STATE_PICK:
			_switch_clip(def.hero_pick_clip, true)
		StartSteps.STATE_PANEL:
			if _current_clip != def.rydan_panel_clip:
				_switch_clip(def.rydan_panel_clip, true)
		StartSteps.STATE_REACTION:
			_switch_clip(def.rydan_reaction_clip, false)
			if ui != null:
				ui.fade_panel(def.reaction_fade_duration)
			_begin_busy(def.reaction_fade_duration)
		StartSteps.STATE_LAUNCH:
			_switch_clip(def.launch_clip, false)
			_start_launch()
		StartSteps.STATE_DONE:
			_emit_done()


func _emit_done() -> void:
	if _done_emitted:
		return
	_done_emitted = true
	done.emit(steps.difficulty)


func _start_launch() -> void:
	_begin_busy(def.hud_boot_duration + def.launch_glitch_duration)
	if ui != null:
		ui.start_hud_boot(def.hud_boot_duration, def.launch_glitch_duration, _finish_launch)
	else:
		_finish_launch()


func _finish_launch() -> void:
	if steps.state != StartSteps.STATE_LAUNCH:
		return
	steps.clip_done()
	_apply_state(steps.state)


func _switch_clip(clip_path: String, loop_clip: bool) -> void:
	if _current_clip == clip_path:
		if video_player != null:
			video_player.loop = loop_clip
		return
	if video_player != null and fade_overlay != null and def != null:
		StartFlowFX.crossfade(fade_overlay, video_player.get_video_texture(), def.crossfade_duration, self)
		_begin_busy(def.crossfade_duration)
	_current_clip = clip_path
	if video_player != null:
		video_player.stream = load(clip_path) as VideoStream
		video_player.loop = loop_clip
		video_player.play()


func _on_video_finished() -> void:
	if steps.state in [StartSteps.STATE_WINDOW_PUSH, StartSteps.STATE_REACTION]:
		steps.clip_done()
		_apply_state(steps.state)


func _update_video_layout() -> void:
	if def == null:
		return
	var vp: Vector2 = size if (size.x > 0.0 and size.y > 0.0) else get_viewport_rect().size
	StartFlowFX.fit_cover(video_player, vp, def.aspect_ratio)
	StartFlowFX.fit_cover(fade_overlay, vp, def.aspect_ratio)


func _begin_busy(duration: float) -> void:
	_busy_left = maxf(_busy_left, duration)


func _is_busy() -> bool:
	return _busy_left > 0.0


func set_state_for_shot(target_state: String) -> void:
	steps.state = StringName(target_state)
	if steps.state == StartSteps.STATE_PICK:
		steps.hero = StartSteps.HERO_RYDAN
	elif steps.state == StartSteps.STATE_PANEL:
		steps.difficulty = StartSteps.DIFF_NORMAL
	_apply_state(steps.state)
