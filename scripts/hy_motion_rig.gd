extends Node3D

# HY-Motion's native SMPL-H hierarchy: 52 bones, 22 generated body rotations.
# Bone names, parents and rest positions come directly from Tencent's asset dump.
const DIRECTORY = "res://animations/hy_motion/"
const CLIP_NAMES = ["idle","run","dribble","defense","shoot","pass","dunk","block","steal","stun","layup"]
static var definition: Dictionary = {}
static var library: Dictionary = {}
var skeleton: Skeleton3D
var rest: Array = []
var attachments: Dictionary = {}
var head: Node3D
var jersey: StandardMaterial3D
var shorts: StandardMaterial3D
var action = ""
var action_time = 0.0
var first_pose = true
var avatar_scale = 1.16

static func load_library() -> void:
 if definition.is_empty():
  definition = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"skeleton.json"))
 if library.is_empty():
  for clip_name in CLIP_NAMES:
   var path = DIRECTORY+clip_name+".json"
   if not FileAccess.file_exists(path):
    push_error("Missing generated HY-Motion clip: "+path)
    continue
   var clip: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
   var tracks: Array = []
   for frame in clip.quaternions_xyzw:
    var pose: Array = []
    for values in frame:
     pose.append(Quaternion(values[0],values[1],values[2],values[3]).normalized())
    tracks.append(pose)
   clip["rotations"] = tracks
   library[clip_name] = clip

func initialize(arena: Node, index: int) -> void:
 load_library()
 skeleton = Skeleton3D.new()
 skeleton.name = "HYMotionSkeleton"
 skeleton.scale = Vector3.ONE*avatar_scale
 add_child(skeleton)
 for xyz in definition.rest_positions:
  rest.append(Vector3(xyz[0],xyz[1],xyz[2]))
 for i in range(int(definition.joint_count)):
  skeleton.add_bone(definition.joint_names[i])
  var parent = int(definition.parents[i])
  skeleton.set_bone_parent(i,parent)
  var offset: Vector3 = rest[i] if parent < 0 else rest[i]-rest[parent]
  skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,offset))
 skeleton.reset_bone_poses()
 var skin = arena.material([Color("b37550"),Color("e6b485"),Color("8f593d"),Color("cf9368")][index])
 jersey = StandardMaterial3D.new()
 jersey.roughness = 0.85
 shorts = StandardMaterial3D.new()
 shorts.roughness = 0.85
 # Low-poly rigid mesh segments attach directly to native HY-Motion bones.
 for chain in [[1,4,7],[2,5,8],[16,18,20],[17,19,21]]:
  for segment in range(chain.size()-1):
   var bone: int = chain[segment]
   var child: int = chain[segment+1]
   arena.rod(attach(bone),Vector3.ZERO,rest[child]-rest[bone],0.095 if bone >= 16 else 0.105,skin,6)
 # Hip/short panels and jersey follow the pelvis and spine chain.
 arena.box(attach(0),Vector3(0.37,0.23,0.31),Vector3(0,-0.015,0),shorts,"Shorts")
 for hip in [1,2]:
  arena.rod(attach(hip),Vector3.ZERO,(rest[4 if hip == 1 else 5]-rest[hip])*0.35,0.12,shorts,6)
 for bone in [3,6]:
  var child = 6 if bone == 3 else 9
  var vector: Vector3 = rest[child]-rest[bone]
  var torso = CylinderMesh.new()
  torso.height = vector.length()+0.06
  torso.top_radius = 0.23 if bone == 6 else 0.21
  torso.bottom_radius = 0.20 if bone == 6 else 0.185
  torso.radial_segments = 6
  torso.rings = 1
  var object = arena.mesh(attach(bone),torso,vector*0.5,jersey,"Jersey")
  object.quaternion = Quaternion(Vector3.UP,vector.normalized())
  object.scale.z = 0.76
 arena.box(attach(9),Vector3(0.40,0.15,0.30),Vector3(0,0.015,0),jersey)
 arena.rod(attach(12),Vector3.ZERO,rest[15]-rest[12],0.08,skin,6)
 head = Node3D.new()
 attach(15).add_child(head)
 head.position.y = 0.075
 var skull = SphereMesh.new()
 skull.radius = 0.19
 skull.height = 0.42
 skull.radial_segments = 8
 skull.rings = 4
 arena.mesh(head,skull,Vector3.ZERO,skin,"LowPolyHead")
 var hair = SphereMesh.new()
 hair.radius = 0.195
 hair.height = 0.23
 hair.radial_segments = 8
 hair.rings = 3
 arena.mesh(head,hair,Vector3(0,0.12,-0.015),arena.material(Color("24232a")))
 arena.box(head,Vector3(0.07,0.09,0.08),Vector3(0,-0.01,0.18),skin)
 for side in [-1,1]:
  arena.box(head,Vector3(0.03,0.03,0.02),Vector3(side*0.075,0.04,0.177),arena.material(Color("181e29")))
 for wrist in [20,21]:
  var shape = SphereMesh.new()
  shape.radius = 0.085
  shape.height = 0.18
  shape.radial_segments = 6
  shape.rings = 3
  arena.mesh(attach(wrist),shape,Vector3(0.035 if wrist == 20 else -0.035,0,0),skin,"Hand")
 for ankle in [7,8]:
  var foot = 10 if ankle == 7 else 11
  var forward: Vector3 = rest[foot]-rest[ankle]
  arena.rod(attach(ankle),Vector3.ZERO,forward,0.075,skin,6)
  arena.box(attach(foot),Vector3(0.17,0.14,0.31),Vector3(0,0.045,0.04),arena.material(Color("ecece0")),"Sneaker")
  arena.box(attach(foot),Vector3(0.175,0.035,0.315),Vector3(0,-0.025,0.04),arena.material(Color("26364a")))
 for side in [-1,1]:
  var number = arena.label_3d(attach(6),str(index%2+1),Vector3(0,0.04,side*0.175),0.0055,Color("fff2db"),false)
  number.rotation.y = PI if side == -1 else 0
  number.outline_size = 4
 # Apply a real generated pose immediately; never show the rest T-pose in play.
 sample("idle",0.0,1.0,false)

