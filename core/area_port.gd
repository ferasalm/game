class_name AreaPort
extends RefCounted
## What the Router needs from the area that is playing (a base class to override; the default does nothing). The
## area's composition root registers one with Router.register_area. The Router never touches the area's nodes
## except through this: host() is the node battle arenas are added to.

## The node battle arenas and stages are added to: the area's parent, so they become the area's siblings. It must
## outlive the battle.
func host() -> Node:
	return null


## A battle starts: hide the area and stop it (actors, physics, patrol), but keep it in the tree.
func suspend() -> void:
	pass


## The battle is over: show the area and run it again.
func resume() -> void:
	pass


## The patrol that fought goes back to its start, harmless for its respawn time.
func reset_patrol() -> void:
	pass


## Makes the area's own camera the current one again.
func restore_camera() -> void:
	pass


## Where the "unstuck" button puts the party: the last spot where the player stood still.
func last_safe_position() -> Vector3:
	return Vector3.ZERO


## Moves the whole party to a floor point.
func teleport_party(_position: Vector3) -> void:
	pass


## Puts the party at a save point (a PlaceDef id); an unknown or empty id means the area's start.
func place_party(_save_point: StringName) -> void:
	pass


## Lifts any actor freeze a crossing or talk left behind (the "unstuck" button).
func unfreeze() -> void:
	pass
