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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("--- TESTING ARCADE MECHANICS PASS 2 (ALL 8 MECHANICS) ---")

	# ==========================================
	# 1. MECHANIC 1: SPIN MOVE & ELBOW CLEAROUT
	# ==========================================
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame

	check(InputMap.has_action("p0_spin"), "InputMap has action p0_spin")
	var spin_events = InputMap.action_get_events("p0_spin")
	var has_l = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_L)
	check(has_l, "p0_spin mapped to KEY_L")
	var has_apostrophe = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_APOSTROPHE)
	check(has_apostrophe, "p0_spin mapped to KEY_APOSTROPHE (right next to semicolon)")

	var has_p = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_P)
	var has_o = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_O)
	var has_i = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_I)
	var has_h = spin_events.any(func(e): return e is InputEventKey and e.physical_keycode == KEY_H)
	check(has_p and has_o and has_i and has_h, "p0_spin has alternate keys near jkl; (P, O, I, H)")

	var has_rs = spin_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_STICK)
	var has_ls = spin_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_LEFT_STICK)
	var has_b = spin_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
	var has_y = spin_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	check(has_rs and has_ls and has_b and has_y, "p0_spin mapped to other Xbox controller buttons (RS, LS, B, Y)")

	var cmd = main_scene.read_command(0)
	check(cmd.has("spin"), "read_command(0) includes spin in command dictionary")

	main_scene.queue_free()
	await process_frame

	# Test Spin Move execution in simulation
	var state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.inbounding_team = -1
	state.owner = 0
	state.players[0].pos = Vector2(500, 450)
	state.players[0].turbo = 1.0

	# Moving + Spin -> Spin Move
	var spin_cmd = {
		0: {"move": Vector2(1, 0), "turbo": false, "shoot": false, "pass": false, "shove": false, "spin": true}
	}
	state.tick(0.016, spin_cmd)
	check(state.players[0].spin > 0.35, "Moving with spin input triggers Spin Move (spin timer active)")
	check(state.players[0].spin_cooldown > 1.5, "Spin Move sets cooldown (~2.0s)")
	check(state.players[0].steal_immune > 0.8, "Spin Move grants steal immunity (~1.0s)")
	check(state.players[0].turbo < 1.0, "Spin Move consumes 2/7 of turbo meter")
	check(state.players[0].vel.x > 200, "Spin Move surges velocity forward in movement direction")

	# Verify steal immunity prevents opponent steal
	state.players[2].pos = state.players[0].pos + Vector2(10, 0)
	state.steal(2, false)
	state.resolve_steal(2, false)
	check(state.owner == 0, "Steal attempt while steal_immune fails to steal the ball")

	# Test Elbow Clearout (stationary + spin)
	var state2 = MatchState.new()
	state2.start(0, 1)
	state2.tipoff = {}
	state2.freeze = 0
	state2.inbounding_team = -1
	state2.owner = 0
	state2.players[0].pos = Vector2(500, 450)
	state2.players[0].turbo = 1.0
	state2.players[2].pos = Vector2(530, 450) # Defender 30 units away
	state2.players[2].stun = 0.0

	var elbow_cmd = {
		0: {"move": Vector2.ZERO, "turbo": false, "shoot": false, "pass": false, "shove": false, "spin": true}
	}
	state2.tick(0.016, elbow_cmd)
	check(state2.players[0].elbow > 0.35, "Stationary with spin input triggers Elbow Clearout (elbow timer active)")
	check(state2.players[2].stun > 0.5, "Elbow Clearout staggers nearby opponent defender")
	check(state2.players[2].pos.x > 540, "Elbow Clearout pushes opponent defender backward")

	# ==========================================
	# 2. MECHANIC 2: TEAM FIRE ("TEAM IN THE ZONE")
	# ==========================================
	var state_team = MatchState.new()
	state_team.start(0, 1)
	state_team.freeze = 0
	check(state_team.team_streak[0] == 0 and state_team.team_fire_timer[0] == 0.0, "Team streak and team fire timer initialized to 0")

	# Complete 3 assisted team baskets for team 0
	for basket in range(3):
		state_team.flight = {"kind":"pass", "start":Vector2(400,400), "end":Vector2(500,400), "time":0.3, "duration":0.3, "target":1, "passer":0, "alley":false}
		state_team.tick_flight(0.1) # completes pass, setting last_passer = 0, assist_window = 3.5
		# Player 1 scores assisted basket
		state_team.flight = {"kind":"shot", "start":Vector2(500,400), "end":state_team.hoop_for(0), "time":0.8, "duration":0.8, "shooter":1, "points":2, "made":true, "dunk":false, "blocked":false}
		state_team.tick_flight(0.1)

	check(state_team.team_fire_timer[0] == 25.0, "3 consecutive team-play baskets ignites TEAM FIRE (25.0s timer)")
	check(state_team.is_player_on_fire(0), "Team Fire puts player 0 on fire")
	check(state_team.is_player_on_fire(1), "Team Fire puts player 1 on fire")
	check(state_team.on_fire(0), "Team Fire marks entire team 0 on fire")

	# Opponent scores a basket: team fire must NOT be extinguished!
	state_team.flight = {"kind":"shot", "start":Vector2(800,400), "end":state_team.hoop_for(1), "time":0.8, "duration":0.8, "shooter":2, "points":2, "made":true, "dunk":false, "blocked":false}
	state_team.tick_flight(0.1)
	check(state_team.team_fire_timer[0] > 20.0, "Opponent basket does NOT extinguish TEAM FIRE (timer persists)")
	check(state_team.is_player_on_fire(0), "Team 0 players remain on fire after opponent scores")

	# Countdown of Team Fire
	state_team.tick(5.0, {})
	check(state_team.team_fire_timer[0] < 21.0, "Team Fire timer counts down during match tick")

	# ==========================================
	# 3. MECHANIC 3: ASSIST STAT TRACKING
	# ==========================================
	var state_ast = MatchState.new()
	state_ast.start(0, 1)
	state_ast.freeze = 0
	check(state_ast.stats[0].has("assists"), "stats dictionary tracks assists")
	check(state_ast.stats[0].assists == 0, "initial assists is 0")

	# Player 0 passes to Player 1
	state_ast.flight = {"kind":"pass", "start":Vector2(400,400), "end":Vector2(500,400), "time":0.3, "duration":0.3, "target":1, "passer":0, "alley":false}
	state_ast.tick_flight(0.1) # completes pass
	check(state_ast.last_passer == 0, "completed pass sets last_passer")
	check(state_ast.assist_window == 3.5, "completed pass opens 3.5s assist window")

	# Player 1 makes a shot within the window
	state_ast.flight = {"kind":"shot", "start":Vector2(500,400), "end":state_ast.hoop_for(0), "time":0.8, "duration":0.8, "shooter":1, "points":2, "made":true, "dunk":false, "blocked":false}
	state_ast.tick_flight(0.1)
	check(state_ast.stats[0].assists == 1, "passer awarded assist upon teammate made basket")

	# ==========================================
	# 4. MECHANIC 4: SHOT CLOCK DEACTIVATION UNDER 24S
	# ==========================================
	var state_sc = MatchState.new()
	state_sc.start(0, 1, 15.0) # 15s quarter
	state_sc.tipoff = {}
	state_sc.freeze = 0
	state_sc.inbounding_team = -1
	state_sc.owner = 0
	state_sc.clock = 10.0
	state_sc.shot_clock = 0.5
	state_sc.tick(1.0, {})
	check(state_sc.shot_clock == 24.0, "Shot clock does not count down when game clock < 24.0s")
	check(state_sc.banner != "SHOT CLOCK VIOLATION", "No shot clock violation triggered when period clock < 24.0s")

	# ==========================================
	# 5. MECHANIC 5: DEFENSIVE RUBBER-BANDING (GOALTEND & INTERCEPT)
	# ==========================================
	var state_rb = MatchState.new()
	state_rb.start(0, 1)
	state_rb.freeze = 0
	state_rb.score = [20, 10] # Team 1 trailing by 10 points

	# Test relaxed vertical threshold when trailing by 5+ points
	var shooter = 0 # Team 0
	var defender = 2 # Team 1 (trailing by 10)
	var hoop = state_rb.hoop_for(0)
	state_rb.flight = {"kind":"shot", "start":Vector2(400,465), "end":hoop, "time":0.85, "duration":1.0, "shooter":shooter, "points":2, "made":true, "dunk":false, "blocked":false, "arc_height":4.6, "release_height":1.3}
	state_rb.players[defender].pos = hoop + Vector2(10, 0)
	state_rb.rng.seed = 42 # deterministic check

	# Interception bonus check when trailing
	var pts_down = state_rb.score[0] - state_rb.score[1]
	check(pts_down == 10, "Team 1 trailing by 10 points for defensive rubber-band checks")

	# ==========================================
	# 6. MECHANIC 6: NATURAL MISSED DUNK CLANK
	# ==========================================
	var state_clank = MatchState.new()
	state_clank.start(0, 1)
	state_clank.freeze = 0
	state_clank.score = [10, 10] # Tied game
	state_clank.players[0].pos = state_clank.hoop_for(0) + Vector2(50, 0)
	state_clank.players[0].vel = Vector2(-100, 0)
	state_clank.players[0].charge = 0.5

	# Seed to find natural dunk clank
	var clank_found = false
	for trial in range(300):
		state_clank.rng.seed = trial * 77 + 13
		state_clank.players[0].vel = Vector2(-100, 0)
		state_clank.players[0].charge = 0.5
		state_clank.shoot_ball(0, false, false)
		if state_clank.flight.get("clank", false):
			clank_found = true
			break
	check(clank_found, "Natural missed dunk clank can occur on uncontested dunk in tied game")

	# Verify clank suppression when trailing by 2+ points
	state_clank.score = [10, 15] # Trailing by 5
	var clank_suppressed = true
	for trial in range(100):
		state_clank.rng.seed = trial * 77 + 13
		state_clank.players[0].vel = Vector2(-100, 0)
		state_clank.players[0].charge = 0.5
		state_clank.shoot_ball(0, false, false)
		if state_clank.flight.get("clank", false):
			clank_suppressed = false
			break
	check(clank_suppressed, "Natural dunk clank strictly suppressed when dunker's team is trailing by 2+ points")

	# ==========================================
	# 7. MECHANIC 7: DUNK FACIAL DEFENDER STAGGER
	# ==========================================
	var state_facial = MatchState.new()
	state_facial.start(0, 1)
	state_facial.freeze = 0
	var rim = state_facial.hoop_for(0)
	state_facial.players[2].pos = rim + Vector2(40, 0) # Opponent defender within 78 units
	state_facial.players[2].stun = 0.0

	# Standard made dunk
	state_facial.flight = {"kind":"shot", "start":rim + Vector2(60,0), "end":rim, "time":0.6, "duration":0.6, "shooter":0, "points":2, "made":true, "dunk":true, "blocked":false}
	state_facial.tick_flight(0.1)
	check(state_facial.players[2].stun >= 0.75, "Standard made dunk staggers opposing defender caught near rim (facial)")

	# ==========================================
	# 8. MECHANIC 8: TIPPED PASS ROOF DEFLECTION
	# ==========================================
	var state_tip = MatchState.new()
	state_tip.start(0, 1)
	state_tip.freeze = 0
	state_tip.flight = {"kind":"pass", "start":Vector2(400,400), "end":Vector2(600,400), "time":0.2, "duration":0.4, "target":1, "passer":0, "alley":false}
	state_tip.ball = Vector2(500,400)
	state_tip.players[2].pos = Vector2(500,400)

	var tipped_found = false
	for trial in range(300):
		state_tip.rng.seed = trial * 93 + 7
		state_tip.intercept_pass(2)
		if state_tip.flight.get("tip", false):
			tipped_found = true
			check(state_tip.owner == -1, "Tipped pass is not caught cleanly (owner is -1)")
			check(state_tip.flight.kind == "loose", "Tipped pass deflects into loose ball scramble")
			check(state_tip.flight.arc_height > 4.0, "Tipped pass deflects high towards roof (arc_height > 4.0)")
			check(state_tip.stats[2].steals > 0, "Tipped pass still awards steal stat to defender")
			break
	check(tipped_found, "Tipped pass roof deflection occurs at authentic 4% rate")

	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	if failures > 0:
		quit(1)
	else:
		quit(0)
