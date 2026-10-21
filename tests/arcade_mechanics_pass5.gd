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
	s_def.freeze = 0.0
	s_def.owner = 0 # Player 0 has ball
	s_def.players[0].pos = Vector2(500, 465)
	s_def.players[1].pos = Vector2(350, 465) # Teammate
	s_def.players[2].pos = Vector2(580, 465) # Defender 2 marking Player 0, 80 units away
	s_def.players[2].turbo = 1.0
	s_def.players[2].cooldown = 0.0

	# 1. Defender turbos aggressively to close the distance to the ball carrier
	var cmd_pursue = s_def.ai(2)
	assert_true.call(cmd_pursue.turbo == true, "CPU defender engages turbo to aggressively pursue the ball carrier")

	# 2. In shove range (< 56 units), defender initiates shove on the ball carrier
	s_def.players[2].pos = Vector2(530, 465) # 30 units away from player 0
	var found_shove_owner = false
	for _i in range(150):
		var cmd_close = s_def.ai(2)
		if cmd_close.pass == true and cmd_close.turbo == true:
			found_shove_owner = true
			s_def.players[2].pos = Vector2(530, 465)
			for _step in range(4):
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
	s_team.freeze = 0.0
	s_team.owner = 0 # Player 0 has ball
	s_team.players[0].pos = Vector2(700, 465)
	s_team.players[1].pos = Vector2(300, 465) # Teammate
	s_team.players[3].pos = Vector2(330, 465) # Defender 3 guarding Teammate, 30 units away
	s_team.players[3].turbo = 1.0
	s_team.players[3].cooldown = 0.0
	var found_shove_teammate = false
	for _i in range(150):
		var cmd_team = s_team.ai(3)
		if cmd_team.pass == true and cmd_team.turbo == true:
			found_shove_teammate = true
			s_team.players[3].pos = Vector2(330, 465)
			for _step in range(4):
				s_team.tick(0.016, {0: {}, 1: {}, 3: cmd_team})
			break
	assert_true.call(found_shove_teammate, "CPU defender attempts shove against the player's teammate")
	assert_true.call(s_team.players[1].stun > 0.0, "Player's teammate is stunned/knocked down by defensive shove")

	# Test 10: Authentic 8-attribute separation (PLYRAT.ASM: Speed, Shoot, Dunk, Block, Steal, Pass, Power, Clutch)
	var s_attr = MatchState.new()
	s_attr.start(0, 1)
	assert_true.call(s_attr.rating(0, 6) >= 0.0 and s_attr.rating(0, 7) >= 0.0, "All 8 PLYRAT.ASM attributes (including Power=6 and Clutch=7) are indexed per athlete")

	# Test 11: Individual On-Fire lasts 4 made shots regardless of 2pt vs 3pt (PLYR2.ASM:487, 2043)
	var s_fire = MatchState.new()
	s_fire.start(0, 1)
	s_fire.record_natural_basket(0, 2)
	s_fire.record_natural_basket(0, 2)
	s_fire.record_natural_basket(0, 2) # Ignites fire on 3rd basket
	assert_true.call(s_fire.fire_player == 0, "3 consecutive baskets ignite individual fire")
	s_fire.record_natural_basket(0, 3) # Shot 1 while on fire (3 pts)
	s_fire.record_natural_basket(0, 3) # Shot 2 while on fire (6 pts)
	s_fire.record_natural_basket(0, 3) # Shot 3 while on fire (9 pts - previously cooled off at 8 pts!)
	assert_true.call(s_fire.fire_player == 0 and s_fire.fire_shots == 3, "Individual On-Fire stays active after 3 made three-pointers (9 points, 3/4 fire shots)")
	s_fire.record_natural_basket(0, 2) # Shot 4 while on fire -> cools off
	assert_true.call(s_fire.fire_player == -1 and s_fire.fire_shots == 0, "Individual On-Fire cools off after 4th made basket while on fire")

	# Test 12: Team Fire timer pauses while opponent controls the ball (SCORE.ASM:3020-3041)
	var s_tfire = MatchState.new()
	s_tfire.start(0, 1)
	s_tfire.tipoff = {}
	s_tfire.freeze = 0.0
	s_tfire.team_fire_timer = [20.0, 0.0]
	s_tfire.owner = 2 # Opponent (Team 1) has the ball
	s_tfire.tick(1.0, {})
	assert_true.call(is_equal_approx(s_tfire.team_fire_timer[0], 20.0), "Team Fire timer pauses while the opposing team has possession")
	s_tfire.owner = 0 # Team 0 has the ball
	s_tfire.tick(1.0, {0: {}})
	assert_true.call(s_tfire.team_fire_timer[0] < 20.0, "Team Fire timer counts down when the team on fire controls the ball")

	# Test 13: Backcourt stalling penalty (PLYR.ASM:2188-2210)
	var s_stall = MatchState.new()
	s_stall.start(0, 1)
	s_stall.tipoff = {}
	s_stall.freeze = 0.0
	s_stall.owner = 0
	s_stall.score = [10, 8] # Team 0 leading
	s_stall.shot_clock = 8.0 # <= 10s on shot clock
	s_stall.players[0].pos = Vector2(300, 465) # In backcourt (> 530px from hoop at 1115)
	s_stall.players[2].pos = Vector2(900, 200)
	s_stall.players[3].pos = Vector2(900, 600)
	s_stall.tick(0.05, {0: {"move": Vector2.RIGHT, "turbo": false}})
	var stalled_speed = s_stall.players[0].vel.length()
	s_stall.shot_clock = 20.0
	s_stall.tick(0.05, {0: {"move": Vector2.RIGHT, "turbo": false}})
	var normal_speed = s_stall.players[0].vel.length()
	assert_true.call(stalled_speed < normal_speed * 0.75, "Backcourt stalling penalty slows leading ball-carrier when shot clock <= 10s")

	# Test 14: Weak 3-point shooter penalty (PLYR.ASM:5913-5915) & close jumper bonus (PLYR.ASM:5925-5927)
	var s_3pt = MatchState.new()
	s_3pt.start(0, 1)
	s_3pt.tipoff = {}
	s_3pt.freeze = 0.0
	for p_idx in range(4):
		s_3pt.players[p_idx].pos = Vector2(50, 50)
	var hoop_t1 = s_3pt.hoop_for(1) # HOOPS[0] = (165, 465)
	s_3pt.players[3].pos = hoop_t1 + Vector2(305, 0) # 3-pointer for weak 3pt shooter (rating 5, <= SHT5)
	s_3pt.players[3].vel = Vector2.ZERO
	s_3pt.players[3].still_time = 1.0
	var weak_3 = s_3pt.calculate_shot_percentage(3, 0.58, false, false, false, false, false, false, false)
	s_3pt.players[3].pos = hoop_t1 + Vector2(295, 0) # 2-pointer just inside the arc (no -20% weak 3pt penalty)
	var weak_2 = s_3pt.calculate_shot_percentage(3, 0.58, false, false, false, false, false, false, false)
	assert_true.call(weak_2.chance - weak_3.chance >= 0.20, "Weak 3-point shooter (shooting <= 5) receives authentic -20% 3pt penalty")

	# Test 15: Quarter transition refills all players' turbo to 100% (SCORE.ASM:1825-1832)
	var s_qtr = MatchState.new()
	s_qtr.start(0, 1)
	s_qtr.tipoff = {}
	s_qtr.players[0].turbo = 0.2
	s_qtr.players[0].turbo_burnout = 0.5
	s_qtr.next_period()
	assert_true.call(is_equal_approx(s_qtr.players[0].turbo, 1.0) and is_equal_approx(s_qtr.players[0].turbo_burnout, 0.0), "Period transition refills all players' turbo meters and clears burnout")

	# Test 16: Consecutive spin within 2.0s grants reduced 0.16s (10-tick) steal immunity (PLYR.ASM:2424-2436)
	var s_cspin = MatchState.new()
	s_cspin.start(0, 1)
	s_cspin.tipoff = {}
	s_cspin.freeze = 0.0
	s_cspin.inbounding_team = -1
	s_cspin.owner = 0
	s_cspin.players[0].pos = Vector2(500, 450)
	s_cspin.players[0].turbo = 1.0
	s_cspin.tick(0.016, {0: {"move": Vector2.RIGHT, "spin": true}})
	assert_true.call(s_cspin.players[0].steal_immune > 0.90, "First spin move grants 1.0s (60-tick) steal immunity")
	# Advance past spin animation (0.45s) while still inside 2.0s spin_cooldown window
	s_cspin.players[0].spin = 0.0
	s_cspin.players[0].cooldown = 0.0
	s_cspin.players[0].turbo = 1.0
	s_cspin.tick(0.016, {0: {"move": Vector2.RIGHT, "spin": true}})
	assert_true.call(s_cspin.players[0].spin > 0.35 and s_cspin.players[0].steal_immune < 0.25, "Consecutive spin within 2.0s executes with reduced 0.16s (10-tick) steal immunity")

	# Test 17: Standing elbow clearout grants 2.33s (140-tick) steal immunity (PLYR2.ASM:4162-4165)
	var s_elbo = MatchState.new()
	s_elbo.start(0, 1)
	s_elbo.tipoff = {}
	s_elbo.freeze = 0.0
	s_elbo.inbounding_team = -1
	s_elbo.owner = 0
	s_elbo.players[0].pos = Vector2(500, 450)
	s_elbo.players[0].turbo = 1.0
	s_elbo.tick(0.016, {0: {"move": Vector2.ZERO, "spin": true}})
	assert_true.call(s_elbo.players[0].elbow > 0.35 and s_elbo.players[0].steal_immune > 2.0, "Standing elbow clearout grants authentic 2.33s (140-tick) steal immunity")

	# Test: Spin move and elbow without enough turbo triggers turbo_flash and NEED TURBO announcement
	var s_noturbo = MatchState.new()
	s_noturbo.start(0, 1)
	s_noturbo.tipoff = {}
	s_noturbo.freeze = 0.0
	s_noturbo.inbounding_team = -1
	s_noturbo.owner = 0
	s_noturbo.players[0].pos = Vector2(500, 450)
	s_noturbo.players[0].turbo = 0.10 # Below 0.14 threshold
	s_noturbo.tick(0.016, {0: {"move": Vector2.RIGHT, "spin": true}})
	assert_true.call(s_noturbo.players[0].spin == 0.0, "Spin move does not execute without enough turbo")
	assert_true.call(s_noturbo.players[0].turbo_flash > 0.50, "Spin move without enough turbo triggers turbo_flash (>0.5s)")
	assert_true.call(s_noturbo.banner.contains("NEED TURBO"), "Spin move without enough turbo announces NEED TURBO!")

	var s_noturbo_elbo = MatchState.new()
	s_noturbo_elbo.start(0, 1)
	s_noturbo_elbo.tipoff = {}
	s_noturbo_elbo.freeze = 0.0
	s_noturbo_elbo.inbounding_team = -1
	s_noturbo_elbo.owner = 0
	s_noturbo_elbo.players[0].pos = Vector2(500, 450)
	s_noturbo_elbo.players[0].turbo = 0.0
	s_noturbo_elbo.tick(0.016, {0: {"move": Vector2.ZERO, "spin": true}})
	assert_true.call(s_noturbo_elbo.players[0].elbow == 0.0, "Elbow clearout does not execute without enough turbo")
	assert_true.call(s_noturbo_elbo.players[0].turbo_flash > 0.50, "Elbow clearout without enough turbo triggers turbo_flash (>0.5s)")

	# Test 18: Bank shots suppressed when any player is on fire (PLYR.ASM:6328-6329)
	var s_bank = MatchState.new()
	s_bank.start(0, 1)
	s_bank.tipoff = {}
	s_bank.freeze = 0.0
	s_bank.fire_player = 2 # Someone on court is on fire
	var banked_while_fire = false
	for trial in range(60):
		s_bank.rng.seed = trial * 37 + 11
		s_bank.owner = 0
		s_bank.players[0].pos = s_bank.hoop_for(0) + Vector2(-120, 80)
		s_bank.players[0].vel = Vector2.ZERO
		s_bank.shoot_ball(0, false)
		if s_bank.flight.get("bank_shot", false):
			banked_while_fire = true
			break
	assert_true.call(not banked_while_fire, "Bank shots are strictly suppressed when any player is on fire")

	# Test 19: Off-ball On-Fire drone spaces to 3-point arc instead of crowding rim (DRONE.ASM:981-984)
	var s_fire_ai = MatchState.new()
	s_fire_ai.start(0, 1)
	s_fire_ai.tipoff = {}
	s_fire_ai.freeze = 0.0
	s_fire_ai.owner = 0
	s_fire_ai.fire_player = 1 # Off-ball teammate is on fire
	var hoop_ai = s_fire_ai.hoop_for(0)
	s_fire_ai.players[1].pos = hoop_ai + Vector2(-80, 0) # Near the basket
	s_fire_ai.players[2].pos = Vector2(300, 200)
	s_fire_ai.players[3].pos = Vector2(300, 600)
	var fire_offball_cmd = s_fire_ai.ai(1)
	assert_true.call(fire_offball_cmd.move.x < -0.5, "Off-ball On-Fire drone moves out toward the 3-point arc instead of cutting to the rim")

	# Test 20: Fast-break outlet spacing when teammate is much closer to rebound (DRONE.ASM:1880-1892)
	var s_outlet = MatchState.new()
	s_outlet.start(0, 1)
	s_outlet.tipoff = {}
	s_outlet.freeze = 0.0
	s_outlet.owner = -1
	s_outlet.flight = {
		"kind": "rebound",
		"start": Vector2(200, 465),
		"end": Vector2(250, 465),
		"time": 0.20,
		"duration": MatchState.REBOUND_FLIGHT_DURATION,
		"shooter": 2,
		"arc_height": 2.2,
		"bounces": 0
	}
	s_outlet.ball = s_outlet.flight_position()
	s_outlet.players[0].pos = Vector2(240, 465) # Close to rebound
	s_outlet.players[1].pos = Vector2(550, 465) # Far from rebound (>90px further than teammate)
	var outlet_cmd = s_outlet.ai(1)
	assert_true.call(outlet_cmd.move.x > 0.5, "Further drone sprints toward offensive 3-point outlet when teammate has rebound covered")

	# Test 21: Contested airball roll & goaltending exemption (PLYR.ASM:6430-6488, PLYR2.ASM:2727-2730)
	var s_air = MatchState.new()
	s_air.start(0, 1)
	s_air.tipoff = {}
	s_air.freeze = 0.0
	var airball_found = false
	for trial in range(250):
		s_air.rng.seed = trial * 53 + 19
		s_air.owner = 0
		s_air.players[0].pos = s_air.hoop_for(0) + Vector2(-320, 0)
		s_air.players[2].pos = s_air.players[0].pos + Vector2(25, 0) # Tightly guarded (<=68px)
		s_air.shoot_ball(0, false)
		if s_air.flight.get("airball", false):
			airball_found = true
			break
	assert_true.call(airball_found, "Tightly contested jump shot can produce an authentic airball")
	# Verify descending airball at rim is never called for goaltending
	s_air.flight.time = s_air.flight.duration * 0.92
	s_air.ball = s_air.flight_position()
	s_air.players[2].pos = s_air.ball
	s_air.defend(2, false)
	assert_true.call(s_air.flight.blocked and s_air.stats[2].goaltends == 0, "Descending airball at rim can be legally swatted without goaltending")

	# Test 22: Post-rebound ball retention and steal immunity (PLYR2.ASM:2832-2842)
	var s_reb_prot = MatchState.new()
	s_reb_prot.start(0, 1)
	s_reb_prot.tipoff = {}
	s_reb_prot.freeze = 0.0
	s_reb_prot.owner = -1
	s_reb_prot.loose_ball_timer = 0.0
	s_reb_prot.in_cylinder_timer = 0.0
	s_reb_prot.ball = Vector2(500, 465)
	s_reb_prot.players[0].pos = Vector2(500, 465)
	s_reb_prot.tick(0.016, {0: {}})
	assert_true.call(s_reb_prot.owner == 0 and s_reb_prot.players[0].push_keep_ball > 1.0 and s_reb_prot.players[0].steal_immune >= 0.20, "Securing a rebound grants 80-tick push_keep_ball protection and steal immunity")

	# Test 23: Per-period 3-alley-oop drone limit & reset on next_period (SCORE.ASM:1864-1873, DRONE.ASM:884-891)
	var s_aly = MatchState.new()
	s_aly.start(0, 1)
	s_aly.tipoff = {}
	s_aly.freeze = 0.0
	s_aly.owner = 0
	s_aly.players[1].pos = s_aly.hoop_for(0) + Vector2(-110, 0)
	s_aly.players[2].pos = Vector2(200, 200)
	s_aly.players[3].pos = Vector2(200, 600)
	s_aly.players[1].alley_cnt = 3 # Already completed 3 alley-oops this period
	var aly_blocked_by_cap = true
	for trial in range(100):
		s_aly.rng.seed = trial * 29 + 3
		if s_aly.ai(1).shoot:
			aly_blocked_by_cap = false
			break
	assert_true.call(aly_blocked_by_cap, "Off-ball drone respects the 3-alley-oop per-period cap (plyr_alley_cnt)")
	s_aly.next_period()
	assert_true.call(s_aly.players[1].alley_cnt == 0, "Period transition resets plyr_alley_cnt back to 0")

	# Test 24: On-Fire ball-carrier drone hunts 3-pointers (DRONE.ASM:725-727)
	var s_fire3 = MatchState.new()
	s_fire3.start(0, 1)
	s_fire3.tipoff = {}
	s_fire3.freeze = 0.0
	s_fire3.owner = 0
	s_fire3.fire_player = 0
	s_fire3.players[0].pos = s_fire3.hoop_for(0) + Vector2(-330, 0) # Outside 3pt arc (300px), within 375px
	var fire3_cmd = s_fire3.ai(0)
	assert_true.call(fire3_cmd.shoot == true, "On-Fire ball-carrier drone immediately pulls up for 3-pointers in range")

	# Test 25: ASM Coordinate Proportions & Dunk Restrictions (WORLD.EQU / PLYR.ASM:4679-4749)
	var s_dim = MatchState.new()
	s_dim.start(1, 0) # LAX (player 0 = HOLLYWOOD, dunk=7, power=5) vs CHI (player 3 = BRICK, def=10)
	s_dim.tipoff = {}
	s_dim.freeze = 0.0
	s_dim.owner = 0
	s_dim.players[0].turbo = 1.0
	s_dim.players[0].drive = 0.5
	s_dim.players[0].vel = Vector2(120, 0)
	s_dim.players[2].pos = Vector2(200, 200)
	s_dim.players[3].pos = Vector2(200, 600)
	# Normal in-bounds dunk position (center court Y, 100px from right hoop)
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x - 100.0, MatchState.HOOPS[1].y)
	assert_true.call(s_dim.finish_kind(0, true, false) == "turbo_dunk", "Dunk succeeds in open lane within scaled TAKEDUNK_T range")
	# Sideline restriction: within 36px of top/bottom court boundary (CZMIN+34 / CZMAX-34, PLYR.ASM:4745-4749)
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x - 80.0, MatchState.COURT.position.y + 20.0)
	assert_true.call(s_dim.finish_kind(0, true, false) == "jumper", "Dunk is disallowed within 36px (CZMIN+34) of the sideline")
	# Behind-the-hoop restriction: past HOOPLX/HOOPRX along baseline (PLYR.ASM:4679-4700)
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x + 15.0, MatchState.HOOPS[1].y - 50.0)
	assert_true.call(s_dim.finish_kind(0, true, false) == "jumper", "Dunk is disallowed from behind the hoop along baseline")
	# Polar angle dunk cone (#width_t in 128-step circle, PLYR.ASM:4936-4945)
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x - 100.0, MatchState.HOOPS[1].y)
	s_dim.players[3].pos = Vector2(MatchState.HOOPS[1].x - 50.0, MatchState.HOOPS[1].y)
	var saw_layup_bailout = false
	for trial in range(50):
		s_dim.rng.seed = trial * 17 + 5
		if s_dim.finish_kind(0, true, false) == "layup":
			saw_layup_bailout = true
			break
	assert_true.call(saw_layup_bailout, "Defender inside scaled DEF_DIST_T and polar DEF_WIDTH_T cone triggers layup bailout")

	# Test 26: Authentic Drone AI Skill Heat Boost (DRONE.ASM:2145-2156)
	var s_dheat = MatchState.new()
	s_dheat.start(0, 1)
	s_dheat.difficulty = 1 # Normal difficulty
	var base_idx = s_dheat.drone_skill_index(0)
	# When teammate heats up, drone gains authentic +2 skill boost
	s_dheat.player_streak[1] = 2
	s_dheat.refresh_heat_summary()
	var team_hot_idx = s_dheat.drone_skill_index(0)
	assert_true.call(team_hot_idx == base_idx + 2, "Drone gains +2 skill index when teammate heats up (DRONE.ASM:2148)")
	# When this drone itself heats up or is on fire, drone gains authentic +8 skill boost
	s_dheat.player_streak[0] = 2
	var self_hot_idx = s_dheat.drone_skill_index(0)
	assert_true.call(self_hot_idx == base_idx + 8, "Drone gains +8 skill index when player itself heats up or is on fire (DRONE.ASM:2155)")

	print("\n--- RESULTS: %d checks, %d failures ---" % [results.checks, results.failures])
	if results.failures == 0:
		print("ALL PASS 5 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
	else:
		printerr("TEST FAILURES OCCURRED!")
		quit(1)
