extends TestCase
## Abu Nabil Haggle and Shop tests: Haggle dialogue branches A/B/C/D, flag side effects,
## walk-away safety, win dialogue, post-win menu gating, and shop prices before/after win.


func _haggle_def() -> DialogueDef:
	return ContentDB.get_def("dialogue", &"abu_nabil_first") as DialogueDef


func test_haggle_talk_choice_a_flow() -> void:
	var dlg: DialogueDef = _haggle_def()
	check(dlg != null and dlg.lines.size() >= 3, "abu_nabil_first has lines")
	var line: DialogueLine = dlg.lines[2]
	check_eq(line.choices.size(), 4, "four haggle choices A-D")
	var choice_a: DialogueChoice = line.choices[0]
	check_eq(choice_a.next, &"abu_nabil_haggle_a", "choice A leads to haggle_a")
	var dlg_a := ContentDB.get_def("dialogue", &"abu_nabil_haggle_a") as DialogueDef
	check(dlg_a != null and not dlg_a.lines.is_empty(), "haggle_a loaded")
	var fight_line: DialogueLine = dlg_a.lines[dlg_a.lines.size() - 1]
	check_eq(fight_line.choices.size(), 2, "Fight? Yes / Not yet")
	var req: BattleRequest = DialogueEffects.build_battle_request(fight_line.choices[0].effects[0].split(" ", false))
	check(req != null and req.opening == &"even" and not req.practice, "Choice A fight is even")
	check_eq(fight_line.choices[1].effects.size(), 0, "Not yet sets no effects")


func test_haggle_talk_choice_b_insults_and_starts_enemy_first() -> void:
	GameState.start_new()
	var choice_b: DialogueChoice = _haggle_def().lines[2].choices[1]
	DialogueEffects.apply_all(choice_b.effects)
	check(bool(GameState.flags.get(&"abu_nabil_insulted", false)), "abu_nabil_insulted set")
	check(not bool(GameState.flags.get(&"abu_nabil_charmed", false)), "abu_nabil_charmed not set")
	var req: BattleRequest = DialogueEffects.build_battle_request(choice_b.effects[1].split(" ", false))
	check(req != null and req.opening == &"enemy_first" and req.ambush == 1, "Choice B is enemy_first")


func test_haggle_talk_choice_c_charms_and_leads_to_party_first() -> void:
	GameState.start_new()
	var choice_c: DialogueChoice = _haggle_def().lines[2].choices[2]
	DialogueEffects.apply_all(choice_c.effects)
	check(bool(GameState.flags.get(&"abu_nabil_charmed", false)), "abu_nabil_charmed set")
	check(not bool(GameState.flags.get(&"abu_nabil_insulted", false)), "abu_nabil_insulted not set")
	var dlg_c := ContentDB.get_def("dialogue", choice_c.next) as DialogueDef
	var fight_line: DialogueLine = dlg_c.lines[dlg_c.lines.size() - 1]
	var req: BattleRequest = DialogueEffects.build_battle_request(fight_line.choices[0].effects[0].split(" ", false))
	check(req != null and req.opening == &"party_first" and req.ambush == 2, "Choice C fight is party_first")


func test_haggle_talk_choice_d_walks_away_leaves_flags_clean() -> void:
	GameState.start_new()
	var choice_d: DialogueChoice = _haggle_def().lines[2].choices[3]
	check_eq(choice_d.next, &"abu_nabil_haggle_d", "choice D leads to haggle_d")
	DialogueEffects.apply_all(choice_d.effects)
	check(not bool(GameState.flags.get(&"abu_nabil_insulted", false)), "not insulted")
	check(not bool(GameState.flags.get(&"abu_nabil_charmed", false)), "not charmed")
	check(not bool(GameState.flags.get(&"abu_nabil_beaten", false)), "not beaten")


func test_shop_prices_before_and_after_win() -> void:
	var shop := ContentDB.get_def("shop", &"herb_stall") as ShopDef
	check(not shop.stock.has(&"qishr_cup"), "qishr_cup leaves herb stall stock")
	var pink := ContentDB.get_def("consumable", &"pink_herb") as ConsumableDef
	var yellow := ContentDB.get_def("consumable", &"yellow_herb") as ConsumableDef
	var white := ContentDB.get_def("consumable", &"white_herb") as ConsumableDef
	var greedy_flags: Dictionary[StringName, bool] = {}
	check_eq(Shop.unit_buy_price(shop, pink, greedy_flags), 300, "pink herb 10x before win: 300")
	check_eq(Shop.unit_buy_price(shop, yellow, greedy_flags), 200, "yellow herb 10x before win: 200")
	check_eq(Shop.unit_buy_price(shop, white, greedy_flags), 800, "white herb 10x before win: 800")
	var beaten_flags: Dictionary[StringName, bool] = {&"abu_nabil_beaten": true}
	check_eq(Shop.unit_buy_price(shop, pink, beaten_flags), 30, "pink herb 1x after win: 30")
	check_eq(Shop.unit_buy_price(shop, yellow, beaten_flags), 20, "yellow herb 1x after win: 20")
	check_eq(Shop.unit_buy_price(shop, white, beaten_flags), 80, "white herb 1x after win: 80")


func test_after_win_dialogue_and_menu_gating() -> void:
	GameState.start_new()
	var win_dlg := ContentDB.get_def("dialogue", &"abu_nabil_after_battle") as DialogueDef
	check(win_dlg != null, "after-battle dialogue exists")
	var last_line: DialogueLine = win_dlg.lines[win_dlg.lines.size() - 1]
	check_eq(last_line.choices.size(), 2, "Pay / Refuse choices")
	for c: DialogueChoice in last_line.choices:
		check(c.effects.has("set_flag abu_nabil_beaten"), "choice sets abu_nabil_beaten")
		check(c.effects.has("give_item qishr_cup 1"), "choice gives qishr_cup")
	var talk := ContentDB.get_def("talk", &"herb_seller") as TalkDef
	var flags: Dictionary[StringName, bool] = {}
	check_eq(TalkPicker.pick(talk, flags), &"abu_nabil_first", "first visit plays haggle talk")
	flags[&"abu_nabil_beaten"] = true
	check_eq(TalkPicker.pick(talk, flags), &"abu_nabil_menu", "after win visit plays menu")
