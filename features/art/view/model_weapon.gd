class_name ModelWeapon
extends RefCounted
## The grandfather's jambiyah in use: drawn from the belt into the hand when a strike begins (the weapon trail starts
## tracking its hilt and its point), an arc smear on the impact frame, sheathed and the trail released when the clip ends.
## A model without the hilt does nothing here.

var hilt: HiltParts = null
var trail: WeaponTrail = null


func setup(new_hilt: HiltParts, new_trail: WeaponTrail) -> void:
	hilt = new_hilt
	trail = new_trail


func start() -> void:
	if hilt != null:
		hilt.draw()
		trail.track(hilt.top, hilt.tip)


## A clip event of the model: smear on impact (at the world point `at`, toward `dir_x`), put away on end.
func on_event(kind: StringName, at: Vector3, dir_x: float) -> void:
	if kind == &"impact" and hilt != null and hilt.drawn:
		trail.smear(at, dir_x)
	elif kind == &"end":
		if hilt != null:
			hilt.sheathe()
		trail.release()
