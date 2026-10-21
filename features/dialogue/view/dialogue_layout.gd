class_name DialogueLayout
extends RefCounted
## Builds the dialogue box's controls in code (no scene file, no path lookups) and keeps references to them.
## Layout is anchored to the screen: an ornate text frame along the bottom, a name plate straddling its top edge,
## the portrait at the left overlapping it.

var portrait: TextureRect
var name_label: Label
var text_label: Label
var arrow: Control


func build(root: Control, style: DialogueStyleDef) -> void:
	var box := Panel.new()
	box.anchor_top = 1.0 - style.box_height
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = style.box_margin
	box.offset_right = -style.box_margin
	box.offset_bottom = -style.box_margin
	root.add_child(box)
	_build_texts(box, style)
	_build_arrow(box, style)
	_build_portrait(root, style)
	_build_plate(root, style)


func _build_texts(box: Control, style: DialogueStyleDef) -> void:
	var column := VBoxContainer.new()
	column.anchor_left = style.text_left
	column.anchor_right = 1.0
	column.anchor_bottom = 1.0
	column.offset_left = style.pad
	column.offset_top = style.pad * 2.0
	column.offset_right = -style.pad * 2.0
	column.offset_bottom = -style.pad
	box.add_child(column)
	text_label = Ui.label("")
	text_label.add_theme_font_size_override("font_size", style.text_size)
	text_label.add_theme_color_override("font_color", style.text_color)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_label)
	column.add_child(Ui.divider())


## The speaker's name on a plate that straddles the top edge of the frame, above the text column.
func _build_plate(root: Control, style: DialogueStyleDef) -> void:
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PlatePanel"
	plate.anchor_left = style.text_left
	plate.anchor_right = style.text_left
	plate.anchor_top = 1.0 - style.box_height
	plate.anchor_bottom = 1.0 - style.box_height
	plate.offset_left = style.pad
	plate.offset_top = style.box_margin * 0.5
	plate.grow_horizontal = Control.GROW_DIRECTION_END
	plate.grow_vertical = Control.GROW_DIRECTION_BOTH
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label = Ui.label("", &"NameLabel")
	name_label.add_theme_font_size_override("font_size", style.name_size)
	name_label.custom_minimum_size.x = style.name_size * 5.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(name_label)
	root.add_child(plate)


func _build_arrow(box: Control, style: DialogueStyleDef) -> void:
	arrow = Control.new()
	arrow.anchor_left = 1.0
	arrow.anchor_top = 1.0
	arrow.anchor_right = 1.0
	arrow.anchor_bottom = 1.0
	arrow.offset_left = -style.pad * 2.0 - style.arrow_size
	arrow.offset_top = -style.pad * 2.0 - style.arrow_size
	var triangle := Polygon2D.new()
	var s: float = style.arrow_size
	triangle.polygon = PackedVector2Array([Vector2(0.0, 0.0), Vector2(s, 0.0), Vector2(s * 0.5, s * 0.7)])
	triangle.color = style.arrow_color
	arrow.add_child(triangle)
	arrow.visible = false
	box.add_child(arrow)


func _build_portrait(root: Control, style: DialogueStyleDef) -> void:
	portrait = TextureRect.new()
	portrait.anchor_top = 1.0 - style.portrait_height
	portrait.anchor_right = style.portrait_width
	portrait.anchor_bottom = 1.0
	portrait.offset_left = style.box_margin
	portrait.offset_bottom = -style.box_margin
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(portrait)
