class_name ViewmodelRenderer
extends Node

@export var enabled: bool = true
@export var main_camera: Camera3D
@export var viewmodel_root: Node3D

@export_group("Rendering")
@export_range(1, 20) var viewmodel_layer: int = 20
@export var canvas_layer_order: int = 0

var viewmodel_camera: Camera3D
var viewmodel_viewport: SubViewport
var viewmodel_display: TextureRect
var layer_bit: int = 0

func _ready() -> void:
	if not enabled or main_camera == null or viewmodel_root == null:
		return

	process_priority = 1000
	layer_bit = 1 << (viewmodel_layer - 1)

	set_layers_recursive(viewmodel_root, layer_bit)
	main_camera.cull_mask &= ~layer_bit

	viewmodel_viewport = SubViewport.new()
	viewmodel_viewport.transparent_bg = true
	viewmodel_viewport.handle_input_locally = false
	viewmodel_viewport.msaa_3d = get_viewport().msaa_3d
	viewmodel_viewport.size = get_window().size

	viewmodel_camera = Camera3D.new()
	viewmodel_camera.cull_mask = layer_bit
	viewmodel_viewport.add_child(viewmodel_camera)

	viewmodel_display = TextureRect.new()
	viewmodel_display.texture = viewmodel_viewport.get_texture()
	viewmodel_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewmodel_display.stretch_mode = TextureRect.STRETCH_SCALE
	viewmodel_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewmodel_display.set_anchors_preset(Control.PRESET_FULL_RECT)

	var canvas := CanvasLayer.new()
	canvas.layer = canvas_layer_order
	canvas.add_child(viewmodel_display)

	add_child(viewmodel_viewport)
	add_child(canvas)

	get_window().size_changed.connect(_on_window_resized)
	sync_camera()

func _process(_delta: float) -> void:
	sync_camera()

func sync_camera() -> void:
	if viewmodel_camera == null:
		return

	viewmodel_camera.global_transform = main_camera.global_transform
	viewmodel_camera.fov = main_camera.fov
	viewmodel_camera.near = main_camera.near
	viewmodel_camera.far = main_camera.far
	viewmodel_camera.keep_aspect = main_camera.keep_aspect

func _on_window_resized() -> void:
	viewmodel_viewport.size = get_window().size

func set_layers_recursive(node: Node, bit: int) -> void:
	var visual := node as VisualInstance3D

	if visual:
		visual.layers = bit

	for child in node.get_children():
		set_layers_recursive(child, bit)
