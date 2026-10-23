class_name BattleDamageEvents
extends Node
## Damage-related event handlers extracted to keep battle_event_player.gd under 200 lines.

static func on_damage(event_player: BattleEventPlayer, event: TimelineEvent) -> void:
	var before: int = event_player._shown_hp.get(event.unit_id, 0)
	event_player._shown_hp[event.unit_id] = maxi(0, before - event.value)
	if event_player._skip:
		return
	AudioDirector.play_hit(event_player._sim.actions.get(event.detail) as ActionDef, event.value)
	var target: CharacterVisual = event_player._fighters.visual(event.unit_id)
	if target != null:
		if event_player._pending_crit.get(event.unit_id, false):
			BattleNumbers.pop(target.get_parent(), str(event.value), target.anchor_position(&"head"), event_player._view.number_font_size, Color("#f2a93a"), 1.3, event_player._view, event_player._juice.def, 0.0)
			event_player._pending_crit.erase(event.unit_id)
		else:
			event_player._fighters.float_number(event.unit_id, event.value)
		await event_player._actions.on_hit(target, event.value)
	await event_player._wait(event_player._view.damage_gap)

static func on_missed(event_player: BattleEventPlayer, event: TimelineEvent) -> void:
	if not event_player._skip:
		var actor: UnitState = event_player._sim.timeline.find(event.unit_id)
		if actor != null:
			for target_id: StringName in actor.acted_targets:
				event_player._fighters.float_text(target_id, BattleStyle.text("UI_MISS"))
	await event_player._wait(event_player._view.damage_gap)
