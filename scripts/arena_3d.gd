extends SubViewport

const HYMotionRig = preload("res://scripts/hy_motion_rig.gd")

# Presentation only: simulation coordinates, inputs, and network state stay unchanged.
const COURT_SCALE = Vector2(28.0 / 1050.0, 15.0 / 410.0)
const GOLD = Color("ffcb68")
const BASE_CAM_Y = 10.6
const BASE_CAM_Z = 18.6
const BASE_LOOK_Y = 1.3
const BASE_FOV = 23.5
var world: Node3D
var camera: Camera3D
var athletes: Array = []
var basketball: Node3D
var ball_fire: Array = []
var ball_trail: Array = []
var ball_trail_history: Array[Vector3] = []
var crowd: MultiMeshInstance3D
var wood_material: StandardMaterial3D
var last_teams: Array = []
var time = 0.0
var materials: Dictionary = {}
var camera_initialized = false
var camera_focus = 0.0
var dunk_cam_lift: float = 0.0
var dunk_cam_zoom: float = 0.0
var dunk_cam_look_lift: float = 0.0
var dunk_shake_timer: float = 0.0
var dunk_shake_duration: float = 0.38
var dunk_shake_intensity: float = 0.0
var dunk_slam_shaken: bool = false
var baskets: Array = []
var possession_flash_material: StandardMaterial3D
var last_event_id: int = -1
var cached_shadow_texture: ImageTexture = null
var ball_shadow: MeshInstance3D
var rim_dips: Array = [0.0, 0.0]
var rim_vels: Array = [0.0, 0.0]
var rim_nodes: Array = []
var rim_rods: Array = []
var flashbulbs: Array = []

func _ready() -> void:
 size = Vector2i(1280,600)
 own_world_3d = true
 render_target_update_mode = SubViewport.UPDATE_DISABLED
 msaa_3d = Viewport.MSAA_4X
 world = Node3D.new()
 world.name = "Arena"
 add_child(world)
 build_lighting()
 build_court()
 build_basket(-1)
 build_basket(1)
 build_stands()
 build_crowd()
 possession_flash_material = StandardMaterial3D.new()
 possession_flash_material.albedo_color = Color.WHITE
 possession_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 possession_flash_material.emission_enabled = true
 possession_flash_material.emission = Color.WHITE
 possession_flash_material.emission_energy_multiplier = 1.0
 for i in range(4):
  athletes.append(build_athlete(i))
 build_ball()
 camera = Camera3D.new()
 camera.name = "SidelineCamera"
 camera.projection = Camera3D.PROJECTION_PERSPECTIVE
 camera.fov = BASE_FOV
 camera.position = Vector3(0,BASE_CAM_Y,BASE_CAM_Z)
 world.add_child(camera)
 camera.look_at(Vector3(0,BASE_LOOK_Y,0))
 camera.current = true
 camera.far = 120.0

func trigger_dunk_shake(intensity: float, duration: float) -> void:
 var remaining_factor = dunk_shake_timer / maxf(0.001, dunk_shake_duration) if dunk_shake_duration > 0.0 else 0.0
 dunk_shake_intensity = maxf(dunk_shake_intensity * remaining_factor, intensity)
 dunk_shake_duration = duration
 dunk_shake_timer = duration

func reset_camera() -> void:
 camera_initialized = false
 dunk_cam_lift = 0.0
 dunk_cam_zoom = 0.0
 dunk_cam_look_lift = 0.0
 dunk_shake_timer = 0.0
 dunk_slam_shaken = false

func update_camera(state: MatchState, ball: Vector2, delta: float, paused: bool) -> void:
 if state.phase == "finished":
  camera.position = Vector3(0,19,34)
  camera.fov = 24.5
  camera.look_at(Vector3(0,0.9,0))
  camera_initialized = false
  return
 if paused:
  return
 var target = clampf(court_point(ball).x*0.72,-7.0,7.0)
 if not camera_initialized:
  camera_focus = target
  camera_initialized = true
 else:
  camera_focus = lerpf(camera_focus,target,1.0-exp(-delta*5.0))

 var is_dunking = not state.flight.is_empty() and state.flight.get("kind", "") == "shot" and state.flight.get("dunk", false)
 var target_lift = 0.0
 var target_look_lift = 0.0
 var target_zoom = 0.0
 if is_dunking:
  var p = clampf(state.flight.time / state.flight.duration, 0.0, 1.0)
  var arc_h = state.flight.get("arc_height", 1.5)
  var lift = arc_h * sin(p * PI)
  target_lift = lift * 0.45
  target_look_lift = lift * 0.60
  target_zoom = minf(4.5, lift * 0.90)

 var follow_speed = 10.0 if is_dunking else 5.0
 dunk_cam_lift = lerpf(dunk_cam_lift, target_lift, 1.0 - exp(-delta * follow_speed))
 dunk_cam_look_lift = lerpf(dunk_cam_look_lift, target_look_lift, 1.0 - exp(-delta * follow_speed))
 dunk_cam_zoom = lerpf(dunk_cam_zoom, target_zoom, 1.0 - exp(-delta * follow_speed))
 if not is_dunking:
  if absf(dunk_cam_lift) < 0.02:
   dunk_cam_lift = 0.0
  if absf(dunk_cam_look_lift) < 0.02:
   dunk_cam_look_lift = 0.0
  if absf(dunk_cam_zoom) < 0.02:
   dunk_cam_zoom = 0.0

 var dolly_z = minf(1.8, dunk_cam_lift * 0.35)
 camera.position = Vector3(camera_focus, BASE_CAM_Y + dunk_cam_lift, BASE_CAM_Z - dolly_z)
 camera.fov = BASE_FOV - dunk_cam_zoom
 camera.look_at(Vector3(camera_focus, BASE_LOOK_Y + dunk_cam_look_lift, 0.0))

 if dunk_shake_timer > 0.0:
  dunk_shake_timer = maxf(0.0, dunk_shake_timer - delta)
  var progress = 1.0 - (dunk_shake_timer / maxf(0.001, dunk_shake_duration))
  var decay = exp(-progress * 4.5) * (1.0 - progress)
  var shake_y = sin(progress * TAU * 14.0) * dunk_shake_intensity * decay
  var shake_x = cos(progress * TAU * 11.0) * dunk_shake_intensity * decay * 0.45
  var shake_z = sin(progress * TAU * 8.0) * dunk_shake_intensity * decay * 0.25
  camera.position += Vector3(shake_x, shake_y, shake_z)

 var latest = maxf(state.board_breaks[0],state.board_breaks[1])
 if latest >= 0:
  var age = state.elapsed-latest
  if age < 0.65:
   var impact = maxf(0.0, 1.0 - age / 0.65) * 0.25
   camera.position += Vector3(sin(age * 73.0) * impact, cos(age * 91.0) * impact, 0.0)

func player_indicator(index: int) -> Dictionary:
 var point = camera.unproject_position(athletes[index].root.position+Vector3(0,1.2,0))
 var bounds = Rect2(30,40,1220,490)
 var edge = point.clamp(bounds.position,bounds.end)
 return {"visible":not bounds.has_point(point),"point":edge,"direction":(point-edge).normalized()}

func court_point(point: Vector2, height: float = 0.0) -> Vector3:
 return Vector3((point.x-640.0)*COURT_SCALE.x,height,(point.y-470.0)*COURT_SCALE.y)

func movement_facing_angle(velocity: Vector2) -> float:
 # Simulation X/Y maps to world X/Z at different scales, so derive heading
 # from the actual rendered direction instead of the unscaled 2D vector.
 var world_velocity = Vector3(velocity.x * COURT_SCALE.x, 0.0, velocity.y * COURT_SCALE.y)
 return atan2(world_velocity.x, world_velocity.z)

func material(color: Color, roughness: float = 0.7, glow: bool = false) -> StandardMaterial3D:
 var key = str(color)+str(roughness)+str(glow)
 if materials.has(key):
  return materials[key]
 var mat = StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = roughness
 if glow:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = 0.7
 materials[key] = mat
 return mat

func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material, node_name: String = "") -> MeshInstance3D:
 var object = MeshInstance3D.new()
 object.mesh = shape
 object.material_override = mat
 object.position = at
 if not node_name.is_empty():
  object.name = node_name
 parent.add_child(object)
 return object

func box(parent: Node3D, dimensions: Vector3, at: Vector3, mat: Material, node_name: String = "") -> MeshInstance3D:
 var shape = BoxMesh.new()
 shape.size = dimensions
 return mesh(parent,shape,at,mat,node_name)

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, sides: int = 8) -> MeshInstance3D:
 var shape = CylinderMesh.new()
 shape.top_radius = radius
 shape.bottom_radius = radius
 shape.height = a.distance_to(b)
 shape.radial_segments = sides
 shape.rings = 1
 var object = mesh(parent,shape,(a+b)*0.5,mat)
 object.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
 return object

