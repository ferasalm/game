class_name UnitLetters
extends RefCounted
## Tells apart units of the same kind on one side: two Concession Enforcers are A and B, a lone unit has no letter.
## Pure: the order is the timeline's unit order, which never changes during a fight.


## "A", "B", ... for a unit that shares its kind and side with another; "" when it is the only one.
static func of(units: Array[UnitState], unit: UnitState) -> String:
	var same: Array[UnitState] = []
	for other: UnitState in units:
		if other.side == unit.side and other.def.id == unit.def.id:
			same.append(other)
	if same.size() < 2:
		return ""
	return HudLayout.letter(same.find(unit))
