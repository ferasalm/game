class_name HudLayout
extends RefCounted
## Pure screen-rectangle maths for the battle HUD: the box around projected points, where a panel may sit beside a
## fighter without covering any fighter, which fighter the mouse points at, and how an info card fades. No nodes.


## The smallest rect holding all points (a zero rect for none).
static func bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var low: Vector2 = points[0]
	var high: Vector2 = points[0]
	for point: Vector2 in points:
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	return Rect2(low, high - low)


## The area `rect` shares with the blockers (0 = clear). Rects that only touch do not overlap.
static func overlap_area(rect: Rect2, blockers: Array[Rect2]) -> float:
	var total: float = 0.0
	for blocker: Rect2 in blockers:
		total += rect.intersection(blocker).get_area()
	return total


## Places of a panel of `size` next to `anchor`, best first: right, left, above, below (each centred on the anchor).
static func beside(anchor: Rect2, size: Vector2, gap: float) -> Array[Rect2]:
	var middle: Vector2 = anchor.get_center() - size / 2.0
	var out: Array[Rect2] = []
	out.append(Rect2(Vector2(anchor.end.x + gap, middle.y), size))
	out.append(Rect2(Vector2(anchor.position.x - gap - size.x, middle.y), size))
	out.append(Rect2(Vector2(middle.x, anchor.position.y - gap - size.y), size))
	out.append(Rect2(Vector2(middle.x, anchor.end.y + gap), size))
	return out


## Shifts a rect back inside the screen (it keeps its size).
static func clamp_inside(rect: Rect2, screen: Rect2) -> Rect2:
	var x: float = clampf(rect.position.x, screen.position.x, maxf(screen.position.x, screen.end.x - rect.size.x))
	var y: float = clampf(rect.position.y, screen.position.y, maxf(screen.position.y, screen.end.y - rect.size.y))
	return Rect2(Vector2(x, y), rect.size)


## The first candidate (kept inside the screen) that covers no blocker; with none clear, the one covering least.
static func pick(candidates: Array[Rect2], blockers: Array[Rect2], screen: Rect2) -> Rect2:
	var best: Rect2 = Rect2()
	var best_area: float = INF
	for candidate: Rect2 in candidates:
		var placed: Rect2 = clamp_inside(candidate, screen)
		var area: float = overlap_area(placed, blockers)
		if area < best_area:
			best = placed
			best_area = area
		if area <= 0.0:
			break
	return best


## The fighter under a screen point: of several rects holding it, the one standing lowest (nearest the camera).
static func hit(rects: Dictionary[StringName, Rect2], point: Vector2) -> StringName:
	var found: StringName = &""
	var lowest: float = -INF
	for unit_id: StringName in rects:
		var rect: Rect2 = rects[unit_id]
		if rect.has_point(point) and rect.end.y > lowest:
			found = unit_id
			lowest = rect.end.y
	return found


## 1 while pointed at or within `delay` seconds of it, then fades to 0 over `fade` seconds.
static func fade_alpha(idle: float, delay: float, fade: float) -> float:
	if idle <= delay:
		return 1.0
	return clampf(1.0 - (idle - delay) / maxf(fade, 0.001), 0.0, 1.0)


## "A", "B", ... for index 0, 1, ... (wraps after Z).
static func letter(index: int) -> String:
	return char(65 + posmod(index, 26))
