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
	print("--- TESTING ANNOUNCER VOICE INTEGRATION ---")

	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	check(main.announcer_player != null, "Announcer AudioStreamPlayer exists on main scene")
	check(main.announcer_voices is Dictionary, "announcer_voices dictionary is initialized")
	check(main.announcer_voices.size() > 0, "announcer_voices loaded audio clips (count: %d)" % main.announcer_voices.size())

	# Test 1: Exact matches
	var exact_tests = [
		"TIP OFF!",
		"BOOMSHAKALAKA!",
		"FROM DOWNTOWN!",
		"SLAM DUNK!",
		"DOUBLE DUNK!",
		"REJECTED!"
	]
	for text in exact_tests:
		var stream = main.get_announcer_stream(text)
		check(stream != null, "Resolves exact announcement banner: '%s'" % text)

	# Test 2: Dynamic pattern matches
	var dynamic_tests = [
		"HE'S ON FIRE! HENNONHOEFER",
		"HE'S HEATING UP! WANG",
		"INFERNO WINS THE TIP!",
		"AFTERSHOCK WINS THE TIP!",
		"GOALTENDING! 2 POINTS",
		"GOALTENDING! 3 POINTS",
		"QUARTER 1",
		"QUARTER 2",
		"QUARTER 3",
		"QUARTER 4",
		"OVERTIME",
		"DOUBLE OVERTIME"
	]
	for banner in dynamic_tests:
		var stream = main.get_announcer_stream(banner)
		check(stream != null, "Resolves dynamic announcement '%s'" % banner)

	# Test 3: Playback test
	main.play_announcer("BOOMSHAKALAKA!")
	check(main.announcer_player.stream != null, "play_announcer sets stream on announcer_player")
	check(main.announcer_player.stream is AudioStreamWAV, "Stream is a valid AudioStreamWAV")

	# Test 4: Mute check
	main.muted = true
	var current_stream = main.announcer_player.stream
	main.play_announcer("AIRBALL!")
	check(main.announcer_player.stream == current_stream, "play_announcer respects muted flag")
	main.muted = false

	# Test 5: Game simulation state preservation contract
	var MatchStateClass = load("res://scripts/match_state.gd")
	var state = MatchStateClass.new()
	state.start(0, 1)
	var snap_before = state.snapshot()
	main.play_announcer(state.banner)
	var snap_after = state.snapshot()
	check(snap_before == snap_after, "Announcer playback never mutates authoritative match state")

	# Test 6: In-game event triggering announcer audio
	main.game.announce("BOOMSHAKALAKA!", "dunk")
	main._physics_process(0.016)
	check(main.announcer_player.stream != null, "Announcement in game triggers announcer_player playback")

	# Test 7: Routine non-turnover shoves produce no voice speech
	main.announcer_player.stream = null
	main.play_announcer("SHOVED! NO FOULS!")
	check(main.announcer_player.stream == null, "Routine non-turnover shove produces no announcer voice speech")
	main.play_announcer("CLEAR OUT!")
	check(main.announcer_player.stream == null, "CLEAR OUT! produces no announcer voice speech")
	main.play_announcer("DOUBLE SHOVE! KEEPS THE BALL!")
	check(main.announcer_player.stream == null, "DOUBLE SHOVE! KEEPS THE BALL! produces no announcer voice speech")

	# Test 8: Head fakes with clock < 4.0s are suppressed
	main.game.clock = 3.5
	main.play_announcer("HEAD FAKE!")
	check(main.announcer_player.stream == null, "Head fake with clock < 4.0s is suppressed")

	# Test 9: Channel priority lockout (lower priority cannot interrupt higher priority)
	main.announcer_busy_until = 0.0
	main.announcer_current_priority = 0
	main.play_announcer("BOOMSHAKALAKA!")
	var active_stream = main.announcer_player.stream
	check(main.announcer_current_priority == 18, "Dunk announcement plays at priority 18")
	main.play_announcer("NICE PASS")
	check(main.announcer_player.stream == active_stream, "Lower priority pass (7) cannot interrupt active dunk call (18)")
	main.play_announcer("HEAD FAKE!")
	check(main.announcer_player.stream == active_stream, "Lower priority head fake (5) cannot interrupt active dunk call (18)")

	# Test 10: Higher priority preempts lower priority
	main.announcer_busy_until = Time.get_ticks_msec() / 1000.0 + 5.0
	main.announcer_current_priority = 10
	main.play_announcer("BOOMSHAKALAKA!")
	check(main.announcer_current_priority == 18, "Higher priority dunk call (18) preempts lower priority speech (10)")

	# Test 11: Period transition has maximum priority 32
	main.play_announcer("HALFTIME • SWITCH ENDS")
	check(main.announcer_current_priority == 32, "Period transition sets maximum priority (32)")

	main.queue_free()
	await process_frame

	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	if failures > 0:
		printerr("ANNOUNCER VOICE TESTS FAILED!")
		quit(1)
	else:
		print("ALL ANNOUNCER VOICE TESTS PASSED!")
		quit(0)
