extends SceneTree

var failures = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = MatchState.new()
	state.start(0, 1, 10.0) # 10s quarters for testing
	state.freeze = 0.0
	state.inbounding_team = -1
	state.tipoff = {}
	
	# Score some points in Q1
	state.score[0] = 6
	state.score[1] = 4
	state.players[0].turbo = 0.35
	state.players[1].turbo = 0.20
	state.players[2].turbo = 0.50
	state.players[3].turbo = 0.10
	
	# Fast-forward clock to 0
	state.clock = 0.05
	state.flight = {}
	state.tick(0.1, {}) # Clock hits 0:00
	
	# 1. Whistle blown and transition triggered
	check(state.quarter_transition.get("active", false), "clock expiration triggers quarter_transition")
	check(state.event_kind == "whistle", "end of quarter blows the referee whistle")
	check(state.quarter_transition.banner == "END OF QUARTER 1", "first quarter sets END OF QUARTER 1 banner")
	check(state.quarter_scores.size() == 1 and state.quarter_scores[0] == [6, 4], "quarter scores table accurately records Q1 points [6, 4]")
	
	# 2. Phase 1: Score display and recovery pause (fade_alpha == 0.0)
	var dur: float = state.quarter_transition.duration
	state.tick(dur * 0.25, {})
	check(state.quarter_transition.fade_alpha == 0.0, "screen remains clear during score display and recovery pause")
	check(state.players[0].vel == Vector2.ZERO and state.players[1].vel == Vector2.ZERO, "players are halted to rest and recover during intermission")
	
	# 3. Snapshot preservation during transition
	var snap = state.snapshot()
	var restored = MatchState.new()
	restored.apply_snapshot(snap)
	check(restored.quarter_transition.get("active", false) and restored.quarter_scores.size() == 1, "snapshots preserve quarter transition state and score table")
	
	# 4. Phase 2: Fade out to black (fade_alpha rises toward 1.0)
	state.tick(dur * 0.45, {}) # Reaches ~0.70 normalized duration
	check(state.quarter_transition.fade_alpha > 0.3, "screen fades smoothly toward black before quarter switch")
	
	# 5. Midpoint: Quarter advances, turbo refilled, in black screen
	state.tick(dur * 0.15, {}) # Reaches ~0.85 normalized duration (past midpoint)
	check(state.quarter == 2, "quarter increments to 2 at black screen midpoint")
	check(is_equal_approx(state.players[0].turbo, 1.0) and is_equal_approx(state.players[1].turbo, 1.0), "all players receive 100% turbo refill during quarter intermission")
	check(state.clock == 10.0, "clock resets to period length for next quarter")
	
	# 6. Phase 3: Fade back in to next quarter (fade_alpha decreases)
	check(state.quarter_transition.fade_alpha < 0.8, "screen fades smoothly back in from black")
	state.tick(dur * 0.20, {}) # Reaches completion
	check(not state.quarter_transition.get("active", false), "quarter transition completes and clears active flag")
	
	# 7. Test Halftime (Q2 -> Q3) End Switching
	state.score[0] = 14
	state.score[1] = 12
	state.freeze = 0.0
	state.inbounding_team = -1
	state.clock = 0.01
	state.flight = {}
	state.tick(0.05, {}) # Q2 ends
	check(state.quarter_transition.get("active", false), "Q2 expiration triggers halftime transition")
	check(state.quarter_transition.banner == "HALFTIME • SWITCH ENDS", "Q2 sets HALFTIME banner")
	check(state.quarter_scores.size() == 2 and state.quarter_scores[1] == [8, 8], "quarter scores table accurately records Q2 delta [8, 8]")
	
	# Advance through halftime midpoint
	state.tick(state.quarter_transition.duration * 0.85, {})
	check(state.quarter == 3, "quarter advances to 3 at halftime")
	check(state.hoop_for(0).x < 640, "halftime switches court ends for both teams")
	state.tick(state.quarter_transition.duration * 0.20, {})
	check(not state.quarter_transition.get("active", false), "halftime transition completes cleanly")
	
	# 8. Test Fourth Quarter Regulation Finish (Q4 -> Final)
	state.quarter = 4
	state.score[0] = 30
	state.score[1] = 26
	state.freeze = 0.0
	state.inbounding_team = -1
	state.clock = 0.01
	state.flight = {}
	state.tick(0.05, {}) # Q4 regulation buzzer sounds
	check(state.quarter_transition.get("active", false), "Q4 expiration triggers final quarter transition")
	check(state.quarter_transition.banner == "FINAL", "Q4 regulation finish sets FINAL banner")
	check(state.phase == "finished", "state phase is marked finished immediately for test assertions")
	check(state.quarter_transition.is_final, "quarter transition marks is_final true")
	state.tick(state.quarter_transition.duration * 1.1, {})
	check(not state.quarter_transition.get("active", false), "final quarter transition completes")
	check(state.phase == "finished", "state phase remains finished after final transition completes")
	
	print("QUARTER TRANSITION TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
