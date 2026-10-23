class_name SlotSocketDraw
extends RefCounted
## purpose: Draws socket border and stone icon for gemstone slots in equipment boxes.


static func draw(panel: PanelContainer, stone_id: StringName) -> void:
	for c: Node in panel.get_children():
		c.queue_free()
	var style: UiStyleDef = Ui.style()
	var s_box := StyleBoxFlat.new()
	s_box.set_corner_radius_all(22)
	if stone_id == &"":
		s_box.draw_center = false
		s_box.border_color = style.colour(&"c_muted")
		s_box.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", s_box)
		return
	var stone_def := ContentDB.get_def("stone", stone_id) as StoneDef
	var col: Color = UiRarity.colour(stone_def.rarity) if stone_def != null else style.colour(&"c_cyan")
	s_box.bg_color = Color(col.r, col.g, col.b, 0.5)
	s_box.border_color = col
	s_box.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", s_box)
	if stone_def != null and "icon" in stone_def and not str(stone_def.get("icon")).is_empty():
		var tex := TextureRect.new()
		tex.texture = load(str(stone_def.get("icon"))) as Texture2D
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(tex)
