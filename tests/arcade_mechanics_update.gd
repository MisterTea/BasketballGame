extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func neutral() -> Dictionary:
	return {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("--- TESTING ARCADE MECHANICS UPDATE (7 ISSUES) ---")

	# ==========================================
	# ISSUE 2: KEYBOARD CONTROLS
	# ==========================================
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame

	check(InputMap.has_action("p0_shove"), "InputMap has action p0_shove")
	var shove_events = InputMap.action_get_events("p0_shove")
	var has_l = shove_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_L)
	check(has_l, "p0_shove is mapped to KEY_L")

	var turbo_events = InputMap.action_get_events("p0_turbo")
	var has_semicolon = turbo_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_SEMICOLON)
	var has_space = turbo_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_SPACE)
	check(has_semicolon, "p0_turbo is mapped to KEY_SEMICOLON")
	check(has_space, "p0_turbo retains KEY_SPACE as alternate")

	var switch_events = InputMap.action_get_events("p0_switch")
	var has_f = switch_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_F)
	var has_tab = switch_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_TAB)
	check(has_f, "p0_switch is mapped to KEY_F")
	check(has_tab, "p0_switch retains KEY_TAB as alternate")

	main_scene.queue_free()
	await process_frame

	# ==========================================
	# ISSUE 4: JUMP SHOT CHARGING & APEX RELEASE
	# ==========================================
	var state = MatchState.new()
	state.start(0, 1)
	state.inbound(0)
	state.freeze = 0
	state.owner = 0
	state.players[0].pos = Vector2(500, 450)
	state.ball = state.players[0].pos

	# Start charging Shoot
	state.players[0].charge = 0.29
	var h_halfway = state.ball_height()
	state.players[0].charge = 0.58
	var h_apex = state.ball_height()
	state.players[0].charge = 0.87
	var h_descending = state.ball_height()

	check(h_apex > h_halfway, "ball elevates as player jumps during shot charging")
	check(h_apex > h_descending, "peak ball elevation is reached at 0.58s apex")
	check(is_equal_approx(h_apex, 1.3 + 1.35), "apex height reaches maximum 2.65m jump elevation")

	var shot_eval = state.calculate_shot_percentage(0, 0.58, false, false, false)
	check(shot_eval.quality == "PERFECT", "release at jump apex (0.58s) is PERFECT quality")
	check(shot_eval.timing >= 0.99, "apex release timing multiplier is maximal (~1.0)")

	# Release shot via tick
	var commands = {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}}
	state.players[0].shoot_held = true
	state.players[0].charge = 0.58
	state.tick(1.0 / 60.0, commands)
	check(state.players[0].jump > 0.4, "shooter has remaining airtime for descent after releasing shot")

	# ==========================================
	# ISSUE 7: BLOCK ANIMATION, SQUAT, & JUMP STRAIGHT UP
	# ==========================================
	var arena = load("res://scripts/arena_3d.gd").new()
	root.add_child(arena)
	var rig = arena.athletes[0].body

	# Squat phase (p < 0.22)
	var pelvis_id = rig.skeleton.find_bone("Pelvis")
	var pelvis_standing = rig.skeleton.get_bone_pose_position(pelvis_id).y
	rig.apply_block_pose(0.10)
	var pelvis_squat = rig.skeleton.get_bone_pose_position(pelvis_id).y
	check(pelvis_squat < pelvis_standing - 0.10, "block animation squats pelvis downward during windup (p < 0.22)")

	# Jump phase (p >= 0.22)
	rig.apply_block_pose(0.50)
	var l_sh = rig.skeleton.find_bone("L_Shoulder")
	var r_sh = rig.skeleton.find_bone("R_Shoulder")
	check(l_sh >= 0 and r_sh >= 0, "skeleton has shoulder bones for block pose")
	var l_rot = rig.skeleton.get_bone_pose_rotation(l_sh).get_euler()
	check(absf(l_rot.z) > 1.0, "arms are raised high overhead during block jump")

	arena.queue_free()

	# In-game straight-up jump constraint
	state.players[2].pos = Vector2(700, 450)
	state.players[2].vel = Vector2(150, 50)
	state.defend(2, false)
	check(state.players[2].vel == Vector2.ZERO, "defend() immediately zeros horizontal velocity")
	check(state.players[2].jump >= 0.65, "defend() sets block jump duration to 0.70s")

	# While jumping for block, movement inputs cannot drift player
	state.tick(1.0 / 60.0, {2: {"move": Vector2.RIGHT, "shoot": false, "pass": false, "turbo": true}})
	check(state.players[2].vel == Vector2.ZERO, "player jumps straight up without horizontal drift during block")

	# ==========================================
	# ISSUE 5: STEAL SWIPE DURATION & ANIMATION
	# ==========================================
	state.owner = 0
	state.players[0].pos = Vector2(500, 450)
	state.players[2].pos = Vector2(530, 450)
	state.players[2].cooldown = 0
	state.steal(2, false)
	check(state.players[2].swipe >= 0.40, "steal attempt takes ~0.45s and triggers swipe animation")
	check(not state.players[2].swipe_resolved, "steal is not resolved instantaneously at initiation")

	# Tick halfway through swipe (0.22s in, swipe <= 0.25) -> resolve_steal triggers
	state.tick(0.22, {2: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.players[2].swipe_resolved, "steal resolves at the forward reach point (swipe <= 0.25)")

	# ==========================================
	# ISSUE 3: STEAL POKES BALL LOOSE & PICKUP DELAY
	# ==========================================
	var loose_seen = false
	var clean_seen = false
	for trial in range(30):
		state.owner = 0
		state.players[0].pos = Vector2(500, 450)
		state.players[0].stun = 0
		state.players[2].pos = Vector2(530, 450)
		state.ball = state.players[0].pos
		state.rng.seed = trial * 101 + 7
		state.resolve_steal(2, false)
		if state.owner == -1 and state.loose_ball_timer > 0:
			loose_seen = true
		elif state.owner == 2:
			clean_seen = true
	check(loose_seen, "steals sometimes poke the ball loose instead of automatic instant transfer")
	check(clean_seen, "steals can also produce a clean pick")

	# Verify loose ball pickup delay
	state.owner = -1
	state.flight = {}
	state.loose_ball_timer = 0.45
	state.ball = Vector2(500, 450)
	state.players[0].pos = Vector2(500, 450)
	state.players[0].stun = 0
	state.tick(0.10, {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.owner == -1, "loose ball cannot be grabbed right away while loose_ball_timer > 0")

	# After loose_ball_timer expires, nearby player can recover
	state.tick(0.40, {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.owner == 0, "loose ball can be recovered once delay timer expires")

	# ==========================================
	# ISSUE 6: OFF-COURT INBOUND AFTER GOAL
	# ==========================================
	state.inbound(1, true) # Inbound after goal for Team 1
	var inbounder = 2
	check(state.owner == inbounder, "team 1 inbounder is player 2")
	var is_off_court = state.players[inbounder].pos.x < MatchState.COURT.position.x or state.players[inbounder].pos.x > MatchState.COURT.end.x
	check(is_off_court, "after a goal, the inbounding player stands off-court behind the baseline")

	# Attempt to shoot from off-court
	state.freeze = 0
	var prev_charge = state.players[inbounder].charge
	state.tick(0.20, {inbounder: {"move": Vector2.ZERO, "shoot": true, "pass": false, "turbo": false}})
	check(state.players[inbounder].charge == 0, "inbounder cannot shoot or charge shot while off-court")
	check(state.flight.is_empty(), "no shot flight can be launched from off-court")

	# Inbounder movement stays clamped behind baseline
	state.tick(0.10, {inbounder: {"move": Vector2.RIGHT, "shoot": false, "pass": false, "turbo": false}})
	var still_off_court = state.players[inbounder].pos.x < MatchState.COURT.position.x or state.players[inbounder].pos.x > MatchState.COURT.end.x
	check(still_off_court, "inbounder cannot run onto the court before passing")

	# Pass in the ball to start the game
	state.players[inbounder].cooldown = 0
	state.tick(0.02, {inbounder: {"move": Vector2.ZERO, "shoot": false, "pass": true, "turbo": false}})
	check(not state.flight.is_empty() and state.flight.kind == "pass", "inbounder passes the ball in to start play")

	# ==========================================
	# ISSUE 1: REBOUND BALL PHYSICS
	# ==========================================
	state.players[0].pos = Vector2(800, 465)
	state.ball = state.players[0].pos
	state.owner = 0
	state.shoot_ball(0, false)
	state.flight.made = false # Force miss
	state.tick_flight(1.20) # Reach rim
	check(not state.flight.is_empty() and state.flight.kind == "rebound", "missed shot bounces off rim into a rebound flight arc")
	check(state.flight.arc_height >= 2.0, "rebound arc height has parabolic lift off rim")

	var max_rebound_h = 0.0
	var sample_t = 0.0
	while sample_t <= state.flight.duration:
		state.flight.time = sample_t
		max_rebound_h = maxf(max_rebound_h, state.ball_height())
		sample_t += 0.05
	check(max_rebound_h > 3.5, "rebound ball arcs high above rim height (> 3.5m peak)")

	# Mid-air catch by jumping player
	state.flight.time = state.flight.duration * 0.5
	state.ball = state.flight_position()
	state.players[2].pos = state.ball
	state.players[2].jump = 0.35 # Mid-air jump
	state.tick_flight(0.01)
	check(state.owner == 2 and state.flight.is_empty(), "jumping player can snatch rebound mid-air")

	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	quit(0 if failures == 0 else 1)
