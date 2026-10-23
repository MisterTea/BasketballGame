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
	check(main_scene.scaled_window_size(2.0, Vector2i(4000, 3000)) == Vector2i(2560, 1600), "Retina scale doubles the macOS window resolution")
	check(main_scene.scaled_window_size(1.0, Vector2i(4000, 3000)) == Vector2i(1280, 800), "standard-density displays retain the base window resolution")
	check(main_scene.scaled_window_size(2.0, Vector2i(1920, 1080)) == Vector2i(1728, 1080), "scaled window fits within the usable desktop while preserving aspect ratio")

	check(InputMap.has_action("p0_shove"), "InputMap has action p0_shove")
	var shove_events = InputMap.action_get_events("p0_shove")
	var has_l = shove_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_L)
	check(has_l, "p0_shove is mapped to KEY_L")

	var turbo_events = InputMap.action_get_events("p0_turbo")
	var has_shift = turbo_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_SHIFT)
	var has_old_turbo_key = turbo_events.any(func(e): return e is InputEventKey and e.physical_keycode in [KEY_SEMICOLON, KEY_SPACE])
	check(has_shift, "p0_turbo is mapped to KEY_SHIFT")
	check(not has_old_turbo_key, "p0_turbo no longer uses semicolon or Space")

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

	# Release shot via tick. x=500 is past midcourt, and those shots are ignored.
	var commands = {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}}
	state.players[0].pos = Vector2(800, 450)
	state.ball = state.players[0].pos
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
	var slide_cap = MatchState.BLOCK_GLIDE_ASM * MatchState.PX_PER_ASM / (30.0 / MatchState.ARCADE_TSEC)
	if state.flight.get("kind", "") == "shot":
		check(absf(state.players[2].vel.x) <= slide_cap + 1.0 and absf(state.players[2].vel.y) <= slide_cap + 1.0, "a shot block slides at most 30 pixels toward the ball")
	else:
		check(state.players[2].vel == Vector2.ZERO, "defend() zeros velocity when the ball is not in the air")
	check(state.players[2].jump >= 0.65, "defend() sets block jump duration to 0.70s")

	# While jumping for block, movement inputs cannot drift player
	var block_vel = state.players[2].vel
	state.tick(1.0 / 60.0, {2: {"move": Vector2.RIGHT, "shoot": false, "pass": false, "turbo": true}})
	check(state.players[2].vel.distance_to(block_vel) < 1.0, "stick input does not add drift during a block jump")

	# ==========================================
	# ISSUE 5: STEAL SWIPE DURATION & ANIMATION
	# ==========================================
	state.owner = 0
	state.players[0].pos = Vector2(500, 450)
	state.players[2].pos = Vector2(530, 450)
	state.players[2].cooldown = 0
	state.steal(2, false)
	var reach_ticks = MatchState.STEAL_REACH_TICKS[state.passer_seqdir(2)]
	var reach = float(reach_ticks) / MatchState.ARCADE_TSEC
	check(is_equal_approx(state.players[2].swipe, reach), "a steal lasts until seq_stealstand, 9 or 10 ticks")
	check(not state.players[2].swipe_resolved, "steal is not resolved instantaneously at initiation")

	# The hand is extended on the last 2 ticks before seq_stealstand.
	state.tick(0.05, {2: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(not state.players[2].swipe_resolved, "the reach has not connected in the first few ticks")
	state.tick(reach, {2: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.players[2].swipe_resolved, "steal resolves on the extended hand, just before standing")

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
		if state.owner == -1 and state.flight.get("kind", "") == "loose":
			loose_seen = true
		elif state.owner == 2:
			clean_seen = true
	check(loose_seen, "steals sometimes poke the ball loose instead of automatic instant transfer")
	check(clean_seen, "steals can also produce a clean pick")

	# Verify knocked away ball gives shtdly pickup lockout to victim and stealer (PLYR2.ASM:3079-3080)
	state.owner = 0
	state.players[0].pos = Vector2(500, 450)
	state.players[0].stun = 0
	state.players[2].pos = Vector2(530, 450)
	state.ball = state.players[0].pos
	# Seed where poke away occurs
	state.rng.seed = 42
	for _attempt in range(50):
		state.owner = 0
		state.resolve_steal(2, false)
		if state.owner == -1:
			break
	check(state.loose_ball_timer <= 0.0, "a poked steal does not add a global loose-ball lockout")
	check(state.players[0].pickup_delay >= MatchState.TE_POKE_DELAY - 0.001 and state.players[2].pickup_delay >= MatchState.TE_POKE_DELAY - 0.001, "knocked away ball locks both players out for 15 ticks (plyr_shtdly)")

	# Verify airborne player cannot snatch a loose ball while loose_ball_timer > 0
	state.owner = -1
	state.flight = {
		"kind": "loose",
		"start": Vector2(500, 450),
		"end": Vector2(540, 450),
		"time": 0.05,
		"duration": 0.45,
		"arc_height": 1.2
	}
	state.loose_ball_timer = 0.50
	state.ball = state.flight_position()
	state.players[1].pos = state.ball
	state.players[1].jump = 0.50
	state.players[1].pickup_delay = 0.0
	state.tick_flight(0.016)
	check(state.owner == -1, "airborne player cannot snatch loose ball while loose_ball_timer > 0")

	# Verify player with pickup_delay cannot recover ball even if loose_ball_timer is 0
	state.flight = {}
	state.loose_ball_timer = 0.0
	state.ball = Vector2(500, 450)
	state.players[0].pos = Vector2(500, 450)
	state.players[1].pos = Vector2(100, 100)
	state.players[2].pos = Vector2(100, 100)
	state.players[3].pos = Vector2(100, 100)
	state.players[0].pickup_delay = 0.30
	state.tick(0.05, {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.owner == -1, "player with active pickup_delay cannot scoop loose ball")

	# Verify shove sets victim pickup_delay (PLYR2.ASM:5900)
	var shove_state = MatchState.new()
	shove_state.start(0, 1)
	shove_state.tipoff = {}
	shove_state.owner = 0
	shove_state.players[0].pos = Vector2(500, 450)
	shove_state.players[2].pos = Vector2(530, 450)
	shove_state.resolve_steal(2, true)
	check(shove_state.players[0].pickup_delay >= 0.30, "shove sets victim pickup_delay (30-40 ticks in PLYR2.ASM)")

	# Verify loose ball pickup delay
	state.bullet_time_remaining = 0.0
	state.owner = -1
	state.flight = {}
	state.loose_ball_timer = 0.45
	state.ball = Vector2(500, 450)
	state.players[0].pos = Vector2(500, 450)
	state.players[0].stun = 0
	state.players[0].pickup_delay = 0.0
	state.tick(0.10, {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.owner == -1, "loose ball cannot be grabbed right away while loose_ball_timer > 0")

	# After loose_ball_timer expires, nearby player can recover
	state.tick(0.40, {0: {"move": Vector2.ZERO, "shoot": false, "pass": false, "turbo": false}})
	check(state.owner == 0, "loose ball can be recovered once delay timer expires")

	# ==========================================
	# ISSUE 6: OFF-COURT INBOUND AFTER GOAL
	# ==========================================
	state.ball = Vector2(1115, 465)
	state.players[2].pos = state.ball
	state.players[3].pos = Vector2(400, 465)
	state.inbound(1, true) # Inbound after goal for Team 1. Closer teammate takes it out.
	var inbounder = 2
	check(state.owner == inbounder, "team 1 inbounder is the teammate closer to the ball")
	var is_off_court = state.players[inbounder].pos.x < MatchState.COURT.position.x or state.players[inbounder].pos.x > MatchState.COURT.end.x
	check(is_off_court, "after a goal, the inbounding player stands off-court behind the baseline")

	# plyrtob_moveo3: inbounder -355/-20, teammate -270/+10, defenders -150 at -50 and +70, mirrored to the right baseline.
	var mate = 3
	var inbound_spot = state.asm_spot(355.0, -20.0)
	var mate_spot = state.asm_spot(270.0, 10.0)
	var def_x = state.asm_spot(150.0, 0.0).x
	check(state.players[inbounder].pos.distance_to(inbound_spot) < 1.0, "inbounder stands at the PLYR.ASM take-out spot")
	check(state.players[mate].pos.distance_to(mate_spot) < 1.0, "teammate stands 270 world units off center")
	check(state.players[mate].face == 1, "teammate faces toward baseline inbounder")
	check(absf(state.players[0].pos.x - def_x) < 1.0 and absf(state.players[1].pos.x - def_x) < 1.0, "defenders park 150 world units off center")
	check(state.players[0].face == 1 and state.players[1].face == 1, "enemy defenders face inbounding team")

	# Attempt to shoot from off-court
	state.freeze = 0
	var prev_charge = state.players[inbounder].charge
	state.tick(0.20, {inbounder: {"move": Vector2.ZERO, "shoot": true, "pass": false, "turbo": false}})
	check(state.players[inbounder].charge == 0, "inbounder cannot shoot or charge shot while off-court")
	check(state.flight.is_empty(), "no shot flight can be launched from off-court")
	check(state.players[mate].pos.x > def_x, "teammate remains in own zone and does not sprint downcourt during inbound hold")
	check(state.players[0].pos.x <= def_x + 1.0, "defenders hold the 150-unit line without rushing the baseline")

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
	state.tick_flight(state.flight.duration + 0.01) # Reach rim
	check(not state.flight.is_empty() and state.flight.kind == "rebound", "missed shot bounces off rim into a rebound flight arc")
	check(state.flight.arc_height >= 2.0, "rebound arc height has parabolic lift off rim")
	check(state.flight.duration == MatchState.REBOUND_FLIGHT_DURATION and state.flight.duration > 1.5, "rebound flight uses the slower shared hang-time")

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
	check(state.players[2].possession_flash == MatchState.POSSESSION_FLASH_DURATION, "rebound winner starts the possession strobe")
	check(state.bullet_time_remaining == MatchState.BULLET_TIME_DURATION, "rebound pickup starts a half-second bullet-time beat")
	var elapsed_before_bullet_time = state.elapsed
	state.tick(0.10, {2: neutral()})
	check(is_equal_approx(state.elapsed - elapsed_before_bullet_time, 0.10 * MatchState.BULLET_TIME_SCALE), "bullet-time slows authoritative gameplay while using real-time duration")

	# Block contact is seq_block's 30px glide plus tbl1/tbl4, not an 78/85 circle.
	var reach_state = MatchState.new()
	reach_state.start(0, 1)
	var high_box = reach_state.block_contact_box(2, true)
	check(high_box.x < 78.0 and high_box.y < 78.0, "a high-ball block box is inside the old 78px radius")
	check(is_equal_approx(reach_state.dunk_rim_ticks(40.0), 37.0), "under-hoop dunks use DUNKB2's 37 ticks to the rim")
	check(is_equal_approx(reach_state.dunk_rim_ticks(70.0), 64.0), "short dunks use DUNKLAY7's 64 ticks")
	check(is_equal_approx(reach_state.dunk_rim_ticks(110.0), 74.0), "long dunks use the 74-tick med/long sequences, including on fire")

	var human_shove = MatchState.new()
	human_shove.start(0, 1)
	human_shove.tipoff = {}
	human_shove.owner = 1
	human_shove.players[0].human = true
	human_shove.players[0].pos = Vector2(500, 450)
	human_shove.players[0].swipe_dir = Vector2.RIGHT
	human_shove.players[1].pos = Vector2(540, 450)
	human_shove.players[2].pos = Vector2(200, 200)
	human_shove.players[3].pos = Vector2(200, 600)
	human_shove.resolve_steal(0, true)
	check(human_shove.players[1].stun > 0.0, "a human shoves a teammate inside the 16/128 cone")

	var wide = MatchState.new()
	wide.start(0, 1)
	wide.tipoff = {}
	wide.owner = 1
	wide.players[0].human = true
	wide.players[0].pos = Vector2(500, 450)
	wide.players[0].swipe_dir = Vector2.RIGHT
	wide.players[1].pos = Vector2(520, 510)
	wide.players[2].pos = Vector2(200, 200)
	wide.players[3].pos = Vector2(200, 600)
	wide.resolve_steal(0, true)
	check(wide.players[1].stun == 0.0, "a teammate outside the narrow cone is not shoved")

	var drone_shove = MatchState.new()
	drone_shove.start(0, 1)
	drone_shove.tipoff = {}
	drone_shove.owner = 1
	drone_shove.players[0].human = false
	drone_shove.players[0].pos = Vector2(500, 450)
	drone_shove.players[0].swipe_dir = Vector2.RIGHT
	drone_shove.players[1].pos = Vector2(540, 450)
	drone_shove.players[2].pos = Vector2(200, 200)
	drone_shove.players[3].pos = Vector2(200, 600)
	drone_shove.resolve_steal(0, true)
	check(drone_shove.players[1].stun == 0.0, "a drone never shoves a teammate")

	var saw_short = false
	var loose_ok = false
	for seed in range(80):
		var fly = MatchState.new()
		fly.start(0, 1)
		fly.tipoff = {}
		fly.rng.seed = seed
		fly.owner = 0
		fly.score = [0, 8]
		fly.players[0].pos = Vector2(500, 450)
		fly.players[0].push_keep_ball = 0.0
		fly.players[2].pos = Vector2(450, 450)
		fly.players[2].swipe_dir = Vector2.RIGHT
		fly.players[2].turbo = 1.0
		fly.resolve_steal(2, true)
		if fly.players[0].shove_kind == "flyback" and fly.players[0].vel.length() < 120.0:
			saw_short = true
		if fly.flight.get("kind", "") == "loose":
			var travel = fly.players[0].pos.distance_to(fly.flight.end)
			if travel < 70.0:
				loose_ok = true
	check(saw_short, "a keep-ball miss or short-fly roll quarters flyback speed")
	check(loose_ok, "a failed keep-ball roll drifts the ball at about one pixel per tick")

	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	quit(0 if failures == 0 else 1)
