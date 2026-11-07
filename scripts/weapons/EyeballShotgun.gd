class_name EyeballShotgun
extends Node3D

signal fired
signal hit_damageable(target: Node, amount: float)

@export_group("References")
@export var camera: Camera3D
@export var player_body: CharacterBody3D
@export var viewmodel: ViewmodelController
@export var blood_effects: BloodEffects
@export var muzzle_left: Marker3D
@export var muzzle_right: Marker3D

@export_group("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 50.0
@export var projectile_minimum_time: float = 0.08
@export var projectile_maximum_time: float = 2.0
@export var random_rotation: bool = true
@export var tumbling_speed: float = 12.0

@export_group("Weapon")
@export var damage: float = 25.0
@export var range: float = 1000.0
@export var fire_rate: float = 0.55
@export var knockback_force: float = 7.5
@export var visual_recoil_strength: float = 1.4
@export var visual_recoil_kick_time: float = 0.07
@export var visual_recoil_recover_time: float = 0.22
@export_flags_3d_physics var collision_mask: int = 1

var can_fire: bool = true
var _shotgun_root: Node3D

func _ready() -> void:
	_shotgun_root = get_parent() as Node3D
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if player_body == null:
		var n := get_tree().get_first_node_in_group("player")
		if n is CharacterBody3D:
			player_body = n

func _process(_delta: float) -> void:
	if _shotgun_root and not _shotgun_root.visible:
		return
	if not can_fire:
		return
	if Input.is_action_just_pressed("fire"):
		fire()

func fire() -> void:
	if not can_fire:
		return
	if _shotgun_root and not _shotgun_root.visible:
		return
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	if projectile_scene == null:
		return
	if muzzle_left == null or muzzle_right == null:
		return
	can_fire = false
	var shot := _perform_hitscan()
	_launch_visual(muzzle_left.global_position, shot["position"], shot["normal"], shot["hit"])
	_launch_visual(muzzle_right.global_position, shot["position"], shot["normal"], shot["hit"])
	_apply_visual_recoil()
	_apply_player_knockback(-camera.global_transform.basis.z)
	fired.emit()
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _perform_hitscan() -> Dictionary:
	var exclude: Array[RID] = []
	if player_body:
		exclude.append(player_body.get_rid())
	var shot := Hitscan.cast_from_camera(camera, range, collision_mask, exclude)
	var hit_object := shot["collider"] as Node
	if hit_object:
		var damageable := Hitscan.find_damageable(hit_object)
		if damageable:
			damageable.take_damage(damage)
			hit_damageable.emit(damageable, damage)
	return shot

func _launch_visual(start_position: Vector3, target_position: Vector3, hit_normal: Vector3, did_hit: bool) -> void:
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = start_position
	projectile.scale = Vector3(0.25, 0.25, 0.25)
	if random_rotation:
		projectile.rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
	var distance := start_position.distance_to(target_position)
	var travel_time := clampf(distance / maxf(projectile_speed, 0.01), projectile_minimum_time, projectile_maximum_time)
	var final_rotation := projectile.rotation + Vector3(
		randf_range(-tumbling_speed, tumbling_speed),
		randf_range(-tumbling_speed, tumbling_speed),
		randf_range(-tumbling_speed, tumbling_speed)
	)
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

func _apply_visual_recoil() -> void:
	if viewmodel and viewmodel.has_method("play_recoil_tween"):
		viewmodel.play_recoil_tween(visual_recoil_strength, visual_recoil_kick_time, visual_recoil_recover_time)
	elif viewmodel:
		viewmodel.play_shoot_animation()

func _apply_player_knockback(aim_dir: Vector3) -> void:
	if player_body == null:
		return
	player_body.velocity -= aim_dir.normalized() * knockback_force
