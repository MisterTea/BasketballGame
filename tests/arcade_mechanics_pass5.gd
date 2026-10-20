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

	# Test 8: Off-ball offensive player moves to the net and shoves guarding defender
	var s_off = MatchState.new()
	s_off.start(0, 1)
	s_off.tipoff = {}
	s_off.owner = 0 # Team 0 has possession (Player 0)
	var hoop0 = s_off.hoop_for(0)
	# Player 1 is off-ball teammate
	s_off.players[1].pos = Vector2(400, 465)
	# Defending players are placed far away initially
	s_off.players[2].pos = Vector2(800, 200)
	s_off.players[3].pos = Vector2(800, 600)
	var cmd_offball = s_off.ai(1)
	var dir_to_net = (hoop0 - s_off.players[1].pos).normalized()
	assert_true.call(cmd_offball.move.dot(dir_to_net) > 0.85, "Off-ball player moves directly to the net when uncontested")

	# Now place an opposing defender guarding player 1
	s_off.players[2].pos = Vector2(440, 465) # 40 units away, right in path to net
	s_off.players[2].stun = 0.0
	s_off.players[1].cooldown = 0.0
	s_off.players[1].turbo = 1.0
	var cmd_guarded = s_off.ai(1)
	assert_true.call(cmd_guarded.pass == true and cmd_guarded.turbo == true, "Off-ball player attempts to shove guarding defender")

	# Tick simulation with the AI command to verify shove resolution
	var prev_def_x = s_off.players[2].pos.x
	s_off.tick(0.016, {0: {}, 1: cmd_guarded})
	assert_true.call(s_off.players[2].stun > 0.0, "Guarding defender is stunned by off-ball offensive shove")
	assert_true.call(s_off.players[2].pos.x > prev_def_x, "Guarding defender is knocked backward by shove")
	assert_true.call(s_off.owner == 0, "Offensive shove maintains team ball possession")

	# Once defender is stunned, off-ball player resumes running to the net
	var cmd_after_shove = s_off.ai(1)
	assert_true.call(cmd_after_shove.move.dot(dir_to_net) > 0.85, "Off-ball player resumes moving to net after defender is stunned")

	# Test 9: Aggressive CPU defense - turboing to player, shoving player, and shoving teammate
	var s_def = MatchState.new()
	s_def.start(0, 1)
	s_def.difficulty = 1 # Normal difficulty
	s_def.tipoff = {}
	s_def.owner = 0 # Player 0 has ball
	s_def.players[0].pos = Vector2(500, 465)
	s_def.players[1].pos = Vector2(350, 465) # Teammate
	s_def.players[2].pos = Vector2(580, 465) # Defender 2 marking Player 0, 80 units away
	s_def.players[2].turbo = 1.0
	s_def.players[2].cooldown = 0.0

	# 1. Defender turbos aggressively to close the distance to the ball carrier
	var cmd_pursue = s_def.ai(2)
	assert_true.call(cmd_pursue.turbo == true, "CPU defender engages turbo to aggressively pursue the ball carrier")

	# 2. In shove range (< 68 units), defender initiates shove on the ball carrier
	s_def.players[2].pos = Vector2(550, 465) # 50 units away from player 0
	var found_shove_owner = false
	for _i in range(50):
		var cmd_close = s_def.ai(2)
		if cmd_close.pass == true and cmd_close.turbo == true:
			found_shove_owner = true
			s_def.tick(0.016, {0: {}, 2: cmd_close})
			break
	assert_true.call(found_shove_owner, "CPU defender attempts shove against the ball carrier")
	assert_true.call(s_def.players[0].stun > 0.0, "Ball carrier is stunned/knocked down by aggressive CPU shove")
	assert_true.call(s_def.owner == 2 or s_def.owner == -1, "CPU shove forces a turnover from the ball carrier")

	# 3. Off-ball defender shoves the player's teammate
	var s_team = MatchState.new()
	s_team.start(0, 1)
	s_team.difficulty = 1 # Normal
	s_team.tipoff = {}
	s_team.owner = 0 # Player 0 has ball
	s_team.players[0].pos = Vector2(700, 465)
	s_team.players[1].pos = Vector2(300, 465) # Teammate
	s_team.players[3].pos = Vector2(345, 465) # Defender 3 guarding Teammate, 45 units away
	s_team.players[3].turbo = 1.0
	s_team.players[3].cooldown = 0.0
	var found_shove_teammate = false
	for _i in range(50):
		var cmd_team = s_team.ai(3)
		if cmd_team.pass == true and cmd_team.turbo == true:
			found_shove_teammate = true
			s_team.tick(0.016, {0: {}, 1: {}, 3: cmd_team})
			break
	assert_true.call(found_shove_teammate, "CPU defender attempts shove against the player's teammate")
	assert_true.call(s_team.players[1].stun > 0.0, "Player's teammate is stunned/knocked down by defensive shove")

	print("\n--- RESULTS: %d checks, %d failures ---" % [results.checks, results.failures])
	if results.failures == 0:
		print("ALL PASS 5 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
	else:
		printerr("TEST FAILURES OCCURRED!")
		quit(1)
