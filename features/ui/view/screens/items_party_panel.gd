class_name ItemsPartyPanel
extends UiPanel
## purpose: Right side of the Items screen: one selectable PartyCard per hero, each previewing the item.

signal hero_chosen(hero: StringName)

var _grid: GridContainer
var _hint: Label
var _cards: Dictionary[StringName, ItemsHeroCard] = {}
var _picking: bool = false
var _has_preview: bool = false
var _party_item: bool = false


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


## Shows the selected item's gain on every card (the rules come from FieldUse). A whole-party item stays
## usable on a full hero while any other hero can still gain, because one confirm heals the party.
func show_preview(def: ConsumableDef, vitals: Dictionary, maxes: Dictionary) -> void:
	_has_preview = true
	_party_item = def.target == &"all_allies"
	var party_usable: bool = FieldUse.can_use(def, vitals, _heroes(), maxes)
	for hero: StringName in _cards:
		var card: ItemsHeroCard = _cards[hero]
		var gain: Dictionary = FieldUse.preview(def, vitals, hero, maxes)
		var usable: bool = party_usable if _party_item else FieldUse.can_target(def, vitals, hero, maxes)
		var text: String = ItemsText.gain(gain)
		var cures: String = ItemsText.cures(def)
		if not ItemEffect.changes(gain):
			text = Ui.text("ITEMS_FULL")
		elif not cures.is_empty():
			text = "%s  %s" % [text, cures]
		card.show_preview(int(gain["hp"]), int(gain["sp"]), text, usable)
	_refresh_hint()


func clear_preview() -> void:
	_has_preview = false
	_party_item = false
	for card: ItemsHeroCard in _cards.values():
		card.clear_preview()
	_refresh_hint()


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
	_refresh_hint()
	for card: ItemsHeroCard in _cards.values():
		card.disabled = not on or not card.preview_usable()
		card.focus_mode = Control.FOCUS_NONE if card.disabled else Control.FOCUS_ALL


func hint_visible() -> bool:
	return _hint.visible


func hint_text() -> String:
	return _hint.text


func _refresh_hint() -> void:
	_hint.visible = _picking or not _has_preview
	if _picking:
		_hint.text = Ui.text("ITEMS_USE_PARTY" if _party_item else "ITEMS_TARGET_HINT")
	else:
		_hint.text = Ui.text("ITEMS_SELECT_HINT")


func _heroes() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_cards.keys())
	return out


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
