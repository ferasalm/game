class_name SkylineLayout
extends RefCounted
## Where the city blocks stand: for each band a jittered grid of cells between the band's distances from the
## play area, minus the al-Saila corridor and the landmark clearings, thinned by the band's fill. The same
## SkylineDef and area always give the same placements. Pure.


## One placed block. building is the BuildingDef id (detailed bands); size is width, height, depth (far bands).
class Block extends RefCounted:
	var band: StringName = &""
	var building: StringName = &""
	var position: Vector3 = Vector3.ZERO
	var yaw: float = 0.0
	var size: Vector3 = Vector3.ONE
	var tint: float = 1.0


## footprints: building id -> Vector2(width, depth) in metres. area: the play area's rectangle in x, z.
static func place(def: SkylineDef, area: Rect2, footprints: Dictionary[StringName, Vector2]) -> Array[Block]:
	var rng := RandomNumberGenerator.new()
	rng.seed = def.seed_value
	var out: Array[Block] = []
	for band: SkylineBand in def.bands:
		var lo := Vector2i((area.position - Vector2.ONE * band.max_dist) / band.cell)
		var hi := Vector2i((area.end + Vector2.ONE * band.max_dist) / band.cell)
		for j: int in range(lo.y - 1, hi.y + 1):
			for i: int in range(lo.x - 1, hi.x + 1):
				var centre := Vector2((i + 0.5) * band.cell, (j + 0.5) * band.cell)
				var keep: bool = _in_band(centre, band, area) and not _blocked(centre, band.cell, def)
				var block: Block = _block(band, centre, footprints, rng)
				if keep and rng.randf() <= band.fill:
					out.append(block)
	return out


## Shortest distance from a point to the rectangle (0 inside).
static func distance_to(point: Vector2, area: Rect2) -> float:
	var dx: float = maxf(maxf(area.position.x - point.x, point.x - area.end.x), 0.0)
	var dz: float = maxf(maxf(area.position.y - point.y, point.y - area.end.y), 0.0)
	return Vector2(dx, dz).length()


static func _in_band(centre: Vector2, band: SkylineBand, area: Rect2) -> bool:
	var d: float = distance_to(centre, area)
	return d >= band.min_dist and d < band.max_dist and d >= band.cell * 0.5 + 0.5


## True when the cell touches the al-Saila corridor or a landmark's clearing.
static func _blocked(centre: Vector2, cell: float, def: SkylineDef) -> bool:
	if absf(centre.x - def.saila_x) < def.saila_half + cell * 0.5 + 0.5:
		return true
	for mark: SkylineLandmark in def.landmarks:
		if Vector2(mark.x, mark.z).distance_to(centre) < mark.clear_radius + cell * 0.5:
			return true
	return false


static func _block(band: SkylineBand, centre: Vector2, footprints: Dictionary[StringName, Vector2],
		rng: RandomNumberGenerator) -> Block:
	var block := Block.new()
	block.band = band.id
	var extent: float = 0.0
	if band.kind == &"detailed":
		block.building = band.building_ids[rng.randi() % band.building_ids.size()]
		var fp: Vector2 = footprints.get(block.building, Vector2(6.0, 6.0))
		extent = maxf(fp.x, fp.y)
		block.yaw = rng.randi_range(0, 3) * PI / 2.0
	else:
		var w: float = rng.randf_range(band.width_range.x, band.width_range.y)
		var d: float = rng.randf_range(band.width_range.x, band.width_range.y)
		block.size = Vector3(w, rng.randf_range(band.height_range.x, band.height_range.y), d)
		block.tint = rng.randf_range(0.55, 1.0)
		extent = maxf(w, d)
	var jitter: float = maxf((band.cell - extent) * 0.5 - 0.25, 0.0)
	block.position = Vector3(centre.x + rng.randf_range(-jitter, jitter), 0.0, centre.y + rng.randf_range(-jitter, jitter))
	return block
