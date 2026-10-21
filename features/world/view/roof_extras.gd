class_name RoofExtras
extends RefCounted
## The 2150 clutter on a tower-house roof: water tank, satellite dish, antenna with a red beacon, small solar
## panel. Solid parts go to the trim buffer, lit parts (beacon, dish LED) to the glow buffer.

const SPOTS: Array[Vector2] = [Vector2(1.0, -1.0), Vector2(-1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]
const INSET: float = 1.4


## Puts the def's extras on the roof at height y, one per corner in order.
static func add(trim: SurfaceBuffer, glow: SurfaceBuffer, def: BuildingDef, y: float, colors: Dictionary[String, Color]) -> void:
	for i: int in mini(def.roof_extras.size(), SPOTS.size()):
		var spot: Vector2 = SPOTS[i] * Vector2(def.footprint_w / 2.0 - INSET, def.footprint_d / 2.0 - INSET)
		var at := Vector3(spot.x, y, spot.y)
		match def.roof_extras[i]:
			&"water_tank":
				_tank(trim, at, colors)
			&"dish":
				_dish(trim, glow, at, colors)
			&"antenna":
				_antenna(trim, glow, at, colors)
			&"solar":
				_solar(trim, at, colors)


static func _tank(trim: SurfaceBuffer, at: Vector3, colors: Dictionary[String, Color]) -> void:
	for leg: Vector2 in SPOTS:
		trim.box(at + Vector3(leg.x * 0.35, 0.3, leg.y * 0.35), Vector3(0.1, 0.6, 0.1), colors["d"])
	trim.frustum(at + Vector3(0.0, 0.6, 0.0), 0.55, 0.5, 0.9, 8, colors["e"])
	trim.box(at + Vector3(0.0, 1.55, 0.0), Vector3(0.3, 0.1, 0.3), colors["f"])


static func _dish(trim: SurfaceBuffer, glow: SurfaceBuffer, at: Vector3, colors: Dictionary[String, Color]) -> void:
	trim.box(at + Vector3(0.0, 0.5, 0.0), Vector3(0.08, 1.0, 0.08), colors["d"])
	var tilted := SurfaceBuffer.new()
	tilted.xf = Transform3D(Basis(Vector3.RIGHT, -0.9), at + Vector3(0.0, 1.1, 0.0))
	tilted.frustum(Vector3.ZERO, 0.1, 0.5, 0.18, 8, colors["f"], 0.0, false)
	tilted.box(Vector3(0.0, 0.0, 0.0), Vector3(0.1, 0.2, 0.1), colors["e"])
	trim.merge(tilted)
	glow.box(at + Vector3(0.0, 1.02, 0.1), Vector3(0.06, 0.06, 0.06), colors["C"])


static func _antenna(trim: SurfaceBuffer, glow: SurfaceBuffer, at: Vector3, colors: Dictionary[String, Color]) -> void:
	trim.box(at + Vector3(0.0, 2.0, 0.0), Vector3(0.06, 4.0, 0.06), colors["d"])
	trim.box(at + Vector3(0.0, 3.0, 0.0), Vector3(0.9, 0.04, 0.04), colors["d"])
	trim.box(at + Vector3(0.0, 3.6, 0.0), Vector3(0.6, 0.04, 0.04), colors["d"])
	glow.box(at + Vector3(0.0, 4.05, 0.0), Vector3(0.12, 0.12, 0.12), colors["R"])


static func _solar(trim: SurfaceBuffer, at: Vector3, colors: Dictionary[String, Color]) -> void:
	trim.box(at + Vector3(0.0, 0.2, 0.0), Vector3(0.1, 0.4, 0.1), colors["d"])
	var panel := SurfaceBuffer.new()
	panel.xf = Transform3D(Basis(Vector3.RIGHT, -0.5), at + Vector3(0.0, 0.6, 0.0))
	panel.box(Vector3.ZERO, Vector3(1.4, 0.05, 0.9), colors["i"])
	panel.box(Vector3(0.0, 0.03, 0.0), Vector3(1.3, 0.03, 0.8), colors["u"])
	trim.merge(panel)
