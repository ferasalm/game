extends TestCase
## The Items entry of the command menu and its list: greyed with no herbs, rows with free counts, then the targets,
## back at each level, and a committed herb is a reserved cast on the timeline.


func _stage(bag: Dictionary) -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var party: Array[CombatantDef] = [loader.zayd_with(&"swift_hilt", &"keen_blade"), loader.fighter(&"bilqis", &"", &"", &"")]
	var setup: BattleSetup = loader.make_setup(party, 7, 0)
	setup.bag = bag
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(BattleSim.create_from(setup), Vector3.ZERO)
	stage.run_to_end(30000)  # until a hero waits
	return stage


func _ids(buttons: Array[Button], key: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for button: Button in buttons:
		out.append(button.get_meta(key) as StringName)
	return out


func test_items_entry_is_greyed_with_no_herbs_and_not_a_move() -> void:
	var stage: BattleStage = _stage({})
	var hero: UnitState = stage.sim.waiting_hero()
	check(stage.hud.menu.items_button() != null and stage.hud.menu.items_button().disabled, "Items is greyed with an empty bag")
	check_eq(_ids(stage.hud.menu.move_buttons(), "action_id"), hero.def.actions, "the move list is only the moves")
	stage.free()


func test_rows_targets_and_back() -> void:
	var stage: BattleStage = _stage({&"pink_herb": 2, &"white_herb": 1})
	var hero: UnitState = stage.sim.waiting_hero()
	check(not stage.hud.menu.items_button().disabled, "Items is open")
	stage.hud.menu.items_button().pressed.emit()
	check(stage.hud.item_menu.is_open() and not stage.hud.menu.visible, "the item list replaces the command menu")
	check_eq(_ids(stage.hud.item_menu.item_buttons(), "item_id"), [&"pink_herb", &"white_herb"] as Array[StringName], "one row per herb")
	var white: Button = stage.hud.item_menu.item_buttons()[1]
	check(white.disabled, "the white herb is greyed while nobody is downed")
	stage.hud.item_menu.item_buttons()[0].pressed.emit()
	check_eq(_ids(stage.hud.item_menu.target_buttons(), "unit_id").size(), 2, "both living heroes are targets")
	check_eq(stage.fighters.marker_target(), &"zayd", "the marker points at the first target")
	stage.hud.item_menu.back()
	check_eq(stage.fighters.marker_target(), &"", "back hides the marker")
	check_eq(stage.hud.item_menu.item_buttons().size(), 2, "back returns to the rows")
	stage.hud.item_menu.back()
	check(not stage.hud.item_menu.is_open() and stage.hud.menu.visible and stage.hud.menu.is_open(),
		"back again shows the command menu")
	check(stage.sim.waiting_hero() == hero, "nothing was committed")
	stage.free()


func test_choosing_a_herb_reserves_it_and_casts() -> void:
	var stage: BattleStage = _stage({&"pink_herb": 1})
	var hero: UnitState = stage.sim.waiting_hero()
	stage.hud.menu.items_button().pressed.emit()
	stage.hud.item_menu.item_buttons()[0].pressed.emit()
	stage.hud.item_menu.target_buttons()[0].pressed.emit()
	check(hero.action is ItemAction and hero.phase == UnitState.Phase.CAST, "the hero casts the herb")
	check_eq(stage.sim.bag.reserved(&"pink_herb"), 1, "it is reserved")
	check(not stage.hud.item_menu.is_open() and not stage.hud.menu.is_open(), "both menus close")
	stage.free()


func test_the_party_herb_skips_the_target_list() -> void:
	var stage: BattleStage = _stage({&"qishr_cup": 1})
	var hero: UnitState = stage.sim.waiting_hero()
	stage.hud.menu.items_button().pressed.emit()
	stage.hud.item_menu.item_buttons()[0].pressed.emit()
	check(hero.action is ItemAction, "the cup is cast at once")
	check_eq(stage.sim.bag.reserved(&"qishr_cup"), 1, "and reserved")
	stage.free()


func test_the_view_plays_a_herb_heal() -> void:
	var stage: BattleStage = _stage({&"pink_herb": 1})
	var hero: UnitState = stage.sim.waiting_hero()
	hero.hp = hero.def.max_hp - 60
	stage.shown_hp[hero.unit_id] = hero.hp
	stage.hud.menu.items_button().pressed.emit()
	stage.hud.item_menu.item_buttons()[0].pressed.emit()
	stage.hud.item_menu.confirm(hero.unit_id)
	stage.auto_play = true
	var healed: int = 0
	for frame: int in 600:
		stage.step_frame()
		if healed == 0 and stage.sim.bag.count(&"pink_herb") == 0:
			healed = stage.shown_hp[hero.unit_id]
		if healed > 0:
			break
	check(healed > hero.def.max_hp - 60, "the shown HP rose when the herb landed (%d)" % healed)
	check_eq(stage.shown_hp[hero.unit_id], hero.hp, "and the shown HP follows the sim")
	check_eq(stage.sim.bag.count(&"pink_herb"), 0, "the herb is spent")
	stage.free()
