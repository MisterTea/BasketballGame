extends SubViewport

const HYMotionRig = preload("res://scripts/hy_motion_rig.gd")

# Presentation only: simulation coordinates, inputs, and network state stay unchanged.
const COURT_SCALE = Vector2(28.0 / 1050.0, 15.0 / 410.0)
const GOLD = Color("ffcb68")
var world: Node3D
var camera: Camera3D
var athletes: Array = []
var basketball: Node3D
var crowd: MultiMeshInstance3D
var wood_material: StandardMaterial3D
var last_teams: Array = []
var time = 0.0
var materials: Dictionary = {}

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
 for i in range(4):
  athletes.append(build_athlete(i))
 build_ball()
 camera = Camera3D.new()
 camera.name = "SidelineCamera"
 camera.projection = Camera3D.PROJECTION_PERSPECTIVE
 camera.fov = 24.5
 camera.position = Vector3(0,19,34)
 world.add_child(camera)
 camera.look_at(Vector3(0,0.9,0))
 camera.current = true
 camera.far = 120.0

func court_point(point: Vector2, height: float = 0.0) -> Vector3:
 return Vector3((point.x-640.0)*COURT_SCALE.x,height,(point.y-470.0)*COURT_SCALE.y)

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
  var angle = asin(180.0/300.0)
  court_arc(hoop,300,-angle if side == 0 else PI-angle,angle if side == 0 else PI+angle,white)
  var arc_x = hoop.x+(240 if side == 0 else -240)
  court_line([Vector2(115 if side == 0 else 1165,285),Vector2(arc_x,285)],0.055,white)
  court_line([Vector2(115 if side == 0 else 1165,645),Vector2(arc_x,645)],0.055,white)
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
 for z in [-0.34,0.34]:
  box(group,Vector3(0.026,0.51,0.035),Vector3(target_x,3.35,center.z+z),net_material)
 for y in [3.095,3.605]:
  box(group,Vector3(0.026,0.035,0.715),Vector3(target_x,y,center.z),net_material)
 rod(group,Vector3(board_x,3.05,center.z),center,0.045,orange)
 ring(group,0.43,0.035,center,orange,36).name = "OrangeRim"
 for layer in range(4):
  var t = float(layer)/3.0
  ring(group,lerpf(0.43,0.27,t),0.009,center-Vector3(0,t*0.62,0),net_material,24)
 for strand in range(12):
  var angle = TAU*strand/12.0
  var top = center+Vector3(cos(angle)*0.43,0,sin(angle)*0.43)
  var mid = center+Vector3(cos(angle+0.15)*0.34,-0.31,sin(angle+0.15)*0.34)
  var bottom = center+Vector3(cos(angle)*0.27,-0.62,sin(angle)*0.27)
  rod(group,top,mid,0.009,net_material,4)
  rod(group,mid,bottom,0.009,net_material,4)
  var cross_mid = center+Vector3(cos(angle-0.15)*0.34,-0.31,sin(angle-0.15)*0.34)
  rod(group,top,cross_mid,0.009,net_material,4)
  rod(group,cross_mid,bottom,0.009,net_material,4)

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
 var fire: Array = []
 for flame in range(5):
  var shape = PrismMesh.new()
  shape.size = Vector3(0.28,0.8,0.28)
  var object = mesh(root,shape,Vector3.ZERO,material(Color("ff772c") if flame%2 else GOLD,0.7,true))
  object.visible = false
  object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  fire.append(object)
 return {"root":root,"body":body,"head":body.head,"skeleton":body.skeleton,"arms":[body.attach(16),body.attach(17)],"legs":[body.attach(1),body.attach(2)],"jersey":body.jersey,"shorts":body.shorts,"marker":marker,"label":name_label,"control":control_label,"fire":fire}

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

