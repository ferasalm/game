class_name AccessoryDef
extends EquipDef
## A ring any hero can wear (content/items/accessories.json). It adds no stats of its own; its gem sockets
## (count fixed by rarity: Common 1 ... Epic 2) hold stones that add to the wearer (docs/design/hilt-stones.md).

## Sockets are 1-2, fixed by rarity: common 1, uncommon 1, rare 2, epic 2.
var sockets: int = 0


func read(r: DefReader) -> void:
	read_gear(r)
	sockets = r.integer("sockets", 1, 2, 0)
	if perk != &"":
		r.problem("perk", "accessories never carry a perk")


func perk_problem(_tier: RarityDef) -> String:
	return ""
