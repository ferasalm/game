class_name StartUIStyle
extends RefCounted
## Applies localization, authored fonts/sizes/colours and mouse handling to a StartUIView.

const FONT_LATIN: String = "res://assets/fonts/reem_kufi.ttf"
const FONT_MUSNAD: String = "res://assets/fonts/noto_sans_old_south_arabian.ttf"


static func apply(view: StartUIView, def: StartFlowDef) -> void:
	if view == null or def == null:
		return
	var font_ui: FontFile = load(FONT_LATIN) as FontFile
	var font_mus: FontFile = load(FONT_MUSNAD) as FontFile
	_apply_text(view)
	_apply_theme(view, def)
	_apply_fonts(view, def, font_ui, font_mus)
	_wire_mouse(view)


static func _apply_text(view: StartUIView) -> void:
	view.title_label.text = view.tr("NEON_START_TITLE")
	view.press_prompt.text = view.tr("NEON_START_PRESS_ANY")
	view.menu_new_game_label.text = view.tr("NEON_START_NEW_GAME")
	view.menu_continue_label.text = view.tr("NEON_START_CONTINUE")
	view.menu_options_label.text = view.tr("NEON_START_OPTIONS")
	view.menu_quit_label.text = view.tr("NEON_START_QUIT")
	view.pick_header.text = view.tr("NEON_START_CHOOSE")
	view.pick_musnad.text = view.tr("NEON_MUSNAD_CHOOSE")
	view.card_rydan_name.text = view.tr("NEON_HERO_RYDAN_NAME")
	view.card_rydan_musnad.text = view.tr("NEON_MUSNAD_RYDAN")
	view.card_rydan_role.text = view.tr("NEON_HERO_RYDAN_ROLE")
	view.card_bilqis_name.text = view.tr("NEON_HERO_BILQIS_NAME")
	view.card_bilqis_musnad.text = view.tr("NEON_MUSNAD_BILQIS")
	view.card_bilqis_later.text = view.tr("NEON_START_LATER")
	view.panel_name.text = view.tr("NEON_HERO_RYDAN_NAME")
	view.panel_musnad.text = view.tr("NEON_MUSNAD_RYDAN")
	view.panel_role.text = view.tr("NEON_HERO_RYDAN_ROLE")
	view.panel_story.text = view.tr("NEON_HERO_RYDAN_STORY")
	view.panel_style_1.text = view.tr("NEON_HERO_RYDAN_STYLE_1")
	view.panel_style_2.text = view.tr("NEON_HERO_RYDAN_STYLE_2")
	view.panel_style_3.text = view.tr("NEON_HERO_RYDAN_STYLE_3")
	view.panel_style_4.text = view.tr("NEON_HERO_RYDAN_STYLE_4")
	view.diff_title.text = view.tr("NEON_START_DIFFICULTY")
	view.diff_musnad.text = view.tr("NEON_MUSNAD_DIFFICULTY")
	view.btn_normal_label.text = view.tr("NEON_DIFF_NORMAL")
	view.btn_hard_label.text = view.tr("NEON_DIFF_HARD")
	view.hud_musnad_1.text = view.tr("NEON_MUSNAD_DIFFICULTY")
	view.hud_musnad_2.text = view.tr("NEON_MUSNAD_CHOOSE")
	view.hud_musnad_3.text = view.tr("NEON_MUSNAD_RYDAN")


static func _apply_theme(view: StartUIView, def: StartFlowDef) -> void:
	var theme := Theme.new()
	theme.set_stylebox("panel", "Panel", _panel_style(def.panel_bg, def.cyan, 2, 0.75))
	view.theme = theme
	var selection: StyleBoxFlat = _panel_style(def.selection_bg, def.cyan, 2, 0.8)
	for bg: Panel in [view.menu_new_game_bg, view.menu_quit_bg, view.btn_normal_bg, view.btn_hard_bg]:
		bg.add_theme_stylebox_override("panel", selection)
	var dim_bg: Color = Color(def.panel_bg, def.panel_bg.a * def.card_alt_alpha)
	view.card_bilqis_border.add_theme_stylebox_override("panel", _panel_style(dim_bg, def.gray, 1, def.border_off_alpha))


