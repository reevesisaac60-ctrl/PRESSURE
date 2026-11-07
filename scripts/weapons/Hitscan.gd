class_name Hitscan
extends RefCounted

static func cast_from_camera(camera: Camera3D, max_range: float, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var screen_center := viewport_size * 0.5
	var origin := camera.project_ray_origin(screen_center)
	var direction := camera.project_ray_normal(screen_center)
	var destination := origin + direction * max_range
	var query := PhysicsRayQueryParameters3D.create(origin, destination, mask)
	query.collide_with_areas = true
	query.exclude = exclude
	var space_state := camera.get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return {"position": destination, "normal": Vector3.ZERO, "hit": false, "collider": null}
	return {"position": result.position, "normal": result.normal, "hit": true, "collider": result.collider}

static func find_damageable(node: Node) -> Node:
	var current := node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
