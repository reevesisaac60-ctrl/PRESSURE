
class_name PlayerMovement
extends Node

signal landed(impact_speed: float)

@export var body: CharacterBody3D
@export var camera: Camera3D

@export_group("Ground Movement")
@export var ground_speed: float = 10.0
@export var ground_acceleration: float = 55.0
@export var ground_friction: float = 8.0
@export var stop_speed: float = 2.0

@export_group("Air Movement")
@export var air_speed: float = 10.0
@export var air_acceleration: float = 12.0

@export_group("Jumping")
@export var jump_velocity: float = 7.5
@export var gravity: float = 22.0

@export_group("Wall Kicking")
@export var wall_kick_horizontal: float = 11.0
@export var wall_kick_vertical: float = 9.0
@export var wall_kick_momentum: float = 0.65
@export var wall_contact_grace: float = 0.18
@export var wall_kick_lockout: float = 0.2

@export_group("Dashing")
@export var dash_speed: float = 26.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 2.0

@export_group("Swimming")
@export var underwater_speed: float = 7.0
@export var underwater_acceleration: float = 9.0
@export var underwater_gravity: float = 4.0
@export var underwater_buoyancy: float = 7.0
@export var underwater_drag: float = 1.0
@export var underwater_vertical_drag: float = 0.5
@export var underwater_swim_acceleration: float = 16.0
@export var underwater_max_vertical_speed: float = 8.0
@export var underwater_dash_drag: float = 0.35

const LANDING_MINIMUM_SPEED: float = 3.0

var current_input_x: float = 0.0

var wall_normal: Vector3 = Vector3.ZERO
var wall_contact_timer: float = 0.0
var wall_kick_lockout_timer: float = 0.0

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var is_submerged: bool = false
var water_surface_height: float = 0.0

