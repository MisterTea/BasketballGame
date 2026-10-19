extends SceneTree

const MatchState = preload("res://scripts/match_state.gd")

func _init() -> void:
	print("\n--- TESTING ARCADE MECHANICS PASS 4 ---")
	var results = {"checks": 0, "failures": 0}

	var assert_true = func(cond: bool, msg: String):
		results.checks += 1
		if cond:
			print("PASS: %s" % msg)
		else:
			print("FAIL: %s" % msg)
			results.failures += 1

	# Test 1: Hook shot detection in finish_kind
	var s = MatchState.new()
	s.start(0, 1)
	s.phase = "playing"
	s.freeze = 0.0
	s.owner = 0
	var hoop0 = s.hoop_for(0)
	# Position player 0 at distance ~120 from hoop, moving vertically (cross-court)
	s.players[0].pos = hoop0 + Vector2(-120.0 if hoop0.x > 640 else 120.0, 0.0)
	s.players[0].vel = Vector2(0.0, 80.0)
	s.players[0].drive = 0.2
	var finish = s.finish_kind(0, false)
	assert_true.call(finish == "hook_shot", "Moving across court without turbo triggers hook_shot finish")

	# Test 2: Hook shot execution in shoot_ball
	s.shoot_ball(0, false)
	assert_true.call(s.flight.get("hook", false) == true, "Hook shot flight has hook flag set")
	assert_true.call(is_equal_approx(s.flight.get("arc_height", 0.0), 2.5), "Hook shot has authentic arc height (2.5)")
	assert_true.call(s.banner.contains("HOOK SHOT"), "Hook shot announces HOOK SHOT!")

	# Test 3: Behind the back pass
	var s_pass = MatchState.new()
	s_pass.start(0, 1)
	s_pass.phase = "playing"
	s_pass.freeze = 0.0
	s_pass.owner = 0
	s_pass.players[0].pos = Vector2(500.0, 450.0)
	s_pass.players[0].face = 1 # facing right (+X)
	s_pass.players[1].pos = Vector2(300.0, 450.0) # teammate is behind (-X)
	s_pass.ball = s_pass.players[0].pos
	s_pass.pass_ball(0, false)
	assert_true.call(s_pass.flight.get("behind_back", false) == true, "Passing behind player facing direction triggers behind-the-back pass")
	assert_true.call(s_pass.banner.contains("BEHIND THE BACK"), "Behind-the-back pass announces BEHIND THE BACK PASS!")

	# Test 4: Double dunk initiation from airborne dish
	var s_dd = MatchState.new()
	s_dd.start(0, 1)
	s_dd.tipoff = {}
	s_dd.phase = "playing"
	s_dd.freeze = 0.0
	s_dd.owner = -1
	var hoop = s_dd.hoop_for(0)
	s_dd.flight = {
		"kind": "shot", "start": hoop + Vector2(-80, 0), "end": hoop,
		"time": 0.25, "duration": 0.80, "shooter": 0, "points": 2,
		"made": true, "dunk": true, "blocked": false
	}
	# Teammate (player 1) is jumping near the basket
	s_dd.players[1].pos = hoop + Vector2(-50, 20)
	s_dd.players[1].receive_jump = 0.50
	s_dd.players[1].jump = 0.50
	# Player 0 presses pass mid-air
	var cmds = {0: {"pass": true, "turbo": false}}
	s_dd.tick(0.016, cmds)
	assert_true.call(s_dd.flight.get("double_dunk", false) == true, "Airborne dish to jumping teammate triggers double_dunk flag")
	assert_true.call(s_dd.banner.contains("DOUBLE DUNK"), "Airborne dish to jumping teammate announces DOUBLE DUNK!")

	# Test 5: Double dunk catch and score advances team streak
	s_dd.players[1].receive_jump = 0.40
	s_dd.flight.time = s_dd.flight.duration + 0.01
	s_dd.tick_flight(0.016)
	assert_true.call(s_dd.flight.get("kind", "") == "shot" and s_dd.flight.shooter == 1, "Teammate caught the double dunk pass and launched dunk")
	# Now let the double dunk score land
	assert_true.call(not s_dd.flight.is_empty(), "Double dunk flight is active")
	if not s_dd.flight.is_empty():
		s_dd.flight.time = s_dd.flight.duration + 0.01
		s_dd.flight.made = true
		var prev_streak = s_dd.team_streak[0]
		s_dd.tick_flight(0.016)
		assert_true.call(s_dd.team_streak[0] == prev_streak + 1, "Made double dunk advances team fire streak")

	# Test 6: Shove knockdown increments victim injury stat
	var s_inj = MatchState.new()
	s_inj.start(0, 1)
	s_inj.tipoff = {}
	s_inj.phase = "playing"
	s_inj.freeze = 0.0
	s_inj.owner = 2 # Player 2 (team 1) has ball
	s_inj.players[2].pos = Vector2(600, 400)
	s_inj.players[0].pos = Vector2(610, 400) # Player 0 (team 0) close by
	var prev_injury = s_inj.stats[2].injury
	s_inj.resolve_steal(0, true) # Shove
	assert_true.call(s_inj.stats[2].injury == prev_injury + 1, "Hard shove knockdown increments victim injury stat")

	# Test 7: Trailing team turbo conservation (pts_down >= 8)
	var s_turb = MatchState.new()
	s_turb.start(0, 1)
	s_turb.tipoff = {}
	s_turb.phase = "playing"
	s_turb.freeze = 0.0
	# Tied score: normal drain
	s_turb.score = [10, 10]
	s_turb.players[0].turbo = 1.0
	s_turb.tick(1.0, {0: {"turbo": true, "move": Vector2.RIGHT}})
	var normal_drain = 1.0 - s_turb.players[0].turbo

	# Trailing by 10 points: conserved drain (0.75x)
	var s_turb2 = MatchState.new()
	s_turb2.start(0, 1)
	s_turb2.tipoff = {}
	s_turb2.phase = "playing"
	s_turb2.freeze = 0.0
	s_turb2.score = [0, 10] # Team 0 trailing by 10
	s_turb2.players[0].turbo = 1.0
	s_turb2.tick(1.0, {0: {"turbo": true, "move": Vector2.RIGHT}})
	var conserved_drain = 1.0 - s_turb2.players[0].turbo
	assert_true.call(is_equal_approx(conserved_drain, normal_drain * 0.75), "Trailing by 8+ points scales turbo drain by 0.75 (trailing conservation)")

	# Test 8: Rim hang gravity suspension on made dunk
	var s_hang = MatchState.new()
	s_hang.start(0, 1)
	s_hang.tipoff = {}
	s_hang.phase = "playing"
	s_hang.freeze = 0.0
	var hoop_h = s_hang.hoop_for(0)
	s_hang.flight = {
		"kind": "shot", "start": hoop_h + Vector2(-60, 0), "end": hoop_h,
		"time": 0.80, "duration": 0.80, "shooter": 0, "points": 2,
		"made": true, "dunk": true, "blocked": false
	}
	s_hang.players[0].jump = 0.05
	s_hang.tick_flight(0.016)
	assert_true.call(s_hang.players[0].jump >= 0.20, "Made dunk suspends gravity with rim hang (jump >= 0.20s)")

	print("\n--- RESULTS: %d checks, %d failures ---" % [results.checks, results.failures])
	if results.failures == 0:
		print("ALL PASS 4 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
	else:
		printerr("TEST FAILURES OCCURRED!")
		quit(1)
