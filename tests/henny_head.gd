extends SceneTree
const ArenaView = preload("res://scripts/arena_3d.gd")
var failures = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func portrait_visible(actor: Dictionary) -> bool:
	return actor.body.henny_head.visible and not actor.body.procedural_head.visible

func shows_named_portrait(actor: Dictionary, roster_name: String) -> bool:
	var holder: Node3D = actor.body.portrait_heads[roster_name]
	return holder.get_child_count() > 0 and holder.visible and not actor.body.procedural_head.visible

func lowpoly_visible(actor: Dictionary) -> bool:
	return actor.body.procedural_head.visible and not actor.body.henny_head.visible

func run() -> void:
	var arena = ArenaView.new()
	root.add_child(arena)
	var state = MatchState.new()
	state.start(0, 1)
	state.inbound(0)
	var before = state.snapshot()
	arena.present(state, [], state.ball, [0], 0.016, false)
	check(state.snapshot() == before, "presenting HENNY does not mutate gameplay state")
	check(portrait_visible(arena.athletes[0]), "HENNY on the home side wears the portrait head")
	check(shows_named_portrait(arena.athletes[1], "GAUCI"), "GAUCI wears the Gauci portrait head")
	check(shows_named_portrait(arena.athletes[2], "WANG"), "WANG wears the Wang portrait head")
	check(shows_named_portrait(arena.athletes[3], "WATERS"), "WATERS wears the Waters portrait head")
	state.start(1, 0)
	state.inbound(1)
	before = state.snapshot()
	arena.present(state, [], state.ball, [0], 0.016, false)
	check(state.snapshot() == before, "moving HENNY to the other side does not mutate gameplay state")
	check(portrait_visible(arena.athletes[2]), "HENNY on the away side wears the portrait head")
	check(shows_named_portrait(arena.athletes[3], "GAUCI"), "GAUCI on the away side wears the portrait head")
	check(shows_named_portrait(arena.athletes[0], "WANG"), "WANG on the home side wears the portrait head")
	check(shows_named_portrait(arena.athletes[1], "WATERS"), "WATERS on the home side wears the portrait head")
	state.big_heads = true
	arena.present(state, [], state.ball, [0], 0.016, false)
	check(arena.athletes[2].head.scale.is_equal_approx(Vector3.ONE * 1.65), "big heads still scale the shared head node")
	var henny = arena.athletes[2].body
	var portrait_height = _tree_aabb(henny.henny_head).size.y
	var procedural_height = _tree_aabb(henny.procedural_head).size.y
	check(portrait_height >= procedural_height * 0.98, "HENNY's head is at least as tall as the low-poly heads")
	print("HENNY HEAD TESTS: ", "PASS" if failures == 0 else "FAIL")
	arena.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _tree_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var started = false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		box = node.global_transform * (node as MeshInstance3D).get_aabb()
		started = true
	for child in node.get_children():
		if child is Node3D:
			var child_box = _tree_aabb(child)
			if child_box.size != Vector3.ZERO:
				box = child_box if not started else box.merge(child_box)
				started = true
	return box

func _initialize() -> void:
	call_deferred("run")