func present(state: MatchState, positions: Array, ball: Vector2, controlled_slots: Array, delta: float, paused: bool) -> void:
 render_target_update_mode = SubViewport.UPDATE_ALWAYS
 if not paused:
  time += delta
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
  var point: Vector2 = positions[i] if positions.size() == 4 else p.pos
  actor.root.position = court_point(point)
  var jump = sin(clampf(p.jump/0.85,0,1)*PI)*2.65
  actor.body.position.y = maxf(0,jump)
  var running = clampf(p.vel.length()/230.0,0,1)
  var target_angle = atan2(p.vel.x,p.vel.y) if p.vel.length() > 8 else (PI/2 if p.face > 0 else -PI/2)
  actor.body.rotation.y = lerp_angle(actor.body.rotation.y,target_angle,1.0-exp(-delta*15))
  actor.head.scale = Vector3.ONE*(1.65 if state.big_heads else 1.0)
  var next_action = "idle"
  var phase = -1.0
  if p.stun > 0:
   next_action = "stun"
   phase = 1.0-clampf(p.stun/0.85,0,1)
  elif not state.flight.is_empty() and state.flight.kind == "shot" and state.flight.shooter == i:
   next_action = "dunk" if state.flight.dunk else "shoot"
   phase = clampf(state.flight.time/state.flight.duration,0,1) if state.flight.dunk else 0.45+0.55*clampf(state.flight.time/state.flight.duration,0,1)
  elif p.charge > 0:
   next_action = "shoot"
   phase = 0.45*clampf(p.charge/0.58,0,1)
  elif p.jump > 0:
   next_action = "block"
   phase = 1.0-clampf(p.jump/0.62,0,1)
  elif not state.flight.is_empty() and state.flight.kind == "pass" and (int(state.flight.target)/2)*2+(1-int(state.flight.target)%2) == i:
   next_action = "pass"
   phase = clampf(state.flight.time/state.flight.duration,0,1)
  elif p.cooldown > 0.2 and state.owner >= 0 and state.owner/2 != i/2:
   next_action = "steal"
   phase = 1.0-clampf(p.cooldown/0.65,0,1)
  elif running > 0.035:
   next_action = "dribble" if state.owner == i else "run"
  elif state.owner >= 0 and state.owner/2 != i/2:
   next_action = "defense"
  actor.body.animate(next_action,delta,phase,lerpf(0.75,1.5,running),paused)
  actor.marker.visible = controlled_slots.has(i)
  actor.control.text = ("P1" if i < 2 else "P2") if controlled_slots.has(i) else ""
  actor.control.position.y = 2.72+jump
  actor.label.position.y = 2.35+jump
  if p.stun > 0:
   actor.control.text = "★ ★ ★"
  for flame in range(5):
   var ember: MeshInstance3D = actor.fire[flame]
   ember.visible = state.on_fire(i/2)
   var angle = time*3+flame*TAU/5
   ember.position = Vector3(cos(angle)*0.43,0.7+fmod(time*1.8+flame*0.37,1.6)+jump,sin(angle)*0.43)
   ember.scale.y = 0.6+sin(time*13+flame)*0.25
 var ball_height = 0.24
 if not state.flight.is_empty():
  var t = clampf(state.flight.time/state.flight.duration,0,1)
  if state.flight.kind == "shot":
   ball_height = lerpf(1.3,3.05,t)+sin(t*PI)*(1.7 if state.flight.dunk else 4.6)
  else:
   ball_height = 1.1+sin(t*PI)*(2.2 if state.flight.alley else 0.5)
 elif state.owner >= 0:
  ball_height = 0.30+absf(sin(state.elapsed*12.0))*0.9
 basketball.position = court_point(ball,ball_height)
 basketball.rotation = Vector3(time*3.2,0,time*2.1)

func shot_meter_position(index: int) -> Vector2:
 var actor: Dictionary = athletes[index]
 return camera.unproject_position(actor.root.position+Vector3(0,actor.body.position.y+3.0,0))
