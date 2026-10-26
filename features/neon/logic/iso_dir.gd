class_name IsoDir
extends RefCounted
## Pure 8-way facing of the baked iso sprites: row 0 faces screen right, then counter-clockwise in 45 degree steps
## (2 = away from the camera, up the screen; 4 = left; 6 = toward the camera, down the screen).

const COUNT: int = 8
const TOWARD_CAMERA: int = 6


## The sheet row for a screen-space direction (y down); `fallback` when the direction is zero.
static func row(direction: Vector2, fallback: int = TOWARD_CAMERA) -> int:
	if direction.length_squared() < 0.0001:
		return fallback
	var turns: float = atan2(-direction.y, direction.x) / (TAU / float(COUNT))
	return posmod(roundi(turns), COUNT)


## A unit screen direction for a sheet row (the inverse of row()).
static func vector(sheet_row: int) -> Vector2:
	var angle: float = TAU * float(posmod(sheet_row, COUNT)) / float(COUNT)
	return Vector2(cos(angle), -sin(angle))
