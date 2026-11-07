extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_prefix: String = args[0]

	var world := Node3D.new()
	root.add_child(world)
	current_scene = world

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.04, 0.04)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.4, 0.35)
	env.environment = environment
	world.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	world.add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.2, 3.2)
	world.add_child(camera)
	camera.current = true

	var definition := EnemyDefinition.new()
	definition.enemy_name = "ZOMBIE"
	definition.max_health = 55.0

	var enemy: EnemyBase = load("res://scenes/enemies/EnemyBase.tscn").instantiate()
	enemy.definition = definition
	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	(mesh.mesh as CapsuleMesh).radius = 0.4
	(mesh.mesh as CapsuleMesh).height = 1.8
	var base := StandardMaterial3D.new()
	base.albedo_color = Color(0.35, 0.25, 0.2)
	mesh.material_override = null
	mesh.mesh.surface_set_material(0, base)
	enemy.add_child(mesh)
	enemy.position = Vector3(0, 0, 0)
	world.add_child(enemy)

	await process_frame
	enemy.set_physics_process(false)
	enemy.global_position = Vector3.ZERO
	enemy.velocity = Vector3.ZERO
	var display: ScrollingTextDisplay = enemy.label_display
	display.font = load("res://assets/Daydream DEMO.otf")
	display.font_size = 32
	display.refresh()

	if OS.get_environment("NO_OVERLAY") == "1":
		display.remove_from_meshes()
	for i in range(14):
		await process_frame
	print("enemy y=", enemy.global_position.y, " state=", enemy.state)
	save(out_prefix + "_a.png")

	for i in range(40):
		await process_frame
	save(out_prefix + "_b.png")

	enemy.take_damage(20.0)
	for i in range(12):
		await process_frame
	save(out_prefix + "_c.png")
	print("label text after damage: ", display.get_display_text())
	quit(0)

func save(path: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("center pixel ", image.get_pixel(image.get_width() / 2, image.get_height() / 2))
	print("saved ", path, " ", image.get_size())
