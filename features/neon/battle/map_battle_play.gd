class_name MapBattlePlay
extends RefCounted
## purpose: Plays a battle batch on the iso map (docs/design/first-playable.md section 3): melee acts dash in, swing
## and apply their hits only at the IsoActor impact frame, then dash back; tech moves cast with a coloured flash;
## ko stays down; damage numbers and a small shake sell the hit. Instant mode plays the same beats synchronously.

const MOVE_KINDS: Array[StringName] = [&"act", &"reverse_stab"]

var battle: MapBattle
var handler: MapBattleEvents
var _attacker: IsoActor
var _pending_hits: Array[TimelineEvent] = []
var _pending_rest: Array[TimelineEvent] = []


func _init(owner: MapBattle) -> void:
	battle = owner
	handler = MapBattleEvents.new(owner)


func play(events: Array[TimelineEvent]) -> void:
	var i: int = 0
	while i < events.size():
		var event: TimelineEvent = events[i]
		if MOVE_KINDS.has(event.kind):
			var unit: UnitState = battle.sim.timeline.find(event.unit_id)
			var action: ActionDef = unit.acted if unit != null else null
			if action == null and event.detail != &"":
				action = battle.sim.actions.get(event.detail) as ActionDef
			var move_events: Array[TimelineEvent] = MapBattleEvents.events_after(events, i)
			if battle.instant:
				_act_instant(event.unit_id, action, move_events, unit)
			else:
				await _act_async(event.unit_id, action, move_events, unit)
			i = MapBattleEvents.next_move(events, i)
			continue
		handler.one(event)
		i += 1
	handler.reconcile()


## The impact frame of a melee swing: applies the pending hits (a test can call it directly).
func begin_melee(actor: IsoActor, hits: Array[TimelineEvent], rest: Array[TimelineEvent] = []) -> void:
	_attacker = actor
	_pending_hits = hits
	_pending_rest = rest
	actor.impact.connect(_on_impact, CONNECT_ONE_SHOT)
	actor.play(&"attack", true)


func _on_impact(_state: StringName) -> void:
	var hits: Array[TimelineEvent] = _pending_hits
	var rest: Array[TimelineEvent] = _pending_rest
	_pending_hits = []
	_pending_rest = []
	if _attacker != null:
		_attacker.freeze(battle.view.hit_stop)
	for hit: TimelineEvent in hits:
		handler.apply(hit)
	for event: TimelineEvent in rest:
		handler.one(event)
	if not hits.is_empty():
		battle.shake()


func _act_instant(actor_id: StringName, action: ActionDef, events: Array[TimelineEvent], unit: UnitState) -> void:
	var actor: IsoActor = battle.actors.get(actor_id)
	var h: Array[TimelineEvent] = []
	var r: Array[TimelineEvent] = []
	_split_events(events, h, r)
	if actor == null or action == null:
		_apply_all(h, r)
		return
	if action.is_melee:
		_melee_instant(actor, h, r, unit)
	else:
		_tech_instant(actor, h, r, unit)


func _act_async(actor_id: StringName, action: ActionDef, events: Array[TimelineEvent], unit: UnitState) -> void:
	var actor: IsoActor = battle.actors.get(actor_id)
	var h: Array[TimelineEvent] = []
	var r: Array[TimelineEvent] = []
	_split_events(events, h, r)
	if actor == null or action == null:
		_apply_all(h, r)
		return
	if action.is_melee:
		await _melee_async(actor, h, r, unit)
	else:
		await _tech_async(actor, h, r, unit)


func _split_events(events: Array[TimelineEvent], hits: Array[TimelineEvent], rest: Array[TimelineEvent]) -> void:
	for e: TimelineEvent in events:
		if e.kind == &"damage":
			hits.append(e)
		else:
			rest.append(e)


func _apply_all(hits: Array[TimelineEvent], rest: Array[TimelineEvent]) -> void:
	for hit: TimelineEvent in hits:
		handler.apply(hit)
	for e: TimelineEvent in rest:
		handler.one(e)


func _melee_instant(actor: IsoActor, hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> void:
	var target: IsoActor = handler.find_target(hits, unit)
	var home: Vector2 = actor.position
	if target != null:
		var toward: Vector2 = (target.position - home).normalized()
		actor.position = target.position - toward * battle.view.approach
		actor.face(target.position - actor.position)
	begin_melee(actor, hits, rest)
	_drive_to_impact(actor)
	actor.position = home
	actor.play(&"idle")


func _melee_async(actor: IsoActor, hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> void:
	var target: IsoActor = handler.find_target(hits, unit)
	var home: Vector2 = actor.position
	if target != null:
		var toward: Vector2 = (target.position - home).normalized()
		var spot: Vector2 = target.position - toward * battle.view.approach
		await _dash(actor, spot)
		actor.face(target.position - actor.position)
	begin_melee(actor, hits, rest)
	if _has_impact(actor):
		await actor.impact
	else:
		_on_impact(&"attack")
	await battle.get_tree().create_timer(battle.view.post_attack_seconds).timeout
	await _dash(actor, home)
	actor.position = home
	actor.play(&"idle")


func _tech_instant(actor: IsoActor, hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> void:
	actor.play(&"cast", true)
	_flash_targets(hits, rest, unit)
	_apply_all(hits, rest)
	actor.play(&"idle")


func _tech_async(actor: IsoActor, hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> void:
	actor.play(&"cast", true)
	_flash_targets(hits, rest, unit)
	_apply_all(hits, rest)
	await battle.get_tree().create_timer(battle.view.cast_seconds).timeout
	actor.play(&"idle")


func _flash_targets(hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> void:
	for target_id: StringName in handler.tech_targets(hits, rest, unit):
		var target: IsoActor = battle.actors.get(target_id)
		if target != null:
			battle.hud.flash_at(target.position, battle.view.flash_color)


func _has_impact(actor: IsoActor) -> bool:
	return actor.sprite_set != null and actor.sprite_set.get_state(&"attack").impact > 0


func _drive_to_impact(actor: IsoActor) -> void:
	if not _has_impact(actor):
		_on_impact(&"attack")
		return
	for i: int in 600:
		if _pending_hits.is_empty() and _pending_rest.is_empty():
			return
		actor._process(1.0 / 60.0)
	if not _pending_hits.is_empty() or not _pending_rest.is_empty():
		_on_impact(&"attack")


func _dash(actor: IsoActor, spot: Vector2) -> void:
	actor.play(&"run", true)
	var dist: float = actor.position.distance_to(spot)
	var time: float = maxf(battle.view.dash_min_seconds, dist / battle.view.dash_speed)
	var tween: Tween = battle.create_tween()
	tween.tween_property(actor, "position", spot, time)
	await tween.finished
