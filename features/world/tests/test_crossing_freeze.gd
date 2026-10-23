class_name TestCrossingFreeze
extends TestCase
## Bug 2026-10-24: pressing E at a crossing froze the party for good and Unstuck could not free it.

const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")


func _rooftop(host: Node3D) -> Rooftop:
	var rooftop := ROOFTOP_SCENE.instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops_v4"
	host.add_child(rooftop)
	return rooftop


func _first_crossing(node: Node) -> CrossingSpot:
	for child: Node in node.get_children():
		if child is CrossingSpot:
			return child as CrossingSpot
		var found: CrossingSpot = _first_crossing(child)
		if found != null:
			return found
	return null


func test_crossing_fade_runs_while_actors_are_frozen() -> void:
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop: Rooftop = _rooftop(host)
	var spot: CrossingSpot = _first_crossing(rooftop)
	check(spot != null, "souq_rooftops_v4 has a crossing")
	rooftop.freeze_actors(true)
	check(not spot.can_process(), "the crossing freezes with the actors")
	check(spot.fade_owner().can_process(), "the fade tween's node still processes, so the party is unfrozen after")
	host.free()


func test_unstuck_unfreezes_the_party() -> void:
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop: Rooftop = _rooftop(host)
	rooftop.freeze_actors(true)
	RooftopPort.new(rooftop, host).unfreeze()
	check(rooftop.player.can_process(), "Unstuck lifts a freeze left by a crossing or talk")
	host.free()
