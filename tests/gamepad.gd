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
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame

	# Check 1: Input actions exist for all 4 players
	for p in range(4):
		for act in ["up", "down", "left", "right", "shoot", "pass", "turbo", "switch"]:
			var action_name = "p%d_%s" % [p, act]
			check(InputMap.has_action(action_name), "InputMap has action " + action_name)

	# Check 2: D-pad buttons mapped to directional movement
	var dpad_map = {
		"up": JOY_BUTTON_DPAD_UP,
		"down": JOY_BUTTON_DPAD_DOWN,
		"left": JOY_BUTTON_DPAD_LEFT,
		"right": JOY_BUTTON_DPAD_RIGHT
	}
	for dir in dpad_map:
		var events = InputMap.action_get_events("p0_" + dir)
		var has_dpad = events.any(func(e): return e is InputEventJoypadButton and e.button_index == dpad_map[dir])
		check(has_dpad, "p0_" + dir + " has D-pad button " + str(dpad_map[dir]))

	# Check 3: 4 buttons on right thumb (X, Y for shoot/block, A, B for pass/steal)
	var shoot_events = InputMap.action_get_events("p0_shoot")
	var has_x = shoot_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_X)
	var has_y = shoot_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	check(has_x, "p0_shoot has Joypad X button (left thumb button)")
	check(has_y, "p0_shoot has Joypad Y button (top thumb button / block / rebound)")

	var pass_events = InputMap.action_get_events("p0_pass")
	var has_a = pass_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	var has_b = pass_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
	check(has_a, "p0_pass has Joypad A button (bottom thumb button)")
	check(has_b, "p0_pass has Joypad B button (right thumb button / steal / shove)")

	# Check 4: RT (Right Trigger) is the sole gamepad control for Boost (Turbo)
	var turbo_events = InputMap.action_get_events("p0_turbo")
	var has_rb = turbo_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_SHOULDER)
	var has_rt = turbo_events.any(func(e): return e is InputEventJoypadMotion and e.axis == JOY_AXIS_TRIGGER_RIGHT)
	check(has_rt, "p0_turbo has Right Trigger (RT) for boost")
	check(not has_rb, "p0_turbo does not use Right Bumper (RB)")

	# Check 5: RB (Right Bumper) is the sole gamepad control for Switch Athlete
	var switch_events = InputMap.action_get_events("p0_switch")
	var switch_has_rb = switch_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_SHOULDER)
	var has_lb = switch_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_LEFT_SHOULDER)
	var has_lt = switch_events.any(func(e): return e is InputEventJoypadMotion and e.axis == JOY_AXIS_TRIGGER_LEFT)
	check(switch_has_rb, "p0_switch has Right Bumper (RB)")
	check(not has_lb, "p0_switch does not use Left Bumper (LB)")
	check(not has_lt, "p0_switch does not use Left Trigger (LT)")

	# Check 6: UI actions have gamepad buttons for navigation
	var ui_accept_events = InputMap.action_get_events("ui_accept")
	var ui_cancel_events = InputMap.action_get_events("ui_cancel")
	var ui_has_a = ui_accept_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	var ui_has_b = ui_cancel_events.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
	check(ui_has_a, "ui_accept has Joypad A button for gamepad menu selection")
	check(ui_has_b, "ui_cancel has Joypad B button for gamepad menu back/cancel")

	# Check 7: read_command produces valid command dictionary structure
	var cmd = main_scene.read_command(0)
	check(cmd.has("move") and cmd.has("shoot") and cmd.has("jump_press") and cmd.has("pass") and cmd.has("turbo"), "read_command(0) returns full command dictionary")
	check(cmd.move is Vector2 and cmd.shoot is bool and cmd.pass is bool and cmd.turbo is bool, "command types are valid")

	# Check 8: Pause toggle and gamepad pause handling
	main_scene.screen = "game"
	main_scene.paused = false
	main_scene.toggle_pause()
	check(main_scene.paused, "toggle_pause pauses the match")
	check(main_scene.ui.get_child_count() > 0, "pause menu UI displayed")
	main_scene.toggle_pause()
	check(not main_scene.paused, "toggle_pause resumes the match")

	# Check 9: Gamepad Start button pauses game
	var start_ev = InputEventJoypadButton.new()
	start_ev.button_index = JOY_BUTTON_START
	start_ev.pressed = true
	main_scene.screen = "game"
	main_scene.paused = false
	main_scene._unhandled_input(start_ev)
	check(main_scene.paused, "JOY_BUTTON_START pauses the match")

	# Check 10: Gamepad B button unpauses when paused
	var b_ev = InputEventJoypadButton.new()
	b_ev.button_index = JOY_BUTTON_B
	b_ev.pressed = true
	main_scene._unhandled_input(b_ev)
	check(not main_scene.paused, "JOY_BUTTON_B unpauses the match")

	# Check 11: Gamepad Back button unpauses when paused
	main_scene.toggle_pause()
	check(main_scene.paused, "match is paused again")
	var back_ev = InputEventJoypadButton.new()
	back_ev.button_index = JOY_BUTTON_BACK
	back_ev.pressed = true
	main_scene._unhandled_input(back_ev)
	check(not main_scene.paused, "JOY_BUTTON_BACK unpauses the match")

	# Check 12: Gamepad Back button in submenus returns to menu
	main_scene.show_help()
	check(main_scene.screen == "help", "navigated to help screen")
	main_scene._unhandled_input(back_ev)
	check(main_scene.screen == "menu", "JOY_BUTTON_BACK returns to main menu")

	# Check 13: Gamepad Start button on selection screen triggers match tip-off
	main_scene.show_selection()
	check(main_scene.screen == "selection", "selection screen active")
	main_scene._unhandled_input(start_ev)
	check(main_scene.screen == "game", "JOY_BUTTON_START on selection screen tips off match")

	print("\nGAMEPAD TESTS: %d checks, %d failures" % [checks, failures])
	main_scene.queue_free()
	if failures > 0:
		quit(1)
	else:
		quit(0)
