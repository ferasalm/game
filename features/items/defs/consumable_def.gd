class_name ConsumableDef
extends Def
## A stackable item used from the bag, in the field or in battle (feathered herbs, the qishr cup). Kind
## "consumable" is NOT an equippable: it stays out of ContentDB.ITEM_KINDS and is referenced as ["consumable", id].

const TARGETS: Array[StringName] = [&"ally", &"all_allies", &"ko_ally"]
const USE_IN: Array[StringName] = [&"field", &"battle", &"both"]

var name_key: String = ""
var desc_key: String = ""
var icon: StringName = &""
## Effects: flat HP, share of max HP, SP; revive stands a downed ally up (then hp_pct is the HP it returns with).
var hp: int = 0
var hp_pct: float = 0.0
var sp: int = 0
var revive: bool = false
var target: StringName = &"ally"
var use_in: StringName = &"both"
## Cast speed and recovery work like an ActionDef's (battle only).
var cast_speed: float = 1.0
var recovery: int = 0
var price: int = 0
var sell: int = 0
var max_stack: int = 1
var vfx: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	icon = StringName(r.text("icon", "", false))
	hp = r.integer("hp", 0, 99999, 0, false)
	hp_pct = r.number("hp_pct", 0.0, 1.0, 0.0, false)
	sp = r.integer("sp", 0, 999, 0, false)
	revive = r.flag("revive")
	target = r.one_of("target", TARGETS)
	use_in = r.one_of("use_in", USE_IN)
	cast_speed = r.number("cast_speed", 0.1, 5.0)
	recovery = r.integer("recovery", 0, 5000)
	price = r.integer("price", 0, 9999)
	sell = r.integer("sell", 0, 9999)
	max_stack = r.integer("max_stack", 1, 99)
	vfx = StringName(r.text("vfx", "", false))
	_check(r)


func references() -> Array[Array]:
	return [["vfx", vfx]] if vfx != &"" else []


func _check(r: DefReader) -> void:
	if hp <= 0 and hp_pct <= 0.0 and sp <= 0:
		r.problem("hp", "an item needs an effect (hp, hp_pct or sp above 0)")
	if revive and hp_pct <= 0.0:
		r.problem("hp_pct", "a reviving item needs hp_pct above 0")
	if (target == &"ko_ally") != revive:
		r.problem("target", "ko_ally and revive go together")
	if revive and use_in != &"battle":
		r.problem("use_in", "a reviving item is battle only")
	if sell * 2 > price:
		r.problem("sell", "sell is above half of price")


func usable_in_battle() -> bool:
	return use_in != &"field"


func usable_in_field() -> bool:
	return use_in != &"battle"
