extends SceneTree

var failures: int = 0

func check(label: String, condition: bool) -> void:
	print("PASS  " if condition else "FAIL  ", label)
	if not condition:
		failures += 1

func hand_layers(node: Node, out: Array) -> void:
	var visual := node as VisualInstance3D
	if visual:
		out.append(visual.layers)
	for child in node.get_children():
		hand_layers(child, out)

func _initialize() -> void:
	var out_disabled: String = OS.get_cmdline_user_args()[0]
	var packed: PackedScene = load("res://scenes/levels/TestPlace.tscn")

	var disabled_scene := packed.instantiate()
	var disabled_renderer := disabled_scene.find_child("ViewmodelRenderer", true, false) as ViewmodelRenderer
	disabled_renderer.enabled = false
	root.add_child(disabled_scene)
	current_scene = disabled_scene
	for i in range(90):
		await process_frame
	var disabled_camera := disabled_scene.find_child("Camera3D", true, false) as Camera3D
	var layers_off: Array = []
	hand_layers(disabled_scene.find_child("ViewModel", true, false), layers_off)
	check("enabled=false: hand meshes stay on layer 1", layers_off.all(func(l: int) -> bool: return l == 1))
	check("enabled=false: main camera cull mask untouched", disabled_camera.cull_mask == 1048575)
	check("enabled=false: no extra viewport created", disabled_renderer.viewmodel_viewport == null)
	root.get_texture().get_image().save_png(out_disabled)
	disabled_scene.queue_free()
	await process_frame
	await process_frame

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	var renderer := scene.find_child("ViewmodelRenderer", true, false) as ViewmodelRenderer
	var camera := scene.find_child("Camera3D", true, false) as Camera3D
	var player := scene.find_child("Player", true, false) as PlayerController
	for i in range(30):
		await process_frame
	await RenderingServer.frame_post_draw

	var bit := 1 << 19
	var layers_on: Array = []
	hand_layers(scene.find_child("ViewModel", true, false), layers_on)
	check("enabled=true: hand meshes only on layer 20", layers_on.size() > 0 and layers_on.all(func(l: int) -> bool: return l == bit))
	check("main camera no longer renders layer 20", (camera.cull_mask & bit) == 0 and (camera.cull_mask & 1) == 1)
	check("viewmodel camera renders only layer 20", renderer.viewmodel_camera.cull_mask == bit)
	check("viewmodel camera transform matches main camera", renderer.viewmodel_camera.global_transform.is_equal_approx(camera.global_transform))
	check("viewmodel viewport is transparent", renderer.viewmodel_viewport.transparent_bg)
	check("viewport matches window size", renderer.viewmodel_viewport.size == get_root().get_window().size)

	player.velocity = Vector3(0, 0, -24)
	camera.fov = 111.0
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	check("viewmodel camera FOV follows main camera FOV", is_equal_approx(renderer.viewmodel_camera.fov, camera.fov))

	player.rotate_y(0.7)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	check("viewmodel camera follows player rotation", renderer.viewmodel_camera.global_transform.is_equal_approx(camera.global_transform))

	root.get_window().size = Vector2i(800, 600)
	for i in range(10):
		await process_frame
	check("viewport follows window resize (800x600)", renderer.viewmodel_viewport.size == Vector2i(800, 600))

	print("FAILURES: ", failures)
	quit(failures)
