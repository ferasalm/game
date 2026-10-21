class_name AreaDressing
extends Node3D
## Everything an area has on top of its tiles: tower-houses and props (PropBuilder), neon signs, the practical
## lights with their fake pools (AreaLights) and the chests (one Chest each, interactive). Built from the area's
## placement lists; the rooftop adds this node and forwards set_active.

const PALETTE_ID: StringName = &"main"

var chests: Array[Chest] = []
var lights: AreaLights
var signs: Array[NeonSign] = []


static func build(area: AreaDef, rules: ExploreRulesDef, player: Player, floor_y: float) -> AreaDressing:
	var dressing := AreaDressing.new()
	dressing.name = "Dressing"
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	dressing.add_child(PropBuilder.build(area, palette, floor_y))
	dressing._add_chests(area, rules, palette, player, floor_y)
	for spec: SignSpec in area.signs:
		var sign_node := NeonSign.new(spec, palette)
		dressing.signs.append(sign_node)
		dressing.add_child(sign_node)
	var specs: Array[LightSpec] = area.lights.duplicate()
	specs.append_array(PropBuilder.light_specs(area, floor_y))
	dressing.lights = AreaLights.new(specs, player, area.light_budget, area.light_fade)
	dressing.add_child(dressing.lights)
	return dressing


## Chests stop answering to interact while the rooftop is not exploring (a battle, a menu).
func set_active(on: bool) -> void:
	for chest: Chest in chests:
		chest.set_active(on)


func chest(chest_id: StringName) -> Chest:
	for c: Chest in chests:
		if c.chest_id == chest_id:
			return c
	return null


func _add_chests(area: AreaDef, rules: ExploreRulesDef, palette: PaletteDef, player: Player, floor_y: float) -> void:
	for p: Placement in area.props:
		var def := ContentDB.get_def("prop", p.ref) as PropDef
		if def == null or not def.chest:
			continue
		var spot := Chest.new(p.name, def, palette, rules, player)
		spot.transform = PropBuilder.transform_of(p, floor_y)
		chests.append(spot)
		add_child(spot)