func ring(parent: Node3D, radius: float, thickness: float, at: Vector3, mat: Material, segments: int = 40) -> MeshInstance3D:
 var shape = TorusMesh.new()
 shape.inner_radius = radius-thickness
 shape.outer_radius = radius+thickness
 shape.rings = segments
 shape.ring_segments = 6
 return mesh(parent,shape,at,mat)

func label_3d(parent: Node3D, text: String, at: Vector3, size_pixels: float = 0.008, color: Color = Color.WHITE, billboard: bool = true) -> Label3D:
 var label = Label3D.new()
 label.text = text
 label.font_size = 48
 label.pixel_size = size_pixels
 label.modulate = color
 label.outline_modulate = Color("101725")
 label.outline_size = 9
 label.position = at
 if billboard:
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 parent.add_child(label)
 return label

func build_lighting() -> void:
 var environment = WorldEnvironment.new()
 var settings = Environment.new()
 settings.background_mode = Environment.BG_COLOR
 settings.background_color = Color("0b1323")
 settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color = Color("b2c4e4")
 settings.ambient_light_energy = 0.32
 settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
 environment.environment = settings
 world.add_child(environment)
 var key = DirectionalLight3D.new()
 key.name = "ArenaKeyLight"
 key.rotation_degrees = Vector3(-64,-32,0)
 key.light_color = Color("fff0d9")
 key.light_energy = 0.8
 key.shadow_enabled = true
 key.directional_shadow_max_distance = 65
 world.add_child(key)
 var fill = DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(-35,140,0)
 fill.light_color = Color("a9c6ff")
 fill.light_energy = 0.24
 world.add_child(fill)

func hardwood_texture() -> ImageTexture:
 var image = Image.create(512,512,false,Image.FORMAT_RGB8)
 for y in range(512):
  var row = y / 64
  var shifted_x = (row % 2) * 128
  for x in range(512):
   var plank = (x+shifted_x) / 256
   var tone = sin(float(row*19+plank*37))*0.045
   var grain = sin(y*1.8+sin(x*0.022)*1.4)*0.012 + sin(y*0.63+sin(x*0.013)*2.0)*0.018
   var color = Color(0.70+tone+grain,0.435+tone+grain,0.215+tone*0.7+grain)
   if y % 64 < 2 or (x+shifted_x) % 256 < 2:
    color = color.darkened(0.24)
   elif y % 64 == 3:
    color = color.lightened(0.1)
   image.set_pixel(x,y,color)
 return ImageTexture.create_from_image(image)

func shadow_texture() -> ImageTexture:
 if cached_shadow_texture != null:
  return cached_shadow_texture
 var img = Image.create(64,64,false,Image.FORMAT_RGBA8)
 var center = Vector2(31.5,31.5)
 for y in range(64):
  for x in range(64):
   var dist = center.distance_to(Vector2(x,y)) / 31.5
   if dist >= 1.0:
    img.set_pixel(x,y,Color(0,0,0,0))
   else:
    var a = pow(1.0-dist,1.8)*0.62
    img.set_pixel(x,y,Color(0,0,0,a))
 cached_shadow_texture = ImageTexture.create_from_image(img)
 return cached_shadow_texture

func trigger_flashbulbs(count: int = 4) -> void:
 var triggered = 0
 for fb in flashbulbs:
  if fb.timer <= 0.0:
   fb.timer = 0.08
   triggered += 1
   if triggered >= count:
    break

func line(points: Array, width: float, mat: Material, height: float = 0.027) -> void:
 var geometry = ImmediateMesh.new()
 geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()-1):
  var a: Vector3 = points[i]
  var b: Vector3 = points[i+1]
  a.y = height
  b.y = height
  var normal = Vector3(-(b-a).z,0,(b-a).x).normalized()*width*0.5
  for vertex in [a-normal,b+normal,a+normal,a-normal,b-normal,b+normal]:
   geometry.surface_set_normal(Vector3.UP)
   geometry.surface_add_vertex(vertex)
 geometry.surface_end()
 var object = mesh(world,geometry,Vector3.ZERO,mat)
 object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func court_line(points: Array, width: float, mat: Material) -> void:
 var mapped: Array = []
 for point in points:
  mapped.append(court_point(point))
 line(mapped,width,mat)

func court_arc(center: Vector2, radius: float, start: float, end: float, mat: Material, width: float = 0.055) -> void:
 var points: Array = []
 for i in range(81):
  var angle = lerpf(start,end,float(i)/80.0)
  points.append(center+Vector2(cos(angle),sin(angle))*radius)
 court_line(points,width,mat)

func build_court() -> void:
 var dark = material(Color("101f33"))
 box(world,Vector3(46,0.3,35),Vector3(0,-0.33,-1.0),dark,"ArenaFloor")
 box(world,Vector3(31,0.28,17),Vector3(0,-0.15,0),material(Color("25384b")),"CourtApron")
 box(world,Vector3(28,0.12,15),Vector3(0,-0.07,0),material(Color("744b2e")),"RectangularCourt")
 var surface = PlaneMesh.new()
 surface.size = Vector2(28,15)
 wood_material = StandardMaterial3D.new()
 wood_material.albedo_texture = hardwood_texture()
 wood_material.albedo_texture_force_srgb = false
 wood_material.texture_repeat = true
 wood_material.uv1_scale = Vector3(6,3,1)
 wood_material.roughness = 0.38
 wood_material.metallic_specular = 0.35
 mesh(world,surface,Vector3.ZERO,wood_material,"RepeatingHardwood")
 var white = material(Color("fff0d4"),0.65)
 white.cull_mode = BaseMaterial3D.CULL_DISABLED
 court_line([Vector2(115,265),Vector2(1165,265),Vector2(1165,675),Vector2(115,675),Vector2(115,265)],0.075,white)
 court_line([Vector2(640,265),Vector2(640,675)],0.06,white)
 court_arc(Vector2(640,465),74,0,TAU,white)
 var center = CylinderMesh.new()
 center.top_radius = 1.42
 center.bottom_radius = 1.42
 center.height = 0.005
 center.radial_segments = 64
 mesh(world,center,court_point(Vector2(640,465),0.009),material(Color("24394a")))
 var mark = label_3d(world,"RIM\nRUMBLE",court_point(Vector2(640,465),0.023),0.012,Color("f0cf8d"),false)
 mark.rotation_degrees.x = -90
 mark.outline_size = 0
 for side in range(2):
  var hoop: Vector2 = MatchState.HOOPS[side]
  var start_x = 115 if side == 0 else 955
  var a = court_point(Vector2(start_x,375))
  var b = court_point(Vector2(start_x+210,555))
  box(world,Vector3(b.x-a.x,0.008,b.z-a.z),(a+b)*0.5+Vector3(0,0.008,0),material(Color("26465b") if side == 0 else Color("4b3453")),"PaintedKey")
  court_line([Vector2(start_x,375),Vector2(start_x+210,375),Vector2(start_x+210,555),Vector2(start_x,555),Vector2(start_x,375)],0.055,white)
  court_arc(Vector2(325 if side == 0 else 955,465),62,-PI/2 if side == 0 else PI/2,PI/2 if side == 0 else 3*PI/2,white)
  var three_point = MatchState.three_point_geometry(side)
  court_arc(three_point.hoop,three_point.radius,three_point.arc_start,three_point.arc_end,white)
  court_line([Vector2(three_point.baseline_x,three_point.top_y),Vector2(three_point.arc_join_x,three_point.top_y)],0.055,white)
  court_line([Vector2(three_point.baseline_x,three_point.bottom_y),Vector2(three_point.arc_join_x,three_point.bottom_y)],0.055,white)
 var sideline = label_3d(world,"R I M   R U M B L E   /   A R C A D E   B A S K E T B A L L",Vector3(0,0.02,8.0),0.008,Color("a6b3c5"),false)
 sideline.rotation_degrees.x = -90
 sideline.outline_size = 0

