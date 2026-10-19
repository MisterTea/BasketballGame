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
	print("--- TESTING ARCADE MECHANICS PASS 3 (ALL 8 MECHANICS) ---")

	# ==========================================
	# 1. MECHANIC 1: DUNK BAIL-OUT LAYUP SWITCH
	# ==========================================
	var state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.inbounding_team = -1
	state.owner = 0
	state.players[0].pos = Vector2(300, 465)

	# Launch a dunk
	state.flight = {
		"kind": "shot",
		"start": Vector2(300, 465),
		"end": state.hoop_for(0),
		"time": 0.22,
		"duration": 0.75,
		"shooter": 0,
		"points": 2,
		"made": true,
		"dunk": true,
		"layup": false,
		"super_dunk": false,
		"finish": "dunk",
		"arc_height": 2.0,
		"blocked": false,
		"clank": false
	}
	state.owner = -1

	# Dunker presses Shoot while airborne
	var dunk_cmd = {0: {"shoot": true, "jump_press": true}}
	state.tick(0.016, dunk_cmd)

	check(state.flight.dunk == false, "Dunk bail-out: flight is no longer a dunk")
	check(state.flight.layup == true, "Dunk bail-out: flight converted into a layup")
	check(state.flight.get("bailed_to_layup", false) == true, "Dunk bail-out: marked as bailed_to_layup")
	check(state.flight.finish == "layup", "Dunk bail-out: finish kind is layup")
	check(state.banner.contains("FINGER ROLL") or state.banner.contains("SWITCHES HANDS"), "Dunk bail-out: announcer calls finger roll / switches hands")

	# ==========================================
	# 2. MECHANIC 2: OFF-BALL DRONE CONTROL
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.inbounding_team = -1
	# Player 1 (CPU) has ball, player 0 (Human) is off-ball
	state.owner = 1
	state.players[1].cooldown = 0
	state.players[1].stun = 0

	# Human player 0 calls for pass
	var call_pass_cmd = {0: {"pass": true, "shoot": false, "turbo": false}}
	state.tick(0.016, call_pass_cmd)
	check(state.banner.contains("CALL FOR PASS") or (not state.flight.is_empty() and state.flight.kind == "pass"), "Off-ball drone control: Human pressing pass calls for pass from AI teammate")

	# Human player 0 calls for shot
	state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.inbounding_team = -1
	state.owner = 1
	state.players[1].cooldown = 0
	state.players[1].pos = Vector2(800, 465)

	var call_shoot_cmd = {0: {"shoot": true, "jump_press": true, "pass": false, "turbo": false}}
	state.tick(0.016, call_shoot_cmd)
	check(state.banner.contains("TAKE THE SHOT") or state.teammate_shot_order == 1 or (not state.flight.is_empty() and state.flight.kind == "shot"), "Off-ball drone control: Human pressing shoot orders AI teammate to shoot")

	# ==========================================
	# 3. MECHANIC 3: BUZZER-BEATER PRAYER BOOST
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	state.players[0].pos = Vector2(200, 465) # Far full-court position
	var hoop = state.hoop_for(0) # at 1115 -> dist > 900
	var dist = state.players[0].pos.distance_to(hoop)
	check(dist > 450.0, "Full court heave position distance > 450 units")

	state.clock = 10.0 # Not buzzer beater
	var normal_pct = state.calculate_shot_percentage(0, 0.58, false, false, false).chance

	state.clock = 3.0 # Under 4.0 seconds remaining!
	var prayer_pct = state.calculate_shot_percentage(0, 0.58, false, false, false).chance

	check(prayer_pct > normal_pct + 0.10, "Buzzer-beater prayer shot receives authentic +15% flat boost")

	# ==========================================
	# 4. MECHANIC 4: RIM CYLINDER & REBOUND LOCKOUT
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.flight = {
		"kind": "shot",
		"start": Vector2(800, 465),
		"end": state.hoop_for(0),
		"time": 1.05,
		"duration": 1.05,
		"shooter": 0,
		"points": 2,
		"made": false,
		"dunk": false,
		"layup": false,
		"super_dunk": false,
		"finish": "jumper",
		"arc_height": 4.6,
		"blocked": false
	}
	state.tick_flight(0.016)

	check(state.in_cylinder_timer >= 0.18, "Rim contact sets in_cylinder lockout timer (~0.20s / 12 ticks)")
	check(state.must_rebound_timer >= 1.95, "Rim contact sets must_rebound lockout timer (~2.0s / 120 ticks)")

	# While in cylinder, loose ball recovery is locked out
	state.owner = -1
	state.ball = state.players[2].pos
	state.tick(0.016, {})
	check(state.owner == -1, "Ball cannot be snatched during in_cylinder debounce window")

	# While must_rebound is active, defend() only executes rebound jumps, no swat blocks
	state.defend(2, false)
	check(state.players[2].jump >= 0.70, "Defender jumps for rebound during must_rebound window")

	# ==========================================
	# 5. MECHANIC 5: TURBO EXHAUSTION BURNOUT
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	state.tipoff = {}
	state.freeze = 0
	state.players[0].turbo = 0.0005 # Just about to empty
	state.players[0].turbo_burnout = 0.0

	var turbo_cmd = {0: {"move": Vector2.RIGHT, "turbo": true}}
	state.tick(0.016, turbo_cmd)

	check(state.players[0].turbo_burnout > 0.70, "Emptying turbo triggers authentic burnout delay (~0.75s / 45 ticks)")

	# During burnout, turbo does not regenerate
	var release_turbo_cmd = {0: {"move": Vector2.RIGHT, "turbo": false}}
	state.tick(0.016, release_turbo_cmd)
	check(state.players[0].turbo == 0.0, "Turbo does not regenerate while burnout cooldown is active")

	# Burnout cooldown expires
	state.players[0].turbo_burnout = 0.01
	state.tick(0.02, release_turbo_cmd)
	check(state.players[0].turbo > 0.0, "Turbo begins regenerating once burnout cooldown expires")

	# ==========================================
	# 6. MECHANIC 6: BACKBOARD BANK SHOT DEFLECTION
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	# Position at authentic 45-degree angle in banking range
	state.players[0].pos = state.hoop_for(0) + Vector2(-120, 80)
	state.owner = 0
	state.shoot_ball(0, false)

	check(state.flight.has("bank_shot"), "Shot dictionary includes bank_shot flag")

	# Verify banked miss dampens rebound arc
	state.flight.made = false
	state.flight.bank_shot = true
	state.flight.time = state.flight.duration
	state.tick_flight(0.016)
	check(state.flight.kind == "rebound", "Missed bank shot transitions to rebound")
	check(state.banner.contains("OFF THE GLASS"), "Bank shot miss announces OFF THE GLASS")

	# ==========================================
	# 7. MECHANIC 7: CPU DRONE DEFICIT AGGRESSION & CLOCK MANAGEMENT
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)
	state.quarter = 4
	state.clock = 45.0
	state.shot_clock = 18.0

	# Case A: CPU (Team 1, Player 2) trailing in Q4 by 10 points
	state.score = [20, 10]
	state.owner = 0 # Human has ball
	state.players[2].pos = state.players[0].pos + Vector2(20, 0)
	var ai_defensive = state.ai(2)
	check(ai_defensive.turbo == true, "Trailing CPU drone in Q4 engages turbo to aggressively pursue ball-carrier")

	# Case B: CPU (Team 1, Player 2) leading in Q4 by 8 points
	state.score = [10, 18]
	state.owner = 2
	state.shot_clock = 15.0
	state.clock = 30.0
	var ai_lead = state.ai(2)
	check(ai_lead.shoot == false, "Leading CPU drone in Q4 burns clock before taking shot")

	# ==========================================
	# 8. MECHANIC 8: CLUTCH ATTRIBUTE SURGE (FINAL 10 SECONDS)
	# ==========================================
	state = MatchState.new()
	state.start(0, 1)

	# Shot percentage clutch boost
	state.clock = 30.0
	var mid_game_chance = state.calculate_shot_percentage(0, 0.58, false, false, false).chance
	state.clock = 8.0 # Final 10 seconds of quarter
	var clutch_game_chance = state.calculate_shot_percentage(0, 0.58, false, false, false).chance
	check(clutch_game_chance > mid_game_chance + 0.05, "Clutch rating boosts shot chance in final 10s of quarter")

	# Clutch pass speed boost
	state.clock = 8.0
	state.owner = 0
	state.pass_ball(0, false)
	check(state.flight.duration < 0.60, "Clutch rating delivers faster laser pass duration in final 10s")

	# Summary
	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	if failures > 0:
		push_error("TEST SUITE FAILED with %d failures" % failures)
		quit(1)
	else:
		print("ALL PASS 3 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
