class_name MapBattleEvents
extends RefCounted
## purpose: Applies timeline events to actors and shown_hp (docs/design/first-playable.md section 3): damage numbers,
## hit freeze, KO pose on defeat, heals and revives, and reconciles shown_hp with the sim at the end of each batch.

const MOVE_KINDS: Array[StringName] = [&"act", &"reverse_stab"]

var battle: MapBattle


func _init(owner: MapBattle) -> void:
	battle = owner


func one(event: TimelineEvent) -> void:
	match event.kind:
		&"damage":
			apply(event)
		&"down":
			down(event)
		&"healed":
			heal(event)
		&"revived":
			revive(event)


func apply(event: TimelineEvent) -> void:
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


func down(event: TimelineEvent) -> void:
	battle.shown_hp[event.unit_id] = 0
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		target.play(&"ko", true)
	battle.hud.refresh()


func heal(event: TimelineEvent) -> void:
	var unit: UnitState = battle.sim.timeline.find(event.unit_id)
	if unit == null:
		return
	battle.shown_hp[event.unit_id] = mini(unit.def.max_hp, battle.shown_hp.get(event.unit_id, 0) + event.value)
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		battle.hud.pop_number(target.position + Vector2(0.0, -target.height()), event.value, battle.view.sp_color)
	battle.hud.refresh()


func revive(event: TimelineEvent) -> void:
	var unit: UnitState = battle.sim.timeline.find(event.unit_id)
	if unit != null:
		battle.shown_hp[event.unit_id] = unit.hp
	var target: IsoActor = battle.actors.get(event.unit_id)
	if target != null:
		target.play(&"idle", true)
	battle.hud.refresh()


func reconcile() -> void:
	for unit: UnitState in battle.sim.timeline.units:
		battle.shown_hp[unit.unit_id] = unit.hp
	battle.hud.refresh()


func find_target(hits: Array[TimelineEvent], unit: UnitState) -> IsoActor:
	for hit: TimelineEvent in hits:
		var actor: IsoActor = battle.actors.get(hit.unit_id)
		if actor != null:
			return actor
	if unit != null:
		for tid: StringName in unit.acted_targets:
			var actor: IsoActor = battle.actors.get(tid)
			if actor != null:
				return actor
	return null


func tech_targets(hits: Array[TimelineEvent], rest: Array[TimelineEvent], unit: UnitState) -> Array[StringName]:
	var out: Array[StringName] = []
	if unit != null:
		for tid: StringName in unit.acted_targets:
			if not out.has(tid):
				out.append(tid)
	for hit: TimelineEvent in hits:
		if not out.has(hit.unit_id):
			out.append(hit.unit_id)
	for e: TimelineEvent in rest:
		if not out.has(e.unit_id) and battle.actors.has(e.unit_id):
			out.append(e.unit_id)
	if out.is_empty() and unit != null and unit.acted != null and unit.acted.target == &"self":
		out.append(unit.unit_id)
	return out


static func events_after(events: Array[TimelineEvent], i: int) -> Array[TimelineEvent]:
	var out: Array[TimelineEvent] = []
	for j: int in range(i + 1, events.size()):
		if MOVE_KINDS.has(events[j].kind) or events[j].kind == &"command":
			break
		out.append(events[j])
	return out


static func next_move(events: Array[TimelineEvent], i: int) -> int:
	for j: int in range(i + 1, events.size()):
		if MOVE_KINDS.has(events[j].kind) or events[j].kind == &"command":
			return j
	return events.size()
