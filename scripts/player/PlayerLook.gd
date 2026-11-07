class_name PlayerLook
extends Node

@export var body: CharacterBody3D

@export_group("Mouse")
@export var mouse_sensitivity: float = 0.002
@export var minimum_pitch: float = -89.0
@export var maximum_pitch: float = 89.0

var pitch: float = 0.0

func _ready() -> void:
	if body == null:
		body = get_parent() as CharacterBody3D

func _unhandled_input(event: InputEvent) -> void:
	if body == null:
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			body.rotate_y(-event.relative.x * mouse_sensitivity)
			pitch -= event.relative.y * mouse_sensitivity
			pitch = clampf(pitch, deg_to_rad(minimum_pitch), deg_to_rad(maximum_pitch))
