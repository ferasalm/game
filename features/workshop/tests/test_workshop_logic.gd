class_name TestWorkshopLogic
extends TestCase
## purpose: Tests pure workshop upgrade costs, refusals, crafting rules, caps, and stone operations.


func _costs() -> UpgradeCostsDef:
	return WorkshopService.costs()


func _rarities() -> Dictionary[StringName, RarityDef]:
	return WorkshopService.rarities()


func _blade(id: StringName) -> EquipDef:
	return ContentDB.get_def("blade", id) as EquipDef


func _holdings(money: int, mats: Dictionary, owned: Array[StringName] = []) -> WorkshopHoldings:
	var h := WorkshopHoldings.new()
	h.money = money
	for k: Variant in mats:
		h.materials[StringName(str(k))] = int(mats[k])
	h.owned = owned.duplicate()
	return h


func test_next_cost_common_and_rare() -> void:
	var common: EquipDef = _blade(&"rustwire_blade")
	var rare: EquipDef = _blade(&"broad_blade")
	var c: UpgradeCostsDef = _costs()
	var r: Dictionary = _rarities()

	var c0: Dictionary = Upgrades.next_cost(common, 0, c, r)
	var c1: Dictionary = Upgrades.next_cost(common, 1, c, r)
	var c2: Dictionary = Upgrades.next_cost(common, 2, c, r)
	check_eq(c0.get("riyal"), 40, "common +0 cost 40 riyal")
	check_eq(c1.get("riyal"), 80, "common +1 cost 80 riyal")
	check_eq(c2.get("riyal"), 140, "common +2 cost 140 riyal")
	check_eq(c0.get("materials"), {&"scrap_copper": 2}, "common +0 materials")
	check_eq(c1.get("materials"), {&"scrap_copper": 3, &"drone_coil": 1}, "common +1 materials")
	check_eq(c2.get("materials"), {&"drone_coil": 2, &"salt_crystal": 1}, "common +2 materials")

	var r0: Dictionary = Upgrades.next_cost(rare, 0, c, r)
	var r1: Dictionary = Upgrades.next_cost(rare, 1, c, r)
	var r2: Dictionary = Upgrades.next_cost(rare, 2, c, r)
	check_eq(r0.get("riyal"), 60, "rare +0 cost 60 riyal (40 * 1.5)")
	check_eq(r1.get("riyal"), 120, "rare +1 cost 120 riyal (80 * 1.5)")
	check_eq(r2.get("riyal"), 210, "rare +2 cost 210 riyal (140 * 1.5)")
	check_eq(r0.get("materials"), {&"scrap_copper": 2}, "rare +0 materials identical")
	check_eq(r1.get("materials"), {&"scrap_copper": 3, &"drone_coil": 1}, "rare +1 materials identical")
	check_eq(r2.get("materials"), {&"drone_coil": 2, &"salt_crystal": 1}, "rare +2 materials identical")


func test_plus_3_gives_ws_max() -> void:
	var common: EquipDef = _blade(&"rustwire_blade")
	var c: UpgradeCostsDef = _costs()
	var r: Dictionary = _rarities()
	var h: WorkshopHoldings = _holdings(9999, {&"scrap_copper": 50, &"drone_coil": 50, &"salt_crystal": 50})

	check_eq(Upgrades.next_cost(common, 3, c, r), {}, "+3 cost is empty")
	check_eq(Upgrades.problem(common, 3, c, r, h), Upgrades.WS_MAX, "+3 problem is WS_MAX")


func test_short_money_and_materials_refuse_and_change_nothing() -> void:
	var common: EquipDef = _blade(&"rustwire_blade")
	var c: UpgradeCostsDef = _costs()
	var r: Dictionary = _rarities()

	var h_poor: WorkshopHoldings = _holdings(10, {&"scrap_copper": 50})
	check_eq(Upgrades.problem(common, 0, c, r, h_poor), Upgrades.WS_SHORT_MONEY, "refuses short money")
	check(not Upgrades.apply_upgrade(common, c, r, h_poor), "upgrade failed")
	check_eq(h_poor.money, 10, "money unchanged")
	check_eq(h_poor.upgrades.get(&"rustwire_blade", 0), 0, "level unchanged")

	var h_nomats: WorkshopHoldings = _holdings(100, {&"scrap_copper": 1})
	check_eq(Upgrades.problem(common, 0, c, r, h_nomats), Upgrades.WS_SHORT_MATERIALS, "refuses short materials")
	check(not Upgrades.apply_upgrade(common, c, r, h_nomats), "upgrade failed")
	check_eq(h_nomats.money, 100, "money unchanged")
	check_eq(h_nomats.materials[&"scrap_copper"], 1, "materials unchanged")
	check_eq(h_nomats.upgrades.get(&"rustwire_blade", 0), 0, "level unchanged")


