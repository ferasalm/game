class_name UiRarity
extends RefCounted
## Rarity helpers for every screen: the tier colour (from RarityDef), coloured item names and the small rarity tag.


## The rarity id of a hilt, blade or prosthetic (&"" for an unknown id).
static func of_item(item_id: StringName) -> StringName:
	var item := ContentDB.get_def("item", item_id) as EquipDef
	return &"" if item == null else item.rarity


## The tier's colour; unknown tiers read as plain text colour.
static func colour(rarity_id: StringName) -> Color:
	var tier := ContentDB.get_def("rarity", rarity_id) as RarityDef
	return Ui.style().colour(&"c_text") if tier == null else tier.colour


static func item_colour(item_id: StringName) -> Color:
	return colour(of_item(item_id))


## The tier's sort order (0 = common); -1 when unknown.
static func order(rarity_id: StringName) -> int:
	var tier := ContentDB.get_def("rarity", rarity_id) as RarityDef
	return -1 if tier == null else tier.order


static func tier_name(rarity_id: StringName) -> String:
	var tier := ContentDB.get_def("rarity", rarity_id) as RarityDef
	return "" if tier == null else Ui.text(tier.name_key)


## The item's translated name in its rarity colour.
static func item_label(item_id: StringName, variant: StringName = &"NameLabel") -> Label:
	var item := ContentDB.get_def("item", item_id) as EquipDef
	var content: String = String(item_id) if item == null else Ui.text(item.name_key)
	return Ui.label(content, variant, item_colour(item_id))


## A small pill with the tier name, edged and lettered in the tier colour.
static func tag(rarity_id: StringName) -> PanelContainer:
	var pill := PanelContainer.new()
	var tint: Color = colour(rarity_id)
	pill.add_theme_stylebox_override("panel", UiBoxes.pill(Ui.style(), tint))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(Ui.label(tier_name(rarity_id), &"CaptionLabel", tint))
	return pill
