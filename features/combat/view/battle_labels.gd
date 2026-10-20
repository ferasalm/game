class_name BattleLabels
extends RefCounted
## Builders for the 3D bits of the battle screen: billboard text (damage numbers, status text, enemy intent) and
## the target marker. Sizes and colours come from the BattleViewDef.


static func floating(content: String, size: int, color: Color, view: BattleViewDef) -> Label3D:
	var label := Label3D.new()
	label.text = content
	label.font_size = size
	label.pixel_size = view.label_pixel_size
	label.modulate = color
	label.outline_size = roundi(size * 0.2)
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	label.shaded = false
	return label


## A cone pointing down at the focused target.
static func marker(view: BattleViewDef) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = view.marker_size
	mesh.bottom_radius = 0.0
	mesh.height = view.marker_size * 2.0
	mesh.radial_segments = 4
	mesh.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = view.highlight_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var out := MeshInstance3D.new()
	out.mesh = mesh
	out.material_override = mat
	return out
