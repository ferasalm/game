class_name RigidRig
extends RefCounted
## A model that is not skinned: a few rigid parts moved by code (the survey drone: a hull, a spinning ring and a lens).
## The parts come from the ModelDef (lathes, glowing ones for lenses); pose() hovers the whole thing, spins the part
## named "ring", and plays the state's motion from the clip's progress (0..1): a strike tips it forward, a hit rolls it,
## knocked out it drops to the floor and tilts. Numbers: the ModelDef (bob, bob_speed, spin).

var root := Node3D.new()
var materials: Array[ShaderMaterial] = []
var _def: ModelDef
var _parts: Dictionary[StringName, MeshInstance3D] = {}
var _clock: float = 0.0


func build(def: ModelDef, holder: Node3D) -> void:
	_def = def
	holder.add_child(root)
	for part: ModelPartDef in def.parts:
		var instance := MeshInstance3D.new()
		instance.mesh = GarmentMesh.lathe(part.profile, part.length, part.depth, Color.WHITE, part.sweep)
		var mat: ShaderMaterial = ModelMaterials.skin(part.texture, part.color, def.outline_hull)
		if part.glow > 0.0:
			ModelMaterials.make_glow(mat, part.accent, part.glow)
		materials.append(mat)
		instance.material_override = mat
		instance.position = part.offset
		instance.rotation_degrees = part.rotation
		root.add_child(instance)
		_parts[part.id] = instance


## Hover and spin, then the motion of a state at `progress` (0..1 through its clip; 1 holds, as a knocked-out drone).
func pose(delta: float, state: StringName, progress: float) -> void:
	_clock += delta
	root.position.y = sin(_clock * _def.bob_speed) * _def.bob
	var ring: MeshInstance3D = _parts.get(&"ring")
	if ring != null:
		ring.rotation.y += delta * _def.spin * TAU
	var tip: float = 0.0
	var roll: float = 0.0
	match state:
		&"attack", &"cast", &"item":
			tip = sin(progress * PI) * 0.6
		&"hurt":
			roll = sin(progress * PI * 4.0) * (1.0 - progress) * 0.4
		&"ko":
			tip = progress * 0.5
			roll = progress * 0.7
			root.position.y = lerpf(root.position.y, -_def.height_m * 0.45, progress)
	root.rotation = Vector3(tip, 0.0, roll)
