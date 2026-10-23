class_name Stones
extends RefCounted
## Pure rules for jambiyah hilt gemstones: open socket counts, rarity fitting rules, and socket mutations.

const RARITY_ORDER: Dictionary[StringName, int] = {
	&"common": 0,
	&"uncommon": 1,
	&"rare": 2,
	&"epic": 3,
	&"legendary": 4,
	&"heirloom": 5,
}


## Derives the grandfather hilt's restoration rank (1 to 3) from story flags.
static func heirloom_rank(flags: Dictionary) -> int:
	if flags.get(&"heirloom_rank_3", false) or flags.get(&"heirloom_restored_3", false):
		return 3
	if flags.get(&"heirloom_rank_2", false) or flags.get(&"heirloom_restored_2", false):
		return 2
	return 1


## The number of open gemstone sockets for a hilt. The heirloom opens slots by story rank.
static func open_slots(hilt: HiltDef, flags: Dictionary = {}) -> int:
	if hilt == null:
		return 0
	if hilt.rarity == &"heirloom":
		return heirloom_rank(flags)
	match hilt.rarity:
		&"uncommon", &"rare":
			return 1
		&"epic", &"legendary":
			return 2
	return 0


## Whether a stone can be socketed into a hilt based on rarity tiers.
static func fits(stone: StoneDef, hilt: HiltDef) -> bool:
	if stone == null or hilt == null:
		return false
	if open_slots(hilt) <= 0:
		return false
	if stone.rarity == &"heirloom":
		return hilt.rarity == &"heirloom"
	if hilt.rarity == &"heirloom":
		return true
	var stone_tier: int = RARITY_ORDER.get(stone.rarity, 0)
	var hilt_tier: int = RARITY_ORDER.get(hilt.rarity, 0)
	return stone_tier <= hilt_tier


## Sets a stone into a hilt's socket. If the stone was socketed in any other slot or hilt, it is moved.
static func set_stone(sockets: Dictionary, hilt: StringName, slot: int, stone: StringName) -> void:
	if stone != &"":
		for h: Variant in sockets:
			var list: Array = sockets[h]
			for i: int in list.size():
				if StringName(str(list[i])) == stone:
					list[i] = &""
	if not sockets.has(hilt):
		sockets[hilt] = []
	var arr: Array = sockets[hilt]
	while arr.size() <= slot:
		arr.append(&"")
	arr[slot] = stone
