class_name TalkPicker
extends RefCounted
## Pure picker that selects the next dialogue for a talk place from saved flags:
## 1. Haven't seen first? -> talk.first
## 2. A battle won since last talk? -> talk.after_battle
## 3. Otherwise -> next chat from talk.chats, wrapping.

const BATTLE_WON_FLAG: StringName = &"talk_battle_won"


static func flag_first(place_id: StringName) -> StringName:
	return StringName("talk_%s_first" % place_id)


static func flag_battle_won(place_id: StringName = &"") -> StringName:
	if place_id.is_empty():
		return BATTLE_WON_FLAG
	return StringName("talk_%s_battle_won" % place_id)


static func flag_chat(place_id: StringName, index: int) -> StringName:
	return StringName("talk_%s_chat_%d" % [place_id, index])


static func record_battle_won(flags: Dictionary, place_id: StringName = &"") -> void:
	flags[flag_battle_won(place_id)] = true


static func current_chat_index(place_id: StringName, flags: Dictionary, count: int) -> int:
	if count <= 0:
		return 0
	for i: int in count:
		if bool(flags.get(flag_chat(place_id, i), false)):
			return (i + 1) % count
	return 0


## Returns the dialogue id to play and updates the flags accordingly.
static func pick(talk: TalkDef, flags: Dictionary) -> StringName:
	if talk == null:
		return &""
	if talk.id == &"herb_seller":
		if not bool(flags.get(&"abu_nabil_beaten", false)):
			flags[flag_first(talk.id)] = true
			return talk.first
		return &"abu_nabil_menu"
	if not talk.first.is_empty() and not bool(flags.get(flag_first(talk.id), false)):
		flags[flag_first(talk.id)] = true
		return talk.first

	var won_flag: StringName = flag_battle_won(talk.id)
	var has_won: bool = bool(flags.get(won_flag, false)) or bool(flags.get(BATTLE_WON_FLAG, false))
	if has_won and not talk.after_battle.is_empty():
		flags[won_flag] = false
		flags[BATTLE_WON_FLAG] = false
		return talk.after_battle

	if talk.chats.is_empty():
		return &""

	return pick_chat(talk, flags)


## Advances and returns the next chat dialogue from the talk's chat list.
static func pick_chat(talk: TalkDef, flags: Dictionary) -> StringName:
	if talk == null or talk.chats.is_empty():
		return &""
	var idx: int = current_chat_index(talk.id, flags, talk.chats.size())
	for i: int in talk.chats.size():
		flags.erase(flag_chat(talk.id, i))
	flags[flag_chat(talk.id, idx)] = true
	return talk.chats[idx]


## Pure preview of what would be picked without mutating flags.
static func peek(talk: TalkDef, flags: Dictionary) -> StringName:
	if talk == null:
		return &""
	if talk.id == &"herb_seller":
		if not bool(flags.get(&"abu_nabil_beaten", false)):
			return talk.first
		return &"abu_nabil_menu"
	if not talk.first.is_empty() and not bool(flags.get(flag_first(talk.id), false)):
		return talk.first
	var won_flag: StringName = flag_battle_won(talk.id)
	var has_won: bool = bool(flags.get(won_flag, false)) or bool(flags.get(BATTLE_WON_FLAG, false))
	if has_won and not talk.after_battle.is_empty():
		return talk.after_battle
	if talk.chats.is_empty():
		return &""
	var idx: int = current_chat_index(talk.id, flags, talk.chats.size())
	return talk.chats[idx]
