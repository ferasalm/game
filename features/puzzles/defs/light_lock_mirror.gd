class_name LightLockMirror
extends RefCounted
## purpose: One rotatable mirror in a light lock puzzle with four directional targets.

var id: StringName = &""
var targets: Array[StringName] = []
var start: int = 0
var at: Vector3 = Vector3.ZERO
