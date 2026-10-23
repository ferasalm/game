class_name DialogueLayout
extends RefCounted
## Builds the dialogue box's controls in code (Hades II style; sizes from the UI style, laid out for 1920x1080): a big
## portrait at the left that slides in, an ornate glass text box at the bottom right with a frieze, a nameplate tab
## on the box's top edge (name in brass, epithet under it) and the button hints. No scene file, no path lookups.

var portrait: TextureRect
var name_label: Label
var epithet_label: Label
var text_label: Label
var arrow: Control
var frame: Control
var choice_box: VBoxContainer
var portrait_rest_x: float = 0.0
var portrait_max_h: float = 0.0


func build(root: Control, style: DialogueStyleDef) -> void:
	var ui: UiStyleDef = Ui.style()
	_build_portrait(root, ui)
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_right = -ui.size(&"s_dialog_right")
	box.offset_bottom = -ui.size(&"s_dialog_bottom")
	box.offset_left = box.offset_right - ui.size(&"s_dialog_w")
	box.offset_top = box.offset_bottom - ui.size(&"s_dialog_h")
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	frame = box
	var glass := PanelContainer.new()
	glass.set_anchors_preset(Control.PRESET_FULL_RECT)
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(glass)
	var column := VBoxContainer.new()
	glass.add_child(column)
	text_label = Ui.label("")
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_color_override("font_color", style.text_color)
	column.add_child(text_label)
	column.add_child(Ui.divider())
	_build_arrow(box, style, ui)
	_build_plate(box, ui)
	_build_choices(root, ui)
	var strip: PromptStrip = Ui.prompt_strip([{"key": "accept", "text": "PROMPT_CONTINUE"},
			{"key": "skip", "text": "PROMPT_SKIP"}, {"key": "cease", "text": "PROMPT_CEASE"}])
	strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	strip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	strip.offset_bottom = -ui.size(&"s_strip_bottom")
	root.add_child(strip)


func _build_portrait(root: Control, ui: UiStyleDef) -> void:
	portrait = TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait_rest_x = ui.size(&"s_portrait_x")
	portrait.offset_left = portrait_rest_x
	portrait.offset_right = portrait_rest_x + ui.size(&"s_portrait_w")
	portrait_max_h = ui.size(&"s_portrait_h")
	portrait.offset_top = -portrait_max_h
	portrait.offset_bottom = 0.0
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(portrait)


## Shows a portrait standing on the screen's bottom edge: the box takes the picture's shape (up to s_portrait_h), so
## a picture shorter than the box no longer floats above the edge with its body cut off in mid-air (playtest 2026-10-23).
func show_portrait(texture: Texture2D) -> void:
	portrait.texture = texture
	if texture == null or texture.get_width() <= 0:
		return
	var width: float = portrait.offset_right - portrait.offset_left
	portrait.offset_top = -minf(portrait_max_h, width * texture.get_height() / texture.get_width())


## The nameplate: a raised tab on the box's top edge (its bottom dips s_plate_lift into the box), name over epithet.
func _build_plate(box: Control, ui: UiStyleDef) -> void:
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PlatePanel"
	plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
	plate.offset_left = ui.size(&"s_dialog_inset")
	plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plate.offset_top = ui.size(&"s_plate_lift")
	plate.offset_bottom = plate.offset_top
	plate.custom_minimum_size = Vector2(ui.size(&"s_plate_w"), ui.size(&"s_plate_h"))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack := VBoxContainer.new()
	plate.add_child(stack)
	name_label = Ui.label("", &"NameLabel", ui.colour(&"c_brass"))
	epithet_label = Ui.label("", &"MutedLabel", ui.colour(&"c_epithet"))
	stack.add_child(name_label)
	stack.add_child(epithet_label)
	box.add_child(plate)


func _build_arrow(box: Control, style: DialogueStyleDef, ui: UiStyleDef) -> void:
	arrow = Control.new()
	arrow.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	arrow.offset_left = -ui.size(&"s_margin") - style.arrow_size
	arrow.offset_top = -ui.size(&"s_margin") - style.arrow_size
	var triangle := Polygon2D.new()
	var s: float = style.arrow_size
	triangle.polygon = PackedVector2Array([Vector2(0.0, 0.0), Vector2(s, 0.0), Vector2(s * 0.5, s * 0.7)])
	triangle.color = ui.colour(&"c_brass")
	arrow.add_child(triangle)
	arrow.visible = false
	box.add_child(arrow)


func _build_choices(root: Control, ui: UiStyleDef) -> void:
	choice_box = VBoxContainer.new()
	choice_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	choice_box.offset_right = -ui.size(&"s_dialog_right")
	choice_box.offset_bottom = -ui.size(&"s_dialog_bottom") - ui.size(&"s_dialog_h") - ui.size(&"s_margin")
	choice_box.offset_left = choice_box.offset_right - ui.size(&"s_confirm_w")
	choice_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	choice_box.add_theme_constant_override("separation", 8)
	choice_box.visible = false
	root.add_child(choice_box)