func build_basket(side: int) -> void:
 var group = Node3D.new()
 group.name = "LeftBasket" if side == -1 else "RightBasket"
 world.add_child(group)
 var center = court_point(MatchState.HOOPS[0 if side == -1 else 1],3.05)
 var metal = material(Color("b6c1cf"),0.28)
 var padding = material(Color("132d49"))
 var orange = material(Color("f45b24"),0.32)
 var net_material = material(Color("e9e8db"))
 var pole_x = side*15.15
 box(group,Vector3(1.5,0.46,1.7),Vector3(pole_x,0.23,center.z),padding,"WeightedBase")
 rod(group,Vector3(pole_x,0.4,center.z),Vector3(pole_x,3.8,center.z),0.13,metal)
 box(group,Vector3(0.48,1.85,0.60),Vector3(pole_x,1.18,center.z),padding,"PolePadding")
 box(group,Vector3(0.495,0.11,0.61),Vector3(pole_x,1.8,center.z),orange)
 var board_x = center.x+side*0.64
 rod(group,Vector3(pole_x,3.8,center.z),Vector3(board_x,3.65,center.z),0.09,metal)
 rod(group,Vector3(pole_x,2.5,center.z),Vector3(board_x,3.45,center.z),0.06,metal)
 var glass = material(Color(0.69,0.83,0.87,0.36),0.17)
 glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 glass.cull_mode = BaseMaterial3D.CULL_DISABLED
 box(group,Vector3(0.07,1.18,1.94),Vector3(board_x,3.54,center.z),glass,"GlassBackboard")
 for z in [-0.97,0.97]:
  box(group,Vector3(0.1,1.22,0.05),Vector3(board_x,3.54,center.z+z),net_material)
 for y in [2.95,4.13]:
  box(group,Vector3(0.1,0.05,1.99),Vector3(board_x,y,center.z),net_material)
 var target_x = board_x-side*0.06
 var target_marks = Node3D.new()
 target_marks.name = "TargetMarkings"
 group.add_child(target_marks)
 for z in [-0.34,0.34]:
  box(target_marks,Vector3(0.026,0.51,0.035),Vector3(target_x,3.35,center.z+z),net_material)
 for y in [3.095,3.605]:
  box(target_marks,Vector3(0.026,0.035,0.715),Vector3(target_x,y,center.z),net_material)
 var rim_rod = rod(group,Vector3(board_x,3.05,center.z),center,0.045,orange)
 var orange_rim = ring(group,0.43,0.035,center,orange,36)
 orange_rim.name = "OrangeRim"
 rim_nodes.append(orange_rim)
 rim_rods.append({"rod": rim_rod, "board_pos": Vector3(board_x,3.05,center.z), "center": center})
 var net_rings: Array = []
 var base_ring_radii = [0.43, lerpf(0.43,0.27,1.0/3.0), lerpf(0.43,0.27,2.0/3.0), 0.27]
 for layer in range(4):
  var t = float(layer)/3.0
  var r_node = ring(group,base_ring_radii[layer],0.009,center-Vector3(0,t*0.62,0),net_material,24)
  net_rings.append(r_node)
 var net_strands: Array = []
 for strand in range(12):
  var angle = TAU*strand/12.0
  var top = center+Vector3(cos(angle)*0.43,0,sin(angle)*0.43)
  var mid = center+Vector3(cos(angle+0.15)*0.34,-0.31,sin(angle+0.15)*0.34)
  var bottom = center+Vector3(cos(angle)*0.27,-0.62,sin(angle)*0.27)
  var cross_mid = center+Vector3(cos(angle-0.15)*0.34,-0.31,sin(angle-0.15)*0.34)
  var r1 = rod(group,top,mid,0.009,net_material,4)
  var r2 = rod(group,mid,bottom,0.009,net_material,4)
  var r3 = rod(group,top,cross_mid,0.009,net_material,4)
  var r4 = rod(group,cross_mid,bottom,0.009,net_material,4)
  net_strands.append({"angle": angle, "r1": r1, "r2": r2, "r3": r3, "r4": r4})
 var net_dict = {
  "center": center,
  "side": side,
  "rings": net_rings,
  "base_radii": base_ring_radii,
  "strands": net_strands,
  "swish_time": 10.0,
  "swish_dir": Vector3.ZERO,
  "is_dirty": false
 }
 build_glass_shards(group,Vector3(board_x,3.54,center.z),side,target_marks,net_dict)

func build_glass_shards(group: Node3D, center: Vector3, side: int, target_marks: Node3D, net_dict: Dictionary = {}) -> void:
 var pieces = Node3D.new()
 pieces.name = "GlassShards"
 group.add_child(pieces)
 pieces.visible = false
 var shard_mat = material(Color(0.55,0.85,1.0,0.82),0.15,true)
 shard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 shard_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 var random = RandomNumberGenerator.new()
 random.seed = 1993+side
 var shards: Array = []
 # Triangles tile the original glass plane, then fly independently.
 for row in range(5):
  for column in range(7):
   var y = -0.59+float(row)*1.18/5.0
   var z = -0.97+float(column)*1.94/7.0
   var corners = [Vector3(0,y,z),Vector3(0,y+1.18/5.0,z),Vector3(0,y+1.18/5.0,z+1.94/7.0),Vector3(0,y,z+1.94/7.0)]
   for indices in [[0,1,2],[0,2,3]]:
    var origin: Vector3 = (corners[indices[0]]+corners[indices[1]]+corners[indices[2]])/3.0
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([corners[indices[0]]-origin,corners[indices[1]]-origin,corners[indices[2]]-origin])
    arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3(side,0,0),Vector3(side,0,0),Vector3(side,0,0)])
    var shape = ArrayMesh.new()
    shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var piece = mesh(pieces,shape,center+origin,shard_mat)
    piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    shards.append({"mesh":piece,"origin":center+origin,"velocity":Vector3(-side*random.randf_range(1.4,4.5),random.randf_range(1.0,4.0),origin.z*3.0+random.randf_range(-2.0,2.0)),"spin":Vector3(random.randf_range(-8,8),random.randf_range(-8,8),random.randf_range(-8,8))})
 baskets.append({"glass":group.get_node("GlassBackboard"),"target":target_marks,"pieces":pieces,"shards":shards,"net":net_dict})

func update_rod(object: MeshInstance3D, a: Vector3, b: Vector3) -> void:
 var diff = b - a
 var dist = diff.length()
 if dist < 0.0001:
  object.visible = false
  return
 object.visible = true
 object.position = (a + b) * 0.5
 var dir = diff / dist
 var cyl = object.mesh as CylinderMesh
 if cyl != null and cyl.height > 0.0001:
  object.scale = Vector3(1.0, dist / cyl.height, 1.0)
 if absf(dir.dot(Vector3.UP)) > 0.999:
  object.quaternion = Quaternion.IDENTITY if dir.y > 0 else Quaternion(Vector3.RIGHT, PI)
 else:
  object.quaternion = Quaternion(Vector3.UP, dir)

func get_net_swirl_amount(u: float) -> float:
 if u <= 0.0:
  return 0.0
 elif u < 0.28:
  return sin((u / 0.28) * (PI * 0.5))
 elif u < 0.52:
  var p = (u - 0.28) / 0.24
  return cos(p * (PI * 0.5))
 elif u < 1.0:
  var p = (u - 0.52) / 0.48
  return -0.32 * sin(p * PI * 3.0) * exp(-p * 5.0)
 else:
  return 0.0

func trigger_net_swish(b_idx: int, dir: Vector3) -> void:
 if b_idx < 0 or b_idx >= baskets.size():
  return
 var net_data: Dictionary = baskets[b_idx].get("net", {})
 if net_data.is_empty():
  return
 net_data.swish_time = 0.0
 net_data.swish_dir = dir

func update_net(net_data: Dictionary, delta: float, paused: bool) -> void:
 if net_data.is_empty():
  return
 if not paused and net_data.swish_time < 1.5:
  net_data.swish_time += delta
 if net_data.swish_time >= 1.0:
  if net_data.get("is_dirty", false):
   net_data.is_dirty = false
   _apply_net_pose(net_data, 0.0, Vector3.ZERO)
  return
 net_data.is_dirty = true
 var u = clampf(net_data.swish_time / 0.85, 0.0, 1.0)
 var swirl = get_net_swirl_amount(u)
 _apply_net_pose(net_data, swirl, net_data.swish_dir)

