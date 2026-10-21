class_name ShopDef
extends Def
## A stall: who keeps it, her greeting and the consumable ids on sale (price and sell come from the ConsumableDef).

var name_key: String = ""
var keeper_key: String = ""
var greeting_key: String = ""
var stock: Array[StringName] = []


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	keeper_key = r.text("keeper_key")
	greeting_key = r.text("greeting_key")
	stock = r.id_list("stock")
	if stock.is_empty():
		r.problem("stock", "a shop needs at least one item")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for item_id: StringName in stock:
		out.append(["consumable", item_id])
	return out
