extends TestCase
## T3: the 4 hilt + blade pairings give 4 different Zayd stat sets, inside the timeline caps; each hilt adds
## exactly one move; the shared base definition is never changed.


func _loader() -> BattleLoader:
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all")
	check_eq(problems, PackedStringArray(), "shipped content loads")
	var loader: BattleLoader = BattleLoader.from_db(db)
	db.free()
	return loader


func _signature(def: CombatantDef) -> String:
	return "%d/%.2f/%.2f/%d/%d" % [def.agility, def.cast_speed, def.weight, def.attack, def.knockback_bonus]


func test_four_pairings_four_different_stat_sets() -> void:
	var loader: BattleLoader = _loader()
	var base: CombatantDef = loader.combatants[&"zayd"]
	var seen: Dictionary[String, bool] = {}
	for hilt_id: StringName in loader.hilts:
		for blade_id: StringName in loader.blades:
			var zayd: CombatantDef = loader.zayd_with(hilt_id, blade_id)
			seen[_signature(zayd)] = true
			check(zayd != base, "equip returns a new object")
			check(zayd.agility >= CombatantDef.AGILITY_MIN and zayd.agility <= CombatantDef.AGILITY_MAX, "agility cap")
			check(zayd.cast_speed >= CombatantDef.CAST_SPEED_MIN and zayd.cast_speed <= CombatantDef.CAST_SPEED_MAX, "cast cap")
			check_eq(zayd.actions.size(), base.actions.size() + 1, "%s adds exactly one move" % hilt_id)
			check(zayd.actions.has(loader.hilts[hilt_id].ability), "and it is the hilt's ability")
	check_eq(seen.size(), 4, "four distinct stat sets")
	check_eq(loader.hilts.size() * loader.blades.size(), 4, "two hilts x two blades")


func test_equip_follows_the_merge_order_and_leaves_the_base_alone() -> void:
	var loader: BattleLoader = _loader()
	var base: CombatantDef = loader.combatants[&"zayd"]
	var hilt: HiltDef = loader.hilts[&"swift_hilt"]
	var blade: BladeDef = loader.blades[&"broad_blade"]
	var zayd: CombatantDef = Djanbeyyah.equip(base, hilt, blade)
	check_eq(zayd.agility, base.agility + hilt.agility, "agility from the hilt")
	check_eq(zayd.cast_speed, base.cast_speed * hilt.cast_speed, "cast speed multiplied by the hilt")
	check_eq(zayd.weight, base.weight + hilt.weight + blade.weight, "weights add up")
	check_eq(zayd.attack, base.attack + blade.attack, "attack from the blade")
	check_eq(zayd.knockback_bonus, base.knockback_bonus + blade.knockback, "knockback from the blade")
	check_eq(zayd.max_hp, base.max_hp, "other stats carry over")
	check_eq(base.actions.size(), 2, "the shared base keeps its two moves")
	check_eq(base.agility, 40, "and its agility")


func test_caps_clamp_extreme_gear() -> void:
	var loader: BattleLoader = _loader()
	var base: CombatantDef = loader.combatants[&"zayd"]
	var hilt := HiltDef.new()
	hilt.id = &"wild_hilt"
	hilt.ability = &"quick_slash"
	hilt.agility = 500
	hilt.cast_speed = 4.0
	var blade: BladeDef = loader.blades[&"keen_blade"]
	var fast: CombatantDef = Djanbeyyah.equip(base, hilt, blade)
	check_eq(fast.agility, CombatantDef.AGILITY_MAX, "agility capped at 99")
	check_eq(fast.cast_speed, CombatantDef.CAST_SPEED_MAX, "cast speed capped at 2.0")
	hilt.agility = -500
	hilt.cast_speed = 0.1
	var slow: CombatantDef = Djanbeyyah.equip(base, hilt, blade)
	check_eq(slow.agility, CombatantDef.AGILITY_MIN, "agility floored at 1")
	check_eq(slow.cast_speed, CombatantDef.CAST_SPEED_MIN, "cast speed floored at 0.5")
