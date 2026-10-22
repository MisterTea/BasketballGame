extends SceneTree

var checks = 0
var failures = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func open_seed(s: MatchState, shooter: int) -> int:
	for n in range(80):
		s.rng.seed = 4000 + n
		var probe = s.calculate_shot_percentage(shooter, 0.58, false, false, false)
		if probe.chance > 0.20:
			return 4000 + n
	return 4000

func fresh() -> MatchState:
	var s = MatchState.new()
	s.start(0, 1)
	s.inbound(0)
	s.freeze = 0
	s.rng.seed = 1993
	# Move non-active players far away to isolate tests
	for i in range(4):
		s.players[i].pos = Vector2(50, 50)
		s.players[i].stun = 0.0
		s.players[i].jump = 0.0
		s.players[i].swipe = 0.0
	return s

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Base Jump Shot & Dunk Probabilities
	var s = fresh()
	var hoop = s.hoop_for(0) # HOOPS[1] = (1115, 465)
	s.players[0].pos = hoop + Vector2(-220, 0)
	var mid_seed = open_seed(s, 0)
	s.rng.seed = mid_seed
	var mid_open = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(mid_open.percentage >= 75.0 and mid_open.percentage <= 95.0, "wide open mid-range jumper uses PAT_SHOTSKILL minus 2 per distance unit: %.1f%%" % mid_open.percentage)
	check(mid_open.quality == "PERFECT", "release charge at 0.58s is evaluated as PERFECT quality")
	
	s.rng.seed = mid_seed
	var dunk_pct = s.calculate_shot_percentage(0, 0.58, true, false, false)
	check(dunk_pct.percentage >= 80.0, "uncontested dunk has high base percentage: %.1f%%" % dunk_pct.percentage)
	
	s.rng.seed = mid_seed
	var super_dunk_pct = s.calculate_shot_percentage(0, 0.58, true, false, true)
	check(super_dunk_pct.percentage >= 90.0, "specialty super dunk has elite base percentage: %.1f%%" % super_dunk_pct.percentage)
	
	# 2. Gaussian Release Timing Curve
	s.rng.seed = mid_seed
	var perfect = s.calculate_shot_percentage(0, 0.58, false, false, false)
	s.rng.seed = mid_seed
	var early = s.calculate_shot_percentage(0, 0.25, false, false, false)
	s.rng.seed = mid_seed
	var late = s.calculate_shot_percentage(0, 0.88, false, false, false)
	check(perfect.timing > early.timing and perfect.timing > late.timing, "peak 0.58s timing beats early and late releases")
	check(perfect.percentage > early.percentage and perfect.percentage > late.percentage, "perfect release grants higher shot percentage than mistimed releases")
	check(early.quality == "EARLY" and late.quality == "LATE", "timing feedback correctly labels early vs late releases")
	
	# 3. 3D Spatial Defensive Contest Cone
	s = fresh()
	s.players[0].pos = Vector2(800, 465)
	var spot_seed = open_seed(s, 0)
	s.rng.seed = spot_seed
	var open_at_spot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	# Defender 2 positioned directly in front of shooter (between shooter and hoop at 1115)
	s.players[2].pos = Vector2(870, 465)
	s.rng.seed = spot_seed
	var in_front = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(in_front.contest_level > 0.15, "defender between shooter and hoop produces substantial contest: %.2f" % in_front.contest_level)
	check(in_front.percentage < open_at_spot.percentage, "in-front contest significantly reduces shot percentage")
	
	# Defender 2 moved behind shooter (outside the 40-unit omnidirectional range)
	s.players[2].pos = Vector2(730, 465)
	s.rng.seed = spot_seed
	var behind = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(behind.contest_level == 0.0, "defender behind shooter and outside 40 units does not contest")
	check(behind.percentage == open_at_spot.percentage, "uncontested shot from behind has zero defensive penalty")
	
	# Jumping defender vs grounded defender
	s.players[2].pos = Vector2(870, 465)
	s.players[2].jump = 0.50
	s.rng.seed = spot_seed
	var jumping_contest = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(jumping_contest.contest_level > in_front.contest_level, "defender above the shooter increases the lane penalty")
	check(jumping_contest.percentage < in_front.percentage, "jumping contest further depresses shot percentage")
	
	# plyr_shoot does not read stun; a body still in the lane still contests
	s.players[2].jump = 0.0
	s.players[2].stun = 0.60
	var stunned_contest = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(stunned_contest.contest_level, in_front.contest_level), "stunned defender still in the lane is contested by position")
	
	# 4. Ballistic Rim Aperture & Distance Attenuation
	s = fresh()
	s.players[0].pos = hoop + Vector2(-180, 0) # Close 180 units
	var range_seed = open_seed(s, 0)
	s.rng.seed = range_seed
	var close_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	s.players[0].pos = hoop + Vector2(-550, 0) # Long 550 units
	s.rng.seed = range_seed
	var deep_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(close_shot.percentage > deep_shot.percentage, "close shots have higher probability than deep perimeter attempts: %.1f%% vs %.1f%%" % [close_shot.percentage, deep_shot.percentage])
	check(deep_shot.dist_penalty > close_shot.dist_penalty, "distance attenuation increases continuously with range")
	
	# 5. Dynamic Rubber-Banding (Arcade Catch-Up Logic)
	s = fresh()
	s.players[0].pos = hoop + Vector2(-250, 0)
	var band_seed = open_seed(s, 0)
	# Tied game
	s.score = [10, 10]
	s.rng.seed = band_seed
	var tied_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	# Trailing by 14 points
	s.score = [10, 24]
	s.rng.seed = band_seed
	var trailing_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(trailing_shot.rubber_band, 0.28), "trailing team receives +2%% per point: +%.3f" % trailing_shot.rubber_band)
	check(trailing_shot.percentage > tied_shot.percentage, "trailing team shot percentage is boosted by rubber-banding")
	# Leading by 14 points
	s.score = [24, 10]
	s.rng.seed = band_seed
	var leading_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(leading_shot.rubber_band < 0.0, "leading team receives negative handicap rubber-band factor: %.3f" % leading_shot.rubber_band)
	check(leading_shot.percentage < tied_shot.percentage, "leading team faces subtle arcade resistance")
	
	# 6. Streak & On-Fire Multipliers
	s = fresh()
	s.players[0].pos = hoop + Vector2(-250, 0)
	s.score = [0, 0]
	var heat_seed = open_seed(s, 0)
	s.rng.seed = heat_seed
	var base_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	s.player_streak[0] = 2 # Heating up
	s.rng.seed = heat_seed
	var heating_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(heating_shot.fire_bonus == 0.0 and is_equal_approx(heating_shot.chance, base_shot.chance), "heating up does not change make percentage until on fire")
	s.player_streak[0] = 3
	s.fire_player = 0 # On fire
	s.rng.seed = heat_seed
	var fire_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(fire_shot.percentage >= 82.0, "on-fire athlete receives massive accuracy boost: %.1f%%" % fire_shot.percentage)
	
	# 7. True 3-Point Boundary Geometry
	s = fresh()
	check(not s.is_three_pointer(hoop + Vector2(-299, 0), hoop), "shot just inside the painted arc is a 2-pointer")
	check(not s.is_three_pointer(hoop + Vector2(-300, 0), hoop), "shot on the painted arc is a 2-pointer")
	check(s.is_three_pointer(hoop + Vector2(-301, 0), hoop), "shot just outside the painted arc is a 3-pointer")
	check(not s.is_three_pointer(hoop + Vector2(-20, -179), hoop), "side shot just inside the straight corner line is a 2-pointer")
	check(not s.is_three_pointer(hoop + Vector2(-20, -180), hoop), "side shot on the straight corner line is a 2-pointer")
	check(s.is_three_pointer(hoop + Vector2(-20, -181), hoop), "side shot just outside the straight corner line is a 3-pointer")
	for side in range(2):
		var geometry = MatchState.three_point_geometry(side)
		var side_hoop: Vector2 = geometry.hoop
		var direction = 1.0 if side == 0 else -1.0
		var join = Vector2(geometry.arc_join_x, geometry.top_y)
		check(is_equal_approx(join.distance_to(side_hoop), geometry.radius), "hoop %d painted arc joins its corner line at the shared scoring radius" % side)
		check(not s.is_three_pointer(join, side_hoop), "hoop %d arc/corner join is a 2-pointer on the line" % side)
		check(s.is_three_pointer(join + Vector2(-direction, -1), side_hoop), "hoop %d shot outside the arc/corner join is a 3-pointer" % side)
	
	# 8. Physics Rim Ricochet
	s = fresh()
	var shot_origin = Vector2(600, 465)
	for trial in range(30):
		var ricochet = s.calculate_rim_ricochet(shot_origin, hoop)
		check(MatchState.COURT.has_point(ricochet), "rim ricochet remains within court bounds: %s" % ricochet)
		check(ricochet.distance_to(hoop) > 15.0, "missed shot bounces off the rim to a reboundable distance")
	
	# 9. Real-time Shot Feedback & Snapshot Persistence
	s = fresh()
	s.players[0].pos = hoop + Vector2(-260, 0)
	s.players[0].charge = 0.58
	s.ball = s.players[0].pos
	s.shoot_ball(0, false)
	check(s.last_shot_feedback.size() > 0, "shooting populates last_shot_feedback dictionary")
	check(s.last_shot_feedback.shooter == 0 and s.last_shot_feedback.has("percentage"), "feedback contains shooter ID and percentage")
	
	var restored = MatchState.new()
	restored.apply_snapshot(s.snapshot())
	check(restored.last_shot_feedback.percentage == s.last_shot_feedback.percentage, "last_shot_feedback survives snapshot restoration")
	check(restored.last_shot_feedback.quality == s.last_shot_feedback.quality, "quality feedback survives snapshot restoration")
	
	# 10. Signature Dunk Pool, On-Fire Acrobatics & Defender Knockdown
	s = fresh()
	s.players[0].pos = hoop + Vector2(-120, 0)
	s.players[0].vel = Vector2(120, 0)
	s.players[0].drive = 0.35
	s.players[0].charge = 0.58
	s.players[0].turbo = 1.0
	s.players[2].pos = hoop + Vector2(-30, 0) # Defender under the rim
	s.ball = s.players[0].pos
	s.fire_player = 0 # On fire!
	s.shoot_ball(0, true) # Drives for a signature dunk
	check(s.flight.dunk and s.flight.get("super_dunk", false), "on-fire turbo drive executes a signature super dunk")
	check(s.flight.arc_height >= 4.0, "on-fire signature dunk elevates to spectacular jump height: %.2fm" % s.flight.arc_height)
	check(MatchState.SIGNATURE_DUNKS.has(s.flight.dunk_style), "dunk style selected from signature pool: %s" % s.flight.dunk_style)
	# Fast-forward dunk to basket completion
	s.flight.time = s.flight.duration
	s.tick_flight(0.01)
	check(s.players[2].stun == 0.0, "seq_slamball does not knock down a defender standing near the rim")
	
	# 11. Sound Effects Procedural Generation
	var main_scene = load("res://scripts/main.gd").new()
	main_scene.make_sounds()
	for snd in ["score", "dunk", "miss", "shatter", "buzzer", "fire", "cheer", "turbo", "whistle"]:
		check(main_scene.sounds.has(snd), "procedural sound generated: %s" % snd)
		var stream: AudioStreamWAV = main_scene.sounds[snd]
		check(stream.data.size() > 500 and stream.mix_rate == 22050, "sound %s contains valid 22.05kHz 16-bit PCM waveform" % snd)
	main_scene.free()

	# 12. Moving vs Still Shot Odds and Straight-Up Jump Physics
	s = fresh()
	s.players[0].pos = hoop + Vector2(-240, 0)
	s.players[0].vel = Vector2.ZERO
	s.players[0].still_time = 1.0
	var still_seed = open_seed(s, 0)
	s.rng.seed = still_seed
	var still_eval = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(not still_eval.moving_shot and still_eval.still_shot, "player standing still is evaluated as a still shot")
	check(still_eval.still_bonus == 0.0, "plyr_shoot does not add a standing-still make bonus")

	# Active moving shot
	s.players[0].vel = Vector2(100, 50)
	s.players[0].still_time = 0.0
	s.rng.seed = still_seed
	var moving_eval = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(moving_eval.moving_shot and not moving_eval.still_shot, "moving player is evaluated as a moving shot")
	check(moving_eval.moving_penalty == 0.0, "plyr_shoot does not apply a moving-shot make penalty")
	check(is_equal_approx(still_eval.chance, moving_eval.chance), "still and moving releases share the same PAT_SHOTSKILL percent")

	# 100ms window test: stopped 50ms ago (< 100ms) -> moving shot
	s = fresh()
	s.players[0].pos = hoop + Vector2(-240, 0)
	s.players[0].vel = Vector2.ZERO
	s.players[0].still_time = 0.05 # 50ms still
	var window_seed = open_seed(s, 0)
	s.rng.seed = window_seed
	var window_50ms = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(window_50ms.moving_shot, "player moving in the past 100ms (50ms ago) remains flagged as a moving shot")
	s.rng.seed = window_seed
	var window_still = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(window_50ms.chance, window_still.chance), "recent movement does not change the make percent")

	# 100ms window test: stopped 120ms ago (>= 100ms) -> still shot
	s.players[0].still_time = 0.12 # 120ms still
	s.rng.seed = window_seed
	var window_120ms = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(not window_120ms.moving_shot and window_120ms.still_shot, "player still for >= 100ms (120ms) is evaluated as a set still shot")
	check(is_equal_approx(window_120ms.chance, window_50ms.chance), "settling into a still shot keeps the same make percent")

	# Straight-up jump vs moving momentum in tick simulation
	s = fresh()
	s.owner = 0
	s.players[0].pos = hoop + Vector2(-220, 0)
	s.ball = s.players[0].pos
	s.players[0].still_time = 1.0 # Stays still before shooting
	# Charge shot while still
	s.tick(0.10, {0: {"move": Vector2.ZERO, "shoot": true}})
	check(s.players[0].vel == Vector2.ZERO, "player who stays still before shooting jumps straight up with zero horizontal velocity")
	check(not s.players[0].shot_is_moving, "shot initiated while still is marked as not moving")

	# Moving shot preserves horizontal momentum
	s = fresh()
	s.owner = 0
	s.players[0].pos = hoop + Vector2(-220, 0)
	s.ball = s.players[0].pos
	s.players[0].vel = Vector2(150, 0)
	s.players[0].still_time = 0.0
	s.tick(0.10, {0: {"move": Vector2.RIGHT, "shoot": true}})
	check(s.players[0].shot_is_moving, "shot initiated while moving is marked as moving shot")
	check(s.players[0].vel.length() > 50.0, "moving shot preserves momentum drift during jump")

	# 13. Post-Goal Inbound Transition (No Teleportation, Air Landing, 2x Running Speed)
	s = fresh()
	var hoop_goal = s.hoop_for(0)
	s.players[0].pos = hoop_goal + Vector2(-30, 0)
	s.players[0].jump = 0.50 # Shooter airborne
	s.players[2].pos = hoop_goal + Vector2(-50, 0)
	s.players[2].jump = 0.40 # Defender airborne contesting
	s.flight = {
		"kind": "shot", "start": hoop_goal + Vector2(-60, 0), "end": hoop_goal,
		"time": 1.0, "duration": 1.0, "shooter": 0, "points": 2,
		"made": true, "dunk": false, "blocked": false
	}
	var p0_pre_pos = s.players[0].pos
	var p2_pre_pos = s.players[2].pos
	s.tick_flight(0.016) # Goal scored
	check(s.inbound_transition.get("active", false), "scoring a goal starts the smooth inbound transition instead of teleporting")
	check(s.players[0].pos.distance_to(p0_pre_pos) < 5.0, "airborne shooter has not teleported across court")
	check(s.players[2].pos.distance_to(p2_pre_pos) < 5.0, "airborne defender has not teleported across court")

	# Tick transition: airborne players land safely
	var initial_jump = s.players[0].jump
	s.tick(0.05, {})
	check(s.players[0].jump < initial_jump, "airborne player lands towards the floor during transition")

	# Advance transition until landed: players run at 2x normal speed
	while s.players[2].jump > 0.0:
		s.tick(0.02, {})
	check(s.players[2].jump == 0.0, "players safely touch ground before running")
	var normal_speed = 125.0 + s.rating(2, 0) * 7.0
	s.tick(0.05, {})
	check(is_equal_approx(s.players[2].vel.length(), normal_speed * 2.0), "players move 2x as fast (%.1f px/s) to their assigned spots" % s.players[2].vel.length())

	# Fast forward transition until all players arrive at assigned spots
	var timeout = 0.0
	while s.inbound_transition.get("active", false) and timeout < 3.0:
		s.tick(0.05, {})
		timeout += 0.05
	check(not s.inbound_transition.get("active", false), "inbound transition completes cleanly")
	check(s.players[2].pos.x < MatchState.COURT.position.x or s.players[2].pos.x > MatchState.COURT.end.x, "inbounder reaches baseline assigned spot")

	# Tournament Edition plyr_shoot decision rules (deterministic branches)
	s = fresh()
	s.score = [0, 4]
	s.players[0].pos = hoop + Vector2(-160, 0)
	var lay = s.calculate_shot_percentage(0, 0.58, false, true, false)
	check(is_equal_approx(lay.chance, 0.87), "lay_perc is 870 while losing: %.3f" % lay.chance)
	s.fire_player = 0
	var lay_fire = s.calculate_shot_percentage(0, 0.58, false, true, false)
	check(is_equal_approx(lay_fire.chance, 0.87) and lay_fire.fire_bonus == 0.0, "on-fire does not change lay_perc")
	s.fire_player = -1
	s.score = [0, 0]
	var saw_lay_full = false
	var saw_lay_cut = false
	for n in range(80):
		s.rng.seed = 9000 + n
		var lay_tied = s.calculate_shot_percentage(0, 0.58, false, true, false)
		if is_equal_approx(lay_tied.chance, 0.87):
			saw_lay_full = true
		elif is_equal_approx(lay_tied.chance, 0.45):
			saw_lay_cut = true
	check(saw_lay_full and saw_lay_cut, "tied lay_perc stays 870 unless the 100/1000 knockdown drops it to 450")
	s.score = [0, 3]
	var saw_hook_full = false
	var saw_hook_cut = false
	for n in range(80):
		s.rng.seed = 9100 + n
		var hook_shot = s.calculate_shot_percentage(0, 0.58, false, false, false, false, true)
		if is_equal_approx(hook_shot.chance, 0.60):
			saw_hook_full = true
		elif is_equal_approx(hook_shot.chance, 0.25):
			saw_hook_cut = true
	check(saw_hook_full and saw_hook_cut, "hook percent is 600, or 250 on the 120/1000 knockdown")
	s.fire_player = 0
	s.players[0].pos = hoop + Vector2(-520, 0)
	var fire_heave = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(fire_heave.chance, 0.10), "on-fire jumper at >= 328 ASM units is forced to 100: %.3f" % fire_heave.chance)
	s.fire_player = -1
	s.brick_count[0] = 3
	s.score = [0, 2]
	s.players[0].pos = hoop + Vector2(-700, 0)
	var brick = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(brick.chance > 0.95, "three bricks force the next shot to 990 at any distance: %.3f" % brick.chance)
	s.brick_count[0] = 0
	s.quarter = 4
	s.clock = 3.0
	s.score = [8, 8]
	var q4_hoop = s.hoop_for(0)
	s.players[0].pos = q4_hoop + Vector2(220, 0)
	var tie_buzzer = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(tie_buzzer.chance, 0.05), "tied Q4 shot at <= 4.00s is forced to 50: %.3f" % tie_buzzer.chance)
	s.clock = 5.0
	var early_clock = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(early_clock.chance > 0.10, "the tied-game 5%% floor waits until game_time <= 0x400")
	s.clock = 3.0
	s.score = [0, 2]
	s.players[0].pos = q4_hoop + Vector2(280, 0)
	var tie_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(not tie_shot.three_pointer and is_equal_approx(tie_shot.chance, 0.80), "Q4 shot that ties is floored at 800: %.3f" % tie_shot.chance)
	s.score = [0, 1]
	s.players[0].pos = q4_hoop + Vector2(520, 0)
	var lead_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(lead_shot.three_pointer and is_equal_approx(lead_shot.chance, 0.38), "Q4 heave that would take the lead is floored at 380: %.3f" % lead_shot.chance)
	s.score = [10, 0]
	s.clock = 3.0
	var blowout = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(is_equal_approx(blowout.chance, 0.30), "winning by 5+ with 2-4s left floors a heave at 300: %.3f" % blowout.chance)
	s.quarter = 1
	s.score = [0, 3]
	s.players[0].pos = hoop + Vector2(-520, 0)
	var early_q = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(early_q.three_pointer and is_equal_approx(early_q.chance, 0.12), "Q1 3 that ties is floored at 120 after the ptsdown bump: %.3f" % early_q.chance)

	print("SHOT PERCENTAGE TESTS: %d checks, %s" % [checks, "PASS" if failures == 0 else "FAIL (%d errors)" % failures])
	quit(0 if failures == 0 else 1)
