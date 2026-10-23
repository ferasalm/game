class_name WorkshopHoldings
extends RefCounted
## purpose: Plain working copy of player state for pure workshop operations.

var money: int = 0
var materials: Dictionary[StringName, int] = {}
var owned: Array[StringName] = []
var upgrades: Dictionary[StringName, int] = {}
var sockets: Dictionary[StringName, Array] = {}
var bag: Bag = Bag.new()


## Creates an isolated deep clone of this holdings copy.
func clone() -> WorkshopHoldings:
	var copy := WorkshopHoldings.new()
	copy.money = money
	copy.materials = materials.duplicate()
	copy.owned = owned.duplicate()
	copy.upgrades = upgrades.duplicate()
	copy.sockets = sockets.duplicate(true)
	copy.bag = Bag.from_counts(bag.snapshot())
	return copy
