class_name Ui
extends RefCounted
## Entry point of the shared UI look: the style (content/ui/style.json), the one cached Theme, and small builders
## (labels, screen roots, the zigzag divider). Every menu, HUD and popup gets its theme through here.

static var _theme: Theme = null


static func style() -> UiStyleDef:
	return ContentDB.get_def("ui_style", &"default") as UiStyleDef


static func theme() -> Theme:
	if _theme == null:
		_theme = UiTheme.build(style())
	return _theme


static func clear_cache() -> void:
	_theme = null
	UiOrnament.clear_cache()


## A translated player-facing string (static code cannot call tr()).
static func text(key: String) -> String:
	return String(TranslationServer.translate(StringName(key)))


## A full-screen Control carrying the theme, smooth texture filtering, and ignoring the mouse itself.
static func screen_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return root


## A label using a theme variation (TitleLabel, NameLabel, NumberLabel, MutedLabel, SmallLabel, CaptionLabel,
## BannerLabel; empty = plain body text). colour overrides the variation's colour when it is not transparent.
static func label(content: String, variant: StringName = &"", colour: Color = Color.TRANSPARENT) -> Label:
	var out := Label.new()
	out.text = content
	out.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if variant != &"":
		out.theme_type_variation = variant
	if colour.a > 0.0:
		out.add_theme_color_override("font_color", colour)
	return out


## A horizontal band of the gypsum zigzag frieze that stretches to its container's width.
static func divider() -> TextureRect:
	var band := TextureRect.new()
	band.texture = UiOrnament.frieze(style())
	band.stretch_mode = TextureRect.STRETCH_TILE
	band.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	band.custom_minimum_size = Vector2(0.0, style().size(&"s_frieze_h"))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return band


## Small tags laid out on the right edge of a Button (add the returned row as the button's child); the button's
## own text keeps the left. The row ignores the mouse.
static func chip_row(chips: Array[Control]) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.alignment = BoxContainer.ALIGNMENT_END
	line.offset_right = -style().size(&"s_pad")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", style().size(&"s_pad"))
	for chip: Control in chips:
		line.add_child(chip)
	return line


## A framed glass panel with an English + Arabic title pair and a frieze (empty English = no title bar).
static func panel(title_en: String = "", title_ar: String = "") -> UiPanel:
	return UiPanel.new().setup(title_en, title_ar)


## A title row: English left in Reem Kufi, Arabic right in dim brass.
static func title_pair(english: String, arabic: String) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left: Label = label(english, &"TitleLabel")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	if not arabic.is_empty():
		row.add_child(label(arabic, &"TitleLabel", style().colour(&"c_brass_dim")))
	return row


## The qamariya focus sweep under a control (see UiSweep).
static func sweep(target: Control) -> Tween:
	return UiSweep.start(target)


## Pushes a Yes/No dialog on the Screens stack; the returned signal emits true (yes) or false (no / back).
## Use: if await Ui.confirm("PAUSE_TITLE_MENU", "PAUSE_CONFIRM_TITLE", false): ...
static func confirm(title_key: String, body_key: String, default_yes: bool = false) -> Signal:
	var dialog := ConfirmDialog.new()
	dialog.setup(title_key, body_key, default_yes)
	Screens.push(dialog)
	return dialog.answered
