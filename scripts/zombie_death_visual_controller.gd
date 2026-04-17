extends RefCounted
class_name ZombieDeathVisualController

const ZombieDeathVisuals = preload("res://scripts/zombie_death_visuals.gd")

func spawn_visual_instance(
	zombie: Node3D,
	visual_profile: Dictionary,
	anchor_nodes: Dictionary
) -> Dictionary:
	var mode: String = String(visual_profile.get("visual_mode", ZombieDeathVisuals.VISUAL_MODE_NONE))
	var anchor_name: String = String(visual_profile.get("spawn_anchor", "root"))
	var anchor_offset: Vector3 = _read_vec3(visual_profile, "anchor_offset", Vector3.ZERO)
	var anchor_node: Node3D = _resolve_anchor_node(anchor_nodes, anchor_name, zombie)

	var instance_root := Node3D.new()
	instance_root.name = "DeathSubtypeVisualRoot"
	instance_root.position = anchor_offset
	anchor_node.add_child(instance_root)

	var instance_data: Dictionary = {
		"mode": mode,
		"root_node": instance_root,
		"visual_node": null,
		"is_placeholder": true,
		"is_active": false,
		"anchor": anchor_name
	}

	match mode:
		ZombieDeathVisuals.VISUAL_MODE_NONE:
			instance_data["is_active"] = false
		ZombieDeathVisuals.VISUAL_MODE_PARTICLE:
			instance_data = _spawn_particle_mode(instance_data, visual_profile)
		ZombieDeathVisuals.VISUAL_MODE_ATTACHMENT_MODEL:
			instance_data = _spawn_attachment_placeholder(instance_data, visual_profile)
		ZombieDeathVisuals.VISUAL_MODE_MESH_OVERLAY:
			instance_data = _spawn_overlay_placeholder(instance_data, visual_profile)
		_:
			instance_data = _spawn_overlay_placeholder(instance_data, visual_profile)

	return instance_data

func clear_instance(instance_data: Dictionary):
	var root_variant: Variant = instance_data.get("root_node", null)
	if root_variant is Node:
		var root_node: Node = root_variant
		if is_instance_valid(root_node):
			root_node.queue_free()

func _spawn_particle_mode(instance_data: Dictionary, visual_profile: Dictionary) -> Dictionary:
	var intensity: float = clampf(float(visual_profile.get("intensity", 0.28)), 0.08, 1.0)
	var primary_color: Color = visual_profile.get("display_color", Color(0.48, 0.58, 0.62, 1.0))
	var secondary_color: Color = visual_profile.get("secondary_color", Color(0.32, 0.38, 0.42, 0.0))

	var particles := GPUParticles3D.new()
	particles.name = "DeathSubtypeParticles"
	particles.amount = int(round(10.0 + intensity * 26.0))
	particles.lifetime = lerpf(0.7, 1.3, intensity)
	particles.one_shot = false
	particles.preprocess = 0.2
	particles.explosiveness = 0.0
	particles.randomness = 0.45
	particles.fixed_fps = 30
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-0.7, -0.7, -0.7), Vector3(1.4, 1.4, 1.4))

	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = lerpf(0.01, 0.024, intensity)
	draw_mesh.height = draw_mesh.radius * 2.0
	particles.draw_pass_1 = draw_mesh

	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = lerpf(0.06, 0.18, intensity)
	particle_material.direction = Vector3(0.0, 1.0, 0.0)
	particle_material.spread = lerpf(18.0, 40.0, intensity)
	particle_material.gravity = Vector3(0.0, lerpf(0.15, 0.42, intensity), 0.0)
	particle_material.initial_velocity_min = lerpf(0.08, 0.22, intensity)
	particle_material.initial_velocity_max = lerpf(0.22, 0.55, intensity)
	particle_material.scale_min = lerpf(0.45, 0.6, intensity)
	particle_material.scale_max = lerpf(0.85, 1.35, intensity)
	particle_material.damping_min = 0.2
	particle_material.damping_max = 0.75
	particle_material.angular_velocity_min = -1.6
	particle_material.angular_velocity_max = 1.6
	particle_material.color_ramp = _build_color_ramp(primary_color, secondary_color, intensity)
	particles.process_material = particle_material

	(instance_data.get("root_node") as Node3D).add_child(particles)
	particles.emitting = true

	instance_data["visual_node"] = particles
	instance_data["is_placeholder"] = true
	instance_data["is_active"] = true
	return instance_data

func _spawn_attachment_placeholder(instance_data: Dictionary, visual_profile: Dictionary) -> Dictionary:
	var marker := MeshInstance3D.new()
	marker.name = "DeathSubtypeAttachmentPlaceholder"
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.08, 0.08, 0.08)
	marker.mesh = marker_mesh
	var marker_mat := StandardMaterial3D.new()
	var color_value: Color = visual_profile.get("display_color", Color(0.48, 0.58, 0.62, 1.0))
	marker_mat.albedo_color = color_value
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_mat.albedo_color.a = 0.35
	marker.material_override = marker_mat
	(instance_data.get("root_node") as Node3D).add_child(marker)
	instance_data["visual_node"] = marker
	instance_data["is_placeholder"] = true
	instance_data["is_active"] = false
	return instance_data

func _spawn_overlay_placeholder(instance_data: Dictionary, visual_profile: Dictionary) -> Dictionary:
	return _spawn_attachment_placeholder(instance_data, visual_profile)

func _resolve_anchor_node(anchor_nodes: Dictionary, anchor_name: String, fallback: Node3D) -> Node3D:
	var candidate: Variant = anchor_nodes.get(anchor_name, null)
	if candidate is Node3D:
		var node3d: Node3D = candidate
		if is_instance_valid(node3d):
			return node3d
	var root_candidate: Variant = anchor_nodes.get("root", null)
	if root_candidate is Node3D and is_instance_valid(root_candidate):
		return root_candidate
	return fallback

func _build_color_ramp(primary_color: Color, secondary_color: Color, intensity: float) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(primary_color.r, primary_color.g, primary_color.b, lerpf(0.0, 0.28, intensity)),
		Color(primary_color.r, primary_color.g, primary_color.b, lerpf(0.3, 0.75, intensity)),
		Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp

func _read_vec3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if value is Vector3:
		return value
	return fallback

