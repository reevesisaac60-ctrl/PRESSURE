class_name EyeballProjectile
extends RigidBody3D

signal hit_damageable(target: Node, amount: float)

@export var damage: float = 25.0
@export var lifetime: float = 3.0
@export var blood_effects: BloodEffects
@export var ignore_body: CollisionObject3D

var _alive: bool = true

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	if ignore_body:
		add_collision_exception_with(ignore_body)
	get_tree().create_timer(lifetime).timeout.connect(_expire)

func launch(direction: Vector3, speed: float) -> void:
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))

func _on_body_entered(body: Node) -> void:
	if not _alive:
		return
	_alive = false
	var damageable := Hitscan.find_damageable(body)
	if damageable:
		damageable.take_damage(damage)
		hit_damageable.emit(damageable, damage)
	var hit_position := global_position
	var hit_normal := Vector3.UP
	if body is Node3D:
		var away := global_position - (body as Node3D).global_position
		if away.length_squared() > 0.0001:
			hit_normal = away.normalized()
	if blood_effects:
		blood_effects.spawn_impact(hit_position, hit_normal)
	queue_free()

func _expire() -> void:
	if is_instance_valid(self):
		queue_free()
