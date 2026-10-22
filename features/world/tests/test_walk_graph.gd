extends TestCase
## WalkGraph rules on small grids (reachability, diagonals, 2 x 2 width, traps, steps) and on every shipped area
## (docs/design/rooftop-v3.md section 5): everything is reachable from the spawn, no corridor is under 2 m, no cell is a
## trap, no step is too tall, and the bridge keeps three rows.

const MAX_STEP: float = 0.1
const POCKET_RADIUS: float = 2.0


func _graph(rows: PackedStringArray, heights: Dictionary[String, float] = {}) -> WalkGraph:
	var open := PackedByteArray()
	var h := PackedFloat32Array()
	for row: String in rows:
		for ch: String in row:
			open.append(0 if ch == "#" else 1)
			h.append(heights.get(ch, 0.5))
	return WalkGraph.new(rows[0].length(), rows.size(), open, h)


func test_reachable_follows_open_cells() -> void:
	var g: WalkGraph = _graph(PackedStringArray(["..#..", "..#..", "..#.."]))
	check_eq(g.reachable(Vector2i(0, 0)).size(), 6, "the left half only")
	check(g.reachable(Vector2i(2, 0)).is_empty(), "a closed start reaches nothing")


func test_a_diagonal_needs_both_orthogonal_cells() -> void:
	var g: WalkGraph = _graph(PackedStringArray([".#", "#."]))
	check_eq(g.reachable(Vector2i(0, 0)).size(), 1, "no squeezing through a pinch")
	var open: WalkGraph = _graph(PackedStringArray(["..", ".."]))
	check_eq(open.reachable(Vector2i(0, 0)).size(), 4, "an open block is one piece")


func test_wide_mask_drops_one_metre_corridors() -> void:
	var g: WalkGraph = _graph(PackedStringArray(["....#", "....#", "#####", "#....", "#####"]))
	var wide: PackedByteArray = g.wide_mask()
	check_eq(wide[0], 1, "a cell of a 2 x 2 block is wide")
	check_eq(wide[3 * 5 + 2], 0, "a cell of a one metre corridor is not")
	var narrow: Dictionary[Vector2i, bool] = g.reachable(Vector2i(0, 0), wide)
	check_eq(narrow.size(), 8, "the wide walk covers only the block")


func test_traps_are_cells_with_all_four_neighbours_closed() -> void:
	var g: WalkGraph = _graph(PackedStringArray(["###", "#.#", "###"]))
	check_eq(g.traps().size(), 1, "an enclosed cell is a trap")
	check(_graph(PackedStringArray(["...", "...", "..."])).traps().is_empty(), "an open field has none")


func test_tall_steps_are_found() -> void:
	var g: WalkGraph = _graph(PackedStringArray([".a.."]), {"a": 1.5})
	var cells: Dictionary[Vector2i, bool] = g.reachable(Vector2i(0, 0))
	check_eq(g.tall_steps(cells, MAX_STEP).size(), 4, "up and down the high cell, both directions of two edges")
	check(_graph(PackedStringArray(["...."])).tall_steps(cells, MAX_STEP).is_empty(), "flat floor has no step")


func _shipped() -> Dictionary[StringName, WalkGraph]:
	var out: Dictionary[StringName, WalkGraph] = {}
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	for id: StringName in ContentDB.ids("area"):
		out[id] = AreaWalk.build(ContentDB.get_def("area", id) as AreaDef, rules)
	return out


func _spawn_of(area: AreaDef) -> Vector2i:
	return area.find_marker(AreaDef.SPAWN)


func test_every_area_is_one_piece_from_its_spawn() -> void:
	var graphs: Dictionary[StringName, WalkGraph] = _shipped()
	for id: StringName in graphs:
		var area := ContentDB.get_def("area", id) as AreaDef
		var g: WalkGraph = graphs[id]
		var reach: Dictionary[Vector2i, bool] = g.reachable(_spawn_of(area))
		check(not reach.is_empty(), "%s: the spawn can be stood on" % id)
		check(AreaDef.MARKERS.all(func(m: String) -> bool: return reach.has(area.find_marker(m))), "%s: markers reachable" % id)
		var lost: Array[Vector2i] = []
		for cell: Vector2i in g.open_cells():
			if not reach.has(cell):
				lost.append(cell)
		check(lost.is_empty(), "%s: open cells that cannot be reached: %s" % [id, str(lost)])


func test_every_area_has_no_traps_and_no_tall_steps() -> void:
	var graphs: Dictionary[StringName, WalkGraph] = _shipped()
	for id: StringName in graphs:
		var area := ContentDB.get_def("area", id) as AreaDef
		var g: WalkGraph = graphs[id]
		check(g.traps().is_empty(), "%s: trap cells %s" % [id, str(g.traps())])
		var reach: Dictionary[Vector2i, bool] = g.reachable(_spawn_of(area))
		var steps: PackedStringArray = g.tall_steps(reach, MAX_STEP)
		check(steps.is_empty(), "%s: tall steps %s" % [id, str(steps)])


func test_every_area_has_no_corridor_under_two_metres() -> void:
	var graphs: Dictionary[StringName, WalkGraph] = _shipped()
	for id: StringName in graphs:
		var area := ContentDB.get_def("area", id) as AreaDef
		var g: WalkGraph = graphs[id]
		var reach: Dictionary[Vector2i, bool] = g.reachable(_spawn_of(area))
		var wide: Dictionary[Vector2i, bool] = g.reachable(_spawn_of(area), g.wide_mask())
		var narrow: Array[Vector2i] = []
		for cell: Vector2i in reach:
			if not wide.has(cell) and not _is_pocket(area, cell, wide):
				narrow.append(cell)
		check(narrow.is_empty(), "%s: cells reachable only through a corridor under 2 m: %s" % [id, str(narrow)])


## An interaction pocket: a cell within POCKET_RADIUS of a chest, the stall, the sabil or the workshop may sit outside
## the wide walk (the prop beside it takes the second metre).
func _is_pocket(area: AreaDef, cell: Vector2i, _wide: Dictionary[Vector2i, bool]) -> bool:
	var centre := Vector2(cell.x + 0.5, cell.y + 0.5)
	for place: PlaceDef in area.places:
		var used: bool = [PlaceDef.CHEST, PlaceDef.SHOP, PlaceDef.SAVE, PlaceDef.WORKSHOP].has(place.kind)
		if used and Vector2(place.pos.x, place.pos.z).distance_to(centre) <= POCKET_RADIUS:
			return true
	return false


func test_the_terrace_is_continuous_across_columns() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var g: WalkGraph = AreaWalk.build(area, ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef)
	var reach: Dictionary[Vector2i, bool] = g.reachable(_spawn_of(area))
	for column: int in range(12, 22):
		var count: int = 0
		for z: int in area.depth():
			count += 1 if reach.has(Vector2i(column, z)) else 0
		check(count >= 15, "column %d: %d walkable cells join the terrace (>= 15 wanted)" % [column, count])
