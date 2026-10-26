class_name TestMapFormation
extends TestCase
## purpose: MapFormation puts the hero right-front of the contact and the foes left-back along the iso diagonal,
## 110 px apart, and keeps every spot on the prison roof's walkable floor.


func _room() -> NeonRoomDef:
	return ContentDB.get_def("neon_room", &"prison_roof") as NeonRoomDef


func test_spots_stay_on_the_floor() -> void:
	var room: NeonRoomDef = _room()
	var contact := Vector2(1450.0, 1000.0)
	var spots: Dictionary = MapFormation.spots(contact, 2, room.walk, room.holes)
	var hero: Vector2 = spots["hero"]
	var foes: Array[Vector2] = spots["foes"]
	check(IsoWalk.can_stand(hero, room.walk, room.holes), "hero spot is on the floor")
	check_eq(foes.size(), 2, "one spot per foe")
	for foe: Vector2 in foes:
		check(IsoWalk.can_stand(foe, room.walk, room.holes), "foe spot %s is on the floor" % foe)


func test_hero_is_right_front_and_foes_left_back() -> void:
	var room: NeonRoomDef = _room()
	var contact := Vector2(1450.0, 1000.0)
	var spots: Dictionary = MapFormation.spots(contact, 2, room.walk, room.holes)
	var hero: Vector2 = spots["hero"]
	var foes: Array[Vector2] = spots["foes"]
	check(hero.x > contact.x and hero.y > contact.y, "hero is right and down of the contact")
	for foe: Vector2 in foes:
		check(foe.x < hero.x and foe.y < hero.y, "foe %s is left-up of the hero" % foe)
	check(absf(hero.distance_to(contact) - MapFormation.HERO_OFFSET) < 1.0, "hero stands 120 px out")
	check(absf(foes[0].distance_to(foes[1]) - MapFormation.FOE_GAP) < 1.0, "foes stand 110 px apart")
