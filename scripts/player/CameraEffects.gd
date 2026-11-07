
class_name CameraEffects
extends Node

@export var body: CharacterBody3D
@export var camera: Camera3D
@export var look: PlayerLook
@export var movement: PlayerMovement

@export_group("Camera")
@export var normal_fov: float = 100.0
@export var maximum_fov: float = 112.0
@export var speed_fov_reference: float = 24.0
@export var fov_smoothing: float = 5.0

@export_group("Camera Tilt")
@export var maximum_tilt: float = 2.5
@export var tilt_smoothing: float = 8.0

@export_group("Camera Bob")
@export var bob_frequency: float = 9.0
@export var bob_amount: float = 0.025
@export var bob_speed_reference: float = 12.0

@export_group("Landing Feedback")
@export var landing_impact_strength: float = 0.8
@export var maximum_landing_kick: float = 0.18
@export var landing_spring: float = 100.0
@export var landing_damping: float = 18.0

var camera_start_position: Vector3
var camera_roll: float = 0.0
var bob_time: float = 0.0
var landing_offset: float = 0.0
var landing_velocity: float = 0.0

func _ready() -> void:
	if body == null:
		body = get_parent() as CharacterBody3D

	if camera == null or body == null:
		push_warning("CameraEffects requires a body and camera.")
		return

	camera.fov = normal_fov
	camera_start_position = camera.position

	if movement:
		movement.landed.connect(_on_landed)

func _on_landed(impact_speed: float) -> void:
	var impact := minf(impact_speed * landing_impact_strength, maximum_landing_kick * 10.0)
	landing_velocity -= impact

func _process(delta: float) -> void:
	if body == null or camera == null:
		return

	update_camera_fov(delta)
	update_camera_tilt(delta)
	update_camera_bob(delta)
	update_landing_effect(delta)

func update_camera_fov(delta: float) -> void:
	var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
	var speed_ratio := clampf(horizontal_speed / speed_fov_reference, 0.0, 1.0)
	var target_fov := lerpf(normal_fov, maximum_fov, speed_ratio)

	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-fov_smoothing * delta))

func update_camera_tilt(delta: float) -> void:
	var input_x := movement.current_input_x if movement else 0.0
	var pitch := look.pitch if look else 0.0
	var target_roll := -deg_to_rad(input_x * maximum_tilt)

	camera_roll = lerpf(camera_roll, target_roll, 1.0 - exp(-tilt_smoothing * delta))
	camera.rotation = Vector3(pitch, 0.0, camera_roll)

func update_camera_bob(delta: float) -> void:
	var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
	var is_moving := body.is_on_floor() and horizontal_speed > 0.5
	var bob_x := 0.0
	var bob_y := 0.0

	if is_moving:
		var intensity := clampf(horizontal_speed / bob_speed_reference, 0.0, 1.0)
		bob_time += delta * bob_frequency
		bob_x = cos(bob_time * 0.5) * bob_amount * intensity
		bob_y = absf(sin(bob_time)) * bob_amount * intensity

	camera.position = camera_start_position + Vector3(bob_x, bob_y + landing_offset, 0.0)

func update_landing_effect(delta: float) -> void:
	var spring_force := -landing_offset * landing_spring
	var damping_force := -landing_velocity * landing_damping

	landing_velocity += (spring_force + damping_force) * delta
	landing_offset += landing_velocity * delta
