class_name ItemsHeroCard
extends Button
## purpose: A hero card you can pick as an item target: the PartyCard look plus the item's gain preview.

signal chosen(hero: StringName)

var hero_id: StringName = &""

var _card: PartyCard


## Builds the card for a hero; returns self.
func setup(hero: StringName) -> ItemsHeroCard:
	hero_id = hero
	custom_minimum_size = Vector2(520.0, 170.0)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	flat = true
	_card = PartyCard.new().setup(hero)
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	focus_entered.connect(UiSweep.start.bind(self))
	focus_exited.connect(UiSweep.clear.bind(self))
	mouse_entered.connect(grab_focus)
	pressed.connect(_on_pressed)
	return self


func card() -> PartyCard:
	return _card


func show_preview(hp_gain: int, sp_gain: int, text: String, usable: bool) -> void:
	_card.set_item_preview(hp_gain, sp_gain, text, usable)


func clear_preview() -> void:
	_card.clear_item_preview()


func preview_hp_gain() -> int:
	return _card.preview_hp_gain()


func preview_sp_gain() -> int:
	return _card.preview_sp_gain()


func preview_text() -> String:
	return _card.preview_text()


func preview_usable() -> bool:
	return _card.preview_usable()


func _on_pressed() -> void:
	chosen.emit(hero_id)
