extends TestCase
## Tests for HpClamp: damage never takes hp below 0 and healing never lifts it above max_hp (proof run, row 26).


func test_damage_stops_at_zero() -> void:
	check_eq(HpClamp.after_damage(10, 4), 6, "10 hp, 4 damage")
	check_eq(HpClamp.after_damage(3, 10), 0, "damage past zero stops at 0")
	check_eq(HpClamp.after_damage(0, 5), 0, "already at 0")
	check_eq(HpClamp.after_damage(5, 0), 5, "no damage")
	check_eq(HpClamp.after_damage(5, -3), 5, "negative damage is ignored, it never heals")


func test_heal_stops_at_max() -> void:
	check_eq(HpClamp.after_heal(5, 3, 10), 8, "5 hp, heal 3, max 10")
	check_eq(HpClamp.after_heal(9, 5, 10), 10, "heal past max stops at max")
	check_eq(HpClamp.after_heal(10, 1, 10), 10, "already at max")
	check_eq(HpClamp.after_heal(5, -2, 10), 5, "negative heal is ignored, it never damages")
	check_eq(HpClamp.after_heal(12, 1, 10), 10, "hp above max is pulled back to max")
