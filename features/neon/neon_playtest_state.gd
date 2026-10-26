class_name NeonPlaytestState
extends RefCounted
## purpose: The Neon Glitch state a playtest capture saves: the stage, the roof room and hero, and the fight if one is on.

static func collect(stage: StringName, roof: RoofScene, battle: MapBattle) -> Dictionary:
	var state: Dictionary = {"stage": stage, "room": &"", "hero": Vector2.ZERO, "fight": {}}
	if roof != null:
		state["room"] = roof.room_id
		var room: NeonRoomDef = roof.room()
		if room != null:
			state["room"] = room.id
		var hero: IsoActor = roof.hero()
		if hero != null:
			state["hero"] = hero.position
	if battle != null and battle.sim != null:
		state["fight"] = _fight(battle)
	return PlaytestDump.plain(state) as Dictionary


static func _fight(battle: MapBattle) -> Dictionary:
	var fighters: Array = []
	for unit: UnitState in battle.sim.timeline.units:
		fighters.append({"id": unit.unit_id, "side": unit.side, "hp": unit.hp, "sp": unit.sp})
	return PlaytestDump.fight(battle.sim.ticks, fighters, battle.recent_events)
