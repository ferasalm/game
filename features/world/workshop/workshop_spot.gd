class_name WorkshopSpot
extends InteractSpot
## The workshop bench: a jambiyah smith's workbench built from the prop 'workbench' (content/world/props/workbench.json:
## one mesh in the painted world's materials) with its brass lamp's light, plus the interact prompt. Pressing interact
## next to it emits `opened`.

## The player pressed interact next to the bench.
signal opened

const PROP_ID: StringName = &"workbench"
const PALETTE_ID: StringName = &"main"


func _init(rules: ExploreRulesDef, player: Player, place: PlaceDef = null, with_mesh: bool = true) -> void:
	super(rules, player, "WORLD_PROMPT_WORKSHOP", rules.bench_size.y + rules.prompt_height)
	if place != null:
		rotation.y = deg_to_rad(place.yaw)
	if not with_mesh:
		return
	var prop_id: StringName = place.prop if (place != null and place.prop != &"") else PROP_ID
	var def := ContentDB.get_def("prop", prop_id) as PropDef
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	var bench := MeshInstance3D.new()
	bench.name = "Bench"
	bench.mesh = PropMesh.mesh(def, palette)
	add_child(bench)
	if def.light != null:
		add_child(AreaLights.new([def.light] as Array[LightSpec], self, 1, rules.bench_light_fade))
	if def.collide != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = def.collide
		shape.shape = box
		shape.position.y = def.collide.y / 2.0
		body.add_child(shape)
		add_child(body)


## Where the player stands to use the bench (facing the table from the front).
func interact_point() -> Vector3:
	return global_position + global_basis * Vector3(0.0, 0.0, 0.7)


func _interact() -> void:
	opened.emit()
