class_name PrototypeBattleFlow
extends RefCounted
## Handles battle conclusion effects for the prototype (patrol wins, Abu Nabil boss and spar).


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
