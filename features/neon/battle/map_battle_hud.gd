class_name MapBattleHud
extends CanvasLayer
## purpose: The on-map battle HUD (docs/design/first-playable.md section 3): the reused timeline bar, the slanted
## HP/SP bar, foe bars over their heads, damage numbers, the letterbox and glitch intro, the victory stamp and the
## defeat panel (Retry / Quit).

signal retry_chosen
signal quit_chosen

const GLITCH_SHADER: Shader = preload("res://features/neon/battle/glitch.gdshader")

var view: NeonBattleViewDef
var _sim: BattleSim
var _shown_hp: Dictionary[StringName, int]
var _root: Control
var _timeline: BattleTimelineBar
var _vitals: MapBattleVitals
var _foe_bars: MapBattleFoeBars
var _glitch: ColorRect
var _top: ColorRect
var _bottom: ColorRect
var _stamp: Label
var _panel: PanelContainer


func setup(sim: BattleSim, neon: NeonBattleViewDef, battle_view: BattleViewDef,
		shown_hp: Dictionary[StringName, int], actors: Dictionary[StringName, IsoActor]) -> void:
	view = neon
	_sim = sim
	_shown_hp = shown_hp
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_timeline = BattleTimelineBar.new()
	_root.add_child(_timeline)
	_timeline.setup(sim, battle_view, shown_hp)
	_vitals = MapBattleVitals.new()
	_root.add_child(_vitals)
	_vitals.setup(sim, view, shown_hp)
	_foe_bars = MapBattleFoeBars.new()
	_root.add_child(_foe_bars)
	_foe_bars.setup(sim, view, shown_hp, actors)
	_build_overlays()
	refresh()


func refresh() -> void:
	_vitals.refresh()
	_foe_bars.refresh()


func show_victory(xp: int, money: int) -> void:
	_stamp.text = "%s\n%s   %s" % [BattleStyle.text("NEON_BATTLE_VICTORY"),
		BattleStyle.text("NEON_BATTLE_XP") % xp, BattleStyle.text("NEON_BATTLE_RIYAL") % money]
	_stamp.visible = true


func show_defeat() -> void:
	_stamp.text = BattleStyle.text("NEON_BATTLE_DEFEAT")
	_stamp.visible = true
	_panel.visible = true


func play_intro() -> void:
	_glitch.visible = true
	var material := _glitch.material as ShaderMaterial
	var half: float = view.glitch_seconds * 0.5
	var tween: Tween = create_tween()
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("strength", v), 0.0, 1.0, half)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("strength", v), 1.0, 0.0, half)
	tween.tween_callback(func() -> void: _glitch.visible = false)
	_letterbox(view.letterbox_height, view.letterbox_seconds)
	await tween.finished


func play_outro() -> void:
	_letterbox(0, view.letterbox_seconds)
	await get_tree().create_timer(view.letterbox_seconds).timeout


func pop_number(world_pos: Vector2, value: int, colour: Color) -> void:
	var label := Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", view.number_font)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_shadow_color", view.ink_color)
	label.add_theme_constant_override("shadow_offset_x", view.number_shadow_offset)
	label.add_theme_constant_override("shadow_offset_y", view.number_shadow_offset)
	label.position = screen_pos(world_pos) + Vector2(view.number_offset_x, view.number_offset_y)
	_root.add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - view.number_rise, view.number_seconds)
	tween.parallel().tween_property(label, "modulate:a", 0.0, view.number_seconds)
	tween.tween_callback(label.queue_free)


func flash_at(world_pos: Vector2, colour: Color) -> void:
	var flash := ColorRect.new()
	flash.color = colour
	flash.size = Vector2(view.flash_size, view.flash_size)
	flash.position = screen_pos(world_pos) - flash.size * 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(flash)
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, view.flash_fade_seconds)
	tween.tween_callback(flash.queue_free)


func screen_pos(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _build_overlays() -> void:
	_glitch = ColorRect.new()
	_glitch.color = Color.WHITE
	_glitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = GLITCH_SHADER
	material.set_shader_parameter("strength", 0.0)
	_glitch.material = material
	_glitch.visible = false
	_glitch.z_index = 100
	_root.add_child(_glitch)
	_top = _bar()
	_top.z_index = -1
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bottom = _bar()
	_bottom.z_index = -1
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_root.add_child(_top)
	_root.add_child(_bottom)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	_stamp = Label.new()
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamp.add_theme_font_size_override("font_size", view.victory_font)
	_stamp.add_theme_color_override("font_color", view.flash_color)
	_stamp.add_theme_color_override("font_shadow_color", view.ink_color)
	_stamp.add_theme_constant_override("shadow_offset_x", view.stamp_shadow_offset)
	_stamp.add_theme_constant_override("shadow_offset_y", view.stamp_shadow_offset)
	_stamp.visible = false
	center.add_child(_stamp)
	_build_panel(center)


func _bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _build_panel(center: CenterContainer) -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var retry := Button.new()
	retry.text = BattleStyle.text("NEON_BATTLE_RETRY")
	retry.add_theme_font_size_override("font_size", view.retry_font)
	retry.pressed.connect(retry_chosen.emit)
	box.add_child(retry)
	var quit := Button.new()
	quit.text = BattleStyle.text("NEON_BATTLE_QUIT")
	quit.add_theme_font_size_override("font_size", view.retry_font)
	quit.pressed.connect(quit_chosen.emit)
	box.add_child(quit)
	center.add_child(_panel)


func _letterbox(height: int, seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_top, "offset_bottom", float(height), seconds)
	tween.tween_property(_bottom, "offset_top", -float(height), seconds)
