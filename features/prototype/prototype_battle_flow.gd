class_name PrototypeBattleFlow
extends RefCounted
## purpose: Handles battle creation and conclusion effects for the prototype (patrol wins, Abu Nabil boss and spar).


static func start_battle(encounter_id: StringName, rooftop: Rooftop, count: int) -> void:
	var request := BattleRequest.new()
	request.encounter_id = encounter_id
	request.ambush = rooftop.last_touch_ambush()
	request.seed = hash([count, Time.get_ticks_usec()])
	request.party = GameState.party.duplicate()
	Router.start_battle(request)


static func grant_start_gear() -> void:
	if GameState.inventory.has(&"grandfather_hilt"):
		return
	for loadout_id: StringName in ContentDB.ids("loadout"):
		Inventory.add_all(GameState.inventory, (ContentDB.get_def("loadout", loadout_id) as LoadoutDef).item_ids())


static func handle_battle_ended(
		encounter_id: StringName, victory: bool, talk_caller: Callable) -> void:
	if encounter_id == &"abu_nabil_duel":
		var req: BattleRequest = Router.last_battle_request
		if req != null and req.practice:
			if not victory:
				talk_caller.call(&"abu_nabil_spar_lost")
		elif victory and not bool(GameState.flags.get(&"abu_nabil_beaten", false)):
			talk_caller.call(&"abu_nabil_after_battle")
		return
	if victory:
		TalkPicker.record_battle_won(GameState.flags)
		if not bool(GameState.flags.get(&"party_after_first_win_done", false)):
			GameState.flags[&"party_after_first_win_done"] = true
			talk_caller.call(&"party_after_first_win")
