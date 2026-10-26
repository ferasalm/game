class_name StartUI
extends Control
## View layer for Neon Glitch start flow overlays (title, menu, pick, panel, HUD boot).

const FONT_LATIN: String = "res://assets/fonts/reem_kufi.ttf"
const FONT_MUSNAD: String = "res://assets/fonts/noto_sans_old_south_arabian.ttf"

@onready var title_view: Control = %TitleView
@onready var title_label: Label = %TitleLabel
@onready var press_prompt: Label = %PressPrompt
@onready var menu_view: Control = %MenuView
@onready var menu_new_game_bar: ColorRect = %MenuNewGameBar
@onready var menu_new_game_bg: Panel = %MenuNewGameBg
@onready var menu_new_game_label: Label = %MenuNewGameLabel
@onready var menu_continue_label: Label = %MenuContinueLabel
@onready var menu_options_label: Label = %MenuOptionsLabel
@onready var menu_quit_bar: ColorRect = %MenuQuitBar
@onready var menu_quit_bg: Panel = %MenuQuitBg
@onready var menu_quit_label: Label = %MenuQuitLabel
@onready var pick_view: Control = %PickView
@onready var card_rydan: Control = %CardRydan
@onready var card_rydan_border: Panel = %CardRydanBorder
@onready var card_bilqis: Control = %CardBilqis
@onready var card_bilqis_border: Panel = %CardBilqisBorder
@onready var panel_view: Control = %PanelView
@onready var btn_normal_bg: Panel = %BtnNormalBg
@onready var btn_normal_bar: ColorRect = %BtnNormalBar
@onready var btn_normal_label: Label = %BtnNormalLabel
@onready var btn_hard_bg: Panel = %BtnHardBg
@onready var btn_hard_bar: ColorRect = %BtnHardBar
@onready var btn_hard_label: Label = %BtnHardLabel
@onready var diff_desc: Label = %DiffDesc
@onready var hud_boot_view: Control = %HudBootView
@onready var hud_musnad_1: Label = %HudMusnad1
@onready var hud_musnad_2: Label = %HudMusnad2
@onready var hud_musnad_3: Label = %HudMusnad3
@onready var hint_bar: Control = %HintBar
@onready var hint_label: Label = %HintLabel

var _def: StartFlowDef
var _font_ui: FontFile
var _font_mus: FontFile
var _title_glitch_timer: float = 0.0
var _blink_clock: float = 0.0


func setup(def: StartFlowDef) -> void:
	_def = def
	_font_ui = load(FONT_LATIN) as FontFile
	_font_mus = load(FONT_MUSNAD) as FontFile
	_apply_fonts_and_colors()


func _process(delta: float) -> void:
	if _def == null:
		return
	if title_view.visible and press_prompt.visible:
		_blink_clock += delta
		var alpha: float = 0.3 + 0.7 * (0.5 + 0.5 * sin(_blink_clock * (TAU / _def.blink_period)))
		press_prompt.modulate.a = alpha
		_title_glitch_timer += delta
		if _title_glitch_timer >= _def.glitch_interval:
			_title_glitch_timer = 0.0
			play_title_glitch(_def.glitch_duration)


