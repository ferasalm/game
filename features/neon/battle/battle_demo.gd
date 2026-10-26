class_name BattleDemo
extends Node2D
## purpose: The battle demo scene (docs/design/first-playable.md section 3): the prison-roof plate, a y-sorted
## world with Rydan and two guards, and a MapBattle that begins on ready at the contact between them.

const ROOM_ID: StringName = &"prison_roof"
const CONTACT: Vector2 = Vector2(1450.0, 1000.0)

var battle: MapBattle


func _ready() -> void:
	var room := ContentDB.get_def("neon_room", ROOM_ID) as NeonRoomDef
	if room == null:
		push_error("BattleDemo: no neon_room '%s'" % ROOM_ID)
		return
	var plate := Sprite2D.new()
	plate.name = "Plate"
	plate.texture = load(room.plate) as Texture2D
	plate.centered = false
	add_child(plate)
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	var hero := IsoActor.new()
	hero.name = "Rydan"
	hero.setup(&"rydan")
	hero.position = room.spawn
	world.add_child(hero)
	var foes: Array[IsoActor] = []
	for i: int in mini(2, room.guards.size()):
		var foe := IsoActor.new()
		foe.name = "Guard%d" % (i + 1)
		foe.setup(&"guard")
		foe.position = (room.guards[i]["path"] as PackedVector2Array)[0]
		world.add_child(foe)
		foes.append(foe)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = CONTACT
	add_child(camera)
	camera.make_current()
	battle = MapBattle.new()
	battle.name = "MapBattle"
	add_child(battle)
	battle.begin(world, room, hero, foes, CONTACT, false)
