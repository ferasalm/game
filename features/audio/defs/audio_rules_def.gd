class_name AudioRulesDef
extends Def
## Mixer and behaviour numbers of the AudioDirector (content/audio/rules.json): bus volumes, voice pools, music
## fade and duck, hit weight, text blip rate, item chime boost per rarity, and which sound each move uses.

var master_db: float = 0.0
var music_db: float = 0.0
var ambience_db: float = 0.0
var sfx_db: float = 0.0
var ui_db: float = 0.0
var voices: int = 8
var music_fade: float = 1.0
var duck_db: float = -6.0
var duck_attack: float = 0.05
var duck_seconds: float = 1.0
var heavy_hit_damage: int = 20
var blip_every: int = 2
var item_rarity_db: Array[int] = []
var fallback_melee: StringName = &""
var fallback_ranged: StringName = &""
## Move id -> vfx id, for moves whose ActionDef has no vfx field (sound "vfx_<vfx>").
var action_vfx: Dictionary[String, String] = {}


func read(r: DefReader) -> void:
	id = r.id()
	master_db = r.number("master_db", -60.0, 12.0)
	music_db = r.number("music_db", -60.0, 12.0)
	ambience_db = r.number("ambience_db", -60.0, 12.0)
	sfx_db = r.number("sfx_db", -60.0, 12.0)
	ui_db = r.number("ui_db", -60.0, 12.0)
	voices = r.integer("voices", 1, 64)
	music_fade = r.number("music_fade", 0.0, 10.0)
	duck_db = r.number("duck_db", -40.0, 0.0)
	duck_attack = r.number("duck_attack", 0.0, 2.0)
	duck_seconds = r.number("duck_seconds", 0.0, 10.0)
	heavy_hit_damage = r.integer("heavy_hit_damage", 1, 9999)
	blip_every = r.integer("blip_every", 1, 20)
	item_rarity_db = r.int_list("item_rarity_db", -24, 24)
	fallback_melee = StringName(r.text("fallback_melee"))
	fallback_ranged = StringName(r.text("fallback_ranged"))
	action_vfx = r.text_map("action_vfx")


func references() -> Array[Array]:
	var out: Array[Array] = [["sound", fallback_melee], ["sound", fallback_ranged]]
	for action_id: String in action_vfx:
		out.append(["action", StringName(action_id)])
		out.append(["sound", StringName("vfx_" + action_vfx[action_id])])
	return out
