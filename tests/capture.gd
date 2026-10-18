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
 root.get_texture().get_image().save_png("res://tests/gameplay.png")
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

