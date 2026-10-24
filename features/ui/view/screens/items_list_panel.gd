class_name ItemsListPanel
extends UiPanel
## purpose: The left bag list of the Items screen: one ListRow per field-usable consumable, with count and effect.

signal item_focused(item_id: StringName)
signal item_activated(item_id: StringName)

var _vbox: VBoxContainer
var _rows: Dictionary[StringName, ListRow] = {}
var _empty: Label


func _init() -> void:
	setup(Ui.text("ITEMS_BAG"), "")
	position = Vector2(80.0, 124.0)
	custom_minimum_size = Vector2(560.0, 756.0)
	size = Vector2(560.0, 756.0)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_vbox)


## Rebuilds the rows from the bag (battle-only items stay out of the field list).
func populate() -> void:
	_drop_rows()
	if _empty != null:
		_empty.queue_free()
		_empty = null
	var owned: Array[ConsumableDef] = ItemService.owned()
	if owned.is_empty():
		_empty = Ui.label(Ui.text("ITEMS_EMPTY"), &"MutedLabel")
		_vbox.add_child(_empty)
		return
	for def: ConsumableDef in owned:
		if def.usable_in_field():
			_add_row(def)


func focus_first() -> void:
	if not _rows.is_empty():
		(_rows.values()[0] as ListRow).grab_focus()


func row_of(item_id: StringName) -> Button:
	return _rows.get(item_id)


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_rows.keys())
	return out


func rows() -> Array[ListRow]:
	var out: Array[ListRow] = []
	out.assign(_rows.values())
	return out


func _add_row(def: ConsumableDef) -> void:
	var row := ListRow.new()
	var icon: Texture2D = ItemIcons.texture(def)
	if icon == null:
		icon = ItemIcons.disc(Ui.style().colour(&"c_cyan").darkened(0.2), 48)
	var colour: Color = Ui.style().colour(&"c_cyan")
	row.setup(icon, Ui.text(def.name_key), GameState.bag.get(def.id, 0), colour, ItemsText.tag(def))
	row.focus_entered.connect(item_focused.emit.bind(def.id))
	row.pressed.connect(item_activated.emit.bind(def.id))
	_vbox.add_child(row)
	_rows[def.id] = row


func _drop_rows() -> void:
	for row: ListRow in _rows.values():
		row.queue_free()
	_rows.clear()
