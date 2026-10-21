class_name RooftopWorld
extends RefCounted
## Builds the still world of the rooftop scene under a host node: environment, sun, the area's blocks, mist, skyline,
## the camera and its ExploreCamera. Holds the pieces Rooftop needs to keep.

var env: WorldEnvironment
var blocks: Node3D
var camera: Camera3D
var camera_rig: ExploreCamera


static func build(host: Node3D, area: AreaDef, rules: ExploreRulesDef, look: LookDef, rig: CameraRigDef,
		spawn: Vector3) -> RooftopWorld:
	var out := RooftopWorld.new()
	PaintedLook.begin(look)
	out.env = Diorama.make_environment(look)
	host.add_child(out.env)
	host.add_child(Diorama.make_sun(look))
	out.blocks = AreaBuilder.build(area, rules)
	host.add_child(out.blocks)
	host.add_child(MistBuilder.build_area(area))
	host.add_child(SkylineBuilder.build(area))
	out.camera = Diorama.make_camera(look)
	host.add_child(out.camera)
	out.camera.make_current()
	out.camera_rig = ExploreCamera.new()
	host.add_child(out.camera_rig)
	out.camera_rig.setup(out.camera, look, rig, area.vista_world(), rules.camera_smoothing, spawn)
	return out
