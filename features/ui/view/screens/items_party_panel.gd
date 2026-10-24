class_name ItemsPartyPanel
extends UiPanel
## purpose: Right side of the Items screen: one selectable PartyCard per hero, each previewing the item.

signal hero_chosen(hero: StringName)

var _grid: GridContainer
var _hint: Label
var _cards: Dictionary[StringName, ItemsHeroCard] = {}
var _picking: bool = false


func _init() -> void:
	setup(Ui.text("ITEMS_USE_ON"), "")
	position = Vector2(664.0, 124.0)
	custom_minimum_size = Vector2(1176.0, 756.0)
	size = Vector2(1176.0, 756.0)
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(centre)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	centre.add_child(_grid)
	_hint = Ui.label(Ui.text("ITEMS_SELECT_HINT"), &"MutedLabel")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_hint)


## Builds one card per hero; returns self.
func setup_party(party: Array[StringName]) -> ItemsPartyPanel:
	for card: ItemsHeroCard in _cards.values():
		card.queue_free()
	_cards.clear()
	for hero: StringName in party:
		var card := ItemsHeroCard.new().setup(hero)
		card.chosen.connect(hero_chosen.emit)
		_grid.add_child(card)
		_cards[hero] = card
	return self


## Shows the selected item's gain on every card (the rules come from FieldUse).
func show_preview(def: ConsumableDef, vitals: Dictionary, maxes: Dictionary) -> void:
	for hero: StringName in _cards:
		var card: ItemsHeroCard = _cards[hero]
		var gain: Dictionary = FieldUse.preview(def, vitals, hero, maxes)
		var usable: bool = FieldUse.can_target(def, vitals, hero, maxes)
		var text: String = ItemsText.gain(gain)
		var cures: String = ItemsText.cures(def)
		if not cures.is_empty():
			text = cures if text.is_empty() else "%s  %s" % [text, cures]
		card.show_preview(int(gain["hp"]), int(gain["sp"]), text, usable)


func clear_preview() -> void:
	for card: ItemsHeroCard in _cards.values():
		card.clear_preview()


## Re-reads the party's HP/SP after an item changed them.
func refresh_vitals() -> void:
	var maxes: Dictionary = ItemService.maxes()
	for hero: StringName in _cards:
		var top: Vector2i = maxes.get(hero, Vector2i.ZERO)
		var now: Vector2i = PauseLogic.vitals_of(GameState.vitals, hero, top.x, top.y)
		_cards[hero].card().update(now.x, now.y)


## Cards only take focus and clicks while an item is being aimed.
func set_picking(on: bool) -> void:
	_picking = on
	_hint.text = Ui.text("ITEMS_TARGET_HINT" if on else "ITEMS_SELECT_HINT")
	for card: ItemsHeroCard in _cards.values():
		card.disabled = not on or not card.preview_usable()
		card.focus_mode = Control.FOCUS_NONE if card.disabled else Control.FOCUS_ALL


func focus_first_usable() -> bool:
	for card: ItemsHeroCard in _cards.values():
		if not card.disabled and card.is_visible_in_tree():
			card.grab_focus()
			return true
	return false


func hero_button(hero: StringName) -> Button:
	return _cards.get(hero)


func hero_card(hero: StringName) -> PartyCard:
	var card: ItemsHeroCard = _cards.get(hero)
	return null if card == null else card.card()


func is_picking() -> bool:
	return _picking
