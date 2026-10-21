class_name WalkGraph
extends RefCounted
## The walk graph of an area: which one-metre cells can be stood on, which can be reached from a start, which
## belong to a free 2 x 2 block (a corridor under 2 m has none), where the cells are traps and where a step is too
## high. Eight-neighbour moves; a diagonal needs both orthogonal cells open. Pure: built from plain arrays.

const AROUND: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var width: int
var depth: int
var _open: PackedByteArray
var _height: PackedFloat32Array


## open: one byte per cell (row by row), 1 = can be stood on; heights: the floor height of every cell.
func _init(w: int, d: int, open: PackedByteArray, heights: PackedFloat32Array) -> void:
	width = w
	depth = d
	_open = open
	_height = heights


func is_open(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < depth and _open[cell.y * width + cell.x] == 1


func height_at(cell: Vector2i) -> float:
	return _height[cell.y * width + cell.x]


## Every open cell.
func open_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z: int in depth:
		for x: int in width:
			if is_open(Vector2i(x, z)):
				out.append(Vector2i(x, z))
	return out


## The cells reachable from start walking only on cells of `mask` (default: every open cell); empty when start is not in it.
func reachable(start: Vector2i, mask: PackedByteArray = PackedByteArray()) -> Dictionary[Vector2i, bool]:
	var allowed: PackedByteArray = _open if mask.is_empty() else mask
	var seen: Dictionary[Vector2i, bool] = {}
	if not _in(allowed, start):
		return seen
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in AROUND:
			var next: Vector2i = cell + step
			if seen.has(next) or not _can_step(allowed, cell, step):
				continue
			seen[next] = true
			queue.append(next)
	return seen


## One byte per cell: 1 for the open cells that belong to a free 2 x 2 block of open cells.
func wide_mask() -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(width * depth)
	for z: int in depth - 1:
		for x: int in width - 1:
			var block: Array[Vector2i] = [Vector2i(x, z), Vector2i(x + 1, z), Vector2i(x, z + 1), Vector2i(x + 1, z + 1)]
			if block.all(is_open):
				for cell: Vector2i in block:
					out[cell.y * width + cell.x] = 1
	return out


## Open cells whose four neighbours are all closed (a standing spot you could never leave).
func traps() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in open_cells():
		var free: bool = false
		for step: Vector2i in AROUND.slice(0, 4):
			free = free or is_open(cell + step)
		if not free:
			out.append(cell)
	return out


## Edges inside `cells` whose floor differs by more than max_step, as "x,z -> x,z" strings.
func tall_steps(cells: Dictionary[Vector2i, bool], max_step: float) -> PackedStringArray:
	var out := PackedStringArray()
	for cell: Vector2i in cells:
		for step: Vector2i in AROUND:
			var next: Vector2i = cell + step
			if cells.has(next) and _can_step(_open, cell, step) and absf(height_at(cell) - height_at(next)) > max_step:
				out.append("%s -> %s" % [cell, next])
	return out


func _in(mask: PackedByteArray, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < depth and mask[cell.y * width + cell.x] == 1


func _can_step(mask: PackedByteArray, cell: Vector2i, step: Vector2i) -> bool:
	if not _in(mask, cell + step):
		return false
	if step.x != 0 and step.y != 0:
		return _in(mask, cell + Vector2i(step.x, 0)) and _in(mask, cell + Vector2i(0, step.y))
	return true
