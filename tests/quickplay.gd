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
	print("--- TESTING QUICK PLAY LAUNCH HOOKS ---")

	# Test 1: Verify default main scene startup without quickplay hooks shows menu
	var default_scene = load("res://main.tscn").instantiate()
	root.add_child(default_scene)
	await process_frame
	await process_frame

	# When launched normally without CLI bypass, it shows the menu
	var is_quickplay_cli = OS.get_cmdline_user_args().has("--quickplay") or OS.get_cmdline_args().has("--quickplay")
	if not is_quickplay_cli:
		check(default_scene.screen == "menu", "Default startup lands on main menu")
		check(default_scene.ui.get_child_count() > 0, "Main menu UI contains menu items")
	else:
		check(default_scene.screen == "game", "CLI quickplay startup lands directly on game screen")
		check(default_scene.picks == [0, 1], "CLI quickplay picks standard teams [0, 1]")
		check(default_scene.ui.get_child_count() == 0, "CLI quickplay has no leftover menu UI")

	default_scene.queue_free()
	await process_frame

	# Test 2: Test quick play match initialization directly
	var qp_scene = load("res://main.tscn").instantiate()
	root.add_child(qp_scene)
	await process_frame

	# Simulate what the quickplay CLI hook does
	qp_scene.mode = "solo"
	qp_scene.local_two = false
	var test_teams = [qp_scene.picks[0], qp_scene.picks[1]]
	check(test_teams == [0, 1], "Default quick play teams are [0, 1] (Chicago Inferno vs LA Aftershock)")
	qp_scene.begin_match({"teams": test_teams, "seconds": qp_scene.seconds, "level": qp_scene.level})
	await process_frame

	check(qp_scene.screen == "game", "Quick play sets screen to game")
	check(qp_scene.picks == [0, 1], "Quick play preserves the same two teams [0, 1]")
	check(qp_scene.game.teams == [0, 1], "MatchState teams match quick play teams")
	check(qp_scene.game.players.size() == 4, "Match has 4 active players on court")
	check(qp_scene.controlled == [0, 2], "Player 0 is human controlled")
	check(qp_scene.mode == "solo", "Mode is solo")
	check(qp_scene.local_two == false, "Local two-player is false")
	check(qp_scene.ui.get_child_count() == 0, "Menu UI cleared during quick play match")

	# Test 3: Verify pause and resume during quick play
	qp_scene.toggle_pause()
	check(qp_scene.paused == true, "Pause menu toggles on during quick play")
	qp_scene.toggle_pause()
	check(qp_scene.paused == false, "Pause menu resumes gameplay cleanly")

	# Test 4: Custom team quick play hook support
	qp_scene.begin_match({"teams": [2, 5], "seconds": 60.0, "level": 2})
	check(qp_scene.picks == [2, 5], "Custom teams [2, 5] apply to quick play match")
	check(qp_scene.game.teams == [2, 5], "MatchState reflects custom teams")

	qp_scene.queue_free()
	await process_frame

	print("\n--- RESULTS: %d checks, %d failures ---" % [checks, failures])
	if failures > 0:
		push_error("QUICKPLAY TESTS FAILED!")
		quit(1)
	else:
		print("ALL QUICKPLAY TESTS PASSED!")
		quit(0)
