extends TestCase
## How a fight starts: carried vitals fill the units, and a hero with no entry starts full.


func test_carried_vitals_fill_the_units() -> void:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB, &"patrol_scouts")
	var setup: BattleSetup = loader.make_setup(loader.party_from_equipment({}), 5)
	setup.vitals = {&"zayd": {"hp": 120, "sp": 5}}
	var sim: BattleSim = BattleSim.create_from(setup)
	var zayd: UnitState = sim.timeline.find(&"zayd")
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	check_eq(zayd.hp, 120, "the carried HP")
	check_eq(zayd.sp, 5, "and the carried SP")
	check_eq(bilqis.hp, bilqis.def.max_hp, "a hero with no entry is full")
	check_eq(bilqis.sp, bilqis.def.max_sp, "and has full SP")
