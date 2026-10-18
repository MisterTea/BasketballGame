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
 state.players[0].jump = 0.4
 state.players[1].vel = Vector2(180,0)
 state.streak[0] = 3
 var before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 check(state.snapshot() == before,"3D presentation does not mutate gameplay state")
 var floor_node = arena.world.get_node("RepeatingHardwood")
 check(floor_node.mesh.size == Vector2(28,15),"court is a rectangular 28 by 15 mesh")
 check(arena.wood_material.texture_repeat and arena.wood_material.uv1_scale == Vector3(6,3,1),"wood texture tiles across the court")
 check(arena.wood_material.albedo_texture.get_width() == 512,"hardwood texture is generated without external assets")
 check(arena.athletes.size() == 4 and arena.athletes[0].arms.size() == 2 and arena.athletes[0].legs.size() == 2,"four humanoids have articulated arms and legs")
 check(arena.athletes[0].body.position.y > 1 and arena.athletes[0].arms[0].rotation.x < -2,"jump and shooting states produce airborne raised-arm poses")
 check(arena.athletes[0].marker.visible and not arena.athletes[1].marker.visible,"controlled athlete receives a floor marker")
 check(arena.athletes[0].fire[0].visible and not arena.athletes[2].fire[0].visible,"on-fire visuals follow the correct team")
 var left = arena.world.get_node("LeftBasket/OrangeRim")
 var right = arena.world.get_node("RightBasket/OrangeRim")
 check(is_equal_approx(left.position.y,3.05) and is_equal_approx(right.position.y,3.05),"both modeled rims align with the 3D shot destination")
 check(arena.world.has_node("LeftBasket/GlassBackboard") and arena.world.has_node("RightBasket/PolePadding"),"backboards, supports, and padding are modeled")
 check(arena.crowd.multimesh.instance_count == 464,"crowd uses 464 instanced billboard spectators")
 check(arena.crowd.multimesh.mesh.material.shader.code.contains("TIME * 5.5"),"billboard atlas animation runs on the GPU")
 var framed = true
 for x in [-14,14]:
  for z in [-7.5,7.5]:
   var projected = arena.camera.unproject_position(Vector3(x,0,z))
   framed = framed and Rect2(0,0,1280,600).has_point(projected)
 check(framed and arena.camera.position.z > arena.camera.position.y,"elevated sideline camera frames every court corner")
 var display_positions: Array = []
 for i in range(4):
  display_positions.append(state.players[i].pos+Vector2(10,5))
 arena.present(state,display_positions,state.ball+Vector2(20,0),[2],0.1,false)
 check(arena.athletes[2].root.position.is_equal_approx(arena.court_point(display_positions[2])),"network-smoothed coordinates drive the 3D athlete")
 check(state.snapshot() == before,"interpolated presentation still leaves simulation unchanged")
 print("3D ARENA TESTS: ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
