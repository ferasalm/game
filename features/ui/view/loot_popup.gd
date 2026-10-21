class_name LootPopup
extends CanvasLayer
## The "Obtained" banner: listens to EventBus.item_obtained and shows each new item centred high on the screen with
## its name in the rarity colour, a light sweep for Rare and above and a rarity jingle (AudioDirector.play_item).
## Riyal earned (money_changed with a positive delta, except while the shop is open) gets its own "+N riyal" banner.
## Several banners queue in order (the more waiting, the shorter each one stays). It never takes input.

signal shown(item_id: StringName)
## A riyal banner started (rewards only: shop sales do not show one).
signal money_shown(amount: int)

var _root: Control
var _queue: Array[Dictionary] = []
var _current: StringName = &""
var _amount: int = 0
var _busy: bool = false
var _banner: PanelContainer = null
var _tween: Tween = null
var _clip: Control = null


func _ready() -> void:
	layer = UiLayers.LOOT
	_root = Ui.screen_root()
	add_child(_root)
	EventBus.item_obtained.connect(enqueue)
	EventBus.money_changed.connect(_on_money_changed)


## Adds an item to the queue; it shows at once when nothing is showing.
func enqueue(item_id: StringName) -> void:
	_queue.append({"item": item_id, "money": 0})
	if not _busy:
		_next()


## Adds a riyal banner to the queue.
func enqueue_money(amount: int) -> void:
	_queue.append({"item": &"", "money": amount})
	if not _busy:
		_next()


func _on_money_changed(_total: int, delta: int) -> void:
	if delta > 0 and not Screens.is_open_id(&"shop"):
		enqueue_money(delta)


## The item on screen now (&"" when idle) and how many wait behind it.
func current_item() -> StringName:
	return _current


func pending() -> int:
	return _queue.size()


## Ends the banner on screen at once and starts the next one.
func skip() -> void:
	if _tween != null:
		_tween.kill()
	_finish()


func _next() -> void:
	if _queue.is_empty():
		return
	var entry: Dictionary = _queue.pop_front()
	_busy = true
	_current = entry["item"]
	_amount = entry["money"]
	var rarity: StringName = UiRarity.of_item(_current)
	_banner = _build_banner(rarity)
	_root.add_child(_banner)
	AudioDirector.play_item(maxi(UiRarity.order(rarity), 0))
	if _amount > 0:
		money_shown.emit(_amount)
	else:
		shown.emit(_current)
	var style: UiStyleDef = Ui.style()
	_banner.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_banner, "modulate:a", 1.0, style.time(&"t_loot_fade"))
	if _shines(rarity):
		_tween.tween_callback(_sweep.bind(rarity))
	_tween.tween_interval(style.time(&"t_loot_hold") / (1.0 + _queue.size()))
	_tween.tween_property(_banner, "modulate:a", 0.0, style.time(&"t_loot_fade"))
	_tween.tween_callback(_finish)


func _finish() -> void:
	if _banner != null:
		_root.remove_child(_banner)
		_banner.queue_free()
		_banner = null
	_current = &""
	_busy = false
	_next()


func _shines(rarity: StringName) -> bool:
	var tier := ContentDB.get_def("rarity", rarity) as RarityDef
	return tier != null and tier.allows_perk


func _build_banner(rarity: StringName) -> PanelContainer:
	var banner := PanelContainer.new()
	banner.theme_type_variation = &"PlatePanel"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = Ui.style().size(&"s_loot_top")
	banner.offset_bottom = banner.offset_top
	banner.custom_minimum_size.x = Ui.style().size(&"s_loot_w")
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(box)
	var caption: Label = Ui.label(Ui.text("LOOT_OBTAINED"), &"CaptionLabel")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	var name_label: Label = Ui.label(Ui.text("LOOT_MONEY") % str(_amount), &"TitleLabel", Ui.style().colour(&"c_brass")) \
			if _amount > 0 else UiRarity.item_label(_current, &"TitleLabel")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	if _amount > 0:
		return _finish_banner(banner)
	box.add_child(Ui.divider())
	var tag_row := HBoxContainer.new()
	tag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tag_row.add_child(UiRarity.tag(rarity))
	box.add_child(tag_row)
	return _finish_banner(banner)


func _finish_banner(banner: PanelContainer) -> PanelContainer:
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(_clip)
	return banner


## A soft bar of light crossing the banner left to right.
func _sweep(rarity: StringName) -> void:
	if _banner == null or _clip == null:
		return
	var bar := TextureRect.new()
	var gradient := Gradient.new()
	var tint: Color = UiRarity.colour(rarity).lightened(0.5)
	gradient.colors = PackedColorArray([Color(tint, 0.0), Color(tint, 0.55), Color(tint, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	bar.texture = texture
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.size = Vector2(_clip.size.x * 0.3, _clip.size.y)
	bar.position.x = -bar.size.x
	_clip.add_child(bar)
	var sweep: Tween = create_tween()
	sweep.tween_property(bar, "position:x", _clip.size.x, Ui.style().time(&"t_loot_shine"))
