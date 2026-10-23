extends SceneTree

var failures = 0

func check(condition: bool, message: String) -> void:
 if condition:
  print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func press(scene, key: Key) -> void:
 var event = InputEventKey.new()
 event.physical_keycode = key
 event.keycode = key
 event.pressed = true
 scene._unhandled_input(event)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var roster = Teams.roster()
 check(roster.size() == 16, "side view walks all sixteen athletes")
 check(roster[0].name == "HENNY" and roster[0].team == 0 and roster[0].slot == 0, "side view starts on Henny of the Inferno")
 check(roster[1].name == "GAUCI" and roster[1].team == 0, "D moves from Henny to Gauci")
 check(roster[2].name == "WANG" and roster[2].team == 1 and roster[2].slot == 0, "the next athlete is Wang of the Aftershock")
 check(roster[3].name == "WATERS" and roster[3].team == 1 and roster[3].slot == 1, "Waters follows Wang on the Aftershock")
 check(roster[4].name == "GHOST" and roster[4].team == 2, "the third team follows the Aftershock")
 check(roster[15].name == "ANCHOR" and roster[15].team == 7, "the roster ends on Anchor of the Clover")
 var scene = load("res://main.tscn").instantiate()
 check(scene.has_side_view_flag(PackedStringArray(["--sideview"])), "play.sh --sideview is recognized")
 check(scene.has_side_view_flag(PackedStringArray(["--side-view"])), "the dashed side-view flag is recognized")
 check(not scene.has_side_view_flag(PackedStringArray(["--quickplay"])), "quick play is a different launch mode")
 root.add_child(scene)
 scene.begin_side_view()
 check(scene.screen == "sideview", "side view replaces the menu")
 check(scene.side_roster_index == 0 and scene.side_action == "run", "side view opens on Henny running")
 var arena = scene.arena
 check(arena.athletes[0].label.text == "HENNY", "the shown athlete is Henny")
 check(arena.athletes[0].jersey.albedo_color.is_equal_approx(Teams.color_for(0)), "Henny wears Inferno colors")
 check(arena.athletes[0].numbers[0].text == "1" and arena.athletes[0].numbers[1].text == "1", "Henny keeps jersey number 1")
 if arena.athletes[0].body.henny_head.get_child_count() > 0:
  check(arena.athletes[0].body.henny_head.visible, "Henny uses the portrait head")
 press(scene, KEY_D)
 press(scene, KEY_D)
 press(scene, KEY_D)
 press(scene, KEY_D)
 check(scene.side_roster_index == 4, "four D presses advance four athletes")
 scene.update_side_view(0.05)
 var shown = Teams.roster()[scene.side_roster_index]
 check(shown.name == "GHOST" and shown.team == 2, "D cycles Henny, Gauci, Wang, Waters, then the third team")
 check(arena.athletes[0].label.text == "GHOST", "the model label follows the roster")
 check(arena.athletes[0].jersey.albedo_color.is_equal_approx(Teams.color_for(2)), "the third team recolors the jersey")
 scene.side_roster_index = 2
 scene.update_side_view(0.05)
 check(arena.athletes[0].label.text == "WANG", "the model can show Wang")
 check(arena.athletes[0].jersey.albedo_color.is_equal_approx(Teams.color_for(1)), "Wang wears Aftershock colors")
 check(arena.athletes[0].numbers[0].text == "1", "Wang is the first Aftershock athlete")
 check(not arena.athletes[0].body.henny_head.visible, "Wang does not wear Henny's head")
 if arena.athletes[0].body.portrait_heads["WANG"].get_child_count() > 0:
  check(arena.athletes[0].body.portrait_heads["WANG"].visible, "Wang uses the portrait head")
 scene.side_roster_index = 3
 scene.update_side_view(0.05)
 check(arena.athletes[0].numbers[0].text == "2" and arena.athletes[0].label.text == "WATERS", "Waters is jersey number 2")
 if arena.athletes[0].body.portrait_heads["WATERS"].get_child_count() > 0:
  check(arena.athletes[0].body.portrait_heads["WATERS"].visible, "Waters uses the portrait head")
 scene.side_roster_index = 0
 press(scene, KEY_A)
 check(scene.side_roster_index == 15, "A from Henny wraps to the last athlete")
 scene.update_side_view(0.05)
 check(arena.athletes[0].label.text == "ANCHOR", "A shows Anchor")
 scene.begin_side_view()
 var origin = arena.athletes[0].skeleton.get_bone_pose_position(0)
 for _step in range(10):
  scene.update_side_view(0.1)
 var posed = arena.athletes[0].skeleton.get_bone_pose_position(0)
 check(arena.athletes[0].root.position == Vector3.ZERO, "running stays on the center mark")
 check(is_zero_approx(arena.athletes[0].body.position.x) and is_zero_approx(arena.athletes[0].body.position.z), "the run cycle does not travel across the court")
 check(is_equal_approx(posed.x, origin.x) and is_equal_approx(posed.z, origin.z), "the run clip keeps a fixed root")
 check(arena.athletes[0].body.action == "run", "the athlete keeps running between shots")
 check(is_equal_approx(arena.athletes[0].body.rotation.y, PI * 0.5), "the athlete faces downcourt in profile")
 check(arena.camera.position.z > 3.0 and is_zero_approx(arena.camera.position.x), "the camera watches from the sideline")
 check(not arena.athletes[1].root.visible and not arena.athletes[2].root.visible and not arena.athletes[3].root.visible, "the other athletes stay off stage")
 check(not arena.basketball.visible, "the loose ball stays hidden")
 check(not arena.athletes[0].marker.visible, "the control ring stays hidden")
 scene.side_action = "shoot"
 scene.side_action_elapsed = 0.0
 var shoot_root = arena.athletes[0].skeleton.get_bone_pose_position(0)
 for _step in range(8):
  scene.update_side_view(0.16)
 var shot = arena.athletes[0].skeleton.get_bone_pose_position(0)
 check(arena.athletes[0].body.action == "shoot", "the athlete breaks into the shoot animation")
 check(arena.athletes[0].root.position == Vector3.ZERO, "the shot stays in place")
 check(is_zero_approx(arena.athletes[0].body.position.x) and is_zero_approx(arena.athletes[0].body.position.z), "shooting does not slide the athlete")
 check(is_equal_approx(shot.x, shoot_root.x) and is_equal_approx(shot.z, shoot_root.z), "the shoot clip keeps a fixed root")
 var shoot_length = arena.athletes[0].body.clip_length("shoot")
 check(shoot_length > 2.0 and shoot_length < 4.0, "the occasional shot plays the full shoot clip")
 scene.side_action = "run"
 scene.side_action_elapsed = scene.SIDE_VIEW_RUN_SECONDS - 0.05
 scene.update_side_view(0.1)
 check(scene.side_action == "shoot" and arena.athletes[0].body.action == "shoot", "running gives way to an occasional shot")
 scene.side_action_elapsed = shoot_length - 0.05
 scene.update_side_view(0.1)
 check(scene.side_action == "run" and arena.athletes[0].body.action == "run", "the run resumes after the shot")
 print("SIDE VIEW TESTS: ", "PASS" if failures == 0 else "FAIL")
 scene.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
