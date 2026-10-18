extends SceneTree
const ArenaView = preload("res://scripts/arena_3d.gd")
const RigView = preload("res://scripts/hy_motion_rig.gd")
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
 var actor: Dictionary = arena.athletes[0]
 var rig = actor.body
 var definition: Dictionary = RigView.definition
 check(rig.skeleton.get_bone_count() == 52,"player uses all 52 native SMPL-H joints")
 var matches = true
 for i in range(52):
  var parent = int(definition.parents[i])
  var expected: Vector3 = rig.rest[i] if parent < 0 else rig.rest[i]-rig.rest[parent]
  matches = matches and rig.skeleton.get_bone_name(i) == str(definition.joint_names[i])
  matches = matches and rig.skeleton.get_bone_parent(i) == parent
  matches = matches and rig.skeleton.get_bone_rest(i).origin.is_equal_approx(expected)
 check(matches,"bone names, parents and rest transforms match upstream exactly")
 var valid = true
 var animated = true
 for clip_name in RigView.CLIP_NAMES:
  var clip: Dictionary = RigView.library.get(clip_name,{})
  valid = valid and clip.get("machine_generated",false) and clip.get("joint_count",0) == 22 and clip.get("frames",0) >= 20
  if clip.is_empty():
   continue
  var movement = 0.0
  for frame in clip.rotations:
   for q in frame:
    valid = valid and is_finite(q.x) and absf(q.length()-1.0) < 0.0001
  for i in range(22):
   movement += clip.rotations[0][i].angle_to(clip.rotations[clip.frames/2][i])
  animated = animated and movement > 0.01
 check(valid,"all eleven clips contain finite normalized generated 22-joint rotations")
 check(animated,"every clip contains actual time-varying joint motion")
 # Compare Skeleton3D's FK against the same local transforms used by HY-Motion.
 rig.sample("run",0.5,1.0,false)
 var clip: Dictionary = RigView.library.run
 var cursor = 0.5*clip.fps
 var a = int(cursor)%int(clip.frames)
 var b = (a+1)%int(clip.frames)
 var fraction = fmod(cursor,float(clip.frames))-float(a)
 var transforms: Array = []
 var fk_matches = true
 for i in range(22):
  var parent = int(definition.parents[i])
  var offset: Vector3 = rig.rest[i] if parent < 0 else rig.rest[i]-rig.rest[parent]
  if i == 0:
   offset.y += lerpf(clip.root_y[a],clip.root_y[b],fraction)
  var rotation: Quaternion = clip.rotations[a][i].slerp(clip.rotations[b][i],fraction)
  var pose = Transform3D(Basis(rotation),offset)
  var global_pose: Transform3D = pose if parent < 0 else transforms[parent]*pose
  transforms.append(global_pose)
  fk_matches = fk_matches and rig.skeleton.get_bone_global_pose(i).is_equal_approx(global_pose)
 check(fk_matches,"Godot forward kinematics reproduces imported HY-Motion joint transforms")
 var hands_static = true
 for i in range(22,52):
  hands_static = hands_static and rig.skeleton.get_bone_pose_rotation(i).is_equal_approx(Quaternion.IDENTITY)
 check(hands_static,"ungenerated finger joints retain their native rest rotations")
 # Pose-based grounding removes the model jump while gameplay owns jump height.
 rig.sample("dunk",0.75,1.0,true)
 var minimum_foot = 100.0
 for bone in [7,8,10,11]:
  minimum_foot = minf(minimum_foot,rig.skeleton.get_bone_global_pose(bone).origin.y)
 check(absf(minimum_foot-0.0425) < 0.001,"authoritative jumps ground the generated pose without doubling root elevation")
 rig.first_pose = true
 rig.animate("shoot",0.1,0.45,1.0,false)
 var shot: Dictionary = RigView.library.shoot
 var release_cursor = float(shot.event_phase)*float(shot.frames-1)
 var release_a = int(floor(release_cursor))
 var release_b = mini(release_a+1,int(shot.frames-1))
 var expected_release: Quaternion = shot.rotations[release_a][20].slerp(shot.rotations[release_b][20],release_cursor-release_a)
 check(rig.skeleton.get_bone_pose_rotation(20).is_equal_approx(expected_release),"gameplay release maps to the generated peak wrist pose")
 var state = MatchState.new()
 state.start(0,1)
 state.inbound(0)
 state.players[0].vel = Vector2.RIGHT*180
 var before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 var unchanged = state.snapshot() == before
 check(actor.body.action == "dribble","ball-carrier locomotion selects generated dribble clip")
 state.players[0].vel = Vector2.ZERO
 state.players[0].charge = 0.3
 before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 unchanged = unchanged and state.snapshot() == before
 check(actor.body.action == "shoot","shot charge selects generated shooting clip")
 state.players[0].charge = 0
 state.players[0].stun = 0.5
 before = state.snapshot()
 arena.present(state,[],state.ball,[0],0.1,false)
 check(actor.body.action == "stun","stun state selects generated recovery clip")
 unchanged = unchanged and state.snapshot() == before
 check(unchanged,"animation does not alter movement, scoring or simulation data")
 var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://animations/hy_motion/provenance.json"))
 check(record.executed_locally and record.clips.size() == 11 and record.generator.contains("1B"),"provenance records a completed local standard-model run")
 print("HY-MOTION TESTS: ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
