class_name StormHost
extends Node3D
## Runtime coordinator for storm effects: positions rain and splashes around the active camera and runs lightning.

var def: StormDef
var floor_y: float = 0.0
var rain_particles: GPUParticles3D
var splash_particles: GPUParticles3D
var puddles_root: Node3D
var lightning_light: DirectionalLight3D
var flash_rect: ColorRect

var _lightning_timer: float = 0.0
var _flash_timer: float = 0.0
var _is_flashing: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if def == null:
		return
	_rng.seed = def.puddle_seed
	_setup_lightning_light()
	_schedule_lightning()


func _process(delta: float) -> void:
	_follow_camera()
	_update_lightning(delta)


func trigger_lightning() -> void:
	if not def.lightning_enabled:
		return
	_is_flashing = true
	_flash_timer = 0.0


func is_lightning_active() -> bool:
	return def != null and def.lightning_enabled


func is_flashing() -> bool:
	return _is_flashing


func _setup_lightning_light() -> void:
	lightning_light = DirectionalLight3D.new()
	lightning_light.name = "LightningLight"
	lightning_light.light_color = def.lightning_color
	lightning_light.light_energy = 0.0
	lightning_light.rotation_degrees = Vector3(-35.0, -140.0, 0.0)
	add_child(lightning_light)
	var layer := CanvasLayer.new()
	layer.name = "LightningFlash"
	add_child(layer)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(def.lightning_color, 0.0)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash_rect.material = add
	layer.add_child(flash_rect)


func _schedule_lightning() -> void:
	if not def.lightning_enabled:
		_lightning_timer = 0.0
		return
	_lightning_timer = _rng.randf_range(def.lightning_interval_min, def.lightning_interval_max)


func _update_lightning(delta: float) -> void:
	if not def.lightning_enabled:
		return
	if not _is_flashing:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			trigger_lightning()
		return
	_flash_timer += delta
	var boost: float = _double_flash_intensity(_flash_timer, def.lightning_duration)
	if lightning_light != null:
		lightning_light.light_energy = boost * def.lightning_energy_boost
	if flash_rect != null:
		flash_rect.color.a = boost * def.lightning_screen_alpha
	if _flash_timer >= def.lightning_duration:
		_is_flashing = false
		if lightning_light != null:
			lightning_light.light_energy = 0.0
		if flash_rect != null:
			flash_rect.color.a = 0.0
		_schedule_lightning()


static func _double_flash_intensity(t: float, total: float) -> float:
	var progress: float = clampf(t / total, 0.0, 1.0)
	if progress < 0.25:
		return progress / 0.25
	if progress < 0.45:
		return lerpf(1.0, 0.15, (progress - 0.25) / 0.20)
	if progress < 0.8:
		return lerpf(0.15, 0.85, (progress - 0.45) / 0.35)
	return lerpf(0.85, 0.0, (progress - 0.8) / 0.20)


func _follow_camera() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cam_pos: Vector3 = cam.global_position
	var cur_floor_y: float = cam_pos.y - 4.9 if cam_pos.y > 2.0 else floor_y
	if rain_particles != null:
		rain_particles.global_position.x = cam_pos.x
		rain_particles.global_position.z = cam_pos.z
		rain_particles.global_position.y = cur_floor_y - def.rain_floor_margin + (def.rain_box.y * 0.5)
	if splash_particles != null:
		splash_particles.global_position.x = cam_pos.x
		splash_particles.global_position.z = cam_pos.z
		splash_particles.global_position.y = cur_floor_y + def.splash_height_offset