func attach(index: int) -> BoneAttachment3D:
 if attachments.has(index):
  return attachments[index]
 var attachment = BoneAttachment3D.new()
 attachment.name = "Attach_"+str(definition.joint_names[index])
 attachment.bone_name = definition.joint_names[index]
 skeleton.add_child(attachment)
 attachments[index] = attachment
 return attachment

func sample(clip_name: String, seconds: float, blend: float = 1.0, authoritative_jump: bool = false, filter_heading: bool = false) -> void:
 if not library.has(clip_name):
  return
 var clip: Dictionary = library[clip_name]
 var length = int(clip.frames)
 var cursor: float = maxf(0,seconds)*float(clip.fps)
 if clip.loop:
  cursor = fmod(cursor,float(length))
 else:
  cursor = minf(cursor,float(length-1))
 var a = int(floor(cursor))
 var b = (a+1)%length if clip.loop else mini(a+1,length-1)
 var fraction = cursor-float(a)
 for i in range(22):
  var qa: Quaternion = clip.rotations[a][i]
  var qb: Quaternion = clip.rotations[b][i]
  var rotation = qa.slerp(qb,fraction)
  if blend < 1:
   rotation = skeleton.get_bone_pose_rotation(i).slerp(rotation,blend)
  if i == 0 and filter_heading and clip_name in ["run", "dribble"]:
   rotation = remove_heading(rotation)
  skeleton.set_bone_pose_rotation(i,rotation)
 var root_height = lerpf(clip.grounded_root_y[a],clip.grounded_root_y[b],fraction) if authoritative_jump else lerpf(clip.root_y[a],clip.root_y[b],fraction)
 var pelvis: Vector3 = rest[0]+Vector3(0,root_height,0)
 skeleton.set_bone_pose_position(0,skeleton.get_bone_pose_position(0).lerp(pelvis,blend))

