extends RigidBody3D

@export var minimum_lifetime: float = 1.0
@export var maximum_lifetime: float = 2.5

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 2
	var lifetime := randf_range(minimum_lifetime, maximum_lifetime)
	get_tree().create_timer(lifetime).timeout.connect(_expire)

func ignore_body(body: CollisionObject3D) -> void:
	add_collision_exception_with(body)

func _expire() -> void:
	if is_instance_valid(self):
		queue_free()
