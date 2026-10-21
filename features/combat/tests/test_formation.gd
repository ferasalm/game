extends TestCase
## Formation rows: cover and melee multipliers.


func test_cover() -> void:
	check(Formation.is_covered(2, [0, 2]), "slot 2 is covered by a living slot 0")
	check(not Formation.is_covered(3, [0, 3]), "slot 3 is open when slot 1 is empty")
	check(not Formation.is_covered(0, [0, 1, 2, 3]), "the vanguard is never covered")


func test_melee_multiplier() -> void:
	check_eq(Formation.melee_multiplier(0, 0, BattleRulesDef.new()), 1.15, "front hits front")
	check_eq(Formation.melee_multiplier(3, 3, BattleRulesDef.new()), 0.7, "back hits back")