func _apply_net_pose(net_data: Dictionary, swirl: float, dir: Vector3) -> void:
 var center: Vector3 = net_data.center
 var side: int = net_data.side
 var swirl_pos = maxf(0.0, swirl)
 if dir.length() < 0.01:
  dir = Vector3(side, 0, 0)
 dir = dir.normalized()

 var shift_mid = dir * (0.08 * swirl_pos)
 var r_mid = 0.34 + 0.12 * swirl_pos
 var y_mid = -0.31 + 0.08 * swirl
 var d_theta_mid = 0.18 * swirl

 var shift_bot = dir * (0.16 * swirl_pos)
 var r_bot = 0.27 + 0.24 * swirl_pos
 var y_bot = -0.62 + 0.38 * swirl
 var d_theta_bot = 0.48 * swirl

 var rings: Array = net_data.rings
 var base_radii: Array = net_data.base_radii

 rings[0].position = center
 rings[0].scale = Vector3.ONE
 rings[0].quaternion = Quaternion.IDENTITY

 var r1 = lerpf(0.43, 0.27, 1.0/3.0) + 0.06 * swirl_pos
 rings[1].position = center + dir * (0.03 * swirl_pos) + Vector3(0, -0.207 - 0.02 * swirl_pos, 0)
 var sc1 = r1 / base_radii[1]
 rings[1].scale = Vector3(sc1, 1.0, sc1)
 rings[1].quaternion = Quaternion.IDENTITY

 var r2 = lerpf(0.43, 0.27, 2.0/3.0) + 0.16 * swirl_pos
 rings[2].position = center + shift_mid + Vector3(0, -0.413 + 0.14 * swirl, 0)
 var sc2 = r2 / base_radii[2]
 rings[2].scale = Vector3(sc2, 1.0, sc2)
 rings[2].quaternion = Quaternion.IDENTITY

 var sc3 = r_bot / base_radii[3]
 rings[3].position = center + shift_bot + Vector3(0, y_bot, 0)
 rings[3].scale = Vector3(sc3, 1.0, sc3)
 var ring_normal = (Vector3.UP + dir * (0.60 * swirl_pos)).normalized()
 rings[3].quaternion = Quaternion(Vector3.UP, ring_normal)

 for strand in net_data.strands:
  var angle: float = strand.angle
  var top = center + Vector3(cos(angle) * 0.43, 0.0, sin(angle) * 0.43)
  var a_mid = angle + 0.15 + d_theta_mid
  var mid = center + shift_mid + Vector3(cos(a_mid) * r_mid, y_mid, sin(a_mid) * r_mid)
  var a_cross = angle - 0.15 + d_theta_mid
  var cross_mid = center + shift_mid + Vector3(cos(a_cross) * r_mid, y_mid, sin(a_cross) * r_mid)

  var dir_dot = Vector3(cos(angle), 0, sin(angle)).dot(dir)
  var directional_bias = maxf(0.0, dir_dot)
  var strand_r_bot = r_bot + 0.06 * directional_bias * swirl_pos
  var strand_y_bot = y_bot + 0.05 * directional_bias * swirl
  var a_bot = angle + d_theta_bot
  var bottom = center + shift_bot + Vector3(cos(a_bot) * strand_r_bot, strand_y_bot, sin(a_bot) * strand_r_bot)

  update_rod(strand.r1, top, mid)
  update_rod(strand.r2, mid, bottom)
  update_rod(strand.r3, top, cross_mid)
  update_rod(strand.r4, cross_mid, bottom)

func update_backboards(state: MatchState) -> void:
 for side in range(2):
  var basket: Dictionary = baskets[side]
  var broken: bool = state.board_breaks[side] >= 0
  basket.glass.visible = not broken
  basket.target.visible = not broken
  var age = maxf(0,state.elapsed-state.board_breaks[side])
  basket.pieces.visible = broken and age < 6.0
  if not basket.pieces.visible:
   continue
  var t = minf(age,1.8)
  for shard in basket.shards:
   var position: Vector3 = shard.origin+shard.velocity*t-Vector3(0,4*t*t,0)
   var grounded = position.y <= 0.035
   position.y = maxf(0.035,position.y)
   shard.mesh.position = position
   if grounded:
    shard.mesh.basis = Basis(Vector3.UP,shard.spin.y*t)*Basis(Vector3.BACK,PI/2)
   else:
    shard.mesh.rotation = shard.spin*t
   shard.mesh.transparency = clampf((age-4.0)/2.0,0,1)

func build_stands() -> void:
 var riser = material(Color("192637"))
 for row in range(7):
  box(world,Vector3(39,0.45+row*0.52,1.15),Vector3(0,(-0.05+row*0.52)*0.5,-9.2-row*1.08),riser)
  box(world,Vector3(39,0.12,0.4),Vector3(0,0.55+row*0.52,-9.5-row*1.08),material(Color("33475d")))
 for side in [-1,1]:
  for row in range(4):
   box(world,Vector3(1.1,0.4+row*0.56,14),Vector3(side*(17+row*1.05),row*0.28,-0.5),riser)
 box(world,Vector3(40,0.95,0.30),Vector3(0,0.48,-8.35),material(Color("0b1b2d")))
 for i in range(5):
  var x = -15.5+i*7.75
  var color = Color("fdad56") if i%2 == 0 else Color("70cdf1")
  box(world,Vector3(7.3,0.05,0.05),Vector3(x,0.93,-8.13),material(color,0.7,true))
  label_3d(world,["RIM RUMBLE","NO FOULS. ALL FIRE.","2 ON 2","BOOMSHAKA!","RIM RUMBLE"][i],Vector3(x,0.49,-8.16),0.007,color,false)

# Generate an eight-person, four-frame cheering atlas, with transparent silhouettes.
func image_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
 for y in range(-radius,radius+1):
  for x in range(-radius,radius+1):
   if x*x+y*y <= radius*radius:
    var point = center+Vector2i(x,y)
    if point.x >= 0 and point.x < image.get_width() and point.y >= 0 and point.y < image.get_height():
     image.set_pixelv(point,color)

func image_line(image: Image, a: Vector2i, b: Vector2i, radius: int, color: Color) -> void:
 var steps = maxi(absi(a.x-b.x),absi(a.y-b.y))+1
 for step in range(steps):
  image_circle(image,Vector2i(Vector2(a).lerp(Vector2(b),float(step)/steps)),radius,color)

func crowd_atlas() -> ImageTexture:
 var image = Image.create(256,768,false,Image.FORMAT_RGBA8)
 image.fill(Color.TRANSPARENT)
 var shirts = [Color("d34d40"),Color("dfae54"),Color("3f8abb"),Color("6577c9"),Color("43a991"),Color("d6d2bb"),Color("c65e91"),Color("748498")]
 var skins = [Color("d99b6c"),Color("9d6345"),Color("f0c499"),Color("b7815b")]
 for person in range(8):
  for frame in range(4):
   var origin = Vector2i(frame*64,person*96)
   var bounce = [0,-3,-5,-2][frame]
   var skin: Color = skins[person%4]
   var shirt: Color = shirts[person]
   # Seated legs and sneakers remain grounded while the torso cheers.
   image_line(image,origin+Vector2i(25,66),origin+Vector2i(21,87),5,Color("263449"))
   image_line(image,origin+Vector2i(39,66),origin+Vector2i(44,87),5,Color("263449"))
   image_line(image,origin+Vector2i(16,89),origin+Vector2i(24,89),3,Color("bec4c8"))
   image_line(image,origin+Vector2i(40,89),origin+Vector2i(49,89),3,Color("bec4c8"))
   image.fill_rect(Rect2i(origin+Vector2i(20,35+bounce),Vector2i(25,34)),shirt)
   image_circle(image,origin+Vector2i(32,23+bounce),11,skin)
   image_line(image,origin+Vector2i(23,17+bounce),origin+Vector2i(40,16+bounce),4,Color("25232c"))
   var arm_height: int = [48,25,8,25][frame]
   var spread: int = [11,9,13,18][frame]
   image_line(image,origin+Vector2i(21,39+bounce),origin+Vector2i(spread,arm_height+bounce),4,skin)
   image_line(image,origin+Vector2i(44,39+bounce),origin+Vector2i(64-spread,arm_height+bounce),4,skin)
   image_circle(image,origin+Vector2i(28,24+bounce),1,Color("25232c"))
   image_circle(image,origin+Vector2i(36,24+bounce),1,Color("25232c"))
   image_line(image,origin+Vector2i(30,30+bounce),origin+Vector2i(34,30+bounce),1,Color("673626"))
 return ImageTexture.create_from_image(image)

func build_crowd() -> void:
 crowd = MultiMeshInstance3D.new()
 crowd.name = "AnimatedBillboardCrowd"
 var quad = QuadMesh.new()
 quad.size = Vector2(0.88,1.38)
 var shader = Shader.new()
 shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D crowd_texture : source_color, filter_nearest, repeat_disable;
