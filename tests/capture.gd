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
 scene.game.players[0].pos = Vector2(1030,465)
 scene.game.players[0].charge = 0.58
 scene.game.ball = scene.game.players[0].pos
 scene.game.owner = 0
 scene.game.shoot_ball(0,true)
 scene.game.flight.time = 0.36
 scene.game.ball = scene.game.flight.start.lerp(scene.game.flight.end,0.48)
 scene.game.players[0].jump = 0.43
 scene.arena.athletes[0].body.first_pose = true
 scene.game.streak[0] = 3
 scene.game.banner = "BOOMSHAKA!"
 scene.game.banner_time = 2.0
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/dunk_3d.png")
 scene.game.big_heads = true
 for frame in range(3):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://tests/big_heads_3d.png")
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

