class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died

@export var max_health: float = 100.0

var current_health: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func setup(new_max_health: float) -> void:
	max_health = new_max_health
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0

	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		is_dead = true
		died.emit()

	return applied

func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0

	var applied := minf(amount, max_health - current_health)
	current_health += applied
	healed.emit(applied)
	health_changed.emit(current_health, max_health)
	return applied

func get_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
