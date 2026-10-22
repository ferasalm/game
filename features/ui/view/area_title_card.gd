class_name AreaTitleCard
extends CanvasLayer
## The area title card (centre left, no panel) that fades in when the opening shot ends: the Musnad name big over the
## English name, a gypsum frieze drawing left to right, a subtitle (place and year), then fading out. It takes no input.

signal finished

var _root: Control
var _block: VBoxContainer = null
var _tween: Tween = null
var _latin: Label = null


func _ready() -> void:
	layer = UiLayers.CARD
	_root = Ui.screen_root()
	add_child(_root)


## Shows the card for the given localization keys (name, Musnad name, subtitle).
func show_card(name_key: String, musnad_key: String, subtitle_key: String) -> void:
	if _block != null:
		_tween.kill()
		_root.remove_child(_block)
		_block.queue_free()
	var style: UiStyleDef = Ui.style()
	_block = VBoxContainer.new()
	_block.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_block.position = Vector2(style.size(&"s_area_x"), style.size(&"s_area_y"))
	_block.custom_minimum_size.x = style.size(&"s_area_w")
	_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var latin: Label = Ui.label(Ui.text(name_key), &"TitleLabel", style.colour(&"c_gypsum"))
	var musnad: Label = Ui.label(Ui.text(musnad_key), &"MusnadLabel", style.colour(&"c_brass"))
	musnad.add_theme_font_size_override("font_size", style.size(&"s_font_big"))
	var subtitle: Label = Ui.label(Ui.text(subtitle_key), &"CaptionLabel", style.colour(&"c_muted"))
	_latin = latin
	_block.add_child(musnad)
	_block.add_child(latin)
	var band: TextureRect = Ui.divider()
	band.custom_minimum_size.x = 0.0
	band.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_block.add_child(band)
	_block.add_child(subtitle)
	_block.modulate.a = 0.0
	_root.add_child(_block)
	_tween = create_tween()
	_tween.tween_property(_block, "modulate:a", 1.0, style.time(&"t_card_in"))
	_tween.parallel().tween_property(band, "custom_minimum_size:x", float(style.size(&"s_area_w")), style.time(&"t_card_in"))
	_tween.tween_interval(style.time(&"t_card_hold"))
	_tween.tween_property(_block, "modulate:a", 0.0, style.time(&"t_card_out"))
	_tween.tween_callback(_done)


## True while the card is on screen (fading in, holding or fading out).
## Ends the card at once (a battle starting under it).
func dismiss() -> void:
	if _block != null:
		_tween.kill()
		_done()


func is_showing() -> bool:
	return _block != null


## The English name line now showing ("" when idle).
func name_text() -> String:
	return "" if _block == null else _latin.text


func _done() -> void:
	if _block != null:
		_root.remove_child(_block)
		_block.queue_free()
		_block = null
	finished.emit()
