class_name StartUI
extends StartUIView
## View layer for Neon Glitch start flow overlays (title, menu, pick, panel, HUD boot).

const GLITCH_SHADER: Shader = preload("res://features/neon/start/shaders/glitch.gdshader")

var _def: StartFlowDef
var _title_glitch_timer: float = 0.0
var _blink_clock: float = 0.0


func setup(def: StartFlowDef) -> void:
	_def = def
	StartUIStyle.apply(self, def)
	_apply_glitch_offset()


func _process(delta: float) -> void:
	if _def == null:
		return
	if title_view.visible and press_prompt.visible:
		_blink_clock += delta
		var span: float = _def.blink_max_alpha - _def.blink_min_alpha
		press_prompt.modulate.a = _def.blink_min_alpha + span * (0.5 + 0.5 * sin(_blink_clock * (TAU / _def.blink_period)))
		_title_glitch_timer += delta
		if _title_glitch_timer >= _def.glitch_interval:
			_title_glitch_timer = 0.0
			play_title_glitch(_def.glitch_duration)


func set_state(state: StringName, steps: StartSteps) -> void:
	title_view.visible = (state == StartSteps.STATE_TITLE)
	menu_view.visible = (state == StartSteps.STATE_MENU)
	pick_view.visible = (state == StartSteps.STATE_PICK)
	panel_view.visible = (state in [StartSteps.STATE_PANEL, StartSteps.STATE_REACTION])
	hud_boot_view.visible = (state == StartSteps.STATE_LAUNCH)
	hint_bar.visible = (state in [StartSteps.STATE_MENU, StartSteps.STATE_PICK, StartSteps.STATE_PANEL])

	match state:
		StartSteps.STATE_TITLE:
			press_prompt.visible = true
		StartSteps.STATE_MENU:
			update_menu_cursor(steps.menu_cursor)
			hint_label.text = tr("NEON_HINT_MENU")
		StartSteps.STATE_PICK:
			update_hero_selection(steps.hero)
			hint_label.text = tr("NEON_HINT_PICK")
		StartSteps.STATE_PANEL:
			panel_view.modulate.a = 1.0
			update_difficulty(steps.difficulty)
			hint_label.text = tr("NEON_HINT_PANEL")


func update_menu_cursor(cursor: int) -> void:
	var ng_sel: bool = (cursor == StartSteps.MENU_NEW_GAME)
	var quit_sel: bool = (cursor == StartSteps.MENU_QUIT)

	menu_new_game_bar.visible = ng_sel
	menu_new_game_bg.visible = ng_sel
	menu_new_game_label.modulate = _def.white if ng_sel else _def.white * _def.menu_unselected_alpha

	menu_continue_label.modulate = _def.dim_gray
	menu_options_label.modulate = _def.dim_gray

	menu_quit_bar.visible = quit_sel
	menu_quit_bg.visible = quit_sel
	menu_quit_label.modulate = _def.white if quit_sel else _def.white * _def.menu_unselected_alpha


func update_hero_selection(hero: StringName) -> void:
	var is_rydan: bool = (hero == StartSteps.HERO_RYDAN)
	card_rydan_border.modulate = _def.cyan if is_rydan else _def.gray * _def.border_dim_alpha
	card_bilqis_border.modulate = _def.magenta if not is_rydan else _def.gray * _def.border_off_alpha
	card_rydan.modulate.a = _def.card_selected_alpha if is_rydan else _def.card_idle_alpha
	card_bilqis.modulate.a = _def.card_dim_alpha if is_rydan else _def.card_alt_alpha


func update_difficulty(difficulty: StringName) -> void:
	var is_normal: bool = (difficulty == StartSteps.DIFF_NORMAL)
	btn_normal_bg.modulate = _def.cyan if is_normal else _def.gray * _def.disabled_alpha
	btn_normal_bar.visible = is_normal
	btn_normal_label.modulate = _def.white if is_normal else _def.gray

	btn_hard_bg.modulate = _def.cyan if not is_normal else _def.gray * _def.disabled_alpha
	btn_hard_bar.visible = not is_normal
	btn_hard_label.modulate = _def.white if not is_normal else _def.gray

	diff_desc.text = tr("NEON_DIFF_NORMAL_DESC") if is_normal else tr("NEON_DIFF_HARD_DESC")


func play_title_glitch(duration: float) -> void:
	var mat: ShaderMaterial = _glitch_material(title_label)
	if mat == null:
		return
	mat.set_shader_parameter("glitch_strength", 1.0)
	var tw: Tween = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func() -> void: mat.set_shader_parameter("glitch_strength", 0.0))


func start_hud_boot(duration: float, glitch_duration: float, on_done: Callable) -> void:
	hud_boot_view.visible = true
	var labels: Array[Label] = [hud_musnad_1, hud_musnad_2, hud_musnad_3]
	for label: Label in labels:
		label.visible = false
	var step_time: float = duration / float(labels.size() + 1)
	for i: int in labels.size():
		var label: Label = labels[i]
		var tw: Tween = create_tween()
		tw.tween_callback(func() -> void: label.visible = true).set_delay(step_time * float(i + 1))
	var boot: Tween = create_tween()
	boot.tween_interval(duration)
	boot.tween_callback(func() -> void: _glitch_out(glitch_duration))
	boot.tween_interval(glitch_duration)
	boot.tween_callback(on_done)


func _glitch_out(duration: float) -> void:
	var labels: Array[Label] = [hud_musnad_1, hud_musnad_2, hud_musnad_3]
	for label: Label in labels:
		_glitch_material(label).set_shader_parameter("glitch_strength", 1.0)
	var tw: Tween = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func() -> void:
		for label: Label in labels:
			_glitch_material(label).set_shader_parameter("glitch_strength", 0.0)
		hud_boot_view.visible = false
	)


func fade_panel(duration: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(panel_view, "modulate:a", 0.0, duration)
	tw.tween_callback(func() -> void: panel_view.visible = false)


func _glitch_material(label: Label) -> ShaderMaterial:
	var mat: ShaderMaterial = label.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = GLITCH_SHADER
		label.material = mat
	mat.set_shader_parameter("glitch_offset", _def.glitch_offset)
	return mat


func _apply_glitch_offset() -> void:
	var mat: ShaderMaterial = title_label.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("glitch_offset", _def.glitch_offset)
