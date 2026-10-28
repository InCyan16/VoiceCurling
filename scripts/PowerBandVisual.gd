extends Area3D

enum BandType{ACCELERATE, DECELERATE}

@export var band_type: BandType = BandType.ACCELERATE
@export var arrow_texture: Texture2D

@onready var outer_bloom: MeshInstance3D = $VisualRoot / OuterBloom
@onready var glow_halo: MeshInstance3D = $VisualRoot / GlowHalo
@onready var band_surface: MeshInstance3D = $VisualRoot / BandSurface
@onready var arrow_decal: MeshInstance3D = $VisualRoot / ArrowDecal
@onready var band_light: OmniLight3D = $VisualRoot / BandLight
@onready var spark_particles: GPUParticles3D = $VisualRoot / SparkParticles

const BASE_LIGHT_ENERGY: float = 0.45
const PEAK_LIGHT_ENERGY: float = 0.85


func _ready() -> void :
	_setup_visuals()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _process(_delta: float) -> void :
	if not visible:
		return
	var time_ms: float = Time.get_ticks_msec() * 0.001
	var energy_pulse: float = 0.5 + 0.5 * sin(time_ms * 2.4)
	band_light.light_energy = lerpf(BASE_LIGHT_ENERGY, PEAK_LIGHT_ENERGY, energy_pulse)
	arrow_decal.scale = Vector3.ONE * (1.0 + 0.05 * sin(time_ms * 3.2))


func _on_visibility_changed() -> void :
	set_process(visible)
	spark_particles.emitting = visible
	if not visible:
		band_light.light_energy = 0.0
		band_light.visible = false
	else:
		band_light.visible = true


func _setup_visuals() -> void :
	var is_accel: bool = band_type == BandType.ACCELERATE
	var band_color: Color = Color(0.08, 0.98, 0.5, 0.58) if is_accel else Color(0.98, 0.18, 0.12, 0.58)
	var rim_color: Color = Color(0.55, 1.0, 0.78, 1.0) if is_accel else Color(1.0, 0.55, 0.45, 1.0)
	var glow_color: Color = Color(0.25, 1.0, 0.62, 0.6) if is_accel else Color(1.0, 0.28, 0.18, 0.6)
	var scroll_direction: float = 1.0 if is_accel else -1.0
	var light_color: Color = Color(0.35, 1.0, 0.55) if is_accel else Color(1.0, 0.35, 0.25)
	var arrow_tint: Color = Color(0.15, 1.0, 0.4, 1.0) if is_accel else Color(1.0, 0.13, 0.08, 1.0)

	outer_bloom.material_override = _create_glow_material(glow_color, scroll_direction, 1.0)
	glow_halo.material_override = _create_glow_material(glow_color, scroll_direction, 0.72)
	band_surface.material_override = _create_band_material(band_color, rim_color, scroll_direction)
	arrow_decal.material_override = _create_arrow_material(arrow_tint, scroll_direction, 1.6)
	_build_arrow_thickness(arrow_tint, scroll_direction)

	band_light.light_color = light_color
	band_light.light_energy = BASE_LIGHT_ENERGY
	band_light.omni_range = 1.2
	band_light.shadow_enabled = false

	_setup_particles(glow_color, scroll_direction)



func _build_arrow_thickness(tint: Color, scroll_direction: float) -> void :
	var layers: int = 2
	var step: float = 0.018
	for i: int in range(1, layers + 1):
		var f: float = 1.0 - float(i) / float(layers + 1)
		var side_tint: Color = Color(tint.r * (0.4 + 0.4 * f), tint.g * (0.4 + 0.4 * f), tint.b * (0.4 + 0.4 * f), tint.a)
		var layer: MeshInstance3D = MeshInstance3D.new()
		layer.mesh = arrow_decal.mesh
		layer.material_override = _create_arrow_material(side_tint, scroll_direction, 0.45)
		layer.position = Vector3(0.0, - step * float(i), 0.0)
		arrow_decal.add_child(layer)


func _create_arrow_material(tint: Color, scroll_direction: float, brightness: float) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://materials/power_arrow.gdshader")
	material.set_shader_parameter("arrow_tex", arrow_texture)
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("pulse_speed", 3.2 if scroll_direction > 0.0 else 2.7)
	material.set_shader_parameter("pulse_strength", 0.24)
	material.set_shader_parameter("brightness", brightness)
	return material


func _create_band_material(band_color: Color, rim_color: Color, scroll_direction: float) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://materials/power_band.gdshader")
	material.set_shader_parameter("band_color", band_color)
	material.set_shader_parameter("rim_color", rim_color)
	material.set_shader_parameter("arrow_tex", arrow_texture)
	material.set_shader_parameter("scroll_direction", scroll_direction)
	material.set_shader_parameter("scroll_speed", 0.45 if scroll_direction > 0.0 else 0.4)
	material.set_shader_parameter("pulse_speed", 2.4 if scroll_direction > 0.0 else 2.0)
	material.set_shader_parameter("pulse_strength", 0.28)
	return material


func _create_glow_material(glow_color: Color, scroll_direction: float, alpha_scale: float) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://materials/power_band_glow.gdshader")
	material.set_shader_parameter("glow_color", Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * alpha_scale))
	material.set_shader_parameter("pulse_speed", 2.6 if scroll_direction > 0.0 else 2.1)
	material.set_shader_parameter("pulse_strength", 0.38)
	material.set_shader_parameter("sweep_speed", 0.62 if scroll_direction > 0.0 else 0.52)
	material.set_shader_parameter("sweep_direction", scroll_direction)
	return material


func _setup_particles(particle_color: Color, scroll_direction: float) -> void :
	var process_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(0.62, 0.04, 0.95)
	process_material.direction = Vector3(0.0, 1.0 if scroll_direction > 0.0 else -1.0, 0.0)
	process_material.spread = 18.0
	process_material.initial_velocity_min = 0.35
	process_material.initial_velocity_max = 0.95
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 0.05
	process_material.scale_max = 0.12
	process_material.color = particle_color
	process_material.color_ramp = _create_particle_gradient(particle_color)

	spark_particles.process_material = process_material
	spark_particles.amount = 10
	spark_particles.lifetime = 1.0
	spark_particles.preprocess = 0.0
	spark_particles.randomness = 0.45
	spark_particles.visibility_aabb = AABB(Vector3(-1.0, -0.5, -1.4), Vector3(2.0, 1.2, 2.8))
	spark_particles.emitting = false


func _create_particle_gradient(base_color: Color) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(base_color.r, base_color.g, base_color.b, 0.0))
	gradient.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0.95))
	gradient.add_point(0.35, Color(1.0, 1.0, 1.0, 0.85))
	var texture: GradientTexture1D = GradientTexture1D.new()
	texture.gradient = gradient
	return texture
