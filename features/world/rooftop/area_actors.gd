class_name AreaActors
extends RefCounted
## The living things of an area, built from its markers and places: Zayd, Bilqis, one Patrol per patrol place, the
## workshop bench, the herb stall and its seller, the sabil, crossings, doors and valves. Rooftop wires the signals.

var player: Player
var follower: Follower
var patrols: Array[Patrol] = []
var workshop: WorkshopSpot
var stalls: Array[StallSpot] = []
var sabil: SabilSpot
var talk_spots: Array[TalkSpot] = []
var bystanders: Array[Bystander] = []
var bystander_places: Array[PlaceDef] = []
var crossings: Array[CrossingSpot] = []
var doors: Array[DoorSpot] = []
var valves: Array[ValveSpot] = []
var puzzle: PuzzleBoard


static func build(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> AreaActors:
	var out := AreaActors.new()
	out.player = Player.new(rules)
	out.player.position = marker_of(area, AreaDef.SPAWN, floor_y)
	parent.add_child(out.player)
	out.follower = Follower.new(rules, out.player)
	parent.add_child(out.follower)
	for place: PlaceDef in area.places_of(PlaceDef.PATROL):
		var py: float = _floor_at(area, place.pos.x, place.pos.z, floor_y)
		var patrol := Patrol.new(rules, place, py, out.player)
		out.patrols.append(patrol)
		parent.add_child(patrol)
	var workshop_place: PlaceDef = area.place(&"workshop")
	if workshop_place != null or area.find_marker(AreaDef.WORKSHOP) != Vector2i(-1, -1):
		out.workshop = WorkshopSpot.new(rules, out.player, workshop_place)
		if workshop_place != null:
			out.workshop.position = _at(area, workshop_place, floor_y)
			out.workshop.rotation.y = deg_to_rad(workshop_place.yaw)
		else:
			out.workshop.position = marker_of(area, AreaDef.WORKSHOP, floor_y)
		parent.add_child(out.workshop)
	out._add_places(parent, area, rules, floor_y)
	out._add_crossings(parent, area, rules, floor_y)
	return out


## Every actor that switches off during a battle or menu (all but the people standing about).
func switchables() -> Array[Node]:
	var out: Array[Node] = [player, follower]
	if workshop != null:
		out.append(workshop)
	out.append_array(patrols)
	out.append_array(stalls)
	out.append_array(talk_spots)
	out.append_array(crossings)
	out.append_array(doors)
	out.append_array(valves)
	if puzzle != null:
		out.append_array(puzzle.level_spots)
	if sabil != null:
		out.append(sabil)
	return out


func _add_places(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> void:
	var lift: float = rules.prompt_height + rules.capsule_height
	for place: PlaceDef in area.places_of(PlaceDef.SHOP):
		var stall := StallSpot.new(rules, player, place.shop, "PROMPT_TALK", lift)
		stall.position = _at(area, place, floor_y)
		stalls.append(stall)
		parent.add_child(stall)
	for place: PlaceDef in area.places_of(PlaceDef.SAVE):
		sabil = SabilSpot.new(rules, player, place.id, "SABIL_PROMPT", lift)
		sabil.position = _at(area, place, floor_y)
		parent.add_child(sabil)
	for place: PlaceDef in area.places_of(PlaceDef.NPC):
		_add_npc(parent, area, rules, floor_y, place, lift)
	for place: PlaceDef in area.places_of(PlaceDef.DOOR):
		var door := DoorSpot.new(rules, player, place, lift)
		door.position = _at(area, place, floor_y)
		doors.append(door)
		parent.add_child(door)
		if parent is Rooftop:
			door.entered.connect((parent as Rooftop).door_entered.emit)
	for place: PlaceDef in area.places_of(PlaceDef.VALVE):
		var valve := ValveSpot.new(rules, player, place, lift)
		valve.position = _at(area, place, floor_y)
		valves.append(valve)
		parent.add_child(valve)
		if place.id == &"valve_water":
			puzzle = PuzzleBoard.new(true)
			parent.add_child(puzzle)
			puzzle.setup_level(valve.position, rules, player, parent)
			valve.set_puzzle(puzzle)


func _add_npc(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float, place: PlaceDef,
		lift: float) -> void:
	var counter: Placement = kept_prop(area, place)
	var at: Vector3 = _at(area, place, floor_y) if counter == null else keeper_point(counter, rules, floor_y)
	var yaw: float = place.yaw
	if counter != null:
		yaw = StallKeeper.facing(Vector2(at.x, at.z), Vector2(place.pos.x, place.pos.z))
	var person := Bystander.new(place.sprite, yaw)
	person.position = at
	bystanders.append(person)
	bystander_places.append(place)
	parent.add_child(person)
	var spot := TalkSpot.new(rules, player, place.id, "PROMPT_TALK", lift)
	spot.position = _at(area, place, floor_y)
	talk_spots.append(spot)
	parent.add_child(spot)


func _add_crossings(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> void:
	var rooftop: Rooftop = parent as Rooftop
	for place: PlaceDef in area.places_of(PlaceDef.CROSSING):
		var y_from: float = _floor_at(area, place.from_pos.x, place.from_pos.y, floor_y)
		var y_to: float = _floor_at(area, place.to_pos.x, place.to_pos.y, floor_y)
		var p_from := Vector3(place.from_pos.x, y_from, place.from_pos.y)
		var p_to := Vector3(place.to_pos.x, y_to, place.to_pos.y)
		var spot := CrossingSpot.new(rules, player, place, p_from, p_to, rooftop)
		crossings.append(spot)
		parent.add_child(spot)


## The prop an NPC keeps (his place's `prop`, the nearest placement of it), or null: he then stands on his place.
static func kept_prop(area: AreaDef, place: PlaceDef) -> Placement:
	var best: Placement = null
	for p: Placement in area.props:
		if p.ref == place.prop and (best == null or _flat(p.pos, place.pos) < _flat(best.pos, place.pos)):
			best = p
	return best


## Where a keeper stands: at the end of his counter, clear of its collide box (StallKeeper), facing his place.
static func keeper_point(counter: Placement, rules: ExploreRulesDef, floor_y: float) -> Vector3:
	var def := ContentDB.get_def("prop", counter.ref) as PropDef
	var at := Vector2(counter.pos.x, counter.pos.z)
	var spot: Vector2 = StallKeeper.at_end(at, counter.yaw, def.collide, rules.capsule_radius, rules.keeper_gap)
	return Vector3(spot.x, floor_y, spot.y)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _floor_at(area: AreaDef, x: float, z: float, default_floor: float) -> float:
	var cx: int = floori(x)
	var cz: int = floori(z)
	if cx >= 0 and cz >= 0 and cx < area.width() and cz < area.depth():
		var tile := ContentDB.get_def("tile", area.tile_id_at(cx, cz)) as TileDef
		if tile != null and not tile.hidden and not tile.solid:
			return tile.height
	return default_floor


static func _at(area: AreaDef, place: PlaceDef, floor_y: float) -> Vector3:
	var fy: float = _floor_at(area, place.pos.x, place.pos.z, floor_y)
	return Vector3(place.pos.x, fy, place.pos.z)


static func marker_of(area: AreaDef, marker: String, floor_y: float) -> Vector3:
	return AreaBuilder.cell_center(area.find_marker(marker)) + Vector3(0.0, floor_y, 0.0)
