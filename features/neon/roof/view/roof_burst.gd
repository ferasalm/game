class_name RoofBurst
extends RefCounted
## purpose: opening hatch burst visual flash animation on the spawn point.


static func flash(world: Node2D, spawn_pos: Vector2, flash_seconds: float) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-20, -10), Vector2(20, -10), Vector2(20, 10), Vector2(-20, 10)
	])
	poly.position = spawn_pos
	poly.color = Color.WHITE
	world.add_child(poly)
	var tw: Tween = world.create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, flash_seconds)
	tw.tween_callback(poly.queue_free)
