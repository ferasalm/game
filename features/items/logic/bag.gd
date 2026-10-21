class_name Bag
extends RefCounted
## The party's stackable consumables: counts per id plus RESERVATIONS made by pending battle casts.
## available = count - reserved, so two heroes can never both claim the last herb. A cast reserves one, then
## either consume()s it (the cast landed) or release()s it (cancelled, interrupted, target gone). Pure.

## Owned counts {consumable id: count}; never holds a zero.
var counts: Dictionary[StringName, int] = {}
var _reserved: Dictionary[StringName, int] = {}


## A bag over a copy of the saved counts.
static func from_counts(saved: Dictionary) -> Bag:
	var bag := Bag.new()
	for item_id: Variant in saved:
		if int(saved[item_id]) > 0:
			bag.counts[StringName(str(item_id))] = int(saved[item_id])
	return bag


func count(item_id: StringName) -> int:
	return counts.get(item_id, 0)


func reserved(item_id: StringName) -> int:
	return _reserved.get(item_id, 0)


func available(item_id: StringName) -> int:
	return count(item_id) - reserved(item_id)


## Adds up to max_stack in all; returns how many did NOT fit (the caller turns them into riyal).
func add(item_id: StringName, amount: int, max_stack: int) -> int:
	if amount <= 0:
		return 0
	var room: int = maxi(0, max_stack - count(item_id))
	var taken: int = mini(amount, room)
	if taken > 0:
		counts[item_id] = count(item_id) + taken
	return amount - taken


## Takes amount out (never below what is reserved). False and no change when too few are available.
func remove(item_id: StringName, amount: int) -> bool:
	if amount <= 0 or available(item_id) < amount:
		return false
	_store(item_id, count(item_id) - amount)
	return true


## Claims one for a pending cast. False when none is available.
func reserve(item_id: StringName) -> bool:
	if available(item_id) < 1:
		return false
	_reserved[item_id] = reserved(item_id) + 1
	return true


## Gives a claim back (the bag is unchanged).
func release(item_id: StringName) -> void:
	if reserved(item_id) > 0:
		_reserved[item_id] = reserved(item_id) - 1


## The reserved herb is used up: the claim and one count go.
func consume(item_id: StringName) -> bool:
	if reserved(item_id) < 1 or count(item_id) < 1:
		return false
	release(item_id)
	_store(item_id, count(item_id) - 1)
	return true


func is_empty() -> bool:
	return counts.is_empty()


## The saved shape: a plain copy of the counts.
func snapshot() -> Dictionary[StringName, int]:
	return counts.duplicate()


func _store(item_id: StringName, value: int) -> void:
	if value <= 0:
		counts.erase(item_id)
	else:
		counts[item_id] = value
