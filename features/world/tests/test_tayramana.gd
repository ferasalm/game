class_name TestTayramana
extends TestCase
## purpose: Tests for Tayramana room: def parsing, prop building, enter/leave transition, input locks, and qishr sit rewards.

const TAYRAMANA_ID: StringName = &"tayramana"
const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")


func _spec() -> RoomDef:
	return ContentDB.get_def("room", TAYRAMANA_ID) as RoomDef


func _palette() -> PaletteDef:
	return ContentDB.get_def("palette", &"main") as PaletteDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _rig() -> CameraRigDef:
	return ContentDB.get_def("camera_rig", &"explore") as CameraRigDef


func _clean() -> void:
	PaintedMaterials.use(null)
	PropMesh.clear()
	SurfaceMaterials.clear()


func test_room_def_parses() -> void:
	var def: RoomDef = _spec()
	check(def != null, "tayramana room def loaded from rooms.json")
	check_eq(def.size, Vector3(7.0, 3.0, 5.0), "room size is 7 x 3 x 5 m")
	check_eq(def.wall_color, "w", "wall color letter is w")
	check_eq(def.trim_color, "q", "trim color letter is q")
	check(def.qamariya_walls.has("north") and def.qamariya_walls.has("east") and def.qamariya_walls.has("west"),
		"qamariya arches on three walls")
	check_eq(def.entry_pos, Vector3(3.5, 0.0, 4.0), "entry pos inside south door")
	check_eq(def.exit_pos, Vector3(30.5, 1.6, 4.5), "exit pos outside on R3")
	check_eq(def.shots.size(), 2, "two framed camera shots")
	check_eq(def.shots[0].id, &"shot_door", "shot 1 is door corner")
	check_eq(def.shots[1].id, &"shot_window", "shot 2 is window corner")
	check_eq(def.sit_spots.size(), 2, "two sit spots")
	check(def.props.size() >= 10, "props defined: %d" % def.props.size())


func test_builder_makes_every_prop() -> void:
	var def: RoomDef = _spec()
	var node: Node3D = RoomBuilder.build(def, _palette())
	check(node != null, "builder created room node")
	var shell_found: bool = false
	var props_node: Node = null
	for child: Node in node.get_children():
		if child.name == "RoomShell":
			shell_found = true
		elif child.name == "Props":
			props_node = child
	check(shell_found, "room has shell geometry")
	check(props_node != null, "room has props node")
	var unique_refs: Dictionary = {}
	for p: Placement in def.props:
		unique_refs[p.ref] = true
	var child_names: Dictionary = {}
	if props_node != null:
		for child: Node in props_node.get_children():
			child_names[child.name] = true
	for ref: StringName in unique_refs:
		var has_prop: bool = child_names.has(String(ref))
		check(has_prop, "prop %s was built into room" % ref)
	check(child_names.has("Collision"), "props have static collisions")
	node.free()
	_clean()


func test_enter_and_leave_move_party_and_restore_rooftop() -> void:
	if GameState.party.is_empty():
		GameState.start_new()
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop := ROOFTOP_SCENE.instantiate() as Rooftop
	host.add_child(rooftop)
	var port := RooftopPort.new(rooftop, host)
	var dlg := DialogueBox.new()
	host.add_child(dlg)
	var flow := TayramanaFlow.new()
	flow.setup(host, rooftop, port, dlg)
	flow.enter_room(&"tayramana", 0.0)
	check(flow.is_in_room(), "entered room")
	check(not rooftop.visible, "rooftop is hidden like battle")
	check_eq(flow.room.player.position, _spec().entry_pos, "player placed at entry pos")
	flow.exit_room(0.0)
	check(not flow.is_in_room(), "left room")
	check(rooftop.visible, "rooftop is restored")
	check_eq(rooftop.player.position, _spec().exit_pos, "party moved to exit pos on R3")
	host.free()
	_clean()


func test_input_locked_during_fades_and_talk() -> void:
	if GameState.party.is_empty():
		GameState.start_new()
	Router.enter_exploring()
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop := ROOFTOP_SCENE.instantiate() as Rooftop
	host.add_child(rooftop)
	var port := RooftopPort.new(rooftop, host)
	var dlg := DialogueBox.new()
	host.add_child(dlg)
	var flow := TayramanaFlow.new()
	flow.setup(host, rooftop, port, dlg)
	flow.enter_room(&"tayramana", 0.0)
	flow.on_sit_interacted(&"sit_zayd")
	check(Router.state == Router.STATE_BUSY, "Router is busy during talk")
	flow.handle_dialogue_finished(&"tayramana_qishr_first")
	check(Router.state != Router.STATE_BUSY, "Router leaves busy state after talk")
	host.free()
	_clean()


func test_first_sit_gives_two_qishr_once_and_persists_across_save_load() -> void:
	GameState.start_new()
	check_eq(GameState.bag.get(&"qishr_cup", 0), 0, "starts with 0 qishr")
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop := ROOFTOP_SCENE.instantiate() as Rooftop
	host.add_child(rooftop)
	var port := RooftopPort.new(rooftop, host)
	var dlg := DialogueBox.new()
	host.add_child(dlg)
	var flow := TayramanaFlow.new()
	flow.setup(host, rooftop, port, dlg)
	flow.enter_room(&"tayramana", 0.0)
	flow.on_sit_interacted(&"sit_zayd")
	check_eq(GameState.bag.get(&"qishr_cup", 0), 2, "first sit gives 2 qishr")
	check(bool(GameState.flags.get(&"tayramana_qishr_rewarded", false)), "reward flag recorded")
	var saved: Dictionary = GameState.to_dict()
	GameState.start_new()
	GameState.from_dict(saved)
	check_eq(GameState.bag.get(&"qishr_cup", 0), 2, "still 2 qishr after load")
	check(bool(GameState.flags.get(&"tayramana_qishr_rewarded", false)), "reward flag preserved across load")
	flow.on_sit_interacted(&"sit_zayd")
	check_eq(GameState.bag.get(&"qishr_cup", 0), 2, "second sit gives no additional qishr")
	host.free()
	_clean()


## Bug 2026-10-24: interact-focus-3 rewired the workbench straight to InteractFocus, so the first-visit talk and the
## bench stock (prototype_main._on_workshop_opened) never ran. The bench must reach the flow's workshop_opened.
func test_room_workbench_reaches_workshop_opened() -> void:
	if GameState.party.is_empty():
		GameState.start_new()
	var host := Node3D.new()
	tree.root.add_child(host)
	var rooftop := ROOFTOP_SCENE.instantiate() as Rooftop
	host.add_child(rooftop)
	var dlg := DialogueBox.new()
	host.add_child(dlg)
	var flow := TayramanaFlow.new()
	flow.setup(host, rooftop, RooftopPort.new(rooftop, host), dlg)
	flow.enter_room(&"tayramana", 0.0)
	var opened: Array[bool] = []
	flow.workshop_opened.connect(func() -> void: opened.append(true))
	flow.room.workshop.opened.emit()
	check_eq(opened.size(), 1, "the room's workbench reaches prototype_main through workshop_opened")
	host.free()
	_clean()
