class_name FingerGun
extends Node

signal fired
signal hit_damageable(target: Node, amount: float)

@export_group("References")
@export var camera: Camera3D
@export var player_body: CharacterBody3D
@export var viewmodel: ViewmodelController
@export var projectile_visuals: ProjectileVisuals

@export_group("Weapon")
@export var damage: float = 20.0
@export var range: float = 1000.0
@export var fire_rate: float = 0.2
@export_flags_3d_physics var collision_mask: int = 1

var can_fire: bool = true
var is_active: bool = true

func _process(_delta: float) -> void:
	if not is_active:
		return
	if Input.is_action_just_pressed("fire") and can_fire:
		fire()

func fire() -> void:
	if not can_fire or not is_active:
		return
	if camera == null:
		return
	can_fire = false
	if viewmodel:
		viewmodel.play_shoot_animation()
	var shot := perform_hitscan()
	if projectile_visuals:
		projectile_visuals.launch(shot["position"], shot["normal"], shot["hit"])
	fired.emit()
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func perform_hitscan() -> Dictionary:
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
