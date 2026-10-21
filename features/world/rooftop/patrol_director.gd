class_name PatrolDirector
extends RefCounted
## The rules for the patrols of an area: those beaten since the last sabil drink (GameState.cleared_patrols) stay
## gone, the one that fought goes back to its lane start after a battle, nobody can touch for touch_grace seconds
## after a battle, a drink or an unstuck, and a drink brings every patrol back (docs/design/economy.md section 6).

var patrols: Array[Patrol] = []
## The patrol that touched the player last (null until a touch, and after a battle).
var fought: Patrol = null

var _grace: float


func _init(list: Array[Patrol], grace: float) -> void:
	patrols = list
	_grace = grace


## Hides the beaten patrols and revives those no longer in the cleared list.
func sync_cleared() -> void:
	for p: Patrol in patrols:
		if GameState.cleared_patrols.has(p.encounter_id):
			p.clear()
		elif p.is_cleared():
			p.revive(_grace)


## Nobody can touch for the grace time; patrols keep their places.
func hold_all() -> void:
	for p: Patrol in patrols:
		p.hold(_grace)


## A battle ended: sync, hold everyone, and the patrol that fought (if it survived) restarts its lane.
func after_battle() -> void:
	sync_cleared()
	hold_all()
	if fought != null and not fought.is_cleared():
		fought.send_home(_grace)
	fought = null


## The sabil was drunk: the cleared list is empty now, every patrol is back at its lane start for the grace time.
func after_drink() -> void:
	sync_cleared()
	for p: Patrol in patrols:
		p.send_home(_grace)


## 1: the patrol came at the player from behind (from_behind), 2: the player came at it from behind, 0: neither.
func ambush_side(from_behind: bool, player_pos: Vector3, source: Patrol) -> int:
	if from_behind:
		return 1
	var to_player: Vector3 = (player_pos - source.position) * Vector3(1.0, 0.0, 1.0)
	return 2 if to_player.dot(source.facing()) < 0.0 else 0