func remove_heading(rotation: Quaternion) -> Quaternion:
 # Generated locomotion contains frame-to-frame root yaw even though gameplay
 # owns travel direction. Strip that yaw so the outer athlete node can face the
 # authoritative velocity while retaining the clip's lean and body motion.
 var forward = Basis(rotation) * Vector3.BACK
 var yaw = atan2(forward.x, forward.z)
 return (Quaternion(Vector3.UP, -yaw) * rotation).normalized()

func animate(next_action: String, delta: float, phase: float = -1.0, speed: float = 1.0, paused: bool = false) -> void:
 if not library.has(next_action):
  next_action = "idle"
 if action != next_action:
  action = next_action
  action_time = 0.0
 elif not paused:
  action_time += delta*speed
 var clip: Dictionary = library[action]
 var seconds = action_time
 if phase >= 0:
  var cursor = clampf(phase,0,1)
  # Align the model's actual peak hand pose to the arcade's event timing.
  if action in ["shoot","pass","dunk","block","layup"]:
   var canonical_event = 0.55 if action == "dunk" else (0.32 if action == "block" else 0.45)
   var source_event = clampf(float(clip.get("event_phase",canonical_event)),0.05,0.95)
   cursor = cursor/canonical_event*source_event if cursor <= canonical_event else source_event+(cursor-canonical_event)/(1.0-canonical_event)*(1.0-source_event)
  seconds = cursor*float(clip.frames-1)/float(clip.fps)
 var blend = 1.0 if first_pose else (0.0 if paused else 1.0-exp(-delta*22.0))
 sample(action,seconds,blend,action in ["shoot","dunk","block","layup"], action in ["run", "dribble"])
 if action == "block":
  apply_block_pose(phase if phase >= 0 else action_time / 0.70)
 first_pose = false

func apply_block_pose(progress: float) -> void:
 var p = clampf(progress, 0.0, 1.0)
 if p < 0.22:
  var squat = sin(p / 0.22 * PI)
  var pelvis_pos = skeleton.get_bone_pose_position(0)
  pelvis_pos.y -= 0.16 * squat
  skeleton.set_bone_pose_position(0, pelvis_pos)
  var knee_q = Quaternion(Vector3.RIGHT, -0.55 * squat)
  skeleton.set_bone_pose_rotation(4, skeleton.get_bone_pose_rotation(4) * knee_q)
  skeleton.set_bone_pose_rotation(5, skeleton.get_bone_pose_rotation(5) * knee_q)
 else:
  var jump_p = (p - 0.22) / 0.78
  var arm_rise = clampf(jump_p / 0.20, 0.0, 1.0) * (1.0 - clampf((jump_p - 0.75) / 0.25, 0.0, 1.0))
  if arm_rise > 0.001:
   var q_sh_l = Quaternion(Vector3.FORWARD, 1.45 * arm_rise)
   var q_sh_r = Quaternion(Vector3.FORWARD, -1.45 * arm_rise)
   skeleton.set_bone_pose_rotation(16, q_sh_l * skeleton.get_bone_pose_rotation(16))
   skeleton.set_bone_pose_rotation(17, q_sh_r * skeleton.get_bone_pose_rotation(17))
   var q_el_l = Quaternion(Vector3.UP, -0.25 * arm_rise)
   var q_el_r = Quaternion(Vector3.UP, 0.25 * arm_rise)
   skeleton.set_bone_pose_rotation(18, q_el_l * skeleton.get_bone_pose_rotation(18))
   skeleton.set_bone_pose_rotation(19, q_el_r * skeleton.get_bone_pose_rotation(19))
