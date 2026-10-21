class_name ActorBody
extends RefCounted
## The collision capsule of a walking actor (Zayd, Bilqis): radius and height come from ExploreRulesDef (explore.json;
## builder B4 later reads them from the ModelDef instead). Feet at the node's origin.


static func add_capsule(body: Node3D, rules: ExploreRulesDef) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = rules.capsule_radius
	capsule.height = rules.capsule_height
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = rules.capsule_height / 2.0
	body.add_child(shape)
