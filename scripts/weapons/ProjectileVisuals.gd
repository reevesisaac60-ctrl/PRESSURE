class_name ProjectileVisuals
extends Node

@export var muzzle_point: Marker3D
@export var blood_effects: BloodEffects

@export_group("Meat Projectile")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 80.0
@export var projectile_minimum_time: float = 0.08
@export var projectile_maximum_time: float = 2.0
@export var random_rotation: bool = true
@export var tumbling_speed: float = 8.0

func launch(target_position: Vector3, hit_normal: Vector3, did_hit: bool) -> void:
	if projectile_scene == null or muzzle_point == null:
		return
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	var start_position := muzzle_point.global_position
	projectile.global_position = start_position
	if random_rotation:
		projectile.rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
	var distance := start_position.distance_to(target_position)
	var travel_time := clampf(distance / maxf(projectile_speed, 0.01), projectile_minimum_time, projectile_maximum_time)
	var final_rotation := projectile.rotation + Vector3(randf_range(-tumbling_speed, tumbling_speed), randf_range(-tumbling_speed, tumbling_speed), randf_range(-tumbling_speed, tumbling_speed))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(projectile, "global_position", target_position, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(projectile, "rotation", final_rotation, travel_time)
	tween.set_parallel(false)
	tween.tween_callback(_on_projectile_arrived.bind(projectile, target_position, hit_normal, did_hit))

func _on_projectile_arrived(projectile: Node3D, target_position: Vector3, hit_normal: Vector3, did_hit: bool) -> void:
	if did_hit and blood_effects:
		blood_effects.spawn_impact(target_position, hit_normal)
	if is_instance_valid(projectile):
		projectile.queue_free()