varying vec4 spectator;
void vertex() {
 spectator = INSTANCE_CUSTOM;
 vec3 object_scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 mat4 facing = MODELVIEW_MATRIX;
 facing[0] = vec4(object_scale.x,0.0,0.0,0.0);
 facing[1] = vec4(0.0,object_scale.y,0.0,0.0);
 facing[2] = vec4(0.0,0.0,object_scale.z,0.0);
 MODELVIEW_MATRIX = facing;
}
void fragment() {
 float frame = floor(mod(TIME * 5.5 + spectator.x,4.0));
 vec2 atlas_uv = vec2((UV.x+frame)/4.0,(UV.y+floor(spectator.y))/8.0);
 vec4 person = texture(crowd_texture,atlas_uv);
 if (person.a < 0.5) { discard; }
 ALBEDO = person.rgb * spectator.z;
}
"""
 var mat = ShaderMaterial.new()
 mat.shader = shader
 mat.set_shader_parameter("crowd_texture",crowd_atlas())
 quad.material = mat
 var instances = MultiMesh.new()
 instances.transform_format = MultiMesh.TRANSFORM_3D
 instances.use_custom_data = true
 instances.mesh = quad
 instances.instance_count = 464
 var random = RandomNumberGenerator.new()
 random.seed = 1988
 var index = 0
 for row in range(7):
  for col in range(48):
   var pos = Vector3(-18.3+col*0.78+(row%2)*0.16,1.1+row*0.52,-9.1-row*1.08)
   instances.set_instance_transform(index,Transform3D(Basis.IDENTITY,pos))
   instances.set_instance_custom_data(index,Color(random.randf_range(0,4),random.randi_range(0,7),0.75-row*0.035,1))
   index += 1
 for side in [-1,1]:
  for row in range(4):
   for col in range(16):
    var pos = Vector3(side*(17+row*1.05),1.0+row*0.56,-6.5+col*0.80)
    instances.set_instance_transform(index,Transform3D(Basis.IDENTITY,pos))
    instances.set_instance_custom_data(index,Color(random.randf_range(0,4),random.randi_range(0,7),0.70-row*0.035,1))
    index += 1
 crowd.multimesh = instances
 crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 world.add_child(crowd)
 flashbulbs.clear()
 for fb_i in range(18):
  var flash = MeshInstance3D.new()
  var fb_mesh = QuadMesh.new()
  fb_mesh.size = Vector2(0.44,0.44)
  flash.mesh = fb_mesh
  var fb_mat = StandardMaterial3D.new()
  fb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  fb_mat.albedo_color = Color(1.0,1.0,1.0,0.0)
  fb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  fb_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
  fb_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
  flash.material_override = fb_mat
  flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var fb_pos = Vector3.ZERO
  if fb_i < 12:
   var row = fb_i % 6
   var col_x = -16.0 + float(fb_i) * 2.8 + random.randf_range(-0.5, 0.5)
   fb_pos = Vector3(col_x, 1.4 + row * 0.52, -9.3 - row * 1.08)
  else:
   var s = -1 if fb_i < 15 else 1
   var row = (fb_i - 12) % 3
   fb_pos = Vector3(s * (17.5 + row * 1.05), 1.6 + row * 0.56, -4.0 + float(row) * 2.5)
  flash.position = fb_pos
  world.add_child(flash)
  flashbulbs.append({"mesh": flash, "material": fb_mat, "timer": 0.0, "cooldown": random.randf_range(0.4, 3.2)})

func build_athlete(index: int) -> Dictionary:
 var root = Node3D.new()
 root.name = "Athlete%d" % index
 world.add_child(root)
 var body = HYMotionRig.new()
 body.name = "HYMotionPlayer"
 root.add_child(body)
 body.initialize(self,index)
 var marker = ring(root,0.57,0.035,Vector3(0,0.035,0),material(GOLD,0.7,true),32)
 var name_label = label_3d(root,"",Vector3(0,2.38,0),0.007,Color("f8eed9"))
 var control_label = label_3d(root,"",Vector3(0,2.72,0),0.0065,GOLD)
 var aim_root = Node3D.new()
 aim_root.name = "AimIndicator"
 aim_root.visible = false
 root.add_child(aim_root)
 var aim_ring = ring(aim_root,0.44,0.024,Vector3(0,0.038,0),material(Color("2eff82"),0.5,true),32)
 var aim_outer = ring(aim_root,0.68,0.016,Vector3(0,0.038,0),material(Color("10d970"),0.6,true),32)
 var aim_pips: Array = []
 var pip_mat = material(Color("70ffb0"),0.4,true)
 for pip_idx in range(4):
  var angle = pip_idx * TAU / 4.0
  var pip_pos = Vector3(cos(angle) * 0.56, 0.038, sin(angle) * 0.56)
  var tick = box(aim_root, Vector3(0.14, 0.012, 0.028) if (pip_idx % 2 == 0) else Vector3(0.028, 0.012, 0.14), pip_pos, pip_mat)
  aim_pips.append(tick)
 var aim_label = label_3d(root,"",Vector3(0,3.02,0),0.0065,Color("2eff82"))
 aim_label.visible = false
 var fire: Array = []
 for flame in range(5):
  var shape = PrismMesh.new()
  shape.size = Vector3(0.28,0.8,0.28)
  var object = mesh(root,shape,Vector3.ZERO,material(Color("ff772c") if flame%2 else GOLD,0.7,true))
  object.visible = false
  object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  fire.append(object)
 var shadow_mat = StandardMaterial3D.new()
 shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 shadow_mat.albedo_texture = shadow_texture()
 shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 shadow_mat.albedo_color = Color(0,0,0,0.60)
 var shadow_quad = QuadMesh.new()
 shadow_quad.size = Vector2(1.15,0.72)
 shadow_quad.orientation = PlaneMesh.FACE_Y
 var shadow = MeshInstance3D.new()
 shadow.name = "FloorShadow"
 shadow.mesh = shadow_quad
 shadow.material_override = shadow_mat
 shadow.position = Vector3(0,0.005,0)
 shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 root.add_child(shadow)
 return {"root":root,"body":body,"head":body.head,"skeleton":body.skeleton,"arms":[body.attach(16),body.attach(17)],"legs":[body.attach(1),body.attach(2)],"jersey":body.jersey,"shorts":body.shorts,"marker":marker,"label":name_label,"control":control_label,"fire":fire,"mesh_parts":collect_mesh_parts(body),"aim_indicator":aim_root,"aim_ring":aim_ring,"aim_outer":aim_outer,"aim_pips":aim_pips,"aim_label":aim_label,"shadow":shadow,"shadow_mat":shadow_mat}

func collect_mesh_parts(node: Node) -> Array:
 var parts: Array = []
 for child in node.get_children():
  if child is MeshInstance3D:
   parts.append({"mesh":child,"material":child.material_override})
  parts.append_array(collect_mesh_parts(child))
 return parts

func build_ball() -> void:
 basketball = Node3D.new()
 basketball.name = "Basketball"
 world.add_child(basketball)
 var shape = SphereMesh.new()
 shape.radius = 0.235
 shape.height = 0.47
 shape.radial_segments = 16
 shape.rings = 8
 mesh(basketball,shape,Vector3.ZERO,material(Color("e8782f"),0.82))
 var seam = material(Color("492a20"))
 for axis in range(3):
  var seam_ring = ring(basketball,0.236,0.007,Vector3.ZERO,seam,32)
  if axis == 1:
   seam_ring.rotation.x = PI/2
  if axis == 2:
   seam_ring.rotation.z = PI/2
 var b_shadow_mat = StandardMaterial3D.new()
 b_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 b_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 b_shadow_mat.albedo_texture = shadow_texture()
 b_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 b_shadow_mat.albedo_color = Color(0,0,0,0.55)
 var b_shadow_quad = QuadMesh.new()
 b_shadow_quad.size = Vector2(0.55,0.55)
 b_shadow_quad.orientation = PlaneMesh.FACE_Y
 ball_shadow = MeshInstance3D.new()
 ball_shadow.name = "BasketballShadow"
 ball_shadow.mesh = b_shadow_quad
 ball_shadow.material_override = b_shadow_mat
 ball_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 ball_shadow.position = Vector3(0,0.006,0)
 world.add_child(ball_shadow)
 for i in range(8):
  var flame = SphereMesh.new()
  flame.radius = 0.22
  flame.height = 0.65
  flame.radial_segments = 6
  flame.rings = 3
  var ember = mesh(world,flame,Vector3.ZERO,material(GOLD if i < 3 else Color("ff6622"),0.7,true))
  ember.name = "FireBallTrail%d" % i
  ember.visible = false
  ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  ball_fire.append(ember)
 for i in range(10):
  var sphere = SphereMesh.new()
  sphere.radius = 0.16
  sphere.height = 0.32
  sphere.radial_segments = 6
  sphere.rings = 3
  var trail_particle = mesh(world,sphere,Vector3.ZERO,material(Color("70dcff"),0.5,true))
  trail_particle.name = "BallTrail%d" % i
  trail_particle.visible = false
  trail_particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  ball_trail.append(trail_particle)

func present(state: MatchState, positions: Array, ball: Vector2, controlled_slots: Array, delta: float, paused: bool) -> void:
 render_target_update_mode = SubViewport.UPDATE_ALWAYS
 if not paused:
  time += delta
 var motion_delta = delta * state.gameplay_time_scale()
 if last_teams != state.teams:
  last_teams = state.teams.duplicate()
  for i in range(4):
   var color = Teams.color_for(state.teams[i/2])
   athletes[i].jersey.albedo_color = color
   athletes[i].shorts.albedo_color = color.darkened(0.25)
   athletes[i].label.text = Teams.DATA[state.teams[i/2]].players[i%2]
 for i in range(4):
  var p: Dictionary = state.players[i]
  var actor: Dictionary = athletes[i]
  var flash_white = p.get("possession_flash", 0.0) > 0.0 and int(time / 0.075) % 2 == 0
  for part in actor.mesh_parts:
   part.mesh.material_override = possession_flash_material if flash_white else part.material
  var point: Vector2 = positions[i] if positions.size() == 4 else p.pos
  actor.root.position = court_point(point)
  var jump = 0.0
  if not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.shooter == i and state.flight.has("player_start"):
   var progress = clampf(state.flight.time/state.flight.duration,0,1)
   var launch: float = state.flight.get("player_launch_height",0.0)
   var peak = 4.2 if state.is_player_on_fire(i) else (2.85 if state.flight.get("super_dunk",false) else 1.8 if state.flight.dunk else 1.15)
   jump = lerpf(launch,0,progress)+sin(progress*PI)*(peak-launch*0.5)
  elif not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.shooter == i:
   if p.jump > 0.0:
    jump = sin(clampf((1.16 - p.jump) / 1.16, 0.0, 1.0) * PI) * 1.35
   else:
    jump = 0.0
  elif p.receive_jump > 0:
   jump = state.receive_height(i)
  elif p.charge > 0:
   jump = sin(clampf(p.charge / 1.16, 0.0, 1.0) * PI) * 1.35
  elif p.jump > 0:
   var t = 1.0 - clampf(p.jump / 0.70, 0.0, 1.0)
   if t <= 0.20:
    jump = 0.0
   else:
    var jp = (t - 0.20) / 0.80
    jump = sin(jp * PI) * 2.85
  var tip_jump = -1.0
  if not state.tipoff.is_empty() and i%2 == 0 and state.tipoff.jumps[i/2] >= 0:
   var age: float = state.elapsed-state.tipoff.started_at-state.tipoff.jumps[i/2]
   if age >= 0 and age < 0.62:
    tip_jump = age/0.62
    jump = sin(tip_jump*PI)*1.6
  actor.body.position.y = maxf(0,jump)
  var running = clampf(p.vel.length() / 420.0, 0, 1)
  var is_stunned = p.stun > 0.0
  var is_running = p.vel.length() > 8 and not is_stunned
  var is_shot_actor = not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.shooter == i
  var is_dunking = (is_shot_actor and state.flight.get("dunk", false)) or p.get("rim_hang", 0.0) > 0.0
  var dunk_style = state.flight.get("dunk_style", "standard") if (not state.flight.is_empty() and state.flight.get("dunk", false)) else "standard"
  var dunk_p = clampf(state.flight.time / state.flight.duration, 0.0, 1.0) if not state.flight.is_empty() else 1.0
  if p.get("rim_hang", 0.0) > 0.0:
   actor.body.position.y = 1.35
  var hoop_dir = state.hoop_for(i/2) - p.pos
  var target_angle = movement_facing_angle(hoop_dir) if (is_shot_actor or p.get("rim_hang", 0.0) > 0.0) else (movement_facing_angle(p.vel) if is_running else (PI/2 if p.face > 0 else -PI/2))
  var faces_ball_for_block = p.jump > 0 and p.receive_jump <= 0 and tip_jump < 0 and not is_shot_actor
  # Locomotion must point along travel immediately; smoothing here made athletes
  # visibly run backward while their body caught up after a direction change.
  actor.body.rotation.y = target_angle if (is_running or is_shot_actor or p.get("rim_hang", 0.0) > 0.0) else lerp_angle(actor.body.rotation.y,target_angle,1.0-exp(-motion_delta*15))
  if p.get("spin", 0.0) > 0.0:
   actor.body.rotation.y = target_angle + (1.0 - p.spin / 0.45) * TAU
  elif p.get("elbow", 0.0) > 0.0:
   actor.body.rotation.y = target_angle + sin((1.0 - p.elbow / 0.50) * TAU * 2.0) * 0.9
  if is_dunking:
   var face_dir = 1.0 if p.face > 0 else -1.0
   match dunk_style:
    "helicopter":
     var spin_p = clampf(dunk_p / 0.80, 0.0, 1.0)
     actor.body.rotation.y = target_angle + spin_p * TAU * 2.0
     actor.body.rotation.z = 0.0
     actor.body.rotation.x = 0.0
    "frontflip":
     var flip_p = clampf((dunk_p - 0.05) / 0.75, 0.0, 1.0)
     actor.body.rotation.y = target_angle
     actor.body.rotation.x = flip_p * TAU
     actor.body.rotation.z = 0.0
    "spin_360":
     var spin_p = clampf(dunk_p / 0.80, 0.0, 1.0)
     actor.body.rotation.y = target_angle + spin_p * TAU
     actor.body.rotation.z = 0.0
     actor.body.rotation.x = 0.0
    "between_legs":
     actor.body.rotation.y = target_angle
     actor.body.rotation.z = 0.0
     actor.body.rotation.x = 0.0
    "behind_back":
     var twist_p = clampf((dunk_p - 0.20) / 0.55, 0.0, 1.0)
     var twist = sin(twist_p * PI) if (dunk_p > 0.20 and dunk_p < 0.75) else 0.0
     actor.body.rotation.y = target_angle + twist * 0.75 * face_dir
     actor.body.rotation.z = 0.0
     actor.body.rotation.x = twist * 0.25
    _:
     actor.body.rotation.y = target_angle
     actor.body.rotation.z = 0.0
     actor.body.rotation.x = 0.0
  else:
   actor.body.rotation.z = 0.0
   actor.body.rotation.x = 0.0
  if p.stun > 0:
   var shove_time = maxf(p.get("shove_time", 0.85), 0.001)
   var prog = 1.0 - clampf(p.stun / shove_time, 0.0, 1.0)
   var kind = p.get("shove_kind", "flyback" if p.stun > 0.6 else "stumble")
   if kind == "flyback":
    if prog < 0.35:
     var air_t = prog / 0.35
     actor.body.position.y = sin(air_t * PI) * 0.70
     actor.body.rotation.x = -air_t * 1.52
     actor.body.rotation.z = 0.0
    elif prog < 0.68:
     actor.body.position.y = 0.06
     actor.body.rotation.x = -1.52
     actor.body.rotation.z = 0.0
    else:
     var rec_t = (prog - 0.68) / 0.32
     actor.body.position.y = lerpf(0.06, 0.0, rec_t)
     actor.body.rotation.x = lerpf(-1.52, 0.0, rec_t)
     actor.body.rotation.z = sin(rec_t * PI) * 0.35
   else:
    actor.body.rotation.x = -sin(prog * PI) * 0.40
    actor.body.rotation.z = 0.0
    actor.body.position.y = 0.0
  actor.head.scale = Vector3.ONE*(1.65 if state.big_heads else 1.0)
  var next_action = "idle"
  var phase = -1.0
  if p.stun > 0:
   next_action = "stun"
   var shove_time = maxf(p.get("shove_time", 0.85), 0.001)
   phase = 1.0 - clampf(p.stun / shove_time, 0.0, 1.0)
  elif state.quarter_transition.get("active", false):
   next_action = "idle"
  elif tip_jump >= 0:
   next_action = "block"
   phase = tip_jump
  elif state.pending_inbound >= 0 and state.shatter_shooter == i:
   next_action = "dunk"
   phase = 1.0
  elif p.get("rim_hang", 0.0) > 0.0:
   next_action = "dunk"
   phase = 1.0
  elif p.receive_jump > 0:
   next_action = "block"
   var progress = 1.0-clampf(p.receive_jump/0.7,0,1)
   phase = progress*0.64 if progress <= 0.5 else 0.32+(progress-0.5)*1.36
  elif not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.shooter == i:
   next_action = "dunk" if state.flight.dunk else "layup" if (state.flight.get("layup",false) or state.flight.get("hook",false)) else "shoot"
   phase = clampf(state.flight.time/state.flight.duration,0,1) if state.flight.dunk else 0.45+0.55*clampf(state.flight.time/state.flight.duration,0,1)
   if state.flight.get("finish","") == "alley_oop":
    phase = 0.55+0.45*clampf(state.flight.time/state.flight.duration,0,1)
  elif p.charge > 0:
   next_action = "shoot"
   phase = 0.45*clampf(p.charge/0.58,0,1)
  elif p.get("fake",0.0) > 0:
   next_action = "shoot"
   phase = 0.42*sin((1.0-clampf(p.fake/0.38,0,1))*PI)
  elif p.get("swipe",0.0) > 0:
   if p.get("swipe_shove", false):
    next_action = "shove"
    phase = 1.0 - clampf(p.swipe / 0.45, 0.0, 1.0)
    actor.body.rotation.x = sin(phase * PI) * 0.32
   else:
    next_action = "steal"
    phase = 1.0 - clampf(p.swipe / 0.45, 0.0, 1.0)
  elif not state.flight.is_empty() and state.flight.kind == "pass" and not state.flight.get("tip",false) and (int(state.flight.target)/2)*2+(1-int(state.flight.target)%2) == i:
   next_action = "pass"
   phase = clampf(state.flight.time/state.flight.duration,0,1)
  elif p.jump > 0:
   next_action = "block"
   phase = 1.0-clampf(p.jump/0.70,0,1)
  elif running > 0.035:
   next_action = "dribble" if state.owner == i else "run"
  elif state.owner >= 0 and state.owner/2 != i/2:
   next_action = "defense"
  var extra_arg = dunk_style if next_action == "dunk" else p.get("shove_kind","")
  actor.body.animate(next_action,motion_delta,phase,lerpf(0.75,1.5,running),paused,extra_arg)
  if is_dunking:
   var reach_blend = 0.0
   if dunk_p >= 0.85:
    reach_blend = clampf((dunk_p - 0.85) / 0.07, 0.0, 1.0)
   elif p.get("rim_hang", 0.0) > 0.0:
    reach_blend = 1.0
   var is_one_handed = (dunk_style == "spin_360" and dunk_p < 0.94)
   actor.body.reach_rim(reach_blend, is_one_handed)
   if reach_blend > 0.0:
    var hoop_pos = state.flight.end if not state.flight.is_empty() else state.hoop_for(i / 2)
    var b_idx = 0 if hoop_pos.x < 640 else 1
    var rim_target = court_point(hoop_pos, 3.05 - rim_dips[b_idx])
    var rim_local = actor.skeleton.global_transform.affine_inverse() * rim_target
    var target_l = Transform3D(Basis.IDENTITY, rim_local + Vector3(0.12, 0.02, -0.05))
    var target_r = Transform3D(Basis.IDENTITY, rim_local + Vector3(-0.12, 0.02, -0.05))
    if not is_one_handed:
     actor.skeleton.set_bone_global_pose_override(20, target_l, reach_blend, true)
    else:
     actor.skeleton.set_bone_global_pose_override(20, Transform3D.IDENTITY, 0.0, false)
    actor.skeleton.set_bone_global_pose_override(21, target_r, reach_blend, true)
   else:
    actor.skeleton.clear_bones_global_pose_override()
  else:
   actor.skeleton.clear_bones_global_pose_override()
  if faces_ball_for_block and next_action == "block":
   # The generated block clip includes some root rotation. Compensate for it so
   # the rendered athlete, not just its outer node, tracks the ball precisely.
   var ball_direction = ball-point
   if ball_direction.length_squared() > 0.01:
    var ball_angle = movement_facing_angle(ball_direction)
    var root_forward = Basis(actor.skeleton.get_bone_pose_rotation(0)) * Vector3.BACK
    var root_yaw = atan2(root_forward.x,root_forward.z)
    actor.body.rotation.y = ball_angle-root_yaw
  var lowest_foot = 100.0
  for bone in [7, 8, 10, 11]:
   var foot_trans: Transform3D = actor.skeleton.global_transform * actor.skeleton.get_bone_global_pose(bone)
   lowest_foot = minf(lowest_foot, foot_trans.origin.y)
  var sneaker_bottom = lowest_foot - 0.045
  if sneaker_bottom < 0.0 and p.stun <= 0.0:
   actor.body.position.y += -sneaker_bottom
  actor.marker.visible = controlled_slots.has(i)
  actor.control.text = ("P1" if i < 2 else "P2") if controlled_slots.has(i) else ""
  actor.control.position.y = 2.72+actor.body.position.y
  actor.label.position.y = 2.35+actor.body.position.y
  if p.receive_jump > 0 or (not state.flight.is_empty() and state.flight.get("finish","") == "alley_oop" and state.flight.shooter == i):
   actor.label.position.y = 3.1+actor.body.position.y
   actor.control.position.y = 3.45+actor.body.position.y
  var label_offset = (-0.7 if i == 0 else 0.7 if i == 2 else 0.0) if state.tipoff.get("active",false) else 0.0
  actor.label.position.x = label_offset
  actor.control.position.x = label_offset
  if p.stun > 0:
   actor.control.text = "★ ★ ★"
  elif p.receive_jump > 0 and p.pos.distance_to(state.hoop_for(i/2)) < 220 and ((state.owner >= 0 and state.owner != i and state.owner/2 == i/2) or (not state.flight.is_empty() and state.flight.kind == "pass" and state.flight.get("alley",false) and state.flight.target == i)):
   actor.control.text = "LOB!"
  var is_carrier = state.owner == i
  var on_court = p.pos.x >= MatchState.COURT.position.x and p.pos.x <= MatchState.COURT.end.x
  var still_time: float = p.get("still_time", 0.0)
  var is_still_enough = is_carrier and on_court and still_time >= 0.10 and p.vel.length() <= 10.0 and p.jump <= 0.0
  var is_charging_still = is_carrier and on_court and p.charge > 0.0 and not p.get("shot_is_moving", false)
  var is_locking_on = is_carrier and on_court and p.vel.length() <= 10.0 and still_time > 0.0 and still_time < 0.10 and p.charge <= 0.0 and p.jump <= 0.0
  if is_still_enough or is_charging_still:
   actor.aim_indicator.visible = true
   var pulse = 1.0 + sin(time * 9.0) * 0.04
   actor.aim_indicator.scale = Vector3(pulse, 1.0, pulse)
   actor.aim_indicator.rotation.y = time * 0.85
   actor.aim_ring.material_override = material(Color("2eff82"), 0.5, true)
   actor.aim_outer.material_override = material(Color("10d970"), 0.6, true)
   var green_pip = material(Color("70ffb0"), 0.4, true)
   for pip in actor.aim_pips:
    pip.material_override = green_pip
   actor.aim_label.visible = true
   actor.aim_label.text = "⌖ AIMED"
   actor.aim_label.position.y = 3.02 + jump
   actor.aim_label.position.x = label_offset
   actor.aim_label.modulate = Color("2eff82")
  elif is_locking_on:
   var lock_p = clampf(still_time / 0.10, 0.0, 1.0)
   actor.aim_indicator.visible = true
   var contract = lerpf(1.35, 1.0, lock_p)
   actor.aim_indicator.scale = Vector3(contract, 1.0, contract)
   actor.aim_indicator.rotation.y = lock_p * 1.57
   actor.aim_ring.material_override = material(Color("ffcc33"), 0.5, true)
   actor.aim_outer.material_override = material(Color("ffaa22"), 0.6, true)
   var amber_pip = material(Color("ffe066"), 0.4, true)
   for pip in actor.aim_pips:
    pip.material_override = amber_pip
   actor.aim_label.visible = false
  else:
   actor.aim_indicator.visible = false
   actor.aim_label.visible = false
  for flame in range(5):
   var ember: MeshInstance3D = actor.fire[flame]
   ember.visible = state.is_player_on_fire(i) or (state.player_streak[i] == 2 and flame < 2)
   var angle = time*3+flame*TAU/5
   ember.position = Vector3(cos(angle)*0.43,0.7+fmod(time*1.8+flame*0.37,1.6)+jump,sin(angle)*0.43)
   ember.scale.y = 0.6+sin(time*13+flame)*0.25
  var h = actor.body.position.y
  var spread = 1.0 + minf(h * 0.38, 1.3)
  actor.shadow.scale = Vector3(spread, 1.0, spread)
  var shadow_alpha = clampf(0.60 - h * 0.11, 0.12, 0.60)
  actor.shadow_mat.albedo_color.a = shadow_alpha
 var ball_height = state.ball_height()
 basketball.position = court_point(ball,ball_height)
 if state.flight.is_empty() and state.owner >= 0:
  var carrier = athletes[state.owner]
  var p_carrier: Dictionary = state.players[state.owner]
  var in_air = carrier.body.position.y > 0.08 or p_carrier.get("jump", 0.0) > 0.0 or p_carrier.get("receive_jump", 0.0) > 0.0 or p_carrier.get("charge", 0.0) > 0.0
  if in_air:
   var hand_l: Transform3D = carrier.skeleton.global_transform * carrier.skeleton.get_bone_global_pose(20)
   var hand_r: Transform3D = carrier.skeleton.global_transform * carrier.skeleton.get_bone_global_pose(21)
   var hands_mid = (hand_l.origin + hand_r.origin) * 0.5
   var forward_dir = -carrier.body.global_transform.basis.z
   basketball.global_position = hands_mid + forward_dir * 0.12
 if not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.dunk:
  var dunker = athletes[state.flight.shooter]
  var dunk_style = state.flight.get("dunk_style", "standard")
  var dunk_p = clampf(state.flight.time / state.flight.duration, 0.0, 1.0)
  var hand_l: Transform3D = dunker.skeleton.global_transform * dunker.skeleton.get_bone_global_pose(20)
  var hand_r: Transform3D = dunker.skeleton.global_transform * dunker.skeleton.get_bone_global_pose(21)
  var hands_mid = (hand_l.origin + hand_r.origin) * 0.5
  var fwd_dir = dunker.body.global_transform.basis.z
  var up_dir = dunker.body.global_transform.basis.y
  var ball_on_hands = hands_mid + fwd_dir * 0.10
  if dunk_style == "behind_back" and dunk_p > 0.20 and dunk_p < 0.75:
   var dip = sin((dunk_p - 0.20) / 0.55 * PI)
   ball_on_hands = hands_mid - fwd_dir * (dip * 0.38) - up_dir * (dip * 0.12)
  elif dunk_style == "between_legs" and dunk_p > 0.15 and dunk_p < 0.72:
   var dip = sin(clampf((dunk_p - 0.15) / 0.57, 0.0, 1.0) * PI)
   ball_on_hands = hands_mid + fwd_dir * 0.08 - up_dir * (dip * 0.04)
  elif dunk_style == "spin_360":
   ball_on_hands = hand_r.origin + fwd_dir * 0.08 + up_dir * 0.05
  var b_idx = 0 if state.flight.end.x < 640 else 1
  var rim_target = court_point(state.flight.end, 3.05 - rim_dips[b_idx])
  if dunk_p < 0.88:
   basketball.global_position = ball_on_hands
  elif dunk_p < 0.94:
   var slam_t = (dunk_p - 0.88) / 0.06
   basketball.global_position = ball_on_hands.lerp(rim_target, slam_t)
  else:
   var net_drop = (dunk_p - 0.94) / 0.06 * 0.38
   basketball.global_position = rim_target - Vector3(0, net_drop, 0)
  if dunk_p >= 0.90 and not dunk_slam_shaken:
   dunk_slam_shaken = true
   var is_super = state.flight.get("super_dunk", false) or state.is_player_on_fire(state.flight.shooter)
   trigger_dunk_shake(0.35 if is_super else 0.22, 0.45 if is_super else 0.35)
   trigger_flashbulbs(6)
 else:
  dunk_slam_shaken = false
 ball_shadow.position = Vector3(basketball.position.x, 0.006, basketball.position.z)
 var b_h = basketball.position.y
 var b_spread = 1.0 + minf(b_h * 0.35, 1.8)
 ball_shadow.scale = Vector3(b_spread, 1.0, b_spread)
 var b_alpha = clampf(0.55 - b_h * 0.09, 0.06, 0.55)
 ball_shadow.material_override.albedo_color.a = b_alpha
 ball_shadow.visible = b_h < 8.5
 basketball.rotation = Vector3(time*3.2,0,time*2.1)
 # Trigger net swish on made shots reaching rim
 if not state.flight.is_empty() and state.flight.kind == "shot":
  var progress = clampf(state.flight.time / state.flight.duration, 0.0, 1.0)
  if progress >= 0.94 and state.flight.get("made", true):
   var b_idx = 0 if state.flight.end.x < 640 else 1
   if b_idx < baskets.size() and baskets[b_idx].get("net", {}).get("swish_time", 10.0) > 0.5:
    var shot_dir = (state.flight.end - state.flight.start).normalized()
    var incoming_dir = Vector3(shot_dir.x * COURT_SCALE.x, 0, shot_dir.y * COURT_SCALE.y).normalized()
    trigger_net_swish(b_idx, incoming_dir)

 # Trigger net swish on scoring events (dunks, layups, baskets)
 if state.event_id != last_event_id:
  last_event_id = state.event_id
  if state.event_kind == "shatter":
   trigger_dunk_shake(0.48, 0.65)
   trigger_flashbulbs(10)
  elif state.event_kind in ["score", "dunk", "fire"]:
   var scoring_team = 1 - state.inbounding_team if state.inbounding_team >= 0 else (0 if state.score[0] > 0 else 1)
   var hoop = state.hoop_for(scoring_team)
   var b_idx = 0 if hoop.x < 640 else 1
   if b_idx < baskets.size() and baskets[b_idx].get("net", {}).get("swish_time", 10.0) > 0.25:
    var incoming_dir = Vector3(1.0 if hoop.x < 640 else -1.0, 0, 0)
    trigger_net_swish(b_idx, incoming_dir)
   if state.event_kind in ["dunk", "fire"]:
    trigger_dunk_shake(0.32 if state.event_kind == "fire" else 0.24, 0.38)
   trigger_flashbulbs(8 if state.event_kind in ["dunk", "fire"] else 4)

 for b_idx in range(baskets.size()):
  var net_data: Dictionary = baskets[b_idx].get("net", {})
  if not net_data.is_empty():
   update_net(net_data, motion_delta, paused)

 # Visually pass ball down through swirling net upon made basket
 for b_idx in range(baskets.size()):
  var net_data: Dictionary = baskets[b_idx].get("net", {})
  if not net_data.is_empty() and net_data.swish_time < 0.35:
   if state.inbound_transition.get("active", false) or state.pending_inbound >= 0 or (state.flight.is_empty() and state.owner >= 0 and state.players[state.owner].pos.distance_to(state.hoop_for(1 - b_idx)) > 140.0):
    var drop_p = clampf(net_data.swish_time / 0.35, 0.0, 1.0)
    var ball_drop_y = lerpf(3.12, 2.25, drop_p)
    var drop_dir = net_data.swish_dir if net_data.swish_dir.length() > 0.01 else Vector3(net_data.side, 0, 0)
    basketball.position = net_data.center + Vector3(0, ball_drop_y - 3.05, 0) + drop_dir * (sin(drop_p * PI) * 0.08)
    break
 var is_dunk_flight = not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.dunk
 var dunk_basket_idx = -1
 var dunk_dip_target = 0.0
 if is_dunk_flight:
  var dunk_flight_p = clampf(state.flight.time / state.flight.duration, 0.0, 1.0)
  dunk_basket_idx = 0 if state.flight.end.x < 640 else 1
  if dunk_flight_p >= 0.82 and dunk_flight_p <= 1.0:
   var is_super = state.flight.get("super_dunk", false) or state.is_player_on_fire(state.flight.shooter)
   var pull = sin((dunk_flight_p - 0.82) / 0.18 * PI * 0.5)
   dunk_dip_target = (0.19 if is_super else 0.13) * pull

 for b in range(2):
  var target = dunk_dip_target if b == dunk_basket_idx else 0.0
  var diff = target - rim_dips[b]
  var k_spring = 260.0
  var damping = 22.0
  var accel = k_spring * diff - damping * rim_vels[b]
  rim_vels[b] += accel * motion_delta
  rim_dips[b] += rim_vels[b] * motion_delta
  if target == 0.0 and absf(rim_dips[b]) < 0.001 and absf(rim_vels[b]) < 0.005:
   rim_dips[b] = 0.0
   rim_vels[b] = 0.0
  if rim_nodes.size() > b and is_instance_valid(rim_nodes[b]):
   rim_nodes[b].position.y = 3.05 - rim_dips[b]
   if rim_rods.size() > b:
    var r_data = rim_rods[b]
    update_rod(r_data.rod, r_data.board_pos, r_data.center - Vector3(0, rim_dips[b], 0))

 for fb in flashbulbs:
  if not paused:
   if fb.timer > 0.0:
    fb.timer = maxf(0.0, fb.timer - delta)
    var flash_a = clampf(fb.timer / 0.08, 0.0, 1.0)
    fb.material.albedo_color.a = flash_a * 0.95
   else:
    fb.material.albedo_color.a = 0.0
    fb.cooldown -= delta
    if fb.cooldown <= 0.0:
     fb.timer = 0.08
     fb.cooldown = randf_range(1.2, 4.5)
 update_backboards(state)
 update_camera(state,ball,motion_delta,paused)
 var in_flight = not state.flight.is_empty()
 var is_shot = in_flight and state.flight.kind == "shot"
 var burning_shot = is_shot and state.is_player_on_fire(state.flight.shooter) and not state.flight.blocked
 var is_turbo_lob = in_flight and (state.flight.get("turbo",false) or state.flight.get("alley",false) or state.flight.get("super_dunk",false))
 var trail_mat = material(Color("ff4400") if burning_shot else (GOLD if is_turbo_lob else Color("70dcff")), 0.5, true)
 if not paused:
  if in_flight:
   ball_trail_history.push_front(basketball.global_position)
   if ball_trail_history.size() > 32:
    ball_trail_history.resize(32)
  else:
   ball_trail_history.clear()
 for i in range(ball_trail.size()):
  var p_mesh: MeshInstance3D = ball_trail[i]
  p_mesh.visible = in_flight
  if in_flight:
   p_mesh.material_override = trail_mat
   var hist_idx = mini(i + 1, ball_trail_history.size() - 1) if ball_trail_history.size() > 0 else -1
   p_mesh.position = ball_trail_history[hist_idx] if hist_idx >= 0 else basketball.global_position
   var sc = (1.0 - float(i) / float(ball_trail.size())) * 0.85
   p_mesh.scale = Vector3.ONE * sc
 for i in range(ball_fire.size()):
  var ember: MeshInstance3D = ball_fire[i]
  ember.visible = burning_shot
  if burning_shot:
   var hist_idx = mini(i + 1, ball_trail_history.size() - 1) if ball_trail_history.size() > 0 else -1
   var base_pos = ball_trail_history[hist_idx] if hist_idx >= 0 else basketball.global_position
   ember.position = base_pos + Vector3(0, 0.10 + 0.08 * sin(time * 17.0 + i), 0)
   ember.scale = Vector3.ONE * (1.0 - float(i) / 10.0)

func shot_meter_position(index: int) -> Vector2:
 var actor: Dictionary = athletes[index]
 return camera.unproject_position(actor.root.position+Vector3(0,actor.body.position.y+3.0,0))

func shot_badge_position(index: int) -> Vector2:
 var actor: Dictionary = athletes[index]
 return camera.unproject_position(actor.root.position+Vector3(0,actor.body.position.y+3.3,0))
