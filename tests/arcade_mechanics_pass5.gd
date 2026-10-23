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
	# Frontcourt, moving backward away from the hoop. Past midcourt is not a shot.
	s_fade.players[0].pos = hoop_f + Vector2(-250, 40)
	var toward_hoop = (hoop_f - s_fade.players[0].pos).normalized()
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
	s_off.players[2].pos = Vector2(440, 465) # 40px away, inside the 50-unit push reach
	s_off.players[2].stun = 0.0
	s_off.players[1].cooldown = 0.0
	s_off.players[1].turbo = 1.0
	s_off.players[1].face = 1
	s_off.maximum_power = true
	var cmd_guarded = {}
	var found_push = false
	for trial in range(300):
		s_off.rng.seed = trial + 1
		var cmd = s_off.ai(1)
		if cmd.pass == true and cmd.turbo == true:
			cmd_guarded = cmd
			found_push = true
			break
	assert_true.call(found_push, "Off-ball player pushes a defender in front when the #p_t roll hits")

	# TE resolves contact halfway through the 24-tick shove animation.
	var prev_def_x = s_off.players[2].pos.x
	s_off.tick(0.016, {0: {}, 1: cmd_guarded, 2: {}, 3: {}})
	for _step in range(15):
		s_off.tick(0.016, {0: {}, 1: {}, 2: {}, 3: {}})
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
	s_def.players[2].nasty_timer = 1.0 # TE nasty mode always reaches the steal/push decision
	s_def.maximum_power = true
	var found_shove_owner = false
	for _i in range(40):
		s_def.players[2].drone_seek = 0
		var cmd_close = s_def.ai(2)
		if cmd_close.get("shove", false):
			found_shove_owner = true
			s_def.players[2].pos = Vector2(530, 465)
			s_def.tick(0.016, {0: {}, 1: {}, 2: cmd_close, 3: {}})
			for _step in range(15):
				s_def.tick(0.016, {0: {}, 1: {}, 2: {}, 3: {}})
			break
	assert_true.call(found_shove_owner, "CPU defender attempts shove against the ball carrier")
	assert_true.call(s_def.players[0].stun > 0.0, "Ball carrier is stunned/knocked down by aggressive CPU shove")
	assert_true.call(s_def.owner == 0 or s_def.owner == -1, "CPU shove retains or loosens the ball instead of awarding it directly to the defender")

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
	s_team.maximum_power = true
	var shoved_teammate = false
	for trial in range(40):
		s_team.rng.seed = trial + 1
		var cmd_team = s_team.ai(3)
		if cmd_team.pass == true and cmd_team.turbo == true:
			shoved_teammate = true
			break
	assert_true.call(not shoved_teammate, "A defender does not shove an off-ball opponent who is far from the ball")

	# drone_defence waits #skt_t between push/steal rolls, and closing-out turbo stays a steal.
	s_def.flight = {}
	s_def.owner = 0
	s_def.ball = Vector2(500, 465)
	s_def.players[0].pos = Vector2(500, 465)
	s_def.players[0].stun = 0.0
	s_def.players[2].pos = Vector2(530, 465)
	s_def.players[2].nasty_timer = 1.0
	s_def.players[2].drone_seek = 10
	s_def.players[2].turbo = 1.0
	s_def.players[2].cooldown = 0.0
	var held = s_def.ai(2)
	assert_true.call(not held.get("shove", false) and not held.pass and s_def.players[2].drone_seek == 9, "A defender waits out plyr_d_seekcnt before another push or steal")
	var saw_steal = false
	var saw_push = false
	for trial in range(80):
		s_def.rng.seed = 3000 + trial
		s_def.players[2].drone_seek = 0
		s_def.players[2].nasty_timer = 1.0
		s_def.players[2].turbo = 1.0
		s_def.players[2].turbo_burnout = 0.0
		s_def.players[2].cooldown = 0.0
		var cmd_split = s_def.ai(2)
		if cmd_split.pass and cmd_split.turbo and not cmd_split.get("shove", false):
			saw_steal = true
		if cmd_split.get("shove", false):
			saw_push = true
	assert_true.call(saw_steal and saw_push, "Closing-out turbo does not turn a defensive steal into a shove")

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

	# Test 12: Backcourt stalling penalty (PLYR.ASM:2188-2210)
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
	assert_true.call(stalled_speed < normal_speed * 0.90 and stalled_speed > normal_speed * 0.70, "Backcourt stall subtracts 0x3000 from acceleration once the shot clock leaves 10 (was %.1f vs %.1f)" % [stalled_speed, normal_speed])

	# Test 13: Weak 3-point shooter penalty (PLYR.ASM:5913-5915) & close jumper bonus (PLYR.ASM:5925-5927)
	var s_3pt = MatchState.new()
	s_3pt.start(0, 1)
	s_3pt.tipoff = {}
	s_3pt.freeze = 0.0
	for p_idx in range(4):
		s_3pt.players[p_idx].pos = Vector2(50, 50)
	var hoop_t1 = s_3pt.hoop_for(1) # HOOPS[0] = (165, 465)
	s_3pt.players[3].pos = hoop_t1 + Vector2(305, 0) # 3-pointer, shot rating 6 = SHT6 (1080)
	s_3pt.players[3].vel = Vector2.ZERO
	s_3pt.players[3].still_time = 1.0
	s_3pt.score = [5, 0]
	var weak_3 = s_3pt.calculate_shot_percentage(3, 0.58, false, false, false, false, false, false, false)
	s_3pt.players[3].pos = hoop_t1 + Vector2(295, 0) # 2-pointer just inside the arc
	var weak_2 = s_3pt.calculate_shot_percentage(3, 0.58, false, false, false, false, false, false, false)
	assert_true.call(MatchState.SHT_PERMILLE[3] <= 1025 and MatchState.SHT_PERMILLE[4] > 1025, "3pt -200 applies only while PAT_SHOTSKILL <= 1025 (SHT0-SHT3)")
	assert_true.call(weak_2.chance - weak_3.chance < 0.05, "SHT6 (1080) is above 1025, so a 3 loses distance only, not 200")

	# Test 14: Quarter transition refills all players' turbo to 100% (SCORE.ASM:1825-1832)
	var s_qtr = MatchState.new()
	s_qtr.start(0, 1)
	s_qtr.tipoff = {}
	s_qtr.players[0].turbo = 0.2
	s_qtr.players[0].turbo_burnout = 0.5
	s_qtr.next_period()
	assert_true.call(is_equal_approx(s_qtr.players[0].turbo, 1.0) and is_equal_approx(s_qtr.players[0].turbo_burnout, 0.0), "Period transition refills all players' turbo meters and clears burnout")

	# Test 15: Consecutive spin within 2.0s grants reduced 0.16s (10-tick) steal immunity (PLYR.ASM:2424-2436)
	var s_cspin = MatchState.new()
	s_cspin.start(0, 1)
	s_cspin.tipoff = {}
	s_cspin.freeze = 0.0
	s_cspin.inbounding_team = -1
	s_cspin.owner = 0
	s_cspin.players[0].pos = Vector2(500, 450)
	s_cspin.players[0].turbo = 1.0
	s_cspin.tick(0.016, {0: {"move": Vector2.RIGHT, "turbo": true, "spin": true}})
	assert_true.call(s_cspin.players[0].steal_immune > 0.90, "First spin move grants 1.0s (60-tick) steal immunity")
	# Advance past spin animation (0.45s) while still inside 2.0s spin_cooldown window
	s_cspin.players[0].spin = 0.0
	s_cspin.players[0].cooldown = 0.0
	s_cspin.players[0].turbo = 1.0
	s_cspin.tick(0.016, {0: {"move": Vector2.RIGHT, "turbo": true, "spin": true}})
	assert_true.call(s_cspin.players[0].spin > 0.35 and s_cspin.players[0].steal_immune > 0.90, "ELBO2 grants 60 ticks of steal immunity on every elbow, including a repeat")

	# Test 16: Standing elbow clearout grants 2.33s (140-tick) steal immunity (PLYR2.ASM:4162-4165)
	var s_elbo = MatchState.new()
	s_elbo.start(0, 1)
	s_elbo.tipoff = {}
	s_elbo.freeze = 0.0
	s_elbo.inbounding_team = -1
	s_elbo.owner = 0
	s_elbo.players[0].pos = Vector2(500, 450)
	s_elbo.players[2].pos = Vector2(530, 440)
	s_elbo.players[3].pos = Vector2(530, 460)
	s_elbo.players[0].turbo = 1.0
	s_elbo.tick(0.016, {0: {"move": Vector2.ZERO, "spin": true}, 1: {}, 2: {}, 3: {}})
	assert_true.call(s_elbo.players[0].elbow > 0.35 and s_elbo.players[0].steal_immune > 2.0, "Standing ELBO grants 140 ticks of steal immunity and does not spend turbo")
	assert_true.call(is_equal_approx(s_elbo.players[0].turbo, 1.0), "Standing ELBO has no turbo cost")
	assert_true.call((s_elbo.players[2].stun > 0.0) == (s_elbo.players[3].stun > 0.0), "TE elbow's shared HCOUNT roll hits both nearby opponents or neither")

	# Test: Spin move and elbow without enough turbo triggers turbo_flash and NEED TURBO announcement
	var s_noturbo = MatchState.new()
	s_noturbo.start(0, 1)
	s_noturbo.tipoff = {}
	s_noturbo.freeze = 0.0
	s_noturbo.inbounding_team = -1
	s_noturbo.owner = 0
	s_noturbo.players[0].pos = Vector2(500, 450)
	s_noturbo.players[0].turbo = 0.10 # Below 0.14 threshold
	s_noturbo.tick(0.016, {0: {"move": Vector2.RIGHT, "turbo": true, "spin": true}})
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
	assert_true.call(s_noturbo_elbo.players[0].elbow > 0.35, "Standing ELBO still fires with an empty turbo meter")
	assert_true.call(s_noturbo_elbo.players[0].turbo_flash == 0.0, "Standing ELBO does not ask for turbo")

	# Test 17: Close banks are cancelled when anyone is on fire (PLYR.ASM #offbb).
	# Head-on and inside 100 asm units, so the shot is the close-bank path.
	var s_bank = MatchState.new()
	s_bank.start(0, 1)
	s_bank.tipoff = {}
	s_bank.freeze = 0.0
	s_bank.fire_player = 2 # Someone on court is on fire
	var banked_while_fire = false
	for trial in range(60):
		s_bank.rng.seed = trial * 37 + 11
		s_bank.owner = 0
		s_bank.players[0].pos = s_bank.hoop_for(0) + Vector2(-80, 0)
		s_bank.players[0].vel = Vector2.ZERO
		s_bank.shoot_ball(0, false)
		if s_bank.flight.get("bank_shot", false):
			banked_while_fire = true
			break
	assert_true.call(not banked_while_fire, "Bank shots are strictly suppressed when any player is on fire")

	# Test 18: Off-ball On-Fire drone spaces to 3-point arc instead of crowding rim (DRONE.ASM:981-984)
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

	# Test 19: Fast-break outlet spacing when teammate is much closer to rebound (DRONE.ASM:1880-1892)
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

	# Test 20: Contested airball roll & goaltending exemption (PLYR.ASM:6430-6488, PLYR2.ASM:2727-2730)
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
	var air_shot = s_air.snapshot()
	var air_blocked = false
	var air_goaltend = false
	for n in range(40):
		s_air.apply_snapshot(air_shot)
		s_air.rng.seed = 9000 + n
		s_air.players[2].pos = s_air.ball
		s_air.defend(2, false)
		air_blocked = air_blocked or s_air.flight.get("blocked", false)
		air_goaltend = air_goaltend or s_air.stats[2].goaltends > 0
	assert_true.call(air_blocked and not air_goaltend, "A descending airball that connects is a block, never a goaltend")

	# Test 21: Post-rebound ball retention and steal immunity (PLYR2.ASM:2832-2842)
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
	assert_true.call(s_reb_prot.owner == 0 and s_reb_prot.players[0].push_keep_ball > 1.0 and s_reb_prot.players[0].steal_immune == 0.0, "Securing a rebound grants 80-tick push protection without steal immunity")

	# Test 22: Per-period 3-alley-oop drone limit & reset on next_period (SCORE.ASM:1864-1873, DRONE.ASM:884-891)
	var s_aly = MatchState.new()
	s_aly.start(0, 1)
	s_aly.tipoff = {}
	s_aly.freeze = 0.0
	s_aly.owner = 0
	s_aly.players[1].pos = s_aly.hoop_for(0) + Vector2(-110, 0)
	s_aly.players[2].pos = Vector2(200, 200)
	s_aly.players[3].pos = Vector2(200, 600)
	s_aly.players[1].alley_cnt = 3 # Already completed 3 alley-oops this period
	var alley_jump = false
	for trial in range(100):
		s_aly.rng.seed = trial * 29 + 3
		s_aly.players[1].alley_cnt = 0
		if s_aly.ai(1).shoot:
			alley_jump = true
			break
	assert_true.call(not alley_jump, "Off-ball drones do not jump for lobs; TE has no alley-oop rate table")
	s_aly.next_period()
	assert_true.call(s_aly.players[1].alley_cnt == 0, "Period transition resets plyr_alley_cnt back to 0")

	# Test 23: On-Fire ball-carrier drone hunts 3-pointers (DRONE.ASM:725-727)
	var s_fire3 = MatchState.new()
	s_fire3.start(0, 1)
	s_fire3.tipoff = {}
	s_fire3.freeze = 0.0
	s_fire3.owner = 0
	s_fire3.fire_player = 0
	s_fire3.players[0].pos = s_fire3.hoop_for(0) + Vector2(-330, 0) # Outside 3pt arc (300px), within 375px
	var fire3_cmd = s_fire3.ai(0)
	assert_true.call(fire3_cmd.shoot == true, "On-Fire ball-carrier drone immediately pulls up for 3-pointers in range")

	# Test 24: ASM Coordinate Proportions & Dunk Restrictions (WORLD.EQU / PLYR.ASM:4679-4749)
	var s_dim = MatchState.new()
	s_dim.start(1, 0) # LAX (player 0 = WANG, dunk=7, power=5) vs CHI (player 3 = GAUCI, def=10)
	s_dim.tipoff = {}
	s_dim.freeze = 0.0
	s_dim.owner = 0
	s_dim.players[0].turbo = 1.0
	s_dim.players[0].drive = 0.5
	s_dim.players[0].vel = Vector2(120, 0)
	s_dim.players[2].pos = Vector2(200, 200)
	s_dim.players[3].pos = Vector2(200, 600)
	# 160px is inside the 170-unit dunk window and past the 80-unit turbo line.
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x - 160.0, MatchState.HOOPS[1].y)
	s_dim.players[0].vel = Vector2(200, 0)
	assert_true.call(s_dim.finish_kind(0, true, false) == "turbo_dunk", "Turbo dunk succeeds in an open lane inside 170 ASM units")
	# No sideline ban: the same window near the sideline still dunks when facing the hoop.
	var side_pos = Vector2(MatchState.HOOPS[1].x - 150.0, MatchState.COURT.position.y + 30.0)
	s_dim.players[0].pos = side_pos
	s_dim.players[0].vel = (MatchState.HOOPS[1] - side_pos).normalized() * 200.0
	assert_true.call(s_dim.finish_kind(0, true, false) == "turbo_dunk", "A facing turbo drive near the sideline can still dunk")
	# Straight behind the right hoop is a jump shot even with turbo and speed.
	var behind_pos = Vector2(MatchState.HOOPS[1].x + 40.0, MatchState.HOOPS[1].y)
	s_dim.players[0].pos = behind_pos
	s_dim.players[0].vel = Vector2(-200, 0)
	assert_true.call(s_dim.finish_kind(0, true, false) == "jumper", "Dunk is disallowed from directly behind the hoop")
	# Polar angle dunk cone (#width_t in 128-step circle, PLYR.ASM:4936-4945)
	s_dim.players[0].pos = Vector2(MatchState.HOOPS[1].x - 100.0, MatchState.HOOPS[1].y)
	s_dim.players[0].vel = Vector2(200, 0)
	s_dim.players[3].pos = Vector2(MatchState.HOOPS[1].x - 50.0, MatchState.HOOPS[1].y)
	var saw_layup_bailout = false
	for trial in range(50):
		s_dim.rng.seed = trial * 17 + 5
		if s_dim.finish_kind(0, true, false) == "layup":
			saw_layup_bailout = true
			break
	assert_true.call(saw_layup_bailout, "Defender inside scaled DEF_DIST_T and polar DEF_WIDTH_T cone triggers layup bailout")

	# Test 25: Authentic Drone AI Skill Heat Boost (DRONE.ASM:2145-2156)
	var s_dheat = MatchState.new()
	s_dheat.start(0, 1)
	s_dheat.difficulty = 1 # Normal difficulty
	var base_idx = s_dheat.drone_skill_index(0)
	# When teammate heats up, drone gains authentic +2 skill boost
	s_dheat.player_streak[1] = 2
	s_dheat.refresh_heat_summary()
	var team_hot_idx = s_dheat.drone_skill_index(0)
	assert_true.call(team_hot_idx == base_idx, "Heating up does not change drone_getcurskillo")
	s_dheat.player_streak[0] = 2
	s_dheat.fire_player = 0
	var self_hot_idx = s_dheat.drone_skill_index(0)
	assert_true.call(self_hot_idx == base_idx, "On-fire does not add a drone skill index")

	# Test 26: A flyback shove interrupts a dunk the dunker still holds (PLYR.ASM:1137, PLYR2.ASM:4576)
	var stage_dunk = func(keep_ball: bool) -> MatchState:
		var dunk = MatchState.new()
		dunk.start(0, 1)
		dunk.tipoff = {}
		dunk.phase = "playing"
		dunk.freeze = 0.0
		dunk.maximum_power = true
		dunk.owner = -1
		dunk.score = [0, 0]
		dunk.players[2].pos = Vector2(500, 400)
		dunk.players[2].face = -1
		dunk.players[0].pos = Vector2(450, 400)
		dunk.players[0].jump = 0.70
		dunk.players[0].push_keep_ball = 2.0 if keep_ball else 0.0
		dunk.stats[0].attempts = 1
		dunk.player_streak[0] = 2
		dunk.flight = {
			"kind": "shot", "start": Vector2(400, 400), "end": dunk.hoop_for(0),
			"time": 0.20, "duration": 1.15, "shooter": 0, "points": 2,
			"made": true, "dunk": true, "blocked": false, "super_dunk": false
		}
		return dunk

	var s_keep = stage_dunk.call(true)
	var keep_score = s_keep.score[0]
	s_keep.resolve_steal(2, true)
	assert_true.call(s_keep.flight.is_empty(), "Flyback shove before seq_slamball clears the dunk flight")
	assert_true.call(s_keep.owner == 0, "Keeping the ball on a shoved dunk restores possession (FLYBACKWB)")
	assert_true.call(s_keep.players[0].shove_kind == "flyback", "A dunk shove uses the full flyback, never the short stagger")
	assert_true.call(s_keep.score[0] == keep_score and s_keep.stats[0].dunks == 0, "Interrupted dunk does not score")
	assert_true.call(s_keep.stats[0].attempts == 1, "The dunk attempt counted at takeoff is kept")
	assert_true.call(s_keep.stats[2].steals == 1, "Shoving a dunker credits the push-steal")
	assert_true.call(s_keep.player_streak[0] == 2 and s_keep.brick_count[0] == 0, "A kept dunk is not a rim miss")
	assert_true.call(s_keep.banner.contains("KEEPS THE BALL"), "Kept dunk announces the carrier still has the ball")
	s_keep.tick_flight(1.0)
	assert_true.call(s_keep.score[0] == keep_score, "A cleared dunk cannot score on a later flight tick")

	var lost_dunk = false
	var lost_seed = -1
	for seed in range(1, 40):
		var s_lose = stage_dunk.call(false)
		s_lose.rng.seed = seed
		s_lose.resolve_steal(2, true)
		if s_lose.flight.get("kind", "") == "loose" and s_lose.owner == -1:
			lost_dunk = true
			lost_seed = seed
			assert_true.call(s_lose.score[0] == 0 and s_lose.stats[0].dunks == 0, "A dunk knocked loose does not score")
			assert_true.call(s_lose.stats[0].turnovers == 1, "Losing the ball on a dunk shove is a turnover")
			assert_true.call(s_lose.stats[0].attempts == 1, "A loose dunk still counts the takeoff attempt")
			assert_true.call(s_lose.banner.contains("LOOSE BALL"), "Lost dunk announces a loose ball")
			break
	assert_true.call(lost_dunk, "Keep-ball failure during a dunk becomes a loose ball (seed %d)" % lost_seed)

	var s_high = stage_dunk.call(true)
	s_high.flight.time = 0.95
	s_high.players[2].jump = 0.0
	s_high.resolve_steal(2, true)
	assert_true.call(s_high.players[0].stun == 0.0 and s_high.flight.get("dunk", false), "A grounded shove misses a dunker more than 84px above (PLYR2.ASM:4963)")

	var s_reach = stage_dunk.call(true)
	s_reach.flight.time = 0.70
	s_reach.players[2].jump = 0.35
	s_reach.resolve_steal(2, true)
	assert_true.call(s_reach.flight.is_empty() and s_reach.owner == 0, "A jumping defender who can reach the dunker still breaks up the dunk")

	var s_slam = stage_dunk.call(true)
	s_slam.flight.time = s_slam.flight.duration
	s_slam.players[2].jump = 0.35
	s_slam.resolve_steal(2, true)
	assert_true.call(s_slam.flight.get("kind", "") == "shot" and s_slam.flight.get("dunk", false), "A shove after seq_slamball leaves the released dunk in the rim")
	s_slam.flight.time = s_slam.flight.duration
	s_slam.tick_flight(0.016)
	assert_true.call(s_slam.score[0] == 2, "A dunk already through the rim still scores after a late shove")

	var s_lay = stage_dunk.call(false)
	s_lay.flight.dunk = false
	s_lay.flight.layup = true
	s_lay.players[0].jump = 0.0
	s_lay.rng.seed = 1
	s_lay.resolve_steal(2, true)
	assert_true.call(s_lay.flight.get("kind", "") == "shot" and s_lay.flight.get("layup", false), "A released layup is not cancelled by the dunk-interrupt path")

	# Test 27: Contact tables match PLYR2.ASM
	assert_true.call(is_equal_approx(MatchState.STL1[10], 0.300) and is_equal_approx(MatchState.STL1[0], 0.160), "stl1 runs from 160 to 300 per thousand")
	assert_true.call(is_equal_approx(MatchState.STL2[9], 0.235) and is_equal_approx(MatchState.STL2[10], 0.250), "stl2 keeps the 235 then 250 clean-steal entries")
	assert_true.call(MatchState.INT_T[1] == 4 and MatchState.INT_T[15] == 30, "Intercept bonus table matches #int_t")
	assert_true.call(MatchState.TAKEDUNK_T[10] == 0 and MatchState.TAKEDUNK_T[11] == 50 and MatchState.TAKEDUNK_T[20] == 999, "takedunk_t is zero through equal power, then climbs")

	var s_apex = MatchState.new()
	s_apex.start(0, 1)
	s_apex.tipoff = {}
	s_apex.maximum_power = true
	s_apex.players[2].pos = Vector2(500, 400)
	s_apex.players[2].face = -1
	s_apex.players[2].jump = 0.0
	s_apex.players[0].pos = Vector2(450, 400)
	s_apex.players[0].jump = 0.28
	s_apex.resolve_steal(2, true)
	assert_true.call(s_apex.players[0].stun == 0.0, "A grounded shove misses a player at the top of a jump")

	var s_strip = MatchState.new()
	s_strip.start(5, 2) # DIESEL power 10 vs GHOST power 4
	s_strip.tipoff = {}
	s_strip.phase = "playing"
	s_strip.freeze = 0.0
	var hoop_s = s_strip.hoop_for(0)
	s_strip.flight = {
		"kind": "shot", "start": hoop_s + Vector2(-40, 0), "end": hoop_s,
		"time": 0.20, "duration": 1.15, "shooter": 0, "points": 2,
		"made": true, "dunk": true, "blocked": false, "release_height": 1.3, "arc_height": 1.6
	}
	s_strip.ball = s_strip.flight_position()
	s_strip.players[2].pos = s_strip.ball
	var saw_resist = false
	var saw_strip = false
	for seed in range(1, 40):
		s_strip.rng.seed = seed
		s_strip.flight.blocked = false
		s_strip.flight.made = true
		s_strip.stats[2].blocks = 0
		s_strip.defend(2, false)
		if s_strip.flight.blocked:
			saw_strip = true
		else:
			saw_resist = true
	assert_true.call(saw_resist and saw_strip, "A much stronger dunker sometimes keeps the ball through a block (takedunk_t)")

	var s_even = MatchState.new()
	s_even.start(0, 1)
	s_even.maximum_power = true
	s_even.rng.seed = 3
	var even_resisted = false
	for _n in range(30):
		if s_even.dunk_strip_resisted(2, 0):
			even_resisted = true
	assert_true.call(not even_resisted, "A stronger or equal stripper is not resisted by takedunk_t")

	print("\n--- RESULTS: %d checks, %d failures ---" % [results.checks, results.failures])
	if results.failures == 0:
		print("ALL PASS 5 ARCADE MECHANIC TESTS PASSED!")
		quit(0)
	else:
		printerr("TEST FAILURES OCCURRED!")
		quit(1)
