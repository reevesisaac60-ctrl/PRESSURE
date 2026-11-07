class_name PlayerController
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal died

@onready var camera: Camera3D = $Camera3D
@onready var movement: PlayerMovement = $Movement
@onready var look: PlayerLook = $Look
@onready var camera_effects: CameraEffects = $CameraEffects
@onready var health: HealthComponent = $Health
@onready var right_hand: Node3D = $Camera3D/ViewModel/RightHand
@onready var shotgun: Node3D = $Camera3D/ViewModel/Shotgun
@onready var finger_gun: FingerGun = $Camera3D/ViewModel/RightHand/FingerGun

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	health.health_changed.connect(func(current: float, maximum: float) -> void: health_changed.emit(current, maximum))
	health.died.connect(func() -> void: died.emit())
	_equip_finger_gun()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("equip_finger_gun"):
		_equip_finger_gun()
	elif event.is_action_pressed("equip_shotgun"):
		_equip_shotgun()

func take_damage(amount: float) -> void:
	health.take_damage(amount)

func _equip_finger_gun() -> void:
	if right_hand:
		right_hand.visible = true
	if shotgun:
		shotgun.visible = false
	if finger_gun:
		finger_gun.is_active = true

func _equip_shotgun() -> void:
	if right_hand:
		right_hand.visible = false
	if shotgun:
		shotgun.visible = true
	if finger_gun:
		finger_gun.is_active = false
