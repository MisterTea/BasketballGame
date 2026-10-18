extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.begin_match({"teams":[0,1],"seconds":120.0,"level":1})
 scene.game.inbound(0)
 scene.paused = true
 scene.set_process(false)
 scene.game.banner_time = 0
 scene.game.players[0].pos = Vector2(480,510)
 scene.game.players[1].pos = Vector2(640,540)
 scene.game.players[2].pos = Vector2(800,510)
 scene.game.players[3].pos = Vector2(960,540)
 scene.arena.present(scene.game,[],scene.game.ball,[0],0.1,false)
 scene.arena.camera.position = Vector3(0,19,34)
 scene.arena.camera.fov = 24.5
 scene.arena.camera.look_at(Vector3(0,0.9,0))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/preview_frames"))
 var preview_index = 0
 var names = ["idle","run","dribble","defense","shoot","pass","dunk","block","steal","stun","layup"]
 for action in names:
  var clip: Dictionary = scene.arena.athletes[0].body.library[action]
  for frame in range(18):
   var t = float(frame)/17.0*float(clip.frames-1)/float(clip.fps)
   for i in range(4):
    var rig = scene.arena.athletes[i].body
    rig.rotation.y = 0 if i%2 == 0 else 0.8
    rig.sample(action,t,1.0,false)
   scene.game.banner = "HY-MOTION 1.0  /  "+str(action).to_upper()
   scene.game.banner_time = 1
   scene.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.runtime/preview_frames/%04d.png" % preview_index)
   if frame == int(round(float(clip.get("event_phase",0.5))*17.0)):
    root.get_texture().get_image().save_png("res://tests/hy_"+str(action)+".png")
   preview_index += 1
 print("HY-MOTION PREVIEW PASS: ",preview_index," frames")
 scene.queue_free()
 await process_frame
 quit()