func _ready() -> void:
	if body == null:
		body = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	if body == null:
		return

	var was_on_floor := body.is_on_floor()
	var previous_vertical_speed := body.velocity.y

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	current_input_x = input_vector.x

	var wish_direction := (
		body.transform.basis *
		Vector3(input_vector.x, 0.0, input_vector.y)
	).normalized()

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	wall_kick_lockout_timer = maxf(wall_kick_lockout_timer - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		start_dash(wish_direction)

	if dash_timer > 0.0:
		dash_timer = maxf(dash_timer - delta, 0.0)

		if is_submerged:
			apply_underwater_passive_forces(delta, underwater_dash_drag)

		body.move_and_slide()
		update_wall_contact(delta)
		check_landing(was_on_floor, previous_vertical_speed)
		return

	if is_submerged:
		apply_underwater_movement(wish_direction, delta)
	else:
		apply_normal_movement(wish_direction, delta)

	body.move_and_slide()

	update_wall_contact(delta)
	check_landing(was_on_floor, previous_vertical_speed)

func apply_normal_movement(wish_direction: Vector3, delta: float) -> void:
	var wall_kicked := false
	var was_on_floor := body.is_on_floor()

	if not was_on_floor and Input.is_action_just_pressed("jump"):
		if wall_contact_timer > 0.0:
			perform_wall_kick()
			wall_kicked = true

	if was_on_floor:
		apply_ground_friction(delta)
		accelerate(wish_direction, ground_speed, ground_acceleration, delta)

		if Input.is_action_pressed("jump"):
			body.velocity.y = jump_velocity

	elif not wall_kicked:
		body.velocity.y -= gravity * delta
		accelerate(wish_direction, air_speed, air_acceleration, delta)

func apply_underwater_movement(wish_direction: Vector3, delta: float) -> void:
	var wall_kicked := false

	if not body.is_on_floor() and Input.is_action_just_pressed("jump"):
		if wall_contact_timer > 0.0:
			perform_wall_kick()
			wall_kicked = true

	apply_underwater_passive_forces(delta, underwater_drag)

	accelerate(
		wish_direction,
		underwater_speed,
		underwater_acceleration,
		delta
	)

	if Input.is_action_pressed("jump") and not wall_kicked:
		body.velocity.y += underwater_swim_acceleration * delta

	if Input.is_action_pressed("dive"):
		body.velocity.y -= underwater_swim_acceleration * delta

	body.velocity.y = clampf(
		body.velocity.y,
		-underwater_max_vertical_speed,
		underwater_max_vertical_speed
	)

func apply_underwater_passive_forces(delta: float, horizontal_drag: float) -> void:
	body.velocity.y -= underwater_gravity * delta

	if body.global_position.y < water_surface_height:
		body.velocity.y += underwater_buoyancy * delta

	var horizontal_velocity := Vector3(
		body.velocity.x,
		0.0,
		body.velocity.z
	)

	horizontal_velocity = horizontal_velocity.move_toward(
		Vector3.ZERO,
		horizontal_drag * delta
	)

	body.velocity.x = horizontal_velocity.x
	body.velocity.z = horizontal_velocity.z

	body.velocity.y = move_toward(
		body.velocity.y,
		0.0,
		underwater_vertical_drag * delta
	)

func set_submerged(value: bool, surface_height: float = 0.0) -> void:
	is_submerged = value

	if value:
		water_surface_height = surface_height

func start_dash(wish_direction: Vector3) -> void:
	var direction := wish_direction

	if direction.length_squared() < 0.001:
		if camera != null:
			direction = -camera.global_basis.z
		else:
			direction = -body.global_basis.z

		direction.y = 0.0
		direction = direction.normalized()

	direction = direction.normalized()

	body.velocity.x = direction.x * dash_speed
	body.velocity.z = direction.z * dash_speed

	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

func perform_wall_kick() -> void:
	var normal := wall_normal.normalized()

	var horizontal_velocity := Vector3(
		body.velocity.x,
		0.0,
		body.velocity.z
	)

	var wall_tangent := horizontal_velocity.slide(normal)

	body.velocity.x = (
		normal.x * wall_kick_horizontal +
		wall_tangent.x * wall_kick_momentum
	)

	body.velocity.z = (
		normal.z * wall_kick_horizontal +
		wall_tangent.z * wall_kick_momentum
	)

	body.velocity.y = wall_kick_vertical

	wall_contact_timer = 0.0
	wall_kick_lockout_timer = wall_kick_lockout

func update_wall_contact(delta: float) -> void:
	wall_contact_timer = maxf(wall_contact_timer - delta, 0.0)

	if wall_kick_lockout_timer > 0.0:
		return

	for i in range(body.get_slide_collision_count()):
		var collision := body.get_slide_collision(i)
		var normal := collision.get_normal()

		if absf(normal.y) < 0.2:
			wall_normal = normal.normalized()
			wall_contact_timer = wall_contact_grace
			return

func apply_ground_friction(delta: float) -> void:
	var horizontal_velocity := Vector3(
		body.velocity.x,
		0.0,
		body.velocity.z
	)

	var speed := horizontal_velocity.length()

	if speed < 0.01:
		body.velocity.x = 0.0
		body.velocity.z = 0.0
		return

	var control := maxf(speed, stop_speed)
	var drop := control * ground_friction * delta
	var new_speed := maxf(speed - drop, 0.0)

	horizontal_velocity *= new_speed / speed

	body.velocity.x = horizontal_velocity.x
	body.velocity.z = horizontal_velocity.z

func accelerate(
	wish_direction: Vector3,
	wish_speed: float,
	acceleration: float,
	delta: float
) -> void:
	if wish_direction.length_squared() < 0.001:
		return

	var current_speed := body.velocity.dot(wish_direction)
	var add_speed := wish_speed - current_speed

	if add_speed <= 0.0:
		return

	var acceleration_speed := acceleration * wish_speed * delta
	acceleration_speed = minf(acceleration_speed, add_speed)

	body.velocity += wish_direction * acceleration_speed

func check_landing(was_on_floor: bool, previous_vertical_speed: float) -> void:
	if not was_on_floor and body.is_on_floor():
		if previous_vertical_speed < -LANDING_MINIMUM_SPEED:
			landed.emit(-previous_vertical_speed)
