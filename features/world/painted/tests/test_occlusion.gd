extends TestCase
## The camera cut-away: the segment-vs-box helper (hits, misses, grazing, a segment that ends inside), the tube weight
## (inside, soft edge, the party's own margin, the floor), the box list of tall instances, the fade easing, and a
## painted rooftop whose camera line is blocked by the mafraj (the cut amount rises) and clear in the open (it falls).


func test_segment_box_hits_and_misses() -> void:
	var box := AABB(Vector3(-1.0, 0.0, -1.0), Vector3(2.0, 3.0, 2.0))
	check(SegmentBox.hits(Vector3(0.0, 8.0, 8.0), Vector3(0.0, 1.0, -4.0), box), "a line through the box hits")
	check(not SegmentBox.hits(Vector3(5.0, 8.0, 8.0), Vector3(5.0, 1.0, -4.0), box), "a line beside it misses")
	check(not SegmentBox.hits(Vector3(0.0, 8.0, 8.0), Vector3(0.0, 6.0, 4.0), box), "a segment that stops short misses")
	check(SegmentBox.hits(Vector3(0.0, 8.0, 8.0), Vector3(0.0, 1.5, 0.0), box), "a segment that ends inside hits")
	check(not SegmentBox.hits(Vector3(1.4, 8.0, 0.0), Vector3(1.4, 1.0, 0.0), box), "just outside the side misses")
	check(SegmentBox.hits(Vector3(1.4, 8.0, 0.0), Vector3(1.4, 1.0, 0.0), box, 0.5), "...but hits with padding")
	check(SegmentBox.hits(Vector3(0.0, 5.0, 0.0), Vector3(0.0, 5.0, 0.0), AABB(Vector3(-1, 4, -1), Vector3(2, 2, 2))),
		"a zero-length segment inside the box hits")
	check(not SegmentBox.hits(Vector3(0.0, 9.0, 0.0), Vector3(0.0, 9.0, 0.0), box), "a zero-length segment outside misses")
	check(SegmentBox.any_hit(Vector3(0.0, 8.0, 8.0), Vector3(0.0, 1.0, -4.0), [AABB(Vector3(9, 0, 9), Vector3.ONE), box]),
		"any_hit finds the second box")
	check(not SegmentBox.any_hit(Vector3(0.0, 8.0, 8.0), Vector3(0.0, 1.0, -4.0), []), "no boxes, no hit")


func test_boxes_of_keeps_only_tall_instances() -> void:
	var local := AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)
	var low := Transform3D(Basis.from_scale(Vector3(1.0, 0.4, 1.0)), Vector3(0.0, 0.0, 0.0))
	var tall := Transform3D(Basis.from_scale(Vector3(1.0, 3.0, 1.0)), Vector3(4.0, 0.0, 0.0))
	var boxes: Array[AABB] = SegmentBox.boxes_of(local, [low, tall], 0.0, 1.2)
	check_eq(boxes.size(), 1, "the low tile is not a blocker")
	check(absf(boxes[0].end.y - 3.0) < 0.001 and absf(boxes[0].position.x - 3.5) < 0.001, "the tall one is placed in the world")


func test_tube_weight() -> void:
	var cam := Vector3(0.0, 12.0, 12.0)
	var focus := Vector3(0.0, 1.0, 0.0)
	var mid: Vector3 = cam.lerp(focus, 0.5)
	check_eq(SegmentBox.tube_weight(mid, cam, focus, 2.4, 1.4, 2.5), 1.0, "on the line: fully cut")
	check_eq(SegmentBox.tube_weight(mid + Vector3(6.0, 0.0, 0.0), cam, focus, 2.4, 1.4, 2.5), 0.0, "far off the line: not cut")
	var edge: float = SegmentBox.tube_weight(mid + Vector3(3.0, 0.0, 0.0), cam, focus, 2.4, 1.4, 2.5)
	check(edge > 0.0 and edge < 1.0, "in the soft edge: part cut")
	check_eq(SegmentBox.tube_weight(focus + Vector3(0.0, 0.2, 0.3), cam, focus, 2.4, 1.4, 2.5), 0.0, "next to the party: kept")
	check_eq(SegmentBox.tube_weight(mid, cam, focus, 2.4, 1.4, 2.5, 100.0), 0.0, "below the floor line: kept")
	check_eq(SegmentBox.tube_weight(cam, cam, cam, 2.4, 1.4, 2.5), 0.0, "a degenerate line cuts nothing")


func test_eased_moves_by_speed() -> void:
	check(is_equal_approx(SegmentBox.eased(0.0, 1.0, 6.0, 0.1), 0.6), "rises by speed * delta")
	check_eq(SegmentBox.eased(0.9, 1.0, 6.0, 0.1), 1.0, "stops at the target")
	check(is_equal_approx(SegmentBox.eased(0.5, 0.0, 2.0, 0.1), 0.3), "falls too")


func test_painted_rooftop_cuts_when_blocked() -> void:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.look_id = &"painted_b"
	tree.root.add_child(rooftop)
	var fade: OcclusionFade = OcclusionFade.of(rooftop)
	check(fade != null, "a painted look adds the cut-away")
	if fade == null:
		rooftop.free()
		return
	check(fade.box_count() > 0, "it found tall blocks")
	var player_at := Vector3(3.0, 0.5, 9.0)
	var eye := Vector3(3.0, 17.0, 20.5)
	check(fade.is_blocked(eye, player_at + Vector3(0.0, 1.2, 0.0)), "the mafraj stands between a southern camera and its north side")
	var open := Vector3(9.0, 0.5, 8.0)
	check(not fade.is_blocked(open + Vector3(0.0, 16.0, 11.5), open + Vector3(0.0, 1.2, 0.0)), "the open yard is clear")
	rooftop.free()
	PaintedMaterials.use(null)
	tree.root.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
