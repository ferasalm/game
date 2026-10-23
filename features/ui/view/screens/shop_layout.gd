class_name ShopLayout
extends RefCounted
## Builds panels for ShopScreen: brass title plate, money counter pill, and sub-panels.


static func build_title_bar(parent: Control) -> Dictionary:
	var style: UiStyleDef = Ui.style()
	var title_text: String = Ui.text("SHOP_TITLE_HERB_STALL")
	var title_bar := UiPanel.new()
	title_bar.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"plate"))
	title_bar.position = Vector2(80, 40)
	title_bar.size = Vector2(1760, 80)
	title_bar.custom_minimum_size = Vector2(1760, 80)
	var pair: Control = Ui.title_pair(title_text, Ui.text("SHOP_HERB_STALL_MUSNAD"), true)
	pair.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bar.add_child(pair)
	parent.add_child(title_bar)

	var money_counter: MoneyCounter = Ui.money_counter(true)
	money_counter.position = Vector2(1600, 56)
	money_counter.set_amount(GameState.money, false)
	parent.add_child(money_counter)
	return {"title_bar": title_bar, "money_counter": money_counter}


static func build_panels(parent: Control) -> Dictionary:
	var grid := ShopGrid.new().setup_grid()
	parent.add_child(grid)

	var keeper := ShopKeeperBox.new()
	keeper.position = Vector2(80, 720)
	parent.add_child(keeper)

	var detail := ShopDetail.new()
	detail.position = Vector2(840, 140)
	parent.add_child(detail)

	var summary := ShopSummary.new()
	summary.position = Vector2(1440, 140)
	parent.add_child(summary)

	var party := ShopPartyMini.new()
	party.position = Vector2(1440, 600)
	parent.add_child(party)

	return {
		"grid": grid,
		"keeper": keeper,
		"detail": detail,
		"summary": summary,
		"party": party
	}
