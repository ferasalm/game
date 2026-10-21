class_name Chest
extends InteractSpot
## A treasure chest: the prop's body and a lid that swings open on a hinge when the player interacts. It opens
## once, saves nothing itself and emits `opened(chest_id)`; whoever owns the inventory listens.

## The lid started to open (the chest is now empty-handed for good).
signal opened(chest_id: StringName)

const BODY_GROUP: StringName = &"body"
const LID_GROUP: StringName = &"lid"

var chest_id: StringName = &""
var is_open: bool = false
## The hinge node the lid hangs from (its rotation animates the opening).
var hinge: Node3D

var _open_angle: float = 0.0
var _open_time: float = 0.0
var _lid_t: float = 0.0


## open_angle in degrees and open_time in seconds come from the area's chest rules (content, not code).
func _init(id: StringName, def: PropDef, palette: PaletteDef, rules: ExploreRulesDef, player: Player) -> void:
	super(rules, player, "WORLD_PROMPT_CHEST", rules.prompt_height + 0.6)
	chest_id = id
	_open_angle = deg_to_rad(rules.chest_open_angle)
	_open_time = rules.chest_open_time
	var body := MeshInstance3D.new()
	body.mesh = PropMesh.mesh(def, palette, BODY_GROUP)
	add_child(body)
	hinge = Node3D.new()
	hinge.position = def.lid_hinge
	add_child(hinge)
	var lid := MeshInstance3D.new()
	lid.mesh = PropMesh.mesh(def, palette, LID_GROUP)
	lid.position = -def.lid_hinge
	hinge.add_child(lid)


func _can_interact() -> bool:
	return not is_open and _is_near()


func _interact() -> void:
	is_open = true
	prompt.visible = false
	opened.emit(chest_id)


func _process(delta: float) -> void:
	if is_open and _lid_t < 1.0:
		_lid_t = minf(_lid_t + delta / maxf(_open_time, 0.01), 1.0)
		hinge.rotation.x = -_open_angle * ease_out(_lid_t)


## 0..1 progress of the lid (1 = fully open).
func lid_progress() -> float:
	return _lid_t


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