func test_upgrade_raises_gear_stat_by_upgrade_times_level() -> void:
	var loader := BattleLoader.from_db(ContentDB)
	var staged := WorkshopPresenter.StagedState.new()
	var eq: Dictionary[StringName, StringName] = {&"zayd.blade": &"rustwire_blade", &"zayd.armor": &"courier_jacket"}
	staged.equipment = eq

	var base_fighter: CombatantDef = loader.hero_from_state(&"zayd", staged)
	var base_atk: int = base_fighter.attack
	var base_hp: int = base_fighter.max_hp
	var base_def: int = base_fighter.defense

	staged.upgrades[&"rustwire_blade"] = 1
	var f1: CombatantDef = loader.hero_from_state(&"zayd", staged)
	check_eq(f1.attack, base_atk + 2, "blade +1 adds 2 attack")

	staged.upgrades[&"rustwire_blade"] = 2
	var f2: CombatantDef = loader.hero_from_state(&"zayd", staged)
	check_eq(f2.attack, base_atk + 4, "blade +2 adds 4 attack")

	staged.upgrades[&"rustwire_blade"] = 3
	var f3: CombatantDef = loader.hero_from_state(&"zayd", staged)
	check_eq(f3.attack, base_atk + 6, "blade +3 adds 6 attack")

	staged.upgrades[&"courier_jacket"] = 2
	var f_arm: CombatantDef = loader.hero_from_state(&"zayd", staged)
	check_eq(f_arm.max_hp, base_hp + 30, "armor +2 adds 30 max_hp")
	check_eq(f_arm.defense, base_def + 2, "armor +2 adds 2 defense")


func test_crafting_pays_riyal_and_materials_and_adds_output() -> void:
	var recipe := ContentDB.get_def("recipe", &"pink_herb_2") as RecipeDef
	var h: WorkshopHoldings = _holdings(50, {&"scrap_copper": 3})
	check_eq(Crafting.problem(recipe, h, []), &"", "no crafting problem")
	check(Crafting.apply_craft(recipe, h, [], false, 5), "craft succeeds")
	check_eq(h.money, 40, "50 - 10 riyal = 40")
	check_eq(h.materials[&"scrap_copper"], 2, "3 - 1 scrap_copper = 2")
	check_eq(h.bag.count(&"pink_herb"), 2, "bag has 2 pink herbs")


func test_second_sulaimani_refuses() -> void:
	var recipe := ContentDB.get_def("recipe", &"sulaimani_1") as RecipeDef
	var h: WorkshopHoldings = _holdings(100, {&"scrap_copper": 10}, [&"sulaimani"])
	check_eq(Crafting.problem(recipe, h, h.owned), Crafting.WS_STONE_OWNED, "refuses owned stone")
	check(not Crafting.apply_craft(recipe, h, h.owned, true), "apply_craft returns false")
	check_eq(h.money, 100, "money unchanged")
	check_eq(h.materials[&"scrap_copper"], 10, "materials unchanged")


func test_materials_cap_at_99() -> void:
	var mats: Dictionary = {}
	check_eq(Materials.add(mats, &"scrap_copper", 100), 99, "adds 100 capped at 99")
	check_eq(mats[&"scrap_copper"], 99, "stored value is 99")
	check_eq(Materials.add(mats, &"scrap_copper", 5), 99, "further adds clamped to 99")


func test_materials_cannot_be_sold() -> void:
	GameState.reset()
	GameState.materials[&"scrap_copper"] = 10
	GameState.money = 100
	var res: ShopResult = ShopService.sell(&"scrap_copper", 1)
	check(not res.ok, "ShopService.sell refuses material")
	check_eq(GameState.money, 100, "money unchanged")
	check_eq(GameState.materials[&"scrap_copper"], 10, "materials count unchanged")
	GameState.reset()


func test_setting_stone_moves_out_of_old_hilt() -> void:
	GameState.reset()
	GameState.sockets[&"grandfather_hilt"] = [&"aqiq_red"]
	GameState.sockets[&"swift_hilt"] = [&""]
	WorkshopService.set_stone(&"swift_hilt", 0, &"aqiq_red")
	check_eq(GameState.sockets[&"grandfather_hilt"][0], &"", "emptied old socket")
	check_eq(GameState.sockets[&"swift_hilt"][0], &"aqiq_red", "socketed into new hilt")
	GameState.reset()
