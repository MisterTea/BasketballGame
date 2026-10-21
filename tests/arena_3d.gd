extends SceneTree
const ArenaView = preload("res://scripts/arena_3d.gd")
var failures = 0

func check(condition: bool, message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var arena = ArenaView.new()
 root.add_child(arena)
 var state = MatchState.new()
 state.start(0,1)
 state.inbound(0)
 state.players[0].jump = 0.4
 state.players[1].vel = Vector2(180,0)
 state.player_streak[0] = 3
 state.fire_player = 0
 state.refresh_heat_summary()
 var before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 check(state.snapshot() == before,"3D presentation does not mutate gameplay state")
 var floor_node = arena.world.get_node("RepeatingHardwood")
 check(floor_node.mesh.size == Vector2(28,15),"court is a rectangular 28 by 15 mesh")
 check(arena.wood_material.texture_repeat and arena.wood_material.uv1_scale == Vector3(6,3,1),"wood texture tiles across the court")
 check(arena.wood_material.albedo_texture.get_width() == 512,"hardwood texture is generated without external assets")
 check(arena.athletes.size() == 4 and arena.athletes[0].arms.size() == 2 and arena.athletes[0].legs.size() == 2,"four humanoids have articulated arms and legs")
 check(arena.athletes[0].body.position.y > 1 and arena.athletes[0].body.action == "block","jump state produces an airborne HY-Motion block pose")
 check(arena.athletes[0].marker.visible and not arena.athletes[1].marker.visible,"controlled athlete receives a floor marker")
 var original_flash: float = state.players[0].possession_flash
 state.players[0].possession_flash = MatchState.POSSESSION_FLASH_DURATION
 arena.time = 0.0
 arena.present(state,[],state.ball,[0],0.01,false)
 var flashed_white = arena.athletes[0].mesh_parts.all(func(part): return part.mesh.material_override == arena.possession_flash_material)
 arena.time = 0.08
 arena.present(state,[],state.ball,[0],0.01,false)
 var restored_model = arena.athletes[0].mesh_parts.all(func(part): return part.mesh.material_override == part.material)
 check(flashed_white and restored_model,"new ball carrier strobes between a white silhouette and the original model")
 state.players[0].possession_flash = original_flash
 var block_faces_ball = true
 state.players[0].vel = Vector2.ZERO
 state.players[0].face = 1
 for ball_offset in [Vector2(-180,70),Vector2(160,-90)]:
  var rendered_ball = state.players[0].pos+ball_offset
  arena.present(state,[],rendered_ball,[0],0.1,false)
  var block_root_rotation = arena.athletes[0].skeleton.get_bone_pose_rotation(0)
  var body_forward = arena.athletes[0].body.basis * (Basis(block_root_rotation) * Vector3.BACK)
  body_forward.y = 0.0
  var expected = arena.court_point(rendered_ball)-arena.court_point(state.players[0].pos)
  expected.y = 0.0
  block_faces_ball = block_faces_ball and body_forward.normalized().dot(expected.normalized()) > 0.995
 check(block_faces_ball,"airborne blockers face the ball from either side")
 var faces_travel = true
 for velocity in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
  state.players[1].vel = velocity * 180.0
  arena.present(state,[],state.ball,[0],0.1,false)
  var root_rotation = arena.athletes[1].skeleton.get_bone_pose_rotation(0)
  var visual_forward = arena.athletes[1].body.basis * (Basis(root_rotation) * Vector3.BACK)
  visual_forward.y = 0.0
  var expected = Vector3(velocity.x * arena.COURT_SCALE.x, 0.0, velocity.y * arena.COURT_SCALE.y).normalized()
  faces_travel = faces_travel and visual_forward.normalized().dot(expected) > 0.995
 check(faces_travel,"running animations face their rendered travel direction")
 state.players[1].vel = Vector2(180,0)
 check(arena.athletes[0].fire[0].visible and not arena.athletes[1].fire[0].visible and not arena.athletes[2].fire[0].visible,"on-fire visuals follow only the burning athlete")
 var left = arena.world.get_node("LeftBasket/OrangeRim")
 var right = arena.world.get_node("RightBasket/OrangeRim")
 check(is_equal_approx(left.position.y,3.05) and is_equal_approx(right.position.y,3.05),"both modeled rims align with the 3D shot destination")
 check(arena.world.has_node("LeftBasket/GlassBackboard") and arena.world.has_node("RightBasket/PolePadding"),"backboards, supports, and padding are modeled")
 check(arena.crowd.multimesh.instance_count == 464,"crowd uses 464 instanced billboard spectators")
 check(arena.crowd.multimesh.mesh.material.shader.code.contains("TIME * 5.5"),"billboard atlas animation runs on the GPU")
 var camera_x: float = arena.camera.position.x
 arena.present(state,[],Vector2(1100,465),[0],0.1,false)
 check(arena.camera.position.x > camera_x and arena.camera.position.x < 7.5 and arena.camera.position.z > arena.camera.position.y,"sideline camera smoothly pans toward possession within court bounds")
 var camera_before: Transform3D = arena.camera.transform
 arena.present(state,[],Vector2(150,465),[0],0.1,true)
 check(arena.camera.transform == camera_before,"pausing freezes the camera while retaining the sideline view")
 var display_positions: Array = []
 for i in range(4):
  display_positions.append(state.players[i].pos+Vector2(10,5))
 arena.present(state,display_positions,state.ball+Vector2(20,0),[2],0.1,false)
 check(arena.athletes[2].root.position.is_equal_approx(arena.court_point(display_positions[2])),"network-smoothed coordinates drive the 3D athlete")
 check(state.snapshot() == before,"interpolated presentation still leaves simulation unchanged")
 state.players[0].charge = 0.58
 state.shoot_ball(0,false)
 state.flight.time = state.flight.duration*0.5
 state.ball = state.flight_position()
 before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 check(arena.ball_fire[0].visible and arena.ball_fire[0].position.distance_to(arena.basketball.position) < 1.0 and state.snapshot() == before,"a burning shooter's ball has a non-authoritative flame trail")
 state.fire_player = 1
 arena.present(state,[],state.ball,[0],0.1,false)
 check(not arena.ball_fire[0].visible,"a burning teammate cannot ignite another shooter's ball")
 state.flight = {}
 state.players[0].charge = 0
 state.players[0].jump = 0
 state.players[0].fake = 0.19
 before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 check(arena.athletes[0].body.action == "shoot" and state.snapshot() == before,"head-fakes reuse generated shooting poses without changing the simulation")
 state.players[2].pos = Vector2(1145,650)
 arena.reset_camera()
 arena.present(state,[],Vector2(140,465),[0],0.1,false)
 var indicator: Dictionary = arena.player_indicator(2)
 check(indicator.visible and indicator.direction.x > 0 and indicator.point.x == 1250,"off-screen athlete indicator points toward the missing player at the viewport edge")
 state.phase = "playing"
 state.owner = 0
 state.players[0].pos = Vector2(600, 400)
 state.players[0].vel = Vector2(180, 0)
 state.players[0].still_time = 0.0
 state.players[0].charge = 0.0
 arena.present(state, [], state.ball, [0], 0.1, false)
 check(not arena.athletes[0].aim_indicator.visible and not arena.athletes[0].aim_label.visible, "moving ball carrier does not show aimed shot indicator")
 state.players[0].vel = Vector2.ZERO
 state.players[0].still_time = 0.12
 arena.present(state, [], state.ball, [0], 0.1, false)
 check(arena.athletes[0].aim_indicator.visible and arena.athletes[0].aim_label.visible and arena.athletes[0].aim_label.text == "⌖ AIMED", "ball carrier who stands still >= 100ms displays aimed shot indicator and label")
 check(not arena.athletes[1].aim_indicator.visible, "non-ball carrier does not display aimed shot indicator")
 state.players[0].charge = 0.45
 state.players[0].shot_is_moving = false
 arena.present(state, [], state.ball, [0], 0.1, false)
 check(arena.athletes[0].aim_indicator.visible and arena.athletes[0].aim_label.visible, "aimed shot charge preserves visual aimed indicator")
 state.owner = 0
 state.flight = {}
 state.players[0].charge = 0.0
 state.players[0].jump = 0.40
 arena.present(state, [], state.ball, [0], 0.016, false)
 var bone_l: Transform3D = arena.athletes[0].skeleton.global_transform * arena.athletes[0].skeleton.get_bone_global_pose(20)
 var bone_r: Transform3D = arena.athletes[0].skeleton.global_transform * arena.athletes[0].skeleton.get_bone_global_pose(21)
 var hands_mid = (bone_l.origin + bone_r.origin) * 0.5
 check(state.ball_height() > 1.5 and arena.basketball.global_position.y > 1.5, "ball elevates in authoritative and presentation layers while player has ball in air")
 check(arena.basketball.global_position.distance_to(hands_mid) < 0.25, "ball remains in player hands while in the air")
 var mesh_stays_above_floor = true
 for test_jump in [0.70, 0.65, 0.55, 0.45, 0.35, 0.20, 0.10, 0.05, 0.01]:
  state.players[0].jump = test_jump
  arena.present(state, [], state.ball, [0], 0.016, false)
  var lowest_y = 100.0
  for bone in [7, 8, 10, 11]:
   var trans: Transform3D = arena.athletes[0].skeleton.global_transform * arena.athletes[0].skeleton.get_bone_global_pose(bone)
   lowest_y = minf(lowest_y, trans.origin.y)
  var bottom = lowest_y - 0.045
  if bottom < -0.005:
   mesh_stays_above_floor = false
 check(mesh_stays_above_floor, "athlete mesh never penetrates through floor during jump stages")
 state.players[0].jump = 0.0

 # Net impact swirl presentation tests
 check(arena.baskets.size() == 2 and arena.baskets[0].has("net") and arena.baskets[1].has("net"), "modeled baskets contain structured dynamic net data")
 var net1: Dictionary = arena.baskets[1].net
 check(net1.rings.size() == 4 and net1.strands.size() == 12, "net contains 4 horizontal rings and 12 vertical diamond strands")
 var rest_bottom_y = net1.rings[3].position.y
 var rest_bottom_scale = net1.rings[3].scale.x
 check(absf((net1.center.y - 0.62) - rest_bottom_y) < 0.02 and absf(rest_bottom_scale - 1.0) < 0.01, "net rests hanging down at default length and diameter")
 arena.trigger_net_swish(1, Vector3.RIGHT)
 state.event_id = 99
 state.event_kind = "score"
 state.inbound_transition = {"active": true}
 before = state.snapshot()
 arena.present(state, [], state.ball, [0], 0.25, false)
 var peak_bottom_y = net1.rings[3].position.y
 var peak_bottom_scale = net1.rings[3].scale.x
 check(peak_bottom_y > rest_bottom_y + 0.25, "impact of made shot causes the bottom of the net to swirl upwards towards the rim")
 check(peak_bottom_scale > 1.45, "bottom and mid rings of the net flare outwards to wrap around the ball")
 check(net1.rings[3].quaternion != Quaternion.IDENTITY, "net bottom tilts in direction of ball momentum")
 check(arena.basketball.position.y > 2.2 and arena.basketball.position.y < 3.15, "basketball passes down through the swirling net on made basket")
 check(state.snapshot() == before, "dynamic net swish presentation never mutates authoritative game state")
 arena.present(state, [], state.ball, [0], 0.90, false)
 var settled_bottom_y = net1.rings[3].position.y
 var settled_bottom_scale = net1.rings[3].scale.x
 check(absf(settled_bottom_y - rest_bottom_y) < 0.02 and absf(settled_bottom_scale - rest_bottom_scale) < 0.02, "net cleanly returns to resting geometry after swish settling oscillations")
 state.inbound_transition = {}

 # Dunk camera vertical tracking, dynamic zoom, and shake presentation tests
 state.phase = "playing"
 arena.reset_camera()
 arena.present(state, [], state.ball, [0], 0.1, false)
 var rest_cam_y = arena.camera.position.y
 var rest_cam_fov = arena.camera.fov
 check(is_equal_approx(rest_cam_y, arena.BASE_CAM_Y) and is_equal_approx(rest_cam_fov, arena.BASE_FOV), "baseline camera sits at arcade zoom and elevation")
 state.flight = {
  "kind": "shot",
  "shooter": 0,
  "time": 0.40,
  "duration": 0.80,
  "dunk": true,
  "arc_height": 2.6,
  "super_dunk": true,
  "dunk_style": "helicopter",
  "start": Vector2(800, 465),
  "end": Vector2(1115, 465),
  "made": true
 }
 arena.present(state, [], state.ball, [0], 0.1, false)
 check(arena.camera.position.y > rest_cam_y + 0.35, "camera ascends vertically to frame high vertical dunk")
 check(arena.camera.fov < rest_cam_fov - 0.5, "camera zooms in dynamically as dunk approaches apex")
 state.flight.time = 0.76
 arena.present(state, [], state.ball, [0], 0.05, false)
 check(arena.dunk_shake_timer > 0.0, "dunk slamming into rim triggers camera shake timer")
 check(arena.camera.position != Vector3(arena.camera_focus, arena.BASE_CAM_Y + arena.dunk_cam_lift, arena.BASE_CAM_Z - minf(1.8, arena.dunk_cam_lift * 0.35)), "camera shake imparts 3D displacement")
 state.flight = {}
 arena.present(state, [], state.ball, [0], 1.2, false)
 check(absf(arena.camera.fov - arena.BASE_FOV) < 0.05 and absf(arena.camera.position.y - arena.BASE_CAM_Y) < 0.05 and arena.dunk_shake_timer == 0.0, "camera cleanly recovers base framing and shake decays to zero")

 # Dunk hand attachment and rim delivery presentation tests
 var dunk_styles_tested = ["frontflip", "helicopter", "standard", "between_legs"]
 var all_dunks_stay_in_hands = true
 for style in dunk_styles_tested:
  state.flight = {
   "kind": "shot",
   "start": Vector2(600, 465),
   "end": Vector2(1000, 465),
   "time": 0.0,
   "duration": 1.2,
   "shooter": 0,
   "points": 2,
   "made": true,
   "dunk": true,
   "super_dunk": false,
   "dunk_style": style,
   "finish": "dunk",
   "arc_height": 2.0,
   "player_start": Vector2(600, 465),
   "player_end": Vector2(970, 465),
   "player_launch_height": 0.0
  }
  state.owner = -1
  for test_p in [0.20, 0.45, 0.70, 0.85]:
   state.flight.time = test_p * state.flight.duration
   state.players[0].pos = state.finisher_position(state.flight.time)
   arena.present(state, [], state.flight_position(), [0], 0.016, false)
   var b_l: Transform3D = arena.athletes[0].skeleton.global_transform * arena.athletes[0].skeleton.get_bone_global_pose(20)
   var b_r: Transform3D = arena.athletes[0].skeleton.global_transform * arena.athletes[0].skeleton.get_bone_global_pose(21)
   var mid = (b_l.origin + b_r.origin) * 0.5
   if arena.basketball.global_position.distance_to(mid) > 0.25:
    all_dunks_stay_in_hands = false
 check(all_dunks_stay_in_hands, "basketball remains attached to player hands during somersault, flip, spin, and standard dunks")
 state.flight.time = 0.94 * state.flight.duration
 state.players[0].pos = state.finisher_position(state.flight.time)
 arena.present(state, [], state.flight_position(), [0], 0.016, false)
 var rim_pos = arena.court_point(state.flight.end, 3.05 - arena.rim_dips[1])
 check(arena.basketball.global_position.distance_to(rim_pos) < 0.05, "basketball reaches and delivers directly through rim at dunk impact")
 state.flight = {}

 state.phase = "finished"
 arena.present(state,[],state.ball,[0],0.1,true)
 var framed = true
 for x in [-14,14]:
  for z in [-7.5,7.5]:
   framed = framed and Rect2(0,0,1280,600).has_point(arena.camera.unproject_position(Vector3(x,0,z)))
 check(framed and arena.camera.position.x == 0,"results restore the complete court overview")
 print("3D ARENA TESTS: ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
