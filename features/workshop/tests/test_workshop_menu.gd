class_name TestWorkshopMenu
extends TestCase
## purpose: Tests opening WorkshopMenu via Screens stack, tab counts, and disabled reasons when short.


func test_workshop_menu_opens_by_id_with_tabs_and_disabled_button() -> void:
	GameState.start_new()
	GameState.money = 0
	GameState.materials.clear()
	for item_id: StringName in [&"rustwire_blade", &"keen_blade"]:
		Inventory.add(GameState.inventory, item_id)

	var screen: UiScreen = Screens.open(&"workshop")
	check(screen is WorkshopMenu, "Screens.open(&'workshop') returns WorkshopMenu")
	var menu := screen as WorkshopMenu

	check(menu.is_open(), "workshop menu is open")
	check_eq(menu._tabs._buttons.size(), 3, "menu has 3 tabs: UPGRADE, GEMSTONES, CRAFTING")

	check(menu._action_btn.disabled, "upgrade button is disabled when player is short")
	check_eq(menu._action_btn.text, Ui.text("WS_SHORT_MONEY"), "button displays short money reason")

	menu._tabs.select_tab(WorkshopTabsBar.Tab.CRAFTING)
	check_eq(menu._tabs.current_tab, WorkshopTabsBar.Tab.CRAFTING, "current tab is now CRAFTING")
	check(menu._action_btn.disabled, "craft button is disabled when player is short")
	check(menu._action_btn.text == Ui.text("WS_SHORT_MONEY") or menu._action_btn.text == Ui.text("WS_SHORT_MATERIALS"),
		"craft button displays short reason")

	Screens.clear()
	GameState.reset()


func test_workshop_hologram_has_no_3d_nodes() -> void:
	GameState.start_new()
	var screen: UiScreen = Screens.open(&"workshop")
	var menu := screen as WorkshopMenu
	var holo: WorkshopHologram = menu._hologram
	check(holo != null, "workshop hologram exists")
	check(NodeScan.of_type(holo, &"SubViewport").is_empty(), "no SubViewport")
	check(NodeScan.of_type(holo, &"Node3D").is_empty(), "no Node3D")
	check(holo.sprite_texture() != null, "the hologram shows a hero picture")
	Screens.clear()
	GameState.reset()
