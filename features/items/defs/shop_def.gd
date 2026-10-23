class_name ShopDef
extends Def
## A stall: who keeps it, her greeting and the consumable ids on sale (price and sell come from the ConsumableDef).

var name_key: String = ""
var keeper_key: String = ""
var greeting_key: String = ""
var stock: Array[StringName] = []
var price_flag_multipliers: Dictionary[StringName, float] = {}


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	keeper_key = r.text("keeper_key")
	greeting_key = r.text("greeting_key")
	stock = r.id_list("stock")
	if stock.is_empty():
		r.problem("stock", "a shop needs at least one item")
	price_flag_multipliers.clear()
	if r.has("price_flag_multipliers"):
		var raw: Dictionary[String, String] = r.text_map("price_flag_multipliers")
		for flag_name: String in raw:
			price_flag_multipliers[StringName(flag_name)] = float(raw[flag_name])


## Multiplier on buy prices based on saved flags.
func price_multiplier(flags: Dictionary) -> float:
	if price_flag_multipliers.is_empty():
		return 1.0
	for flag: StringName in price_flag_multipliers:
		var s: String = String(flag)
		if s == "default":
			continue
		var negated: bool = s.begins_with("!")
		var key: StringName = StringName(s.substr(1)) if negated else flag
		var is_set: bool = bool(flags.get(key, false))
		if (not is_set) if negated else is_set:
			return price_flag_multipliers[flag]
	if price_flag_multipliers.has(&"default"):
		return price_flag_multipliers[&"default"]
	return 1.0


func references() -> Array[Array]:
	var out: Array[Array] = []
	for item_id: StringName in stock:
		out.append(["consumable", item_id])
	return out
