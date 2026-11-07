class_name ScrollingTextDisplay
extends Node

const TEXT_SHADER: Shader = preload("res://shaders/ScrollingText.gdshader")

@export var target_root: Node

@export_group("Text")
@export var display_name: String = ""
@export var text_template: String = "{name}: {health}"
@export var text_separator: String = "   "
@export var font: Font
@export var font_size: int = 32

@export_group("Appearance")
@export var text_color: Color = Color(0.9, 0.12, 0.05, 1.0)
@export var opacity: float = 1.0
@export var brightness: float = 1.0
@export var pixelate: float = 0.0

@export_group("Scrolling")
@export var scroll_speed: float = 0.15
@export var scroll_direction: Vector2 = Vector2.RIGHT
@export var alternate_rows: bool = true

@export_group("Mapping")
@export var tiling: Vector2 = Vector2(1.0, 5.0)
@export var object_space_mapping: bool = true
@export var object_space_scale: float = 1.0

var current_health: float = 0.0
var maximum_health: float = 0.0

var text_viewport: SubViewport
var text_label: Label
var text_material: ShaderMaterial
var applied_meshes: Array[GeometryInstance3D] = []
var is_ready: bool = false

func _ready() -> void:
	text_viewport = SubViewport.new()
	text_viewport.transparent_bg = true
	text_viewport.disable_3d = true
	text_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	text_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(text_viewport)

	text_label = Label.new()
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_viewport.add_child(text_label)

	text_material = ShaderMaterial.new()
	text_material.shader = TEXT_SHADER
	text_material.set_shader_parameter("text_texture", text_viewport.get_texture())

	is_ready = true
	refresh()
	apply_to_meshes()

func _exit_tree() -> void:
	remove_from_meshes()

func configure(new_name: String, new_template: String, new_color: Color, new_scroll_speed: float) -> void:
	display_name = new_name
	text_template = new_template
	text_color = new_color
	scroll_speed = new_scroll_speed
	refresh()

func bind_health(source: HealthComponent) -> void:
	source.health_changed.connect(set_health)
	set_health(source.current_health, source.max_health)

func set_health(current: float, maximum: float) -> void:
	current_health = current
	maximum_health = maximum
	refresh()

func set_display_name(new_name: String) -> void:
	display_name = new_name
	refresh()

func get_display_text() -> String:
	var unit := text_template.format({
		"name": display_name,
		"health": ceili(current_health),
		"max_health": ceili(maximum_health)
	})
	return unit + text_separator

func refresh() -> void:
	if not is_ready:
		return

	var active_font: Font = font if font else ThemeDB.fallback_font
	var unit_text := get_display_text()
	var text_size := active_font.get_string_size(unit_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	text_label.add_theme_font_override("font", active_font)
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.text = unit_text
	text_viewport.size = Vector2i(maxi(ceili(text_size.x), 1), maxi(ceili(text_size.y), 1))
	text_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	text_material.set_shader_parameter("text_color", text_color)
	text_material.set_shader_parameter("opacity", opacity)
	text_material.set_shader_parameter("brightness", brightness)
	text_material.set_shader_parameter("pixelate", pixelate)
	text_material.set_shader_parameter("scroll_speed", scroll_speed)
	text_material.set_shader_parameter("scroll_direction", scroll_direction)
	text_material.set_shader_parameter("alternate_rows", alternate_rows)
	text_material.set_shader_parameter("tiling", tiling)
	text_material.set_shader_parameter("object_space_mapping", object_space_mapping)
	text_material.set_shader_parameter("object_space_scale", object_space_scale)

func apply_to_meshes() -> void:
	remove_from_meshes()

	var root_node: Node = target_root if target_root else get_parent()

	if root_node == null:
		return

	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as GeometryInstance3D
		mesh.material_overlay = text_material
		applied_meshes.append(mesh)

func remove_from_meshes() -> void:
	for mesh in applied_meshes:
		if is_instance_valid(mesh) and mesh.material_overlay == text_material:
			mesh.material_overlay = null

	applied_meshes.clear()
