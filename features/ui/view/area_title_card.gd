class_name AreaTitleCard
extends CanvasLayer
## The area title card that fades in when the opening shot ends: the area's name in Latin and Arabic in Reem Kufi,
## a zigzag divider and a subtitle (place and year), then fades out. It never takes input.

signal finished

var _root: Control
var _block: VBoxContainer = null
var _tween: Tween = null


func _ready() -> void:
	layer = UiLayers.CARD
	_root = Ui.screen_root()
	add_child(_root)


## Shows the card for the given localization keys (name, Arabic name, subtitle).
func show_card(name_key: String, arabic_key: String, subtitle_key: String) -> void:
	if _block != null:
		_tween.kill()
		_root.remove_child(_block)
		_block.queue_free()
	var style: UiStyleDef = Ui.style()
	_block = VBoxContainer.new()
	_block.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_block.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_block.offset_top = get_viewport().get_visible_rect().size.y * 0.16
	_block.offset_bottom = _block.offset_top
	_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var latin: Label = Ui.label(Ui.text(name_key), &"TitleLabel")
	var arabic: Label = Ui.label(Ui.text(arabic_key), &"TitleLabel", style.colour(&"c_gypsum"))
	arabic.language = "ar"
	var subtitle: Label = Ui.label(Ui.text(subtitle_key), &"CaptionLabel", style.colour(&"c_muted"))
	for line: Label in [latin, arabic, subtitle]:
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_block.add_child(latin)
	_block.add_child(arabic)
	var band: TextureRect = Ui.divider()
	band.custom_minimum_size.x = style.size(&"s_frieze_period") * 16.0
	band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_block.add_child(band)
	_block.add_child(subtitle)
	_block.modulate.a = 0.0
	_root.add_child(_block)
	_tween = create_tween()
	_tween.tween_property(_block, "modulate:a", 1.0, style.time(&"t_card_in"))
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
	return "" if _block == null else (_block.get_child(0) as Label).text


func _done() -> void:
	if _block != null:
		_root.remove_child(_block)
		_block.queue_free()
		_block = null
	finished.emit()
