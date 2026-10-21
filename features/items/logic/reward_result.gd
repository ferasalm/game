class_name RewardResult
extends RefCounted
## What a reward really changed: riyal added (after the cap), the equippables that were new, the consumables that
## fit in the bag, and riyal that came from herbs which did not fit (sold at their sell price).

var money: int = 0
var items: Array[StringName] = []
var consumables: Dictionary[StringName, int] = {}
## Riyal included in `money` that came from herbs over the stack limit.
var overflow_money: int = 0
## Riyal that did not fit under the purse cap and was dropped.
var money_lost: int = 0
## True when the flag said this reward was already paid (a chest opened before): nothing was given.
var already_done: bool = false


func is_empty() -> bool:
	return money == 0 and items.is_empty() and consumables.is_empty()
