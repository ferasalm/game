extends TestCase
## The Items screen: Equipment-style layout, party-card previews clamped by missing HP, and the use flow.

func test_layout_puts_the_bag_left_and_party_cards_right() -> void:
	var screen: ItemsScreen = _open()
	check_approx(screen.tabs.position.x, 80.0, 2.0, "tabs x")
	check_approx(screen.tabs.position.y, 40.0, 2.0, "tabs y")
	check_approx(screen.list.position.x, 80.0, 2.0, "list x")
	check_approx(screen.list.position.y, 124.0, 2.0, "list y")
	check(screen.party_panel.position.x > screen.list.position.x + screen.list.size.x, "cards right of the bag")
	check_approx(screen.desc.position.x, 80.0, 2.0, "desc x")
	check_approx(screen.desc.position.y, 900.0, 2.0, "desc y")
	check(screen.desc.position.y >= screen.list.position.y + screen.list.size.y, "desc below the bag")
	_clean()


func test_preview_equals_the_heal_clamped_by_missing_hp() -> void:
	var screen: ItemsScreen = _open()
	screen.select_item(&"pink_herb")
	var card: PartyCard = screen.hero_card(&"zayd")
	var expected: int = 120
	check_eq(card.preview_hp_gain(), expected, "250/400 heals the full 120")
	check_eq(card.preview_text(), "+120 HP", "the card shows the gain")
	GameState.set_vitals({&"zayd": {"hp": 350, "sp": 8}})
	screen.select_item(&"pink_herb")
	check_eq(screen.hero_card(&"zayd").preview_hp_gain(), 50, "350/400 heals only the missing 50")
	_clean()


func test_full_and_battle_only_heroes_are_greyed_or_hidden() -> void:
	var screen: ItemsScreen = _open()
	screen.select_item(&"pink_herb")
	var full: PartyCard = screen.hero_card(&"bilqis")
	check(not full.preview_usable(), "a full hero cannot be helped")
	check_eq(full.preview_text(), Ui.text("ITEMS_FULL"), "the full hero says so")
	GameState.set_bag({&"pink_herb": 1, &"white_herb": 1})
	screen.list.populate()
	check(not screen.item_ids().has(&"white_herb"), "the battle-only white herb never lists")
	_clean()


func test_using_a_herb_updates_the_count_and_the_bag() -> void:
	var screen: ItemsScreen = _open()
	screen.row_of(&"pink_herb").pressed.emit()
	check(screen.hero_button(&"zayd") != null and not screen.hero_button(&"zayd").disabled, "hurt hero can be picked")
	check(screen.hero_button(&"bilqis").disabled, "full hero is disabled")
	screen.hero_button(&"zayd").pressed.emit()
	check_eq(GameState.vitals[&"zayd"]["hp"], 370, "250 + 120")
	check_eq(screen.hero_card(&"zayd").hp_text(), "370/400", "the card's HP bar follows the use")
	check_eq(GameState.bag.get(&"pink_herb", 0), 0, "the herb left the bag")
	check(not screen.item_ids().has(&"pink_herb"), "the row is gone")
	_clean()


func test_qishr_cup_previews_its_cure_on_every_card() -> void:
	GameState.start_new()
	GameState.set_bag({&"qishr_cup": 1})
	GameState.set_vitals({&"zayd": {"hp": 300, "sp": 8}, &"bilqis": {"hp": 200, "sp": 20}})
	Screens.clear()
	Router.state = Router.STATE_EXPLORING
	var screen := Screens.open(&"items") as ItemsScreen
	screen.select_item(&"qishr_cup")
	var text: String = screen.hero_card(&"zayd").preview_text()
	check(text.contains(Ui.text("STATUS_CONFUSED")), "the card names the status it cures")
	check_eq(screen.hero_card(&"zayd").preview_hp_gain(), 75, "the party heal is previewed")
	_clean()


func test_party_item_stays_usable_for_a_full_hero_when_another_can_gain() -> void:
	Screens.clear()
	GameState.start_new()
	Router.state = Router.STATE_EXPLORING
	GameState.set_bag({&"qishr_cup": 1})
	GameState.set_vitals({&"zayd": {"hp": 400, "sp": 8}, &"bilqis": {"hp": 200, "sp": 20}})
	var screen := Screens.open(&"items") as ItemsScreen
	screen.select_item(&"qishr_cup")
	check(screen.hero_card(&"zayd").preview_usable(), "a full hero is not greyed for a party item")
	check_eq(screen.hero_card(&"zayd").preview_hp_gain(), 0, "the full hero gains nothing")
	check_eq(screen.hero_card(&"bilqis").preview_hp_gain(), 75, "the hurt hero previews the party heal")
	screen.choose(&"qishr_cup")
	check_eq(screen.party_panel.hint_text(), Ui.text("ITEMS_USE_PARTY"), "a party item says it uses on all")
	check(not screen.hero_button(&"zayd").disabled, "the full hero card can still be confirmed")
	screen.hero_button(&"zayd").pressed.emit()
	check_eq(GameState.vitals[&"bilqis"]["hp"], 275, "one confirm heals the hurt hero")
	check_eq(GameState.vitals[&"zayd"]["hp"], 400, "the full hero stays full")
	_clean()


func test_hints_hide_with_a_focus_and_only_target_mode_shows_the_target_hint() -> void:
	var screen: ItemsScreen = _open()
	check(not screen.party_panel.hint_visible(), "the focus hint is gone once an item is focused")
	screen.select_item(&"pink_herb")
	check(not screen.party_panel.hint_visible(), "a selected item never shows the focus hint")
	screen.choose(&"pink_herb")
	check(screen.party_panel.hint_visible(), "target mode shows its hint")
	check_eq(screen.party_panel.hint_text(), Ui.text("ITEMS_TARGET_HINT"), "the target hint asks for a card")
	_clean()


func test_using_an_item_toasts_the_translated_line() -> void:
	var screen: ItemsScreen = _open()
	screen.row_of(&"pink_herb").pressed.emit()
	screen.hero_button(&"zayd").pressed.emit()
	check_eq(Screens._toasts.current_text(), "Used Pink-feather herb on Zayd", "the toast is the real line")
	_clean()


func _open() -> ItemsScreen:
	Screens.clear()
	GameState.start_new()
	Router.state = Router.STATE_EXPLORING
	GameState.set_vitals({&"zayd": {"hp": 250, "sp": 8}})
	return Screens.open(&"items") as ItemsScreen


func _clean() -> void:
	Screens.clear()
	GameState.reset()
	Router.state = Router.STATE_TITLE


func check_approx(val: float, target: float, tolerance: float, msg: String) -> void:
	check(absf(val - target) <= tolerance, "%s: expected %f got %f" % [msg, target, val])
