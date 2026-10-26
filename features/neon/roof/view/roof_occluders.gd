class_name RoofOccluders
extends RefCounted
## purpose: builds textured occluder polygons inside %World sorted by baseline y.


static func build(occluders: Array[Dictionary], plate_texture: Texture2D, world: Node2D) -> void:
	for occ: Dictionary in occluders:
		var poly := Polygon2D.new()
		poly.name = String(occ["id"])
		poly.texture = plate_texture
		poly.uv = occ["polygon"]
		var pts := PackedVector2Array()
		var baseline: float = occ["baseline"]
		for pt: Vector2 in (occ["polygon"] as PackedVector2Array):
			pts.append(Vector2(pt.x, pt.y - baseline))
		poly.polygon = pts
		poly.position = Vector2(0.0, baseline)
		world.add_child(poly)
