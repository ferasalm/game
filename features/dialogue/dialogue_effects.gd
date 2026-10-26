class_name DialogueEffects
extends RefCounted
## Applies side effects from dialogue choices: set_flag, open_shop, start_battle, give_item.


static func apply_all(effects: PackedStringArray) -> void:
	for effect: String in effects:
		apply(effect)


static func apply(effect_str: String) -> void:
	var trimmed: String = effect_str.strip_edges()
	if trimmed.is_empty():
		return
	var parts: PackedStringArray = trimmed.split(" ", false)
	var command: String = parts[0]
	match command:
		"set_flag":
			if parts.size() > 1:
				GameState.flags[StringName(parts[1])] = true
		"give_item":
			if parts.size() > 2:
				_give_item(StringName(parts[1]), int(parts[2]))
		"open_shop":
			var shop_id: StringName = StringName(parts[1]) if parts.size() > 1 else &"herb_stall"
			Screens.open(&"shop", {"shop": shop_id})
		"start_battle":
			_start_battle(parts)


static func _give_item(item_id: StringName, count: int) -> void:
	if count <= 0:
		return
	if ContentDB.ids("consumable").has(item_id):
		GameState.bag[item_id] = GameState.bag.get(item_id, 0) + count
		EventBus.item_gained.emit(item_id, count)
	else:
		if Inventory.add(GameState.inventory, item_id):
			EventBus.item_obtained.emit(item_id)


static func build_battle_request(parts: PackedStringArray) -> BattleRequest:
	if parts.size() < 2:
		return null
	var request := BattleRequest.new()
	request.encounter_id = StringName(parts[1])
	if parts.size() > 2:
		request.opening = StringName(parts[2])
	if parts.size() > 3 and (parts[3] == "practice" or parts[3] == "true"):
		request.practice = true
	request.seed = hash([Time.get_ticks_usec(), request.encounter_id])
	request.party = GameState.party.duplicate()
	return request


static func _start_battle(parts: PackedStringArray) -> void:
	var request: BattleRequest = build_battle_request(parts)
	if request != null:
		EventBus.battle_requested.emit(request)
