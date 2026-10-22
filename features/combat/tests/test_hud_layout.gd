extends TestCase
## HudLayout (pure rect maths) and UnitLetters: boxes around points, panels that dodge fighters, which fighter the mouse
## points at, the info card's fade, and the A / B letters of same-kind units.


func test_bounds_box_the_points() -> void:
	var box: Rect2 = HudLayout.bounds(PackedVector2Array([Vector2(10, 20), Vector2(30, 5), Vector2(15, 40)]))
	check_eq(box, Rect2(10, 5, 20, 35), "the smallest box")
	check_eq(HudLayout.bounds(PackedVector2Array()), Rect2(), "none gives an empty rect")


func test_touching_rects_do_not_overlap() -> void:
	var a := Rect2(0, 0, 10, 10)
	check_eq(HudLayout.overlap_area(a, [Rect2(10, 0, 10, 10)] as Array[Rect2]), 0.0, "edges only")
	check_eq(HudLayout.overlap_area(a, [Rect2(5, 5, 10, 10)] as Array[Rect2]), 25.0, "a corner")


func test_pick_takes_the_first_clear_place() -> void:
	var screen := Rect2(0, 0, 1000, 600)
	var anchor := Rect2(400, 300, 100, 200)
	var places: Array[Rect2] = HudLayout.beside(anchor, Vector2(200, 100), 10)
	check_eq(HudLayout.pick(places, [anchor] as Array[Rect2], screen), places[0], "right of the fighter when it is clear")
	var blocked: Array[Rect2] = [anchor, places[0]]
	check_eq(HudLayout.pick(places, blocked, screen), places[1], "else the next side")


func test_pick_keeps_the_panel_on_screen_and_falls_back_to_least_overlap() -> void:
	var screen := Rect2(0, 0, 500, 400)
	var wide: Array[Rect2] = [Rect2(450, 350, 200, 100)]
	check_eq(HudLayout.pick(wide, [] as Array[Rect2], screen), Rect2(300, 300, 200, 100), "shifted back inside")
	var everywhere: Array[Rect2] = [Rect2(0, 0, 500, 400)]
	var a: Array[Rect2] = [Rect2(0, 0, 100, 100), Rect2(300, 0, 100, 100)]
	var chosen: Rect2 = HudLayout.pick(a, everywhere, screen)
	check_eq(HudLayout.overlap_area(chosen, everywhere), 10000.0, "nothing is clear: still a place")


func test_hit_prefers_the_fighter_standing_lowest() -> void:
	var rects: Dictionary[StringName, Rect2] = {&"back": Rect2(0, 0, 100, 100), &"front": Rect2(20, 50, 100, 100)}
	check_eq(HudLayout.hit(rects, Vector2(50, 70)), &"front", "overlapping rects: the nearer one")
	check_eq(HudLayout.hit(rects, Vector2(10, 10)), &"back", "a point on one only")
	check_eq(HudLayout.hit(rects, Vector2(500, 500)), &"", "none")


func test_fade_holds_then_goes() -> void:
	check_eq(HudLayout.fade_alpha(0.5, 1.0, 0.4), 1.0, "within the delay")
	check(is_equal_approx(HudLayout.fade_alpha(1.2, 1.0, 0.4), 0.5), "half way through the fade")
	check_eq(HudLayout.fade_alpha(2.0, 1.0, 0.4), 0.0, "gone")


func test_letters_start_at_a() -> void:
	check_eq(HudLayout.letter(0), "A", "A")
	check_eq(HudLayout.letter(2), "C", "C")
	check_eq(HudLayout.letter(26), "A", "wraps")


func test_only_same_kind_units_get_letters() -> void:
	var units: Array[UnitState] = []
	for entry: Array in [[&"enforcer", 1], [&"enforcer", 1], [&"drone", 1], [&"hero", 0]]:
		var def := CombatantDef.new()
		def.id = entry[0]
		var unit := UnitState.new()
		unit.def = def
		unit.side = entry[1]
		units.append(unit)
	check_eq(UnitLetters.of(units, units[0]), "A", "first enforcer")
	check_eq(UnitLetters.of(units, units[1]), "B", "second enforcer")
	check_eq(UnitLetters.of(units, units[2]), "", "a lone drone")
	check_eq(UnitLetters.of(units, units[3]), "", "a lone hero")
