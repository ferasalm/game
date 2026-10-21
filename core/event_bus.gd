extends Node
## Global signals between features (autoload EventBus). Only coarse, cross-feature events live here;
## a feature's internal events (e.g. each timeline tick in battle) stay on that feature's own objects.

signal area_entered(area_id: StringName, spawn_id: StringName)
signal battle_started(encounter_id: StringName)
signal battle_ended(encounter_id: StringName, victory: bool)
## A stackable consumable joined the bag (loot, a chest, the shop); count is how many were added.
signal item_gained(item_id: StringName, count: int)
## A unique equippable (hilt, blade, prosthetic) joined the inventory: loot, a chest or the workshop bench.
signal item_obtained(item_id: StringName)
signal lore_read(lore_id: StringName)
signal dialogue_started(dialogue_id: StringName)
signal dialogue_ended(dialogue_id: StringName)
signal music_mood_requested(mood: StringName, fade_sec: float)
## Riyal changed by delta (rewards, shop); total is the new balance.
signal money_changed(total: int, delta: int)
## The Screens stack paused or resumed the game (battle juice cancels its freeze on pause).
signal game_paused(paused: bool)
