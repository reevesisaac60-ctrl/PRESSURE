class_name ViewmodelController
extends Node3D

@export_group("References")
@export var player_body: CharacterBody3D
@export var animation_player: AnimationPlayer
@export var motion_target: Node3D

@export_group("Idle Motion")
@export var idle_breath_amount: float = 0.012
@export var idle_rotation_amount: float = 0.012
@export var idle_frequency: float = 1.5

@export_group("Movement Motion")
@export var movement_bob_amount: float = 0.035
@export var movement_bob_frequency: float = 9.0
@export var movement_sway_amount: float = 0.025
@export var movement_tilt_amount: float = 3.0
@export var movement_speed_reference: float = 20.0
@export var movement_smoothing: float = 10.0

@export_group("Air Motion")
@export var air_position_offset: float = 0.035
@export var air_rotation_amount: float = 2.0
@export var air_smoothing: float = 5.0

@export_group("Landing Motion")
@export var landing_position_amount: float = 0.12
@export var landing_rotation_amount: float = 5.0
@export var landing_spring: float = 90.0
@export var landing_damping: float = 16.0

@export_group("Mouse Motion")
@export var mouse_sway_amount: float = 0.0008
@export var mouse_smoothing: float = 12.0

@export_group("Shooting Recoil")
@export var recoil_position: float = 0.09
@export var recoil_rotation: float = 7.0
@export var recoil_recovery: float = 16.0

var base_position: Vector3
var base_rotation: Vector3

var idle_time: float = 0.0
var movement_time: float = 0.0

var current_motion_position: Vector3 = Vector3.ZERO
var current_motion_rotation: Vector3 = Vector3.ZERO

var recoil_amount: float = 0.0

var landing_offset: float = 0.0
var landing_velocity: float = 0.0
var previous_vertical_speed: float = 0.0
var was_on_floor: bool = true

var mouse_motion: Vector2 = Vector2.ZERO

func _ready() -> void:
	if motion_target == null:
		motion_target = self

	base_position = motion_target.position
	base_rotation = motion_target.rotation

	if player_body:
		was_on_floor = player_body.is_on_floor()

	if animation_player:
		if animation_player.has_animation("FingerGunIdle"):
			animation_player.play("FingerGunIdle")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion += event.relative

func _process(delta: float) -> void:
	update_motion(delta)

func update_motion(delta: float) -> void:
	idle_time += delta

	if player_body == null or motion_target == null:
		return

	var horizontal_velocity := Vector2(player_body.velocity.x, player_body.velocity.z)
	var horizontal_speed := horizontal_velocity.length()
	var local_velocity := player_body.global_basis.inverse() * player_body.velocity
	var speed_ratio := clampf(horizontal_speed / movement_speed_reference, 0.0, 1.5)
	var grounded := player_body.is_on_floor()
	
	var idle_position := Vector3(sin(idle_time * idle_frequency * 0.7) * idle_breath_amount, sin(idle_time * idle_frequency) * idle_breath_amount, 0.0)
	var idle_rotation := Vector3(sin(idle_time * idle_frequency) * idle_rotation_amount, cos(idle_time * idle_frequency * 0.6) * idle_rotation_amount, sin(idle_time * idle_frequency * 0.8) * idle_rotation_amount)

	var bob_position := Vector3.ZERO
	var bob_rotation := Vector3.ZERO

	if grounded and horizontal_speed > 0.5:
		movement_time += delta * movement_bob_frequency * clampf(horizontal_speed / 10.0, 0.5, 2.0)

		var bob_strength := speed_ratio
		bob_position.x = cos(movement_time * 0.5) * movement_bob_amount * bob_strength
		bob_position.y = absf(sin(movement_time)) * movement_bob_amount * bob_strength
		bob_rotation.z = sin(movement_time * 0.5) * deg_to_rad(movement_tilt_amount) * bob_strength

	var sway_position := Vector3.ZERO
	var sway_rotation := Vector3.ZERO

	sway_position.x = -local_velocity.x * movement_sway_amount * 0.08
	sway_position.z = local_velocity.z * movement_sway_amount * 0.035
	sway_rotation.z = -local_velocity.x * deg_to_rad(movement_tilt_amount) * 0.035
	sway_rotation.y = -local_velocity.x * 0.003

	var air_position := Vector3.ZERO
	var air_rotation := Vector3.ZERO

	if not grounded:
		air_position.y = air_position_offset
		air_position.x = -local_velocity.x * 0.002
		air_rotation.x = deg_to_rad(air_rotation_amount) * clampf(-local_velocity.y / 15.0, -1.0, 1.0)

	var mouse_rotation := Vector3(-mouse_motion.y * mouse_sway_amount, -mouse_motion.x * mouse_sway_amount, -mouse_motion.x * mouse_sway_amount * 0.5)
	mouse_motion = mouse_motion.lerp(Vector2.ZERO, 1.0 - exp(-mouse_smoothing * delta))
	
	if not grounded:
		previous_vertical_speed = player_body.velocity.y

	if grounded and not was_on_floor:
		var impact_strength := clampf(absf(previous_vertical_speed) / 18.0, 0.0, 1.5)
		landing_velocity -= landing_position_amount * impact_strength * 12.0
	
	was_on_floor = grounded

	var landing_force := -landing_offset * landing_spring
	var landing_damping_force := -landing_velocity * landing_damping
	landing_velocity += (landing_force + landing_damping_force) * delta
	landing_offset += landing_velocity * delta

	var landing_position := Vector3(0.0, landing_offset, 0.0)
	var landing_rotation := Vector3(deg_to_rad(landing_offset * landing_rotation_amount * 8.0), 0.0, 0.0)
	recoil_amount = move_toward(recoil_amount, 0.0, recoil_recovery * delta)

	var recoil_position_offset := Vector3(0.0, recoil_amount * recoil_position * 0.25, recoil_amount * recoil_position)
	var recoil_rotation_offset := Vector3(deg_to_rad(recoil_amount * recoil_rotation), 0.0, 0.0)

	var target_position := (
		idle_position
		+ bob_position
		+ sway_position
		+ air_position
		+ landing_position
		+ recoil_position_offset
	)

	var target_rotation := (
		idle_rotation
		+ bob_rotation
		+ sway_rotation
		+ air_rotation
		+ mouse_rotation
		+ landing_rotation
		+ recoil_rotation_offset
	)

	var smoothing := movement_smoothing

	if not grounded:
		smoothing = air_smoothing

	var blend := 1.0 - exp(-smoothing * delta)
	current_motion_position = current_motion_position.lerp(target_position, blend)
	current_motion_rotation = current_motion_rotation.lerp(target_rotation, blend)
	motion_target.position = base_position + current_motion_position
	motion_target.rotation = base_rotation + current_motion_rotation

func play_shoot_animation() -> void:
	recoil_amount = minf(recoil_amount + 1.0, 1.5)

func play_recoil_tween(strength: float = 1.2, kick_time: float = 0.07, recover_time: float = 0.2) -> void:
	var tween := create_tween()
	var peak := minf(recoil_amount + strength, 2.0)
	tween.tween_method(func(v: float) -> void: recoil_amount = v, recoil_amount, peak, kick_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void: recoil_amount = v, peak, 0.0, recover_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
