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
	var mid_open = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(mid_open.percentage >= 45.0 and mid_open.percentage <= 80.0, "wide open mid-range jumper has balanced arcade percentage: %.1f%%" % mid_open.percentage)
	check(mid_open.quality == "PERFECT", "release charge at 0.58s is evaluated as PERFECT quality")
	
	var dunk_pct = s.calculate_shot_percentage(0, 0.58, true, false, false)
	check(dunk_pct.percentage >= 80.0, "uncontested dunk has high base percentage: %.1f%%" % dunk_pct.percentage)
	
	var super_dunk_pct = s.calculate_shot_percentage(0, 0.58, true, false, true)
	check(super_dunk_pct.percentage >= 90.0, "specialty super dunk has elite base percentage: %.1f%%" % super_dunk_pct.percentage)
	
	# 2. Gaussian Release Timing Curve
	var perfect = s.calculate_shot_percentage(0, 0.58, false, false, false)
	var early = s.calculate_shot_percentage(0, 0.25, false, false, false)
	var late = s.calculate_shot_percentage(0, 0.88, false, false, false)
	check(perfect.timing > early.timing and perfect.timing > late.timing, "peak 0.58s timing beats early and late releases")
	check(perfect.percentage > early.percentage and perfect.percentage > late.percentage, "perfect release grants higher shot percentage than mistimed releases")
	check(early.quality == "EARLY" and late.quality == "LATE", "timing feedback correctly labels early vs late releases")
	
	# 3. 3D Spatial Defensive Contest Cone
	s = fresh()
	s.players[0].pos = Vector2(800, 465)
	var open_at_spot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	# Defender 2 positioned directly in front of shooter (between shooter and hoop at 1115)
	s.players[2].pos = Vector2(870, 465)
	var in_front = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(in_front.contest_level > 0.40, "defender between shooter and hoop produces substantial contest: %.2f" % in_front.contest_level)
	check(in_front.percentage < open_at_spot.percentage, "in-front contest significantly reduces shot percentage")
	
	# Defender 2 moved behind shooter (facing away / beaten)
	s.players[2].pos = Vector2(730, 465)
	var behind = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(behind.contest_level == 0.0, "defender behind shooter cannot contest the shot")
	check(behind.percentage == open_at_spot.percentage, "uncontested shot from behind has zero defensive penalty")
	
	# Jumping defender vs grounded defender
	s.players[2].pos = Vector2(870, 465)
	s.players[2].jump = 0.50
	var jumping_contest = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(jumping_contest.contest_level > in_front.contest_level, "airborne jumping defender creates stronger contest than grounded defender")
	check(jumping_contest.percentage < in_front.percentage, "jumping contest further depresses shot percentage")
	
	# Stunned defender cannot contest
	s.players[2].jump = 0.0
	s.players[2].stun = 0.60
	var stunned_contest = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(stunned_contest.contest_level == 0.0, "stunned defender cannot contest shots")
	
	# 4. Ballistic Rim Aperture & Distance Attenuation
	s = fresh()
	s.players[0].pos = hoop + Vector2(-180, 0) # Close 180 units
	var close_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	s.players[0].pos = hoop + Vector2(-550, 0) # Long 550 units
	var deep_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(close_shot.percentage > deep_shot.percentage, "close shots have higher probability than deep perimeter attempts: %.1f%% vs %.1f%%" % [close_shot.percentage, deep_shot.percentage])
	check(deep_shot.dist_penalty > close_shot.dist_penalty, "distance attenuation increases continuously with range")
	
	# 5. Dynamic Rubber-Banding (Arcade Catch-Up Logic)
	s = fresh()
	s.players[0].pos = hoop + Vector2(-250, 0)
	# Tied game
	s.score = [10, 10]
	var tied_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	# Trailing by 14 points
	s.score = [10, 24]
	var trailing_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(trailing_shot.rubber_band > 0.0, "trailing team receives positive catch-up rubber-band factor: +%.3f" % trailing_shot.rubber_band)
	check(trailing_shot.percentage > tied_shot.percentage, "trailing team shot percentage is boosted by rubber-banding")
	# Leading by 14 points
	s.score = [24, 10]
	var leading_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(leading_shot.rubber_band < 0.0, "leading team receives negative handicap rubber-band factor: %.3f" % leading_shot.rubber_band)
	check(leading_shot.percentage < tied_shot.percentage, "leading team faces subtle arcade resistance")
	
	# 6. Streak & On-Fire Multipliers
	s = fresh()
	s.players[0].pos = hoop + Vector2(-250, 0)
	s.score = [0, 0]
	var base_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	s.player_streak[0] = 2 # Heating up
	var heating_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(heating_shot.fire_bonus > 0.0 and heating_shot.percentage > base_shot.percentage, "heating up streak awards bonus shot accuracy")
	s.player_streak[0] = 3
	s.fire_player = 0 # On fire
	var fire_shot = s.calculate_shot_percentage(0, 0.58, false, false, false)
	check(fire_shot.percentage >= 82.0, "on-fire athlete receives massive accuracy boost: %.1f%%" % fire_shot.percentage)
	
	# 7. True 3-Point Boundary Geometry
	s = fresh()
	# Mid-range: distance 200
	check(not s.is_three_pointer(hoop + Vector2(-200, 0), hoop), "200 units from hoop is a 2-pointer")
	# Top of key: distance 310
	check(s.is_three_pointer(hoop + Vector2(-310, 0), hoop), "310 units at top of arc is a 3-pointer")
	# Corner 3: dy = 160, dx = 265
	var corner_pos = Vector2(hoop.x - 265, hoop.y - 160)
	check(s.is_three_pointer(corner_pos, hoop), "baseline corner position (dx=265, dy=160) is accurately recognized as 3-pointer")
	
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
	
	print("SHOT PERCENTAGE TESTS: %d checks, %s" % [checks, "PASS" if failures == 0 else "FAIL (%d errors)" % failures])
	quit(0 if failures == 0 else 1)
