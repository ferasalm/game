class_name TalkDef
extends Def
## Maps a place id to its first dialogue, after-battle dialogue and ordered chats.

var first: StringName = &""
var after_battle: StringName = &""
var chats: Array[StringName] = []


func read(r: DefReader) -> void:
	id = r.id()
	first = r.id("first")
	after_battle = StringName(r.text("after_battle", "", false))
	chats = r.id_list("chats")


func references() -> Array[Array]:
	var out: Array[Array] = []
	if not first.is_empty():
		out.append(["dialogue", first])
	if not after_battle.is_empty():
		out.append(["dialogue", after_battle])
	for chat_id: StringName in chats:
		out.append(["dialogue", chat_id])
	return out
