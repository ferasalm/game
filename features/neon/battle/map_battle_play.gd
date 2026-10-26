class_name MapBattlePlay
extends RefCounted
## purpose: Plays a battle batch on the iso map (docs/design/first-playable.md section 3): melee acts dash in, swing
## and apply their hits only at the IsoActor impact frame, then dash back; tech moves cast with a coloured flash;
## ko stays down; damage numbers and a small shake sell the hit. Instant mode plays the same beats synchronously.

const MOVE_KINDS: Array[StringName] = [&"act", &"reverse_stab", &"command"]

var battle: MapBattle
var _pending: Array[TimelineEvent] = []


func _init(owner: MapBattle) -> void:
	battle = owner


func play(events: Array[TimelineEvent]) -> void:
	var i: int = 0
	while i < events.size():
		var event: TimelineEvent = events[i]
		if MOVE_KINDS.has(event.kind):
			var action: ActionDef = battle.sim.actions.get(event.detail) as ActionDef
			var hits: Array[TimelineEvent] = _hits_after(events, i)
			await _act(event.unit_id, action, hits)
			i = _next_move(events, i)
			continue
		_one(event)
		i += 1


## The impact frame of a melee swing: applies the pending hits (a test can call it directly).
func begin_melee(actor: IsoActor, hits: Array[TimelineEvent]) -> void:
	_pending = hits
	actor.impact.connect(_on_impact, CONNECT_ONE_SHOT)
	actor.play(&"attack", true)


func _on_impact(_state: StringName) -> void:
	var hits: Array[TimelineEvent] = _pending
	_pending = []
	for hit: TimelineEvent in hits:
		_apply(hit)
	if not hits.is_empty():
		battle.shake()


func _act(actor_id: StringName, action: ActionDef, hits: Array[TimelineEvent]) -> void:
	var actor: IsoActor = battle.actors.get(actor_id)
	if actor == null or action == null:
		for hit: TimelineEvent in hits:
			_apply(hit)
		return
	if action.is_melee:
		await _melee(actor, hits)
	else:
		await _tech(actor, hits)


func _melee(actor: IsoActor, hits: Array[TimelineEvent]) -> void:
	var target: IsoActor = _first_target(hits)
	var home: Vector2 = actor.position
	if target != null:
		var toward: Vector2 = (target.position - home).normalized()
		var spot: Vector2 = target.position - toward * battle.view.approach
		if battle.instant:
			actor.position = spot
		else:
			await _dash(actor, spot)
		actor.face(target.position - actor.position)
	begin_melee(actor, hits)
	if battle.instant:
		_drive_to_impact(actor)
	elif _has_impact(actor):
		await actor.impact
	else:
		_on_impact(&"attack")
	if not battle.instant:
		await battle.get_tree().create_timer(0.12).timeout
		await _dash(actor, home)
	actor.position = home
	actor.play(&"idle")


func _tech(actor: IsoActor, hits: Array[TimelineEvent]) -> void:
	actor.play(&"cast", true)
	for hit: TimelineEvent in hits:
		var target: IsoActor = battle.actors.get(hit.unit_id)
		if target != null:
			battle.hud.flash_at(target.position, battle.view.flash_color)
		_apply(hit)
	if not battle.instant:
		await battle.get_tree().create_timer(0.35).timeout
	actor.play(&"idle")


func _one(event: TimelineEvent) -> void:
	match event.kind:
		&"damage":
			_apply(event)
		&"down":
			_down(event)
		&"healed":
			_heal(event)
		&"revived":
			_revive(event)


func _apply(event: TimelineEvent) -> void:
	if event.value <= 0:
		return
	var unit_id: StringName = event.unit_id
	battle.shown_hp[unit_id] = maxi(0, battle.shown_hp.get(unit_id, 0) - event.value)
	var target: IsoActor = battle.actors.get(unit_id)
	if target != null:
		target.freeze(battle.view.hit_stop)
		if target.state != &"ko":
			target.play(&"hurt", true)
		battle.hud.pop_number(target.position + Vector2(0.0, -target.height()), event.value, battle.view.hp_color)
	battle.hud.refresh()


func _down(event: TimelineEvent) -> void:
	battle.shown_hp[event.unit_id] = 0
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		target.play(&"ko", true)
	battle.hud.refresh()


func _heal(event: TimelineEvent) -> void:
	var unit: UnitState = battle.sim.timeline.find(event.unit_id)
	if unit == null:
		return
	battle.shown_hp[event.unit_id] = mini(unit.def.max_hp, battle.shown_hp.get(event.unit_id, 0) + event.value)
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		battle.hud.pop_number(target.position + Vector2(0.0, -target.height()), event.value, battle.view.sp_color)
	battle.hud.refresh()


func _revive(event: TimelineEvent) -> void:
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		target.play(&"idle", true)


func _first_target(hits: Array[TimelineEvent]) -> IsoActor:
	for hit: TimelineEvent in hits:
		var actor: IsoActor = battle.actors.get(hit.unit_id)
		if actor != null:
			return actor
	return null


func _has_impact(actor: IsoActor) -> bool:
	return actor.sprite_set != null and actor.sprite_set.get_state(&"attack").impact > 0


func _drive_to_impact(actor: IsoActor) -> void:
	if not _has_impact(actor):
		_on_impact(&"attack")
		return
	for i: int in 600:
		if _pending.is_empty():
			return
		actor._process(1.0 / 60.0)
	if not _pending.is_empty():
		_on_impact(&"attack")


func _dash(actor: IsoActor, spot: Vector2) -> void:
	actor.play(&"run", true)
	var time: float = maxf(0.12, actor.position.distance_to(spot) / 700.0)
	var tween: Tween = battle.create_tween()
	tween.tween_property(actor, "position", spot, time)
	await tween.finished


func _hits_after(events: Array[TimelineEvent], i: int) -> Array[TimelineEvent]:
	var out: Array[TimelineEvent] = []
	for j: int in range(i + 1, events.size()):
		if MOVE_KINDS.has(events[j].kind):
			break
		if events[j].kind == &"damage":
			out.append(events[j])
	return out


func _next_move(events: Array[TimelineEvent], i: int) -> int:
	for j: int in range(i + 1, events.size()):
		if MOVE_KINDS.has(events[j].kind):
			return j
	return events.size()
