extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 await process_frame
 for page in ["show_menu","show_selection","show_options","show_help","show_network"]:
  scene.call(page)
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  var path = "res://tests/"+page+".png"
  root.get_texture().get_image().save_png(path)
  print("CAPTURED ",page)
 scene.net.host_game("QA HOST")
 scene.status = "Hosting on UDP 27888"
 scene.show_lobby()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/lobby.png")
 scene.net.leave()
 scene.begin_match({"teams":[0,1],"seconds":120.0,"level":1})
 scene.game.freeze = 0
 for frame in range(90):
  await process_frame
 await RenderingServer.frame_post_draw
 var gameplay_image = root.get_texture().get_image()
 gameplay_image.save_png("res://tests/gameplay.png")
 # Two GPU frames far enough apart prove that the billboard atlas animates.
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 var animated_image = root.get_texture().get_image()
 animated_image.save_png("res://tests/crowd_animated.png")
 var changed = 0
 for y in range(238,310,3):
  for x in range(125,1155,3):
   if gameplay_image.get_pixel(x,y) != animated_image.get_pixel(x,y):
    changed += 1
 if changed < 100:
  push_error("Crowd billboards failed pixel animation check")
  quit(1)
  return
 print("PASS: animated billboard crowd changed ",changed," sampled pixels")
 scene.paused = true
 scene.game.players[0].fake = 0.19
 scene.arena.athletes[0].body.first_pose = true
 scene.game.banner = "HEAD FAKE!"
 scene.game.banner_time = 2.0
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/head_fake.png")
 scene.game.players[0].fake = 0.0
 scene.game.players[0].pos = Vector2(1030,465)
 scene.game.players[0].charge = 0.58
 scene.game.ball = scene.game.players[0].pos
 scene.game.owner = 0
 scene.game.shoot_ball(0,true)
 scene.game.flight.time = 0.36
 scene.game.ball = scene.game.flight.start.lerp(scene.game.flight.end,0.48)
 scene.game.players[0].jump = 0.43
 scene.arena.athletes[0].body.first_pose = true
 scene.game.player_streak[0] = 3
 scene.game.fire_player = 0
 scene.game.refresh_heat_summary()
 scene.game.banner = "BOOMSHAKA!"
 scene.game.banner_time = 2.0
 scene.arena.reset_camera()
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/dunk_3d.png")
 scene.game.big_heads = true
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/big_heads_3d.png")
 # Goaltending applies to a released jump shot, not a held dunk.
 scene.game.owner = 0
 scene.game.players[0].pos = Vector2(850,465)
 scene.game.players[0].charge = 0.58
 scene.game.ball = scene.game.players[0].pos
 scene.game.shoot_ball(0,false)
 scene.game.flight.time = scene.game.flight.duration*0.92
 scene.game.players[2].pos = scene.game.flight_position()
 scene.game.defend(2,false)
 if scene.game.stats[2].goaltends != 1 or scene.game.score[0] != 2:
  push_error("Render fixture did not trigger actual goaltending")
  quit(1)
  return
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/goaltending.png")
 scene.game.freeze = 0
 scene.game.owner = 0
 scene.game.players[0].pos = Vector2(1030,465)
 scene.game.players[1].pos = Vector2(850,580)
 scene.game.players[0].charge = 0.58
 scene.game.ball = scene.game.players[0].pos
 scene.game.shoot_ball(0,true)
 scene.game.flight.time = 0.25
 scene.game.ball = scene.game.flight_position()
 scene.game.tick(1.0/60.0,{0:{"pass":true},1:{},2:{},3:{}})
 if scene.game.flight.kind != "pass":
  push_error("Render fixture failed airborne dish input")
  quit(1)
  return
 scene.game.flight.time = 0.12
 scene.game.ball = scene.game.flight_position()
 scene.arena.athletes[0].body.first_pose = true
 scene.arena.reset_camera()
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 if scene.arena.athletes[0].body.action != "pass":
  push_error("Airborne dish did not select generated pass animation")
  quit(1)
  return
 root.get_texture().get_image().save_png("res://tests/airborne_dish.png")
 scene.game.start(0,1)
 scene.game.quarter = 4
 scene.game.freeze = 0
 scene.game.owner = 2
 scene.game.players[2].pos = Vector2(1020,465)
 scene.game.players[2].charge = 0.58
 scene.game.ball = scene.game.players[2].pos
 scene.game.shoot_ball(2,true)
 scene.game.flight.made = true
 for frame in range(120):
  if scene.game.flight.is_empty():
   break
  scene.game.tick(1.0/60.0,{0:{},1:{},2:{},3:{}})
 scene.game.tick(0.30,{})
 if scene.game.board_breaks[1] < 0 or scene.game.pending_inbound != 0 or not scene.sounds.has("shatter"):
  push_error("Render fixture failed real shattering dunk")
  quit(1)
  return
 scene.play_sound("shatter")
 scene.arena.reset_camera()
 for athlete in scene.arena.athletes:
  athlete.body.first_pose = true
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/backboard_shatter.png")
 scene.game.tick(2.0,{})
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/backboard_settled.png")
 scene.saved_result = true
 scene.game.score = [42,39]
 scene.game.phase = "finished"
 scene.show_results()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/results.png")
 print("RENDER SMOKE PASS")
 quit()

