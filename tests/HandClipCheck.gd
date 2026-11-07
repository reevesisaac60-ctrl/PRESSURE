extends SceneTree

func make_wall(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh.mesh = box_mesh
	body.add_child(mesh)
	body.position = pos
	return body

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var player_scene_path: String = args[0]
	var out_path: String = args[1]
	var wall_distance: float = float(args[2])

	var world := Node3D.new()
	root.add_child(world)
	current_scene = world

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.2, 0.25, 0.4)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 20, 0)
	world.add_child(light)

	world.add_child(make_wall(Vector3(100, 2, 100), Vector3(0, -2, 0), Color(0.3, 0.3, 0.3)))
	world.add_child(make_wall(Vector3(30, 20, 2), Vector3(0, 8, -wall_distance - 1.0), Color(0.9, 0.9, 0.85)))

	var player: Node3D = load(player_scene_path).instantiate()
	world.add_child(player)

	for i in range(60):
		await process_frame
	root.get_texture().get_image().save_png(out_path)
	print("captured ", out_path, " wall_distance=", wall_distance)
	quit(0)
