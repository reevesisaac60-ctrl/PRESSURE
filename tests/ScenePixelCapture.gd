extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0]
	var out_path: String = args[1]
	var packed: PackedScene = load(scene_path)
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in range(90):
		await process_frame
	root.get_texture().get_image().save_png(out_path)
	print("captured ", out_path)
	quit(0)
