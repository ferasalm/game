class_name AreaActors
extends RefCounted
## The living things of an area, built from its markers and places: Zayd, Bilqis, one Patrol per patrol place, the
## workshop bench, the herb stall and its seller, and the sabil. Every node is added to `parent`; their positions
## are area positions. Rooftop wires the signals.

var player: Player
var follower: Follower
var patrols: Array[Patrol] = []
var workshop: WorkshopSpot
var stalls: Array[StallSpot] = []
var sabil: SabilSpot
var talk_spots: Array[TalkSpot] = []
var bystanders: Array[Bystander] = []
var bystander_places: Array[PlaceDef] = []


static func build(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> AreaActors:
	var out := AreaActors.new()
	out.player = Player.new(rules)
	out.player.position = marker_of(area, AreaDef.SPAWN, floor_y)
	parent.add_child(out.player)
	out.follower = Follower.new(rules, out.player)
	parent.add_child(out.follower)
	for place: PlaceDef in area.places_of(PlaceDef.PATROL):
		var patrol := Patrol.new(rules, place, floor_y, out.player)
		out.patrols.append(patrol)
		parent.add_child(patrol)
	out.workshop = WorkshopSpot.new(rules, out.player)
	out.workshop.position = marker_of(area, AreaDef.WORKSHOP, floor_y)
	parent.add_child(out.workshop)
	out._add_places(parent, area, rules, floor_y)
	return out


## Every actor that switches off during a battle or menu (all but the people standing about).
func switchables() -> Array[Node]:
	var out: Array[Node] = [player, follower, workshop]
	out.append_array(patrols)
	out.append_array(stalls)
	out.append_array(talk_spots)
	if sabil != null:
		out.append(sabil)
	return out


func _add_places(parent: Node3D, area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> void:
	var lift: float = rules.prompt_height + rules.capsule_height
	for place: PlaceDef in area.places_of(PlaceDef.SHOP):
		var stall := StallSpot.new(rules, player, place.shop, "PROMPT_TALK", lift)
		stall.position = _at(place, floor_y)
		stalls.append(stall)
		parent.add_child(stall)
	for place: PlaceDef in area.places_of(PlaceDef.SAVE):
		sabil = SabilSpot.new(rules, player, place.id, "SABIL_PROMPT", lift)
		sabil.position = _at(place, floor_y)
		parent.add_child(sabil)
	for place: PlaceDef in area.places_of(PlaceDef.NPC):
		var person := Bystander.new(place.sprite, place.yaw)
		person.position = _at(place, floor_y)
		bystanders.append(person)
		bystander_places.append(place)
		parent.add_child(person)
		var spot := TalkSpot.new(rules, player, place.id, "PROMPT_TALK", lift)
		spot.position = _at(place, floor_y)
		talk_spots.append(spot)
		parent.add_child(spot)


static func _at(place: PlaceDef, floor_y: float) -> Vector3:
	return Vector3(place.pos.x, floor_y, place.pos.z)


static func marker_of(area: AreaDef, marker: String, floor_y: float) -> Vector3:
	return AreaBuilder.cell_center(area.find_marker(marker)) + Vector3(0.0, floor_y, 0.0)
