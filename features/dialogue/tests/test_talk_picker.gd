extends TestCase
## Tests for TalkPicker: first dialogue, after-battle dialogue on victory, chat sequence and wrapping,
## battle interruption resuming chats, and defensive fallbacks.


func _sample_talk() -> TalkDef:
	var talk := TalkDef.new()
	talk.id = &"test_npc"
	talk.first = &"talk_first"
	talk.after_battle = &"talk_after_battle"
	talk.chats = [&"chat_1", &"chat_2", &"chat_3", &"chat_4"]
	return talk


func test_first_dialogue_picked_when_not_seen() -> void:
	var talk := _sample_talk()
	var flags: Dictionary = {}
	check_eq(TalkPicker.peek(talk, flags), &"talk_first", "peek returns first")
	var picked: StringName = TalkPicker.pick(talk, flags)
	check_eq(picked, &"talk_first", "first talk chosen")
	check(bool(flags.get(TalkPicker.flag_first(talk.id), false)), "first talk recorded in flags")


func test_after_battle_picked_on_victory_after_first() -> void:
	var talk := _sample_talk()
	var flags: Dictionary = {}
	TalkPicker.pick(talk, flags)
	TalkPicker.record_battle_won(flags)
	check_eq(TalkPicker.peek(talk, flags), &"talk_after_battle", "peek returns after_battle")
	var picked: StringName = TalkPicker.pick(talk, flags)
	check_eq(picked, &"talk_after_battle", "after battle chosen")
	check(not bool(flags.get(TalkPicker.flag_battle_won(), false)), "battle won flag cleared")
	check(not bool(flags.get(TalkPicker.flag_battle_won(talk.id), false)), "per-place battle won cleared")


func test_battle_won_before_first_still_picks_first_then_after_battle() -> void:
	var talk := _sample_talk()
	var flags: Dictionary = {}
	TalkPicker.record_battle_won(flags)
	var first_picked: StringName = TalkPicker.pick(talk, flags)
	check_eq(first_picked, &"talk_first", "first visit always picks first")
	var second_picked: StringName = TalkPicker.pick(talk, flags)
	check_eq(second_picked, &"talk_after_battle", "second visit picks after_battle")


func test_chats_sequence_and_wrapping() -> void:
	var talk := _sample_talk()
	var flags: Dictionary = {}
	TalkPicker.pick(talk, flags)
	check_eq(TalkPicker.pick(talk, flags), &"chat_1", "chat 1")
	check_eq(TalkPicker.pick(talk, flags), &"chat_2", "chat 2")
	check_eq(TalkPicker.pick(talk, flags), &"chat_3", "chat 3")
	check_eq(TalkPicker.pick(talk, flags), &"chat_4", "chat 4")
	check_eq(TalkPicker.pick(talk, flags), &"chat_1", "wraps to chat 1")
	check_eq(TalkPicker.pick(talk, flags), &"chat_2", "continues to chat 2")


func test_battle_interrupt_resumes_chats_sequence() -> void:
	var talk := _sample_talk()
	var flags: Dictionary = {}
	TalkPicker.pick(talk, flags)
	check_eq(TalkPicker.pick(talk, flags), &"chat_1", "chat 1")
	check_eq(TalkPicker.pick(talk, flags), &"chat_2", "chat 2")
	TalkPicker.record_battle_won(flags, talk.id)
	check_eq(TalkPicker.pick(talk, flags), &"talk_after_battle", "interrupted by after_battle")
	check_eq(TalkPicker.pick(talk, flags), &"chat_3", "resumes at chat 3")


func test_empty_fallbacks() -> void:
	check_eq(TalkPicker.pick(null, {}), &"", "null talk returns empty")
	var empty_talk := TalkDef.new()
	empty_talk.id = &"empty_npc"
	var flags: Dictionary = {}
	check_eq(TalkPicker.pick(empty_talk, flags), &"", "empty talk returns empty")
	empty_talk.first = &"just_first"
	check_eq(TalkPicker.pick(empty_talk, flags), &"just_first", "picks first")
	check_eq(TalkPicker.pick(empty_talk, flags), &"", "no after_battle or chats returns empty")