static func _panel_style(bg: Color, border: Color, width: int, border_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.border_color = Color(border, border_alpha)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style


static func _apply_fonts(view: StartUIView, def: StartFlowDef, font_ui: FontFile, font_mus: FontFile) -> void:
	_apply_label(view.title_label, font_ui, def.font_title_size)
	_apply_label(view.press_prompt, font_ui, def.font_press_size)
	for label: Label in [view.menu_new_game_label, view.menu_continue_label, view.menu_options_label, view.menu_quit_label]:
		_apply_label(label, font_ui, def.font_menu_size)
	_apply_label(view.pick_header, font_ui, def.font_pick_header_size)
	_apply_label(view.pick_musnad, font_mus, def.font_musnad_title_size)
	_apply_label(view.card_rydan_name, font_ui, def.font_hero_name_size)
	_apply_label(view.card_bilqis_name, font_ui, def.font_hero_name_size)
	_apply_label(view.card_rydan_musnad, font_mus, def.font_musnad_accent_size)
	_apply_label(view.card_bilqis_musnad, font_mus, def.font_musnad_accent_size)
	_apply_label(view.card_rydan_role, font_ui, def.font_panel_role_size)
	_apply_label(view.card_bilqis_later, font_ui, def.font_musnad_accent_size)
	_apply_label(view.panel_name, font_ui, def.font_panel_name_size)
	_apply_label(view.panel_musnad, font_mus, def.font_musnad_name_size)
	_apply_label(view.panel_role, font_ui, def.font_panel_role_size)
	_apply_label(view.panel_story, font_ui, def.font_panel_body_size)
	for label: Label in [view.panel_style_1, view.panel_style_2, view.panel_style_3, view.panel_style_4]:
		_apply_label(label, font_ui, def.font_panel_body_size)
	_apply_label(view.diff_title, font_ui, def.font_diff_title_size)
	_apply_label(view.diff_musnad, font_mus, def.font_musnad_title_size)
	_apply_label(view.btn_normal_label, font_ui, def.font_diff_button_size)
	_apply_label(view.btn_hard_label, font_ui, def.font_diff_button_size)
	_apply_label(view.diff_desc, font_ui, def.font_panel_body_size)
	_apply_label(view.hint_label, font_ui, def.font_hint_size)
	for label: Label in [view.hud_musnad_1, view.hud_musnad_2, view.hud_musnad_3]:
		_apply_label(label, font_mus, def.font_hud_musnad_size)


static func _apply_label(label: Label, font: FontFile, size: int) -> void:
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)


static func _wire_mouse(view: StartUIView) -> void:
	_wire(view.title_view, Callable(), func() -> void: view.any_pressed.emit())
	_wire(view.menu_new_game, func() -> void: view.menu_hovered.emit(StartSteps.MENU_NEW_GAME), func() -> void: view.menu_chosen.emit(StartSteps.MENU_NEW_GAME))
	_wire(view.menu_continue, func() -> void: view.menu_hovered.emit(StartSteps.MENU_CONTINUE), func() -> void: view.menu_chosen.emit(StartSteps.MENU_CONTINUE))
	_wire(view.menu_options, func() -> void: view.menu_hovered.emit(StartSteps.MENU_OPTIONS), func() -> void: view.menu_chosen.emit(StartSteps.MENU_OPTIONS))
	_wire(view.menu_quit, func() -> void: view.menu_hovered.emit(StartSteps.MENU_QUIT), func() -> void: view.menu_chosen.emit(StartSteps.MENU_QUIT))
	_wire(view.card_rydan, func() -> void: view.hero_hovered.emit(StartSteps.HERO_RYDAN), func() -> void: view.hero_chosen.emit(StartSteps.HERO_RYDAN))
	_wire(view.card_bilqis, func() -> void: view.hero_hovered.emit(StartSteps.HERO_BILQIS), func() -> void: view.hero_chosen.emit(StartSteps.HERO_BILQIS))
	_wire(view.btn_normal, func() -> void: view.difficulty_hovered.emit(StartSteps.DIFF_NORMAL), func() -> void: view.difficulty_chosen.emit(StartSteps.DIFF_NORMAL))
	_wire(view.btn_hard, func() -> void: view.difficulty_hovered.emit(StartSteps.DIFF_HARD), func() -> void: view.difficulty_chosen.emit(StartSteps.DIFF_HARD))


static func _wire(node: Control, on_hover: Callable, on_click: Callable) -> void:
	if node == null:
		return
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	_ignore_descendants(node)
	if on_hover.is_valid():
		node.mouse_entered.connect(on_hover)
	node.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if (event as InputEventMouseButton).pressed:
				on_click.call()
	)


static func _ignore_descendants(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_descendants(child)
