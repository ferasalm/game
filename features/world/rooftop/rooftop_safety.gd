class_name RooftopSafety
extends RefCounted
## Where the party may be put by the game: after a battle (the old spot if it is clear of every patrol, else the
## nearest clear walkable cell) and by "Unstuck" (the newest remembered still spot that is clear, else the nearest
## `safe` place). Remembers standing-still spots while they are clear of the patrols. Keeps the lane maths in
## PatrolSafety; this class only gathers the live patrol lanes and the area's cells.

var _rules: ExploreRulesDef
var _spots: SafeSpot
var _cells: Array[Vector3] = []
var _safe_places: Array[Vector3] = []
var _floor_y: float
var _still_radius: float


## The safety for an area: the cells reachable from `start` (a floor point) are the places the party may be put.
static func for_area(area: AreaDef, rules: ExploreRulesDef, flow: FlowRulesDef, start: Vector3) -> RooftopSafety:
	var reach: Dictionary[Vector2i, bool] = AreaWalk.build(area, rules).reachable(AreaWalk.cell_of(start))
	return RooftopSafety.new(area, rules, flow, start, AreaWalk.centers(reach, start.y))


## cells: floor points of the cells the party can reach (AreaWalk.centers); the area supplies the `safe` places.
func _init(area: AreaDef, rules: ExploreRulesDef, flow: FlowRulesDef, start: Vector3, cells: Array[Vector3]) -> void:
	_rules = rules
	_cells = cells
	_still_radius = flow.safe_still_radius
	_floor_y = start.y
	_spots = SafeSpot.new(flow.safe_idle_seconds, flow.safe_still_radius, start, rules.safe_ring)
	for place: PlaceDef in area.places_of(PlaceDef.SAFE):
		_safe_places.append(Vector3(place.pos.x, _floor_y, place.pos.z))


## Call every frame while exploring: a still spot is remembered only while no patrol is within touch range + 1 m.
func update(player_pos: Vector3, delta: float, patrols: Array[Patrol]) -> void:
	var lanes: Array[PackedVector3Array] = _lanes(patrols)
	if PatrolSafety.is_clear(player_pos, lanes, _rules.touch_radius + 1.0):
		_spots.update(player_pos, delta)


## The spot "Unstuck" puts the party at.
func unstuck_target(player_pos: Vector3, patrols: Array[Patrol]) -> Vector3:
	return PatrolSafety.unstuck_spot(player_pos, _spots.spots(), _safe_places, _lanes(patrols),
		_rules.unstuck_patrol_distance, _still_radius)


## Where the party stands once a battle is over (patrols already reset).
func return_spot(player_pos: Vector3, patrols: Array[Patrol]) -> Vector3:
	return PatrolSafety.return_spot(player_pos, _cells, _lanes(patrols), _rules.safe_return_distance)


func _lanes(patrols: Array[Patrol]) -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	for p: Patrol in patrols:
		if p.is_live():
			out.append(p.lane())
	return out
