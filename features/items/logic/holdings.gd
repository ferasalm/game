class_name Holdings
extends RefCounted
## What rewards are paid into: riyal, the consumable Bag, the unique-item inventory and the flags. A plain
## working copy; GameState hands one out (holdings()) and takes the money and bag back (take()). Pure.

var money: int = 0
var bag: Bag = Bag.new()
var inventory: Array[StringName] = []
var flags: Dictionary[StringName, bool] = {}
