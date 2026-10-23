class_name UiTheme
extends RefCounted
## Builds the one Godot Theme every menu and HUD uses: Amiri for reading, Reem Kufi for titles, names and numbers,
## ornate panels, brass-focus buttons, gradient bars. Label variations: TitleLabel, NameLabel, NumberLabel,
## MutedLabel, SmallLabel, BannerLabel, CaptionLabel. Panels: PanelContainer (default), PlatePanel, InsetPanel.
## Buttons: Button (menu entry) and TabButton. Bars: HpBar and SpBar.

const LABEL_VARIANTS: Array[StringName] = [
	&"TitleLabel", &"NameLabel", &"NumberLabel", &"MutedLabel", &"SmallLabel", &"BannerLabel", &"CaptionLabel"]


static func build(style: UiStyleDef) -> Theme:
	var theme := Theme.new()
	var body: Font = font(style, &"font_body")
	theme.default_font = body
	theme.default_font_size = style.size(&"s_font_body")
	_labels(theme, style)
	_buttons(theme, style)
	for kind: StringName in [&"panel", &"plate", &"inset"]:
		var type_name: StringName = &"PanelContainer" if kind == &"panel" else StringName(String(kind).capitalize() + "Panel")
		if kind != &"panel":
			theme.set_type_variation(type_name, &"PanelContainer")
		theme.set_stylebox(&"panel", type_name, UiBoxes.panel(style, kind))
	theme.set_stylebox(&"panel", &"Panel", UiBoxes.panel(style, &"panel"))
	_bars(theme, style)
	return theme


## A font by its style key; Reem Kufi falls back to Amiri for any glyph it lacks.
static func font(style: UiStyleDef, key: StringName) -> Font:
	var base := load(style.fonts[key]) as Font
	if key != &"font_title":
		return base
	var variation := FontVariation.new()
	variation.base_font = base
	variation.spacing_space = style.size(&"s_title_space")
	variation.fallbacks = [load(style.fonts[&"font_body"]) as Font]
	return variation


static func _labels(theme: Theme, style: UiStyleDef) -> void:
	theme.set_color(&"font_color", &"Label", style.colour(&"c_text"))
	theme.set_color(&"font_shadow_color", &"Label", style.colour(&"c_shadow"))
	theme.set_font_size(&"font_size", &"Label", style.size(&"s_font_body"))
	for variant: StringName in LABEL_VARIANTS:
		theme.set_type_variation(variant, &"Label")
	_label(theme, style, &"TitleLabel", &"font_title", &"s_font_title", &"c_brass")
	_label(theme, style, &"NameLabel", &"font_title", &"s_font_name", &"c_text")
	_label(theme, style, &"NumberLabel", &"font_title", &"s_font_number", &"c_text")
	_label(theme, style, &"MusnadLabel", &"font_musnad", &"s_font_title", &"c_brass_dim")
	_label(theme, style, &"MutedLabel", &"font_body", &"s_font_small", &"c_muted")
	_label(theme, style, &"SmallLabel", &"font_body", &"s_font_small", &"c_text")
	_label(theme, style, &"CaptionLabel", &"font_title", &"s_font_small", &"c_brass")
	_label(theme, style, &"BannerLabel", &"font_title", &"s_font_big", &"c_brass")
	theme.set_constant(&"outline_size", &"BannerLabel", style.size(&"s_outline"))
	theme.set_color(&"font_outline_color", &"BannerLabel", style.colour(&"c_glass_deep"))


static func _label(theme: Theme, style: UiStyleDef, variant: StringName, font_key: StringName, size_key: StringName,
		colour_key: StringName) -> void:
	theme.set_font(&"font", variant, font(style, font_key))
	theme.set_font_size(&"font_size", variant, style.size(size_key))
	theme.set_color(&"font_color", variant, style.colour(colour_key))


static func _buttons(theme: Theme, style: UiStyleDef) -> void:
	theme.set_type_variation(&"TabButton", &"Button")
	for type_name: StringName in [&"Button", &"TabButton"]:
		theme.set_font(&"font", type_name, font(style, &"font_bold" if type_name == &"Button" else &"font_title"))
		theme.set_font_size(&"font_size", type_name, style.size(&"s_font_body"))
		theme.set_color(&"font_color", type_name, style.colour(&"c_text"))
		theme.set_color(&"font_hover_color", type_name, style.colour(&"c_gypsum"))
		theme.set_color(&"font_focus_color", type_name, style.colour(&"c_brass"))
		theme.set_color(&"font_pressed_color", type_name, style.colour(&"c_brass"))
		theme.set_color(&"font_hover_pressed_color", type_name, style.colour(&"c_brass"))
		theme.set_color(&"font_disabled_color", type_name, style.colour(&"c_disabled"))
		theme.set_constant(&"h_separation", type_name, style.size(&"s_gap"))
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			theme.set_stylebox(state, type_name, UiBoxes.button(style, state) if type_name == &"Button" else UiBoxes.pill_button(style, state))
		theme.set_stylebox(&"hover_pressed", type_name, UiBoxes.button(style, &"pressed") if type_name == &"Button" else UiBoxes.pill_button(style, &"pressed"))
	theme.set_color(&"font_focus_color", &"TabButton", style.colour(&"c_cyan"))
	theme.set_color(&"font_pressed_color", &"TabButton", style.colour(&"c_cyan"))
	theme.set_color(&"font_hover_color", &"TabButton", style.colour(&"c_cyan"))


static func _bars(theme: Theme, style: UiStyleDef) -> void:
	_bar(theme, style, &"HpBar", &"c_hp_a", &"c_hp_b")
	_bar(theme, style, &"SpBar", &"c_sp_a", &"c_sp_b")


static func _bar(theme: Theme, style: UiStyleDef, variant: StringName, a: StringName, b: StringName) -> void:
	theme.set_type_variation(variant, &"ProgressBar")
	theme.set_stylebox(&"background", variant, UiBoxes.bar_back(style))
	theme.set_stylebox(&"fill", variant, UiBoxes.bar_fill(style, a, b))
