class_name RooftopPort
extends AreaPort
## The rooftop as the Router sees it: hide and disable it during a battle (it stays in the tree, so its awaits,
## signals and camera keep working), bring it back, and move the party for unstuck and loading.

var _rooftop: Rooftop


func _init(rooftop: Rooftop) -> void:
	_rooftop = rooftop


func world() -> Node3D:
	return _rooftop


func suspend() -> void:
	_rooftop.set_exploring(false)
	_rooftop.visible = false
	_rooftop.process_mode = Node.PROCESS_MODE_DISABLED


func resume() -> void:
	_rooftop.process_mode = Node.PROCESS_MODE_INHERIT
	_rooftop.visible = true
	_rooftop.set_exploring(true)


func reset_patrol() -> void:
	_rooftop.reset_patrol()


func restore_camera() -> void:
	_rooftop.restore_camera()


func last_safe_position() -> Vector3:
	return _rooftop.last_safe_position()


func teleport_party(position: Vector3) -> void:
	_rooftop.teleport_party(position)


func place_party(save_point: StringName) -> void:
	_rooftop.place_party(save_point)
