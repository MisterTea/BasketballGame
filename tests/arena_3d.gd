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
