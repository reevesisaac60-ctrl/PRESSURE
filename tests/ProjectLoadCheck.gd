extends SceneTree

var failures: int = 0
var checked: int = 0

func collect(dir_path: String, extensions: PackedStringArray, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if sub.begins_with(".") or sub == "addons" or sub == "tests":
			continue
		collect(dir_path.path_join(sub), extensions, out)
	for file_name in dir.get_files():
		if file_name.get_extension() in extensions:
			out.append(dir_path.path_join(file_name))

func _initialize() -> void:
	var files := PackedStringArray()
	collect("res://", PackedStringArray(["gd", "gdshader", "tscn", "tres"]), files)
	files.sort()

	for path in files:
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		checked += 1

		if resource == null:
			print("FAIL  load ", path)
			failures += 1
			continue

		if resource is PackedScene:
			var instance := (resource as PackedScene).instantiate()
			if instance == null:
				print("FAIL  instantiate ", path)
				failures += 1
			else:
				instance.free()

		var missing := PackedStringArray()
		for dependency in ResourceLoader.get_dependencies(path):
			var dep_path := dependency.get_slice("::", 2)
			if dep_path == "":
				dep_path = dependency
			if not ResourceLoader.exists(dep_path):
				missing.append(dep_path)

		if not missing.is_empty():
			print("FAIL  missing dependencies in ", path, ": ", missing)
			failures += 1

	print("checked ", checked, " files, failures: ", failures)
	quit(failures)