func set_state(state: StringName, steps: StartSteps) -> void:
	title_view.visible = (state == StartSteps.STATE_TITLE)
	menu_view.visible = (state == StartSteps.STATE_MENU)
	pick_view.visible = (state == StartSteps.STATE_PICK)
	panel_view.visible = (state == StartSteps.STATE_PANEL)
	hud_boot_view.visible = (state == StartSteps.STATE_LAUNCH)
	hint_bar.visible = (state in [StartSteps.STATE_MENU, StartSteps.STATE_PICK, StartSteps.STATE_PANEL])

	match state:
		StartSteps.STATE_TITLE:
			press_prompt.visible = true
		StartSteps.STATE_MENU:
			update_menu_cursor(steps.menu_cursor)
			hint_label.text = "[^v] " + tr("NEON_HINT_SELECT") + "     [OK] " + tr("NEON_HINT_CONFIRM")
		StartSteps.STATE_PICK:
			update_hero_selection(steps.hero)
			hint_label.text = "[<>] " + tr("NEON_HINT_HERO") + "     [OK] " + tr("NEON_HINT_CONFIRM") + "     [ESC] " + tr("NEON_HINT_BACK")
		StartSteps.STATE_PANEL:
			panel_view.modulate.a = 1.0
			update_difficulty(steps.difficulty)
			hint_label.text = "[<>] " + tr("NEON_HINT_DIFFICULTY") + "     [OK] " + tr("NEON_HINT_BEGIN") + "     [ESC] " + tr("NEON_HINT_BACK")


func update_menu_cursor(cursor: int) -> void:
	var ng_sel: bool = (cursor == StartSteps.MENU_NEW_GAME)
	var quit_sel: bool = (cursor == StartSteps.MENU_QUIT)

	menu_new_game_bar.visible = ng_sel
	menu_new_game_bg.visible = ng_sel
	menu_new_game_label.modulate = _def.white if ng_sel else _def.white * 0.8

	menu_continue_label.modulate = _def.dim_gray
	menu_options_label.modulate = _def.dim_gray

	menu_quit_bar.visible = quit_sel
	menu_quit_bg.visible = quit_sel
	menu_quit_label.modulate = _def.white if quit_sel else _def.white * 0.8


func update_hero_selection(hero: StringName) -> void:
	var is_rydan: bool = (hero == StartSteps.HERO_RYDAN)
	card_rydan_border.modulate = _def.cyan if is_rydan else _def.gray * 0.5
	card_bilqis_border.modulate = _def.magenta if not is_rydan else _def.gray * 0.3
	card_rydan.modulate.a = 1.0 if is_rydan else 0.75
	card_bilqis.modulate.a = 0.6 if is_rydan else 0.85


func update_difficulty(difficulty: StringName) -> void:
	var is_normal: bool = (difficulty == StartSteps.DIFF_NORMAL)
	btn_normal_bg.modulate = _def.cyan if is_normal else _def.gray * 0.4
	btn_normal_bar.visible = is_normal
	btn_normal_label.modulate = _def.white if is_normal else _def.gray

	btn_hard_bg.modulate = _def.cyan if not is_normal else _def.gray * 0.4
	btn_hard_bar.visible = not is_normal
	btn_hard_label.modulate = _def.white if not is_normal else _def.gray

	diff_desc.text = tr("NEON_DIFF_NORMAL_DESC") if is_normal else tr("NEON_DIFF_HARD_DESC")


func play_title_glitch(duration: float) -> void:
	var mat: ShaderMaterial = title_label.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("glitch_strength", 1.0)
	var tw: Tween = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func() -> void: mat.set_shader_parameter("glitch_strength", 0.0))


func start_hud_boot(duration: float) -> void:
	hud_boot_view.visible = true
	hud_musnad_1.visible = false
	hud_musnad_2.visible = false
	hud_musnad_3.visible = false
	var step_time: float = duration / 4.0
	var tw: Tween = create_tween()
	tw.tween_callback(func() -> void: hud_musnad_1.visible = true).set_delay(step_time)
	tw.tween_callback(func() -> void: hud_musnad_2.visible = true).set_delay(step_time * 2.0)
	tw.tween_callback(func() -> void: hud_musnad_3.visible = true).set_delay(step_time * 3.0)


func fade_panel(duration: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(panel_view, "modulate:a", 0.0, duration)


func _apply_fonts_and_colors() -> void:
	if _font_ui:
		title_label.add_theme_font_override("font", _font_ui)
		press_prompt.add_theme_font_override("font", _font_ui)
		hint_label.add_theme_font_override("font", _font_ui)
