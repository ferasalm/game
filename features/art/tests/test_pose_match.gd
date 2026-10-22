extends TestCase
## Retargeting (PoseMatch, PoseFollow): the swing turns one direction into another, the per-bone offset makes the
## target bone point where the source bone points (at rest and after a turn), the hips travel scales with hip height,
## and a pose_source model's body follows its hidden source (Zayd's Rodin model stands up with the hand below the head).


func test_swing_turns_from_into_to() -> void:
	var cases: Array[Array] = [[Vector3.UP, Vector3.RIGHT], [Vector3(1, 2, 3), Vector3(-2, 0.5, 1)],
		[Vector3.FORWARD, Vector3.BACK], [Vector3.UP, Vector3.UP]]
	for pair: Array in cases:
		var from: Vector3 = (pair[0] as Vector3).normalized()
		var to: Vector3 = (pair[1] as Vector3).normalized()
		check((PoseMatch.swing(from, to) * from).is_equal_approx(to), "swing %s -> %s" % [from, to])
	check(PoseMatch.swing(Vector3.ZERO, Vector3.UP).is_equal_approx(Basis.IDENTITY), "a zero vector swings nothing")


func test_offset_keeps_the_target_on_the_source_direction() -> void:
	var source_rest := Basis(Vector3(1, 0, 0), -PI * 0.5)  # Z-up axes, like the library rig
	var target_rest := Basis(Vector3(0, 0, 1), 0.3)
	var source_dir := Vector3(1, -0.6, 0)  # arms in an A-pose
	var target_dir := Vector3(0.3, -1, 0)  # arms nearly down
	var bone_axis: Vector3 = target_rest.inverse() * target_dir  # the direction in the target bone's own frame
	var k: Basis = PoseMatch.offset(source_rest, target_rest, source_dir, target_dir)
	check(((source_rest * k) * bone_axis).normalized().is_equal_approx(source_dir.normalized()),
		"at the source's rest the target bone points along the source bone")
	var turn := Basis(Vector3(0, 1, 1).normalized(), 0.8)
	var source_dir_now: Vector3 = turn * source_dir
	check((((turn * source_rest) * k) * bone_axis).normalized().is_equal_approx(source_dir_now.normalized()),
		"after the source turns, the target bone still points along it")


func test_hips_travel_scales_with_hip_height() -> void:
	var spot: Vector3 = PoseMatch.hips(Vector3(0, 1.0, 0), Vector3(0, 0.5, 0), Vector3(0.1, 0.4, 0))
	check(spot.is_equal_approx(Vector3(0.2, 0.8, 0)), "half the hip height on the source = double travel (%s)" % spot)


func test_a_pose_source_body_follows() -> void:
	var def := ContentDB.get_def("model", &"zayd") as ModelDef
	if def.pose_source.is_empty():
		return
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := ModelRig.new()
	check(rig.build(def, holder), "zayd builds with its pose source")
	check(rig.pose != null and rig.anim_skeleton != rig.skeleton, "the clips play on the hidden source")
	rig.player.play(&"Idle_Loop" if rig.player.has_animation(&"Idle_Loop") else rig.player.get_animation_list()[0])
	rig.player.advance(0.4)
	rig.follow()
	var hand: Vector3 = rig.bone_position("hand_r")
	var head: Vector3 = rig.bone_position("Head")
	var foot: Vector3 = rig.bone_position("foot_l")
	check(foot.y < hand.y and hand.y < head.y, "feet < hand < head after following (%s, %s, %s)" % [foot.y, hand.y, head.y])
	check(head.y > rig.native_height * 0.75, "the body stands up (head at %.2f of %.2f)" % [head.y, rig.native_height])
	holder.free()
