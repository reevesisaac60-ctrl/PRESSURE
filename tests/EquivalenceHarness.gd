extends SceneTree

const TICKS: int = 900

var player: CharacterBody3D
var camera: Camera3D
var hand: Node3D
var target: StaticBody3D
var tick: int = 0
var lines: PackedStringArray = []
var out_path: String = ""
var dash_starts: int = 0
var wall_kicks: int = 0
var landings: int = 0
var previous_dash_cooldown: float = 0.0
var previous_lockout: float = 0.0
var previous_floor: bool = true
var previous_vy: float = 0.0
var seeded_damage_hits: int = 0

class DamageTarget extends StaticBody3D:
	var hits: int = 0
	var total: float = 0.0
	func take_damage(amount: float) -> void:
		hits += 1
		total += amount

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var player_scene_path: String = args[0]
	out_path = args[1]
	seed(12345)

	var world := Node3D.new()
	root.add_child(world)
	current_scene = world

	world.add_child(make_box(Vector3(400, 2, 400), Vector3(0, -2, 0)))
	world.add_child(make_box(Vector3(60, 30, 2), Vector3(0, 14, -26)))
	world.add_child(make_box(Vector3(60, 30, 2), Vector3(0, 14, 26)))
	world.add_child(make_box(Vector3(2, 30, 60), Vector3(26, 14, 0)))
	world.add_child(make_box(Vector3(2, 30, 60), Vector3(-26, 14, 0)))

	target = DamageTarget.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	shape.shape = box
	target.add_child(shape)
	target.position = Vector3(0, 0, -12)
	world.add_child(target)

	var packed: PackedScene = load(player_scene_path)
	player = packed.instantiate()
	world.add_child(player)
	camera = player.get_node("Camera3D")
	hand = player.get_node("Camera3D/ViewModel/RightHand")

	physics_frame.connect(_on_physics_frame)
	process_frame.connect(_on_process_frame)

func make_box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	return body

func press(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)

func scripted_input(t: int) -> void:
	var forward := t >= 250 and t < 800
	var right := (t >= 70 and t < 250) or (t >= 250 and t < 560)
	set_action("move_forward", forward)
	set_action("move_right", right)
	set_action("move_left", t >= 600 and t < 700)
	set_action("move_backward", t >= 820 and t < 860)

	var jump_hold := false
	if t >= 100 and t < 110:
		jump_hold = true
	if t >= 250 and t < 800 and (t % 30) < 3:
		jump_hold = true
	if t >= 300 and t < 800 and (t % 47) < 2:
		jump_hold = true
	if t >= 250 and t < 800 and not player.is_on_floor():
		var contact: Variant = read_value("wall_contact_timer")
		if contact != null and float(contact) > 0.0 and (t % 4) == 0:
			jump_hold = true
	set_action("jump", jump_hold)

	set_action("dash", t == 160 or t == 420 or t == 700)
	set_action("fire", t == 10 or t == 40 or t == 500)

	if t == 120:
		mouse(Vector2(80, -30))
	if t == 330:
		mouse(Vector2(-60, 20))
	if t == 450:
		mouse(Vector2(140, 10))
	if t == 650:
		mouse(Vector2(-200, -15))

var action_states: Dictionary = {}

func set_action(action: String, pressed: bool) -> void:
	if action_states.get(action, false) != pressed:
		action_states[action] = pressed
		press(action, pressed)

func mouse(rel: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = rel
	ev.position = Vector2(100, 100)
	Input.parse_input_event(ev)

func read_value(property: String) -> Variant:
	var value: Variant = player.get(property)
	if value != null:
		return value
	for child in player.get_children():
		var inner: Variant = child.get(property)
		if inner != null:
			return inner
	return null

func f(v: float) -> String:
	return "%.9f" % v

func v3(v: Vector3) -> String:
	return "%s,%s,%s" % [f(v.x), f(v.y), f(v.z)]

func _on_physics_frame() -> void:
	if tick >= TICKS:
		return
	scripted_input(tick)
	Input.flush_buffered_events()

func _on_process_frame() -> void:
	if tick >= TICKS:
		finish()
		return

	var on_floor := player.is_on_floor()
	var cooldown: float = read_value("dash_cooldown_timer")
	var lockout: float = read_value("wall_kick_lockout_timer")
	if cooldown > previous_dash_cooldown + 0.0001:
		dash_starts += 1
	if lockout > previous_lockout + 0.0001:
		wall_kicks += 1
	if on_floor and not previous_floor and previous_vy < -3.0:
		landings += 1
	previous_dash_cooldown = cooldown
	previous_lockout = lockout
	previous_floor = on_floor
	previous_vy = player.velocity.y

	lines.append("%d|P %s|V %s|R %s|C fov %s pos %s rot %s|H %s %s|D %d|N %d" % [
		tick,
		v3(player.global_position),
		v3(player.velocity),
		f(player.rotation.y),
		f(camera.fov), v3(camera.position), v3(camera.rotation),
		v3(hand.position), v3(hand.rotation),
		target.hits,
		current_scene.get_child_count()
	])
	tick += 1

func finish() -> void:
	lines.append("SUMMARY dash_starts=%d wall_kicks=%d landings=%d damage_hits=%d damage_total=%s mouse_mode=%d" % [dash_starts, wall_kicks, landings, target.hits, f(target.total), Input.mouse_mode])
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	quit(0)
