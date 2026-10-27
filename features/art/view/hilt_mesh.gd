class_name HiltMesh
extends RefCounted
## The stand-in for Rydan's grandfather's jambiyah (Heirloom `grandfather_hilt`), built in code from the part's colours
## until Feras's picture becomes a model: a curved horn grip with two silver bands, a T pommel with a carnelian stone,
## a curved blade, and a curved leather sheath with silver throat and tip. The grip's base is the origin: +y toward
## the pommel, the blade runs down -y and curves toward +z (forward), so the piece sheathed at the belt front and
## drawn in the hand share one frame. Metres.

const GRIP_LENGTH: float = 0.115
const BLADE_LENGTH: float = 0.23
const CURVE: float = 0.55  ## radians the blade and the sheath bend through
const HORN: Color = Color("#7a4a22")
const STEEL: Color = Color("#c3cbd4")


## Returns {&"hilt": grip mesh, &"blade": blade mesh, &"sheath": sheath mesh, &"tip": Vector3, &"top": Vector3}.
static func build(part: ModelPartDef) -> Dictionary:
	var grip := SurfaceTool.new()
	grip.begin(Mesh.PRIMITIVE_TRIANGLES)
	_grip(grip, part)
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip: Vector3 = _curve(blade, BLADE_LENGTH, Vector3(0.026, 0.05, 0.004), STEEL, 0.0)
	var sheath := SurfaceTool.new()
	sheath.begin(Mesh.PRIMITIVE_TRIANGLES)
	_curve(sheath, BLADE_LENGTH * 1.04, Vector3(0.036, 0.05, 0.02), part.sheath_color, 0.012)
	_band(sheath, part.metal, 0.0, 0.034)
	_band(sheath, part.metal, -BLADE_LENGTH * 0.95, 0.03)
	return {&"hilt": _commit(grip), &"blade": _commit(blade), &"sheath": _commit(sheath),
		&"tip": tip, &"top": Vector3(0.0, GRIP_LENGTH, 0.0)}


static func _grip(st: SurfaceTool, part: ModelPartDef) -> void:
	var grip := CylinderMesh.new()
	grip.top_radius = 0.017
	grip.bottom_radius = 0.02
	grip.height = GRIP_LENGTH
	grip.radial_segments = 10
	GarmentMesh.prim(st, grip, Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0.0, GRIP_LENGTH * 0.5, 0.0)), HORN)
	for y: float in [0.02, GRIP_LENGTH - 0.022]:
		var ring := CylinderMesh.new()
		ring.top_radius = 0.0215
		ring.bottom_radius = 0.0215
		ring.height = 0.008
		ring.radial_segments = 10
		GarmentMesh.prim(st, ring, Transform3D(Basis.IDENTITY, Vector3(0.0, y, -0.002)), part.metal)
	var pommel := BoxMesh.new()
	pommel.size = Vector3(0.072, 0.013, 0.03)
	var top := Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0.0, GRIP_LENGTH + 0.004, -0.008))
	GarmentMesh.prim(st, pommel, top, HORN)
	var stone := SphereMesh.new()
	stone.radius = 0.011
	stone.height = 0.022
	stone.radial_segments = 10
	stone.rings = 6
	GarmentMesh.prim(st, stone, Transform3D(Basis.IDENTITY, Vector3(0.0, GRIP_LENGTH + 0.006, 0.008)), part.accent)


## Boxes along a bend (down -y, curving to +z): `size` is (width at the top, length of a step, thickness). Returns the
## far end; it narrows to the point.
static func _curve(st: SurfaceTool, length: float, size: Vector3, color: Color, grow: float) -> Vector3:
	var steps: int = 6
	var at := Vector3.ZERO
	var step: float = length / float(steps)
	for i: int in steps:
		var angle: float = CURVE * (float(i) + 0.5) / float(steps)
		var dir := Vector3(0.0, -cos(angle), sin(angle))
		var width: float = size.x * (1.0 - 0.7 * float(i) / float(steps))
		var box := BoxMesh.new()
		box.size = Vector3(width, step * 1.08, size.z + grow * (1.0 - float(i) / float(steps)))
		var basis := Basis(Vector3.RIGHT, angle)
		GarmentMesh.prim(st, box, Transform3D(basis, at + dir * step * 0.5), color)
		at += dir * step
	return at


static func _band(st: SurfaceTool, color: Color, y: float, width: float) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(width + 0.006, 0.012, 0.034)
	var angle: float = CURVE * clampf(-y / BLADE_LENGTH, 0.0, 1.0) * 0.5
	GarmentMesh.prim(st, box, Transform3D(Basis(Vector3.RIGHT, angle), Vector3(0.0, y, sin(angle) * -y * 0.5)), color)


static func _commit(st: SurfaceTool) -> ArrayMesh:
	return st.commit()  # normals come from the primitives
