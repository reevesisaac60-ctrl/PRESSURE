class_name BloodEffects
extends Node

@export var ignore_body: CollisionObject3D

@export_group("Blood Effects")
@export var impact_effect_scene: PackedScene
@export var impact_lifetime: float = 2.0

@export_group("Physical Blood")
@export var blood_droplet_scene: PackedScene
@export var droplet_count: int = 10
@export var droplet_min_speed: float = 3.0
@export var droplet_max_speed: float = 9.0
@export var droplet_spread: float = 0.8

@export_group("Blood Splatter")
@export var blood_splatter_scene: PackedScene
@export var splatter_lifetime: float = 12.0
@export var splatter_random_scale: Vector2 = Vector2(0.7, 1.4)

func spawn_impact(position: Vector3, normal: Vector3) -> void:
	if impact_effect_scene:
		var effect := impact_effect_scene.instantiate() as Node3D
		if effect:
			get_tree().current_scene.add_child(effect)
			effect.global_position = position
			var up_direction := Vector3.UP
			if absf(normal.dot(Vector3.UP)) > 0.98:
				up_direction = Vector3.FORWARD
			effect.look_at(position + normal, up_direction)
			var particles := effect.get_node_or_null("GPUParticles3D")
			if particles:
				particles.restart()
				particles.emitting = true
			get_tree().create_timer(impact_lifetime).timeout.connect(_free_node.bind(effect))
	spawn_splatter(position, normal)
	if blood_droplet_scene == null:
		return
	for i in range(droplet_count):
		var droplet := blood_droplet_scene.instantiate() as RigidBody3D
		if droplet == null:
			continue
		get_tree().current_scene.add_child(droplet)
		droplet.global_position = position + normal * 0.04
		if ignore_body and droplet.has_method("ignore_body"):
			droplet.ignore_body(ignore_body)
		var random_direction := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		var direction := (normal + random_direction * droplet_spread).normalized()
		var speed := randf_range(droplet_min_speed, droplet_max_speed)
		droplet.linear_velocity = direction * speed
		droplet.angular_velocity = Vector3(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))

func spawn_splatter(position: Vector3, normal: Vector3) -> void:
	if blood_splatter_scene == null:
		return
	var splatter := blood_splatter_scene.instantiate() as Decal
	if splatter == null:
		return
	get_tree().current_scene.add_child(splatter)
	splatter.global_position = position + normal * 0.02
	var up_direction := Vector3.UP
	if absf(normal.dot(Vector3.UP)) > 0.98:
		up_direction = Vector3.FORWARD
	splatter.look_at(position + normal, up_direction)
	splatter.rotate_object_local(Vector3(0.0, 0.0, 1.0), randf_range(0.0, TAU))
	var scale_amount := randf_range(splatter_random_scale.x, splatter_random_scale.y)
	splatter.size.x *= scale_amount
	splatter.size.y *= scale_amount
	get_tree().create_timer(splatter_lifetime).timeout.connect(_free_node.bind(splatter))

func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
