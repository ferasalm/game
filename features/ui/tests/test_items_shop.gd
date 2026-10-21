extends TestCase
## The Items and Shop screens on the Screens stack, and the riyal banner of the loot popup.


func _fresh() -> void:
	Screens.clear()
	GameState.start_new()
	Router.state = Router.STATE_EXPLORING


func test_both_screens_are_registered_and_the_pause_menu_offers_items() -> void:
	check(Screens.has_screen(&"items") and Screens.has_screen(&"shop"), "registered")
	_fresh()
	Screens.open(&"pause")
	var menu: PauseMenu = Screens.top() as PauseMenu
	check(menu != null and menu.button_of(&"items") != null, "Items shows in the pause menu")
	Screens.clear()
	Router.state = Router.STATE_TITLE


func test_items_screen_lists_the_bag_and_uses_a_herb() -> void:
	_fresh()
	GameState.set_vitals({&"zayd": {"hp": 100, "sp": 24}})
	Screens.open(&"items")
	var screen: ItemsScreen = Screens.top() as ItemsScreen
	check(screen != null, "opens")
	if screen == null:
		return
	check_eq(screen.item_ids(), [&"pink_herb"] as Array[StringName], "the starting bag")
	screen.row_of(&"pink_herb").pressed.emit()
	check(not screen.hero_button(&"zayd").disabled, "a hurt hero can be picked")
	check(screen.hero_button(&"bilqis").disabled, "a full hero is disabled")
	screen.hero_button(&"zayd").pressed.emit()
	check_eq(GameState.vitals[&"zayd"]["hp"], 220, "healed 120")
	check(GameState.bag.is_empty(), "herb used up")
	check(screen.item_ids().is_empty(), "the list is empty now")
	screen.on_back()
	Screens.clear()
	Router.state = Router.STATE_TITLE


func test_shop_screen_buys_and_sells() -> void:
	_fresh()
	Screens.open(&"shop", {"shop": &"herb_stall"})
	var screen: ShopScreen = Screens.top() as ShopScreen
	check(screen != null, "opens")
	if screen == null:
		return
	check_eq(screen.keeper_text(), Ui.text("SHOP_GREET_FIRST"), "first visit greeting")
	screen.select(&"pink_herb")
	screen.set_quantity(2)
	check_eq(screen.quantity(), 2, "two chosen")
	var result: ShopResult = screen.trade()
	check(result.ok, "bought")
	check_eq(GameState.money, 40, "100 - 60")
	check_eq(GameState.bag.get(&"pink_herb"), 3, "bag")
	check_eq(screen.keeper_text(), Ui.text("SHOP_BUY_DONE"), "the keeper answers")
	screen.select(&"white_herb")
	check(not screen.trade().ok and screen.keeper_text() == Ui.text("SHOP_NOT_ENOUGH"), "too poor: refused with a line")
	screen.switch_tab(&"sell")
	check(screen.row_of(&"pink_herb") != null and screen.row_of(&"white_herb") == null, "only the bag is listed")
	screen.select(&"pink_herb")
	check(screen.trade().ok, "sold one")
	check_eq(GameState.money, 55, "40 + 15")
	screen.on_back()
	Screens.clear()
	Router.state = Router.STATE_TITLE


func test_shop_greeting_changes_on_a_return_visit() -> void:
	_fresh()
	Screens.open(&"shop", {"shop": &"herb_stall"})
	Screens.clear()
	Screens.open(&"shop", {"shop": &"herb_stall"})
	var screen: ShopScreen = Screens.top() as ShopScreen
	check(screen != null and screen.keeper_text() == Ui.text("SHOP_GREET_RETURN"), "return greeting")
	Screens.clear()
	Router.state = Router.STATE_TITLE


func test_loot_popup_shows_riyal_but_not_shop_sales() -> void:
	_fresh()
	var popup := LootPopup.new()
	tree.root.add_child(popup)
	var amounts: Array[int] = []
	popup.money_shown.connect(func(amount: int) -> void: amounts.append(amount))
	EventBus.money_changed.emit(140, 40)
	EventBus.money_changed.emit(100, -40)
	popup.skip()
	check_eq(amounts, [40] as Array[int], "a win shows +40, a spend shows nothing")
	Screens.open(&"shop", {"shop": &"herb_stall"})
	EventBus.money_changed.emit(155, 15)
	check_eq(amounts, [40] as Array[int], "a sale in the shop shows nothing")
	Screens.clear()
	popup.free()
	Router.state = Router.STATE_TITLE
