class_name BattleEventExtra
extends Node
## Extra event handlers (dodged, crit, resisted, fled, flee_failed) to keep battle_event_player.gd under 200 lines.

var _event_player: BattleEventPlayer
var _skip: bool = false

func setup(event_player: BattleEventPlayer) -> void:
	_event_player = event_player

func on_dodged(event: TimelineEvent) -> void:
	if not _skip:
		var target: CharacterVisual = _event_player._fighters.visual(event.unit_id)
		if target != null:
			_event_player._fighters.float_text(event.unit_id, BattleStyle.text("UI_DODGED"))
	await _wait(_event_player._view.damage_gap)

func on_crit(event: TimelineEvent) -> void:
	if not _skip:
		var target: CharacterVisual = _event_player._fighters.visual(event.unit_id)
		if target != null:
			_event_player._fighters.float_text(event.unit_id, BattleStyle.text("UI_CRIT"))
		_event_player._pending_crit[event.unit_id] = true
	await _wait(_event_player._view.hit_stop)

func on_resisted(event: TimelineEvent) -> void:
	if not _skip:
		var target: CharacterVisual = _event_player._fighters.visual(event.unit_id)
		if target != null:
			_event_player._fighters.float_text(event.unit_id, BattleStyle.text("UI_RESISTED"))
	await _wait(_event_player._view.damage_gap)

func on_fled(event: TimelineEvent) -> void:
	await _wait(0.05)

func on_flee_failed(event: TimelineEvent) -> void:
	if not _skip:
		_event_player._hud.show_banner(BattleStyle.text("UI_FLEE_FAILED"))
	await _wait(_event_player._view.banner_seconds)

func _wait(seconds: float) -> void:
	if not _skip and seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
