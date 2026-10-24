class_name Accessory
extends RefCounted
## Pure rules for ring gem sockets: which stones fit a ring. The rule is the hilt rule from
## docs/design/hilt-stones.md: a stone fits when its rarity order is not above the holder's, and
## Heirloom stones fit Heirloom holders only (so they never fit a ring).
## Socket counts are content (AccessoryDef.sockets, fixed by rarity); stones are set at the workshop
## bench and shown read only on the equipment screen, like hilt sockets.


## Whether the stone may sit in one of the ring's sockets.
static func fits(stone: StoneDef, ring: AccessoryDef) -> bool:
	if stone == null or ring == null or ring.sockets <= 0:
		return false
	if stone.rarity == &"heirloom":
		return false
	return Stones.RARITY_ORDER.get(stone.rarity, 0) <= Stones.RARITY_ORDER.get(ring.rarity, 0)
