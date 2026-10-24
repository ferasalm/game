class_name ItemsDescBar
extends PanelContainer
## purpose: Bottom description box (1760x90 at 80,900) of the Items screen: name, owned count, text and effect.

var _title: Label
var _owned: Label
var _body: Label
var _effect: Label


func _init() -> void:
	position = Vector2(80.0, 900.0)
	custom_minimum_size = Vector2(1760.0, 90.0)
	size = Vector2(1760.0, 90.0)
	add_theme_stylebox_override("panel", UiBoxes.panel(Ui.style(), &"panel"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_ui()


## Shows one item: its name, how many the bag holds, its description and its effect line.
func set_item(def: ConsumableDef, owned: int) -> void:
	_title.text = Ui.text(def.name_key)
	_owned.text = Ui.text("ITEMS_OWNED") % owned
	_body.text = Ui.text(def.desc_key)
	_effect.text = ItemsText.effect(def)


func clear() -> void:
	_title.text = ""
	_owned.text = ""
	_body.text = ""
	_effect.text = ""


func title_text() -> String:
	return _title.text if _title != null else ""


func body_text() -> String:
	return _body.text if _body != null else ""


func effect_text() -> String:
	return _effect.text if _effect != null else ""


func _build_ui() -> void:
	for c: Node in get_children():
		c.queue_free()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	add_child(hbox)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 350.0
	hbox.add_child(left)
	_title = Ui.label("", &"NameLabel")
	left.add_child(_title)
	_owned = Ui.label("", &"CaptionLabel")
	left.add_child(_owned)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(mid)
	_body = Ui.label("", &"MutedLabel")
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(_body)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 420.0
	hbox.add_child(right)
	_effect = Ui.label("", &"SmallLabel", Ui.style().colour(&"c_good"))
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_effect)
