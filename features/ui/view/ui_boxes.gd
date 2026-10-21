class_name UiBoxes
extends RefCounted
## StyleBox builders for the UI theme: ornate panels (painted nine-patch frames), button states with the warm brass
## focus glow, and progress-bar tracks and gradient fills. Everything comes from the UiStyleDef.


## A framed panel; kind is &"panel", &"plate" or &"inset" (UiOrnament.frame). border: tint of the whole frame.
static func panel(style: UiStyleDef, kind: StringName = &"panel", tint: Color = Color.WHITE) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = UiOrnament.frame(style, kind)
	var cell: float = style.size(&"s_frame_cell")
	box.set_texture_margin_all(cell)
	box.set_content_margin_all(cell - style.size(&"s_frame_gap"))
	box.modulate_color = tint
	return box


## A menu button state. state: normal, hover, pressed, focus, disabled.
static func button(style: UiStyleDef, state: StringName) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var line: int = style.size(&"s_frame_line")
	box.bg_color = Color.TRANSPARENT
	box.set_content_margin_all(style.size(&"s_gap"))
	box.content_margin_left = style.size(&"s_pad") + line * 2
	box.border_color = style.colour(&"c_brass_dim")
	box.border_width_left = line
	match state:
		&"hover":
			box.bg_color = style.colour(&"c_indigo")
			box.border_color = style.colour(&"c_brass")
		&"pressed":
			box.bg_color = style.colour(&"c_brass_dim")
			box.bg_color.a = 0.45
			box.border_color = style.colour(&"c_brass")
			box.border_width_left = line * 3
		&"focus":
			box.bg_color = style.colour(&"c_glass_lit")
			box.border_color = style.colour(&"c_brass")
			box.border_width_left = line * 3
			box.set_border_width(SIDE_BOTTOM, line)
			box.shadow_color = style.colour(&"c_brass")
			box.shadow_color.a = 0.35
			box.shadow_size = style.size(&"s_focus_glow")
		&"disabled":
			box.border_color = style.colour(&"c_disabled")
	box.set_corner_radius_all(0)
	return box


## A square portrait medallion (timeline head icons): glass inside, a brass rim.
static func medallion(style: UiStyleDef, rim: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = style.colour(&"c_glass_deep")
	box.border_color = rim
	box.set_border_width_all(style.size(&"s_frame_line") + 1)
	box.set_corner_radius_all(style.size(&"s_frame_gap"))
	box.shadow_color = style.colour(&"c_shadow")
	box.shadow_size = style.size(&"s_frame_gap")
	return box


## The dark track of a bar with a thin brass outline.
static func bar_back(style: UiStyleDef) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = style.colour(&"c_glass_deep")
	box.set_border_width_all(1)
	box.border_color = style.colour(&"c_brass_dim")
	box.set_corner_radius_all(2)
	return box


## The filled part of a bar: a horizontal gradient from colour a to colour b (colour keys).
static func bar_fill(style: UiStyleDef, a: StringName, b: StringName) -> StyleBoxTexture:
	var gradient := Gradient.new()
	gradient.set_color(0, style.colour(a))
	gradient.set_color(1, style.colour(b))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 8
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var box := StyleBoxTexture.new()
	box.texture = texture
	return box


## A flat tinted pill (rarity tags, cost chips).
static func pill(style: UiStyleDef, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = edge.darkened(0.7)
	box.bg_color.a = 0.9
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(style.size(&"s_gap"))
	box.content_margin_left = style.size(&"s_gap")
	box.content_margin_right = style.size(&"s_gap")
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box
