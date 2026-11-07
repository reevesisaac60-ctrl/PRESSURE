
@tool
class_name PressureWater
extends Node3D

@export_group("Dimensions")
@export_range(1.0, 100.0, 0.5) var water_width: float = 12.0:
	set(value):
		water_width = maxf(value, 1.0)
		_update_geometry()

@export_range(1.0, 100.0, 0.5) var water_depth: float = 8.0:
	set(value):
		water_depth = maxf(value, 1.0)
		_update_geometry()

@export_range(0.5, 50.0, 0.5) var water_height: float = 5.0:
	set(value):
		water_height = maxf(value, 0.5)
		_update_geometry()

@export_range(2, 128, 1) var subdivisions: int = 64:
	set(value):
		subdivisions = maxi(value, 2)
		_update_geometry()

@export_group("Swimming")
@export var enable_swimming: bool = true

var surface: MeshInstance3D
var physics_volume: Area3D
var collision_shape: CollisionShape3D
var water_material: ShaderMaterial

func _ready() -> void:
	surface = get_node_or_null("Surface") as MeshInstance3D
	physics_volume = get_node_or_null("PhysicsVolume") as Area3D

	if surface == null or physics_volume == null:
		push_error("PressureWater requires Surface and PhysicsVolume nodes.")
		return

	collision_shape = physics_volume.get_node_or_null("CollisionShape3D") as CollisionShape3D

	if collision_shape == null:
		push_error("PressureWater requires a CollisionShape3D.")
		return

	_update_geometry()

	if not Engine.is_editor_hint():
		physics_volume.body_entered.connect(_on_body_entered)
		physics_volume.body_exited.connect(_on_body_exited)

func _update_geometry() -> void:
	if not is_instance_valid(surface) or not is_instance_valid(collision_shape):
		return

	var plane := surface.mesh as PlaneMesh

	if plane == null:
		plane = PlaneMesh.new()
		surface.mesh = plane
		plane.orientation = PlaneMesh.FACE_Y

	plane.size = Vector2(water_width, water_depth)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions

	var box := collision_shape.shape as BoxShape3D

	if box == null:
		box = BoxShape3D.new()
		collision_shape.shape = box

	box.size = Vector3(water_width, water_height, water_depth)
	collision_shape.position = Vector3(0.0, -water_height * 0.5, 0.0)

func _on_body_entered(body: Node3D) -> void:
	if not enable_swimming or not body.is_in_group("player"):
		return

	var movement := body.get_node_or_null("Movement") as PlayerMovement

	if movement != null:
		movement.set_submerged(true, global_position.y)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var movement := body.get_node_or_null("Movement") as PlayerMovement

	if movement != null:
		movement.set_submerged(false)
