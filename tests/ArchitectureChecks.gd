extends SceneTree

var failures: int = 0
var world: Node3D
var player: PlayerController

class Recorder extends RefCounted:
	var health_events: Array = []
	var damaged_events: Array = []
	var died_count: int = 0
	var states: Array = []
	var attacks: int = 0

func check(label: String, condition: bool) -> void:
	if condition:
		print("PASS  ", label)
	else:
		print("FAIL  ", label)
		failures += 1

func make_definition(enemy_name: String, health: float, speed: float, damage: float) -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.enemy_name = enemy_name
	definition.max_health = health
	definition.movement_speed = speed
	definition.attack_damage = damage
	definition.attack_range = 1.8
	definition.attack_cooldown = 0.5
	definition.detection_range = 20.0
	definition.corpse_lifetime = 0.3
	return definition

func make_enemy(definition: EnemyDefinition, pos: Vector3) -> EnemyBase:
	var enemy: EnemyBase = load("res://scenes/enemies/EnemyBase.tscn").instantiate()
	enemy.definition = definition
	var mesh := MeshInstance3D.new()
	mesh.name = "TestMesh"
	mesh.mesh = CapsuleMesh.new()
	enemy.add_child(mesh)
	enemy.position = pos
	world.add_child(enemy)
	return enemy

func make_box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	return body

