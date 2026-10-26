extends TestCase
## The loot popup (queues item_obtained in order, skippable), the area title card, and the title overlay (any key
## dismisses it once).


func _key(pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = pressed
	event.echo = echo
	return event


func test_loot_popup_queues_items_in_order() -> void:
	var popup := LootPopup.new()
	tree.root.add_child(popup)
	var order: Array[StringName] = []
	popup.shown.connect(func(item_id: StringName) -> void: order.append(item_id))
	EventBus.item_obtained.emit(&"anvil_hilt")
	EventBus.item_obtained.emit(&"arc_arm")
	EventBus.item_obtained.emit(&"swift_hilt")
	check_eq(popup.current_item(), &"anvil_hilt", "the first shows at once")
	check_eq(popup.pending(), 2, "two wait")
	popup.skip()
	check_eq(popup.current_item(), &"arc_arm", "then the second")
	popup.skip()
	popup.skip()
	check_eq(popup.current_item(), &"", "idle after the last")
	check_eq(order, [&"anvil_hilt", &"arc_arm", &"swift_hilt"] as Array[StringName], "shown in the order obtained")
	popup.free()


func test_loot_popup_never_takes_input() -> void:
	var popup := LootPopup.new()
	tree.root.add_child(popup)
	popup.enqueue(&"arc_arm")
	var stops: int = 0
	for node: Node in NodeWalk.all(popup):
		if node is Control and (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			stops += 1
	check_eq(stops, 0, "no control stops the mouse")
	popup.free()


func test_area_title_card_shows_the_name() -> void:
	var card := AreaTitleCard.new()
	tree.root.add_child(card)
	check(not card.is_showing(), "hidden at first")
	card.show_card("AREA_SOUQ_NAME", "AREA_SOUQ_NAME_MUSNAD", "AREA_SUBTITLE")
	check(card.is_showing(), "showing")
	check_eq(card.name_text(), "Souq al-Milh Rooftops", "the English name")
	card.dismiss()
	check(not card.is_showing(), "a battle starting under the card ends it at once")
	card.free()


func test_title_overlay_dismisses_once_on_a_key() -> void:
	var overlay := TitleOverlay.new()
	tree.root.add_child(overlay)
	var count: Array[int] = [0]
	overlay.dismissed.connect(func() -> void: count[0] += 1)
	overlay._unhandled_input(_key(false))
	overlay._unhandled_input(_key(true, true))
	overlay._unhandled_input(InputEventMouseMotion.new())
	check_eq(count[0], 0, "release, key repeat and mouse motion do nothing")
	check(overlay.is_showing(), "still showing")
	overlay._unhandled_input(_key())
	overlay._unhandled_input(_key())
	check_eq(count[0], 1, "a key press dismisses it, once")
	check(not overlay.is_showing(), "no longer showing")
	overlay.free()
