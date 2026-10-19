extends SceneTree

const MatchState = preload("res://scripts/match_state.gd")

func _init() -> void:
	print("\n--- TESTING ARCADE MECHANICS PASS 5 ---")
	var results = {"checks": 0, "failures": 0}

	var assert_true = func(cond: bool, msg: String):
		results.checks += 1
		if cond:
			print("PASS: %s" % msg)
		else:
			print("FAIL: %s" % msg)
			results.failures += 1

	# Test 1: Tournament mode disables rubber banding and blowout throttle
	var s_tourn = MatchState.new()
	s_tourn.start(0, 1)
	s_tourn.tipoff = {}
	s_tourn.score = [0, 20] # Trailing by 20 points
	s_tourn.tournament_mode = true
	var shot_breakdown = s_tourn.calculate_shot_percentage(0, 0.58, false, false, false)
	assert_true.call(is_equal_approx(shot_breakdown.rubber_band, 0.0), "Tournament mode forces rubber band bonus to strictly 0.0")

	# Test 2: No Pushing mode cancels shoves
	var s_nopush = MatchState.new()
	s_nopush.start(0, 1)
	s_nopush.tipoff = {}
	s_nopush.no_pushing = true
	s_nopush.owner = 2
	s_nopush.players[0].pos = Vector2(600, 400)
	s_nopush.players[2].pos = Vector2(610, 400)
	s_nopush.steal(0, true) # Attempt shove
	assert_true.call(s_nopush.banner.contains("NO PUSHING"), "No pushing mode announces NO PUSHING! on shove attempt")
	assert_true.call(s_nopush.players[2].stun == 0.0, "No pushing mode prevents victim from being stunned")

	# Test 3: Fast Passing halves pass duration
	var s_fp = MatchState.new()
	s_fp.start(0, 1)
	s_fp.tipoff = {}
	s_fp.owner = 0
	s_fp.players[0].pos = Vector2(400, 400)
	s_fp.players[1].pos = Vector2(700, 400)
	s_fp.ball = s_fp.players[0].pos
	s_fp.pass_ball(0, false)
	var standard_duration = s_fp.flight.duration

	var s_fp2 = MatchState.new()
	s_fp2.start(0, 1)
	s_fp2.tipoff = {}
	s_fp2.fast_passing = true
	s_fp2.owner = 0
	s_fp2.players[0].pos = Vector2(400, 400)
	s_fp2.players[1].pos = Vector2(700, 400)
	s_fp2.ball = s_fp2.players[0].pos
	s_fp2.pass_ball(0, false)
	var fast_duration = s_fp2.flight.duration
	assert_true.call(is_equal_approx(fast_duration, standard_duration * 0.50), "Fast passing cheat halves pass flight duration (bullet passes)")

	# Test 4: Maximum Power cheat knocks down any defender
	var s_pwr = MatchState.new()
	s_pwr.start(0, 1)
	s_pwr.tipoff = {}
	s_pwr.maximum_power = true
	s_pwr.owner = 2 # Victim
	s_pwr.players[0].pos = Vector2(600, 400)
	s_pwr.players[2].pos = Vector2(610, 400)
	s_pwr.resolve_steal(0, true)
	assert_true.call(s_pwr.players[2].stun >= 0.90, "Maximum power cheat guarantees heavy knockdown regardless of base strength")

	# Test 5: Fadeaway jumper on backward release
	var s_fade = MatchState.new()
	s_fade.start(0, 1)
	s_fade.tipoff = {}
	s_fade.phase = "playing"
	s_fade.freeze = 0.0
	s_fade.owner = 0
	var hoop_f = s_fade.hoop_for(0)
	# Position at distance 200, moving backward away from hoop
	var toward_hoop = (hoop_f - Vector2(400, 400)).normalized()
	s_fade.players[0].pos = Vector2(400, 400)
	s_fade.players[0].vel = -toward_hoop * 60.0
	s_fade.shoot_ball(0, false)
	assert_true.call(s_fade.flight.get("fadeaway", false) == true, "Moving away from hoop during release launches fadeaway jumper")
	assert_true.call(s_fade.banner.contains("FADEAWAY"), "Fadeaway jumper announces FADEAWAY JUMPER!")
	assert_true.call(s_fade.players[0].vel.dot(toward_hoop) < 0.0, "Fadeaway imparts backward drift velocity away from rim")

	# Test 6: AI Help Defense / Double Team
	var s_ai = MatchState.new()
	s_ai.start(0, 1)
	s_ai.tipoff = {}
	s_ai.owner = 0 # Player 0 (Team 0) has ball
	# Defenders are Player 2 (primary) and Player 3 (off-ball)
	# Stun primary defender
	s_ai.players[2].stun = 1.0
	var ai_cmd3 = s_ai.ai(3)
	# In help defense, Player 3 moves toward ball carrier (player 0)
	var dir_to_ball = (s_ai.players[0].pos - s_ai.players[3].pos).normalized()
	assert_true.call(ai_cmd3.move.dot(dir_to_ball) > 0.5, "Off-ball drone switches to help defense / double-team when partner is stunned")

	# Test 7: Double and Triple Overtime period naming
	var s_ot = MatchState.new()
	s_ot.start(0, 1)
	s_ot.tipoff = {}
	s_ot.quarter = 4
	s_ot.score = [50, 50]
	s_ot.next_period()
	assert_true.call(s_ot.banner == "OVERTIME", "1st OT announces OVERTIME")
	s_ot.next_period()
	assert_true.call(s_ot.banner == "DOUBLE OVERTIME", "2nd OT announces DOUBLE OVERTIME")
	s_ot.next_period()
	assert_true.call(s_ot.banner == "TRIPLE OVERTIME", "3rd OT announces TRIPLE OVERTIME")

	print("\n--- RESULTS: %d checks, %d failures ---" % [results.checks, results.failures])
	if results.failures == 0:
		print("ALL PASS 5 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
	else:
		printerr("TEST FAILURES OCCURRED!")
		quit(1)
