extends TestCase
## Tests for RPG progression: level thresholds, class stat growth, XP awards, and gear merge order.


func _levels() -> LevelsDef:
	var def := LevelsDef.new()
	def.xp_total = [0, 60, 150, 280, 450, 670, 940, 1260, 1640, 2080]
	return def


func _courier_class() -> ClassDef:
	var def := ClassDef.new()
	def.id = &"courier"
	def.hero = &"zayd"
	def.growth = {
		&"max_hp": 30, &"max_sp": 2, &"attack": 2, &"defense": 2, &"agility": 1, &"luck": 1
	}
	def.passive = &"couriers_footing"
	return def


func _zayd_base() -> CombatantDef:
	var def := CombatantDef.new()
	def.id = &"zayd"
	def.max_hp = 100
	def.max_sp = 24
	def.attack = 20
	def.defense = 10
	def.agility = 40
	def.luck = 10
	return def


func test_level_at_each_threshold_and_cap() -> void:
	var levels: LevelsDef = _levels()
	check_eq(Progression.level(0, levels), 1, "0 XP is Lv 1")
	check_eq(Progression.level(59, levels), 1, "59 XP is Lv 1")
	check_eq(Progression.level(60, levels), 2, "60 XP reaches Lv 2")
	check_eq(Progression.level(149, levels), 2, "149 XP is Lv 2")
	check_eq(Progression.level(150, levels), 3, "150 XP reaches Lv 3")
	check_eq(Progression.level(280, levels), 4, "280 XP reaches Lv 4")
	check_eq(Progression.level(450, levels), 5, "450 XP reaches Lv 5")
	check_eq(Progression.level(670, levels), 6, "670 XP reaches Lv 6")
	check_eq(Progression.level(940, levels), 7, "940 XP reaches Lv 7")
	check_eq(Progression.level(1260, levels), 8, "1260 XP reaches Lv 8")
	check_eq(Progression.level(1640, levels), 9, "1640 XP reaches Lv 9")
	check_eq(Progression.level(2080, levels), 10, "2080 XP reaches Lv 10 (cap)")
	check_eq(Progression.level(9999, levels), 10, "XP above max stays at Lv 10 cap")


func test_grow_at_lv1_equals_the_base() -> void:
	var base: CombatantDef = _zayd_base()
	var courier: ClassDef = _courier_class()
	var grown: CombatantDef = Progression.grow(base, courier, 1)
	check_eq(grown.max_hp, base.max_hp, "HP untouched at Lv 1")
	check_eq(grown.max_sp, base.max_sp, "SP untouched at Lv 1")
	check_eq(grown.attack, base.attack, "ATK untouched at Lv 1")
	check_eq(grown.defense, base.defense, "DEF untouched at Lv 1")
	check_eq(grown.agility, base.agility, "AGI untouched at Lv 1")
	check_eq(grown.luck, base.luck, "LCK untouched at Lv 1")


func test_lv3_zayd_equals_base_plus_2x_growth() -> void:
	var base: CombatantDef = _zayd_base()
	var courier: ClassDef = _courier_class()
	var grown: CombatantDef = Progression.grow(base, courier, 3)
	check_eq(grown.max_hp, base.max_hp + 60, "HP + 2x30")
	check_eq(grown.max_sp, base.max_sp + 4, "SP + 2x2")
	check_eq(grown.attack, base.attack + 4, "ATK + 2x2")
	check_eq(grown.defense, base.defense + 4, "DEF + 2x2")
	check_eq(grown.agility, base.agility + 2, "AGI + 2x1")
	check_eq(grown.luck, base.luck + 2, "LCK + 2x1")


func test_award_shares_full_xp_to_downed_heroes_and_50_pct_on_repeat() -> void:
	var levels: LevelsDef = _levels()
	var classes: Dictionary[StringName, ClassDef] = {&"zayd": _courier_class()}
	var xp: Dictionary[StringName, int] = {&"zayd": 0, &"bilqis": 0}
	var party: Array[StringName] = [&"zayd", &"bilqis"]
	var encounter_xp: int = 60
	var level_ups: Array[LevelUp] = Progression.award(xp, party, encounter_xp, levels, classes)
	check_eq(xp[&"zayd"], 60, "zayd got 60 XP")
	check_eq(xp[&"bilqis"], 60, "downed hero got full 60 XP")
	check_eq(level_ups.size(), 2, "both heroes leveled up to 2")
	check_eq(level_ups[0].hero, &"zayd", "zayd level up")
	check_eq(level_ups[0].to_level, 2, "to level 2")
	check_eq(level_ups[0].gains[&"max_hp"], 30, "gain 30 HP")
	check_eq(level_ups[1].hero, &"bilqis", "bilqis level up")
	var repeat_xp: int = floori(encounter_xp * 0.5)
	check_eq(repeat_xp, 30, "50% repeat XP is 30")
	var repeat_ups: Array[LevelUp] = Progression.award(xp, party, repeat_xp, levels, classes)
	check_eq(xp[&"zayd"], 90, "zayd has 90 XP after repeat")
	check(repeat_ups.is_empty(), "no level up on repeat")


func test_merge_order_armor_before_hilt_and_agi_cap_99_with_growth() -> void:
	var state := GearState.new()
	state.base = _zayd_base()
	state.base.agility = 98
	state.class_def = _courier_class()
	state.level = 3
	var armor := ArmorDef.new()
	armor.id = &"souq_leather"
	armor.max_hp = 40
	armor.defense = 4
	armor.agility = -5
	state.armor = armor
	var hilt := HiltDef.new()
	hilt.id = &"swift_hilt"
	hilt.agility = 10
	hilt.cast_speed = 1.0
	state.hilt = hilt
	var out: CombatantDef = Gear.build_hero(&"zayd", state)
	check_eq(out.max_hp, 100 + 60 + 40, "base 100 + growth 60 + armor 40 = 200")
	check_eq(out.defense, 10 + 4 + 4, "base 10 + growth 4 + armor 4 = 18")
	check_eq(out.agility, 99, "98 + 2 growth - 5 armor + 10 hilt = 105, capped at 99")


func test_two_awards_with_different_levels_use_own_levels() -> void:
	var levels_low := LevelsDef.new()
	levels_low.xp_total = [0, 10, 20]
	var levels_high := LevelsDef.new()
	levels_high.xp_total = [0, 100, 200, 300]
	var xp: Dictionary[StringName, int] = {&"zayd": 0}
	var party: Array[StringName] = [&"zayd"]
	var classes: Dictionary[StringName, ClassDef] = {}
	Progression.award(xp, party, 15, levels_low, classes)
	check_eq(xp[&"zayd"], 15, "low def award adds 15 XP")
	Progression.award(xp, party, 95, levels_high, classes)
	check_eq(xp[&"zayd"], 110, "high def award adds 95 XP to 110 total")


func test_old_gear_build_gives_same_fighter_as_before() -> void:
	var base: CombatantDef = _zayd_base()
	var hilt := HiltDef.new()
	hilt.id = &"swift_hilt"
	hilt.agility = 1
	hilt.cast_speed = 1.0
	var blade := BladeDef.new()
	blade.id = &"keen_blade"
	blade.attack = 4
	blade.knockback = 200
	var out: CombatantDef = Gear.build(base, hilt, blade, null, {})
	check_eq(out.attack, base.attack + 4, "attack added")
	check_eq(out.agility, base.agility + 1, "agility added")
	check_eq(out.knockback_bonus, 200, "knockback added")