func wait_ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	seed(7)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	world.add_child(make_box(Vector3(200, 2, 200), Vector3(0, -2, 0)))

	player = load("res://scenes/player/Player.tscn").instantiate()
	world.add_child(player)
	await wait_ticks(5)

	print("--- player components")
	check("player in group 'player'", player.is_in_group("player"))
	check("player has Movement/Look/CameraEffects/Health", player.movement != null and player.look != null and player.camera_effects != null and player.health != null)
	check("player health starts at max (100)", player.health.current_health == 100.0)
	player.take_damage(15.0)
	check("player.take_damage reduces health to 85", player.health.current_health == 85.0)

	print("--- enemy definition and base setup")
	var rec := Recorder.new()
	var definition := make_definition("Test", 100.0, 4.0, 15.0)
	var idle_definition := make_definition("Dummy", 100.0, 4.0, 15.0)
	idle_definition.detection_range = 0.0
	var dummy := make_enemy(idle_definition, Vector3(0, 0, -6))
	dummy.health_changed.connect(func(c: float, m: float) -> void: rec.health_events.append([c, m]))
	dummy.damaged.connect(func(a: float) -> void: rec.damaged_events.append(a))
	dummy.died.connect(func(_e: EnemyBase) -> void: rec.died_count += 1)
	await wait_ticks(3)

	check("enemy health initialised from definition", dummy.health.max_health == 100.0 and dummy.health.current_health == 100.0)
	check("enemy in group 'enemies'", dummy.is_in_group("enemies"))
	check("label shows 'Dummy: 100'", dummy.label_display.get_display_text().begins_with("Dummy: 100"))
	var mesh := dummy.get_node("TestMesh") as MeshInstance3D
	check("label overlay material applied to enemy mesh", mesh.material_overlay is ShaderMaterial)
	check("overlay uses ScrollingText shader", (mesh.material_overlay as ShaderMaterial).shader.resource_path == "res://shaders/ScrollingText.gdshader")

	print("--- damage, signals, feedback")
	dummy.take_damage(30.0)
	check("take_damage(30) -> health 70", dummy.health.current_health == 70.0)
	check("health_changed signal emitted with (70,100)", rec.health_events.size() > 0 and rec.health_events.back() == [70.0, 100.0])
	check("damaged signal emitted with 30", rec.damaged_events == [30.0])
	check("label updated to 'Dummy: 70'", dummy.label_display.get_display_text().begins_with("Dummy: 70"))
	check("damage flash override applied", mesh.material_override != null)
	await wait_ticks(int(144.0 * 0.1) + 6)
	check("damage flash cleared afterwards", mesh.material_override == null)
	dummy.take_damage(10.0)
	dummy.take_damage(10.0)
	await wait_ticks(int(144.0 * 0.1) + 6)
	check("rapid double hit: flash still cleared", mesh.material_override == null)
	check("idle enemy (detection 0) stays IDLE", dummy.state == EnemyBase.State.IDLE)

	print("--- real FingerGun shot against enemy")
	var gun: FingerGun = player.get_node("Camera3D/ViewModel/RightHand/FingerGun")
	var before := dummy.health.current_health
	gun.fire()
	await wait_ticks(3)
	check("FingerGun hitscan damaged enemy by gun damage (20)", is_equal_approx(before - dummy.health.current_health, gun.damage))
	await wait_ticks(int(144.0 * gun.fire_rate) + 5)

	print("--- death")
	dummy.take_damage(1000.0)
	check("health clamped to 0", dummy.health.current_health == 0.0)
	check("state DEAD", dummy.state == EnemyBase.State.DEAD and dummy.is_dead())
	check("died emitted exactly once", rec.died_count == 1)
	check("collision disabled on death", dummy.collision_layer == 0 and dummy.collision_mask == 0)
	dummy.take_damage(50.0)
	check("no damage or second death after dying", rec.died_count == 1 and dummy.health.current_health == 0.0)
	await wait_ticks(int(144.0 * 0.3) + 10)
	check("corpse freed after corpse_lifetime", not is_instance_valid(dummy))

	print("--- state machine and attack")
	player.global_position = Vector3(0, 0, 0)
	var chaser := make_enemy(definition, Vector3(0, 0, -12))
	var rec2 := Recorder.new()
	chaser.state_changed.connect(func(p: EnemyBase.State, c: EnemyBase.State) -> void: rec2.states.append([p, c]))
	chaser.attacked.connect(func(_t: Node3D) -> void: rec2.attacks += 1)
	var player_health_before := player.health.current_health
	await wait_ticks(10)
	check("enemy detects player and enters CHASE", chaser.state == EnemyBase.State.CHASE)
	var start_distance := chaser.distance_to_target()
	await wait_ticks(72)
	check("chasing enemy closes distance", chaser.distance_to_target() < start_distance - 1.0)
	check("chase speed bounded by definition (4.0)", Vector2(chaser.velocity.x, chaser.velocity.z).length() <= 4.001)
	await wait_ticks(144 * 4)
	check("enemy reaches ATTACK state", chaser.state == EnemyBase.State.ATTACK or rec2.attacks > 0)
	check("enemy attacked and damaged the player", player.health.current_health < player_health_before)
	var dealt := player_health_before - player.health.current_health
	check("damage dealt is a multiple of attack_damage (15)", is_equal_approx(fmod(dealt, 15.0), 0.0))
	var attacks_now := rec2.attacks
	await wait_ticks(144)
	var gained := rec2.attacks - attacks_now
	check("attack cooldown respected (<= 2-3 attacks/sec at 0.5s)", gained >= 1 and gained <= 3)
	check("chaser faces the player", absf(chaser.direction_to_target().dot(-chaser.global_basis.z)) > 0.9)

	print("--- missing definition")
	var fallback: EnemyBase = load("res://scenes/enemies/EnemyBase.tscn").instantiate()
	world.add_child(fallback)
	await wait_ticks(2)
	check("enemy without definition falls back to defaults", fallback.definition != null and fallback.health.max_health == 100.0)

	print("--- player death signal")
	print("INFO  player already dead before this step: ", player.health.is_dead)
	player.health.setup(100.0)
	var died_flag := [false]
	player.died.connect(func() -> void: died_flag[0] = true)
	player.take_damage(9999.0)
	check("player died signal emitted, player not freed", died_flag[0] and is_instance_valid(player))

	print("")
	print("FAILURES: ", failures)
	quit(failures)
