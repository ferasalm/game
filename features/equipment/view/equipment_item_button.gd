class_name EquipmentItemButton
extends RefCounted
## Builds one owned item as a menu button: its name in the rarity colour, the rarity tag and an "Equipped" mark on
## the right. The button is a toggle in its slot's ButtonGroup (pressed = staged). Meta: "slot", "item_id".

const TINTED: Array[String] = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]


static func make(item: EquipDef, slot: StringName, group: ButtonGroup, equipped: bool) -> Button:
	var style: UiStyleDef = Ui.style()
	var button := Button.new()
	button.text = Ui.text(item.name_key)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.button_group = group
	button.custom_minimum_size.y = style.size(&"s_button_h") * 1.2
	button.set_meta("slot", slot)
	button.set_meta("item_id", item.id)
	var tint: Color = UiRarity.colour(item.rarity)
	for colour_name: String in TINTED:
		button.add_theme_color_override(colour_name, tint)
	var chips: Array[Control] = []
	if equipped:
		chips.append(Ui.label(Ui.text("WORKSHOP_EQUIPPED"), &"CaptionLabel", style.colour(&"c_muted")))
	chips.append(UiRarity.tag(item.rarity))
	button.add_child(Ui.chip_row(chips))
	return button
