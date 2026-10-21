class_name ShopResult
extends RefCounted
## What one buy or sell did (or why it did not): reason is &"" on success, else one of Shop.SHORT_MONEY etc.
## `count` is how many changed hands, `money_delta` the purse change (negative when buying). Pure data.

var ok: bool = false
var reason: StringName = &""
var item_id: StringName = &""
var count: int = 0
var money_delta: int = 0


static func fail(why: StringName, item: StringName) -> ShopResult:
	var result := ShopResult.new()
	result.reason = why
	result.item_id = item
	return result
