class_name MapFormation
extends RefCounted
## purpose: Pure spots for a fight on an iso plate (docs/design/first-playable.md section 3): the hero stands
## 120 px right-front of the contact point, the foes 140 px left-back, 110 px apart along the iso diagonal; every
## spot is pulled onto the room's floor with IsoWalk.nearest_free.

const ISO: Vector2 = Vector2(0.894427, 0.447214)  ## the 2:1 plate's right-front diagonal (1, 0.5) normalized
const HERO_OFFSET: float = 120.0
const FOE_OFFSET: float = 140.0
const FOE_GAP: float = 110.0


## {"hero": Vector2, "foes": Array[Vector2]} for `foes` enemies around `contact`, kept inside the floor.
static func spots(contact: Vector2, foes: int, outline: PackedVector2Array,
		holes: Array[PackedVector2Array]) -> Dictionary:
	var hero: Vector2 = IsoWalk.nearest_free(contact + ISO * HERO_OFFSET, contact, outline, holes)
	var out: Array[Vector2] = []
	for i: int in maxi(foes, 0):
		var point: Vector2 = contact - ISO * (FOE_OFFSET + FOE_GAP * float(i))
		out.append(IsoWalk.nearest_free(point, contact, outline, holes))
	return {"hero": hero, "foes": out}
