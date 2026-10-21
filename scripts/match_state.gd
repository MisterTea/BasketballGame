class_name MatchState
extends RefCounted

const COURT = Rect2(115, 265, 1050, 410)
const HOOPS = [Vector2(165, 465), Vector2(1115, 465)]
const THREE_POINT_RADIUS = 300.0
const THREE_POINT_CORNER_OFFSET = 180.0
const REBOUND_FLIGHT_DURATION = 1.65
const REBOUND_BOUNCE_DURATION = 0.60
const REBOUND_GLIDE_DURATION = 0.50
const POSSESSION_FLASH_DURATION = 0.60
const BULLET_TIME_DURATION = 0.50
const BULLET_TIME_SCALE = 0.30
const SIGNATURE_DUNKS = ["helicopter", "frontflip", "spin_360", "between_legs", "behind_back"]
const QUARTER_SECONDS = 180.0
const TIP_TOSS = 1.0
const TIP_IDEAL_JUMP = 1.42
const TIP_DECISION = 2.05
# Master arcade hardware refresh rate (DISP.EQU:36, TSEC .equ 53)
const ARCADE_TSEC = 53.20488
# Arcade quarter timer speedup factor: BASETM = 0x5100 per tick (SCORE.ASM:196)
# 65536 / 20736 = 3.1604 ticks per 0.1s = 31.604 ticks/s -> 31.604 / 53.20488 = 0.5940 real sec per clock sec
const CLOCK_TIME_SCALE = 1.6835
# Arcade shot clock speedup factor: 32 ticks per decrement (SCORE.ASM:3235)
# 32 / 53.20488 = 0.60145 real sec per shot clock sec
const SHOT_CLOCK_TIME_SCALE = 1.6628
# Authentic NBA Jam arcade tables
# Base velocity table (PLYRAT.ASM:390-400 BV..BV10)
const BV_TABLE = [0x1002, 0x1044, 0x1086, 0x10c8, 0x110a, 0x114c, 0x118e, 0x11d0, 0x1274, 0x12c6, 0x1318]
# Base shooting skill table (PLYRAT.ASM:476-486 SHT0..SHT10)
const SHT_TABLE = [0.860, 0.890, 0.920, 0.970, 1.040, 1.070, 1.080, 1.100, 1.130, 1.150, 1.200]
# Power dunk-through defender table (PLYR.ASM:5363 dnkthru_t)
const DNKTHRU_T = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.10, 0.15, 0.25, 0.35]
# Dunk lane defense distance and width tables (PLYR.ASM:5367-5380 #dist_t, #width_t; 12th entry is On-Fire defender)
const DEF_DIST_T = [34, 36, 39, 41, 42, 44, 45, 47, 57, 59, 61, 80]
const DEF_WIDTH_T = [27, 29, 31, 33, 36, 37, 38, 39, 40, 43, 45, 70]
# Mid-air dunk block & strip tables (PLYR.ASM:4388 tryblk_t, PLYR2.ASM:2525 takedunk_t)
const TRYBLK_T = [1, 2, 3, 10, 15, 18, 22, 23, 24, 25, 25]
const TAKEDUNK_T = [0, 0, 0, 0, 0, 0, 0, 100, 130, 170, 200, 300, 400, 600, 800, 800, 999, 999, 999, 999, 999, 999]
# Ball retention on shove knockdown tables (PLYR.ASM:3454 #kpball_t, 3481 #flyb_t)
const KPBALL_T = [0.080, 0.104, 0.128, 0.152, 0.160, 0.176, 0.224, 0.240, 0.360, 0.360, 0.360]
const FLYB_T = [0.0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.22, 0.22, 0.22, 0.22]
# Pass speed tables indexed by PAT_PASS (PLYR.ASM:8409-8417 #longpas_t, #shortpas_t, #turbopas_t)
const LONGPAS_T = [103, 101, 99, 97, 95, 93, 91, 89, 87, 85, 83]
const SHORTPAS_T = [127, 124, 121, 118, 115, 112, 109, 106, 103, 100, 97]
const TURBOPAS_T = [28, 29, 30, 31, 32, 33, 35, 38, 41, 44, 44]
# Defensive steal ability table (PLYR2.ASM:3134 stl1) scaled to 0-1 probability
const STL1 = [0.120, 0.127, 0.135, 0.146, 0.150, 0.157, 0.168, 0.183, 0.195, 0.213, 0.225]
# Clean steal vs loose ball deflection table (PLYR2.ASM:3144 stl2)
const STL2 = [0.160, 0.170, 0.180, 0.195, 0.200, 0.205, 0.215, 0.225, 0.230, 0.240, 0.250]
# Interception bonus percentage for losing team (PLYR2.ASM:3496 int_t)
const INT_T = [0, 3, 5, 6, 8, 9, 10, 11, 12, 12, 12, 13, 14, 15, 17, 19]
# Uncalled goaltend probability table for losing team (PLYR2.ASM:3490 #goalt_t)
const GOALT_T = [0, 35, 45, 55, 60, 65, 70, 75, 75, 75, 80, 90, 90, 90, 90, 90]
# Horizontal block reach scaling by PAT_DEFSKILL (PLYR2.ASM:3480 tbl4)
const BLK_REACH_T = [11, 12, 12, 12, 12, 12, 12, 13, 14, 15, 16]
# Drone AI 31-entry skill tables (DRONE.ASM:1047-1065, 1642-1684)
const DRONE_P_T = [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 8, 10, 13, 15, 17, 18, 20, 20, 25, 30, 35, 40, 50]
const DRONE_ALY_T = [1, 2, 3, 4, 5, 15, 20, 25, 25, 30, 30, 30, 30, 32, 35, 35, 35, 36, 38, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 100, 109]
const DRONE_NAST_T = [0, 0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 5, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 18, 20, 24, 28, 30]
const DRONE_DIST_T = [110, 100, 100, 100, 100, 90, 90, 80, 80, 80, 80, 70, 70, 60, 60, 60, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50]
const DRONE_PS_T = [1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 6, 8, 10, 13, 15, 17, 18, 20, 30, 40, 60, 80, 150, 250]
const DRONE_BLK_T = [1, 1, 2, 3, 3, 3, 3, 4, 4, 5, 6, 7, 8, 10, 12, 14, 16, 18, 20, 25, 30, 35, 40, 45, 50, 50, 50, 50, 50, 50, 50]
var rng = RandomNumberGenerator.new()
var players: Array = []
var teams: Array = [0, 1]
var score: Array = [0, 0]
var streak: Array = [0, 0]
var player_streak: Array = [0, 0, 0, 0]
var team_streak: Array = [0, 0]
var team_fire_timer: Array = [0.0, 0.0]
var fire_player = -1
var last_passer: int = -1
var assist_window: float = 0.0
var teammate_shot_order = -1
var stats: Array = []
var ball = Vector2.ZERO
var owner = 0
var flight: Dictionary = {}
var clock = QUARTER_SECONDS
var shot_clock = 24.0
var quarter = 1
var overtime = 0
var phase = "playing"
var freeze = 1.5
var banner = "TIP OFF!"
var banner_time = 2.0
var event_id = 0
var event_kind = "start"
var elapsed = 0.0
var difficulty = 1
var big_heads = false
var infinite_turbo = false
var tournament_mode = false
var no_pushing = false
var fast_passing = false
var maximum_power = false
var period_length = QUARTER_SECONDS
var board_breaks: Array = [-1.0,-1.0]
var pending_inbound = -1
var shatter_shooter = -1
var fire_points: int = 0
var fire_shots: int = 0
var brick_count: Array = [0, 0, 0, 0]
var inbounding_team: int = -1
var loose_ball_timer: float = 0.0
var in_cylinder_timer: float = 0.0
var must_rebound_timer: float = 0.0
var bullet_time_remaining: float = 0.0
var tipoff: Dictionary = {}
var last_shot_feedback: Dictionary = {}
var inbound_transition: Dictionary = {}
var quarter_transition: Dictionary = {}
var quarter_scores: Array = []
var clock_buzzer_sounded: bool = false

func start(a: int, b: int, seconds: float = QUARTER_SECONDS, level: int = 1) -> void:
 rng.randomize()
 teams = [a, b]
 score = [0, 0]
 streak = [0, 0]
 player_streak = [0, 0, 0, 0]
 team_streak = [0, 0]
 team_fire_timer = [0.0, 0.0]
 fire_player = -1
 fire_points = 0
 fire_shots = 0
 last_passer = -1
 assist_window = 0.0
 brick_count = [0, 0, 0, 0]
 inbounding_team = -1
 loose_ball_timer = 0.0
 in_cylinder_timer = 0.0
 must_rebound_timer = 0.0
 bullet_time_remaining = 0.0
 teammate_shot_order = -1
 board_breaks = [-1.0,-1.0]
 pending_inbound = -1
 shatter_shooter = -1
 last_shot_feedback = {}
 inbound_transition = {}
 quarter_transition = {}
 quarter_scores = []
 clock_buzzer_sounded = false
 tournament_mode = false
 no_pushing = false
 fast_passing = false
 maximum_power = false
 stats = []
 players = []
 difficulty = level
 period_length = seconds
 clock = seconds
 shot_clock = 24.0
 quarter = 1
 overtime = 0
 phase = "playing"
 freeze = 1.5
 elapsed = 0.0
 flight = {}
 for i in range(4):
  var t = i / 2
  players.append({"pos":Vector2(420 if t == 0 else 860, 400 + (i % 2) * 140), "vel":Vector2.ZERO, "turbo":1.0, "turbo_burnout":0.0, "jump":0.0, "receive_jump":0.0, "stun":0.0, "cooldown":0.0, "charge":0.0, "fake":0.0, "drive":0.0, "swipe":0.0, "swipe_resolved":false, "swipe_shove":false, "rebound_glide":0.0, "possession_flash":0.0, "shoot_held":false, "face":1 if t == 0 else -1, "spin":0.0, "spin_cooldown":0.0, "elbow":0.0, "steal_immune":0.0, "push_keep_ball":0.0, "pass_off":0.0, "alley_cnt":0, "hold_time":0.0, "nasty_timer":0.0, "rim_hang":0.0, "still_time":1.0, "shot_is_moving":false, "shot_drift_vel":Vector2.ZERO, "last_move_vel":Vector2.ZERO, "pickup_delay":0.0, "turbo_flash":0.0, "shove_kind":"", "shove_time":0.0})
  stats.append({"points":0, "attempts":0, "made":0, "dunks":0, "steals":0, "blocks":0, "rebounds":0, "goaltends":0, "assists":0, "injury":0, "turnovers":0})
 begin_tipoff()

func begin_tipoff() -> void:
 owner = -1
 freeze = 0
 ball = Vector2(640,465)
 players[0].pos = Vector2(610,465)
 players[2].pos = Vector2(670,465)
 players[1].pos = Vector2(490,565)
 players[3].pos = Vector2(790,365)
 var spread = 0.25-0.05*clampi(difficulty,0,2)
 tipoff = {"active":true,"time":0.0,"started_at":elapsed,"jumps":[-1.0,-1.0],"held":[false,false],"cpu_at":[TIP_IDEAL_JUMP+rng.randf_range(-spread,spread),TIP_IDEAL_JUMP+rng.randf_range(-spread,spread)],"winner":-1}
 announce("CENTER COURT — SHOOT TO JUMP", "start")

func tick_tipoff(delta: float, commands: Dictionary) -> void:
 var previous: float = tipoff.time
 tipoff.time = minf(TIP_DECISION,tipoff.time+delta)
 for i in range(4):
  players[i].vel = Vector2.ZERO
  players[i].charge = 0.0
  players[i].jump = maxf(0,players[i].jump-delta)
  players[i].shoot_held = commands.get(i,{}).get("shoot",false)
 for team in range(2):
  var jumper = team*2
  var controller = jumper if commands.has(jumper) else jumper+1
  var human = commands.has(controller)
  var shoot: bool = commands.get(controller,{}).get("shoot",false)
  var pressed: bool = (shoot and not tipoff.held[team]) or commands.get(controller,{}).get("jump_press",false)
  tipoff.held[team] = shoot
  if tipoff.jumps[team] >= 0:
   continue
  var jump_at = -1.0
  if human and pressed and tipoff.time >= TIP_TOSS and tipoff.time <= TIP_DECISION:
   jump_at = tipoff.time
  elif not human and tipoff.time >= tipoff.cpu_at[team]:
   jump_at = tipoff.cpu_at[team]
  if jump_at >= 0:
   tipoff.jumps[team] = jump_at
   players[jumper].jump = 0.62
 if previous < TIP_TOSS and tipoff.time >= TIP_TOSS:
  announce("BALL UP! SHOOT TO JUMP", "whistle")
 if tipoff.time < TIP_DECISION:
  return
 var errors: Array = []
 for team in range(2):
  errors.append(absf(tipoff.jumps[team]-TIP_IDEAL_JUMP) if tipoff.jumps[team] >= 0 else 100.0)
 var winner = rng.randi_range(0,1) if is_equal_approx(errors[0],errors[1]) else (0 if errors[0] < errors[1] else 1)
 var height = ball_height()
 tipoff.active = false
 tipoff.winner = winner
 var receiver = winner*2+1
 flight = {"kind":"pass","start":ball,"end":players[receiver].pos,"start_height":height,"time":0.0,"duration":0.35,"target":receiver,"alley":false,"tip":true}
 announce("%s WINS THE TIP!" % Teams.DATA[teams[winner]].name,"catch")

func announce(message: String, kind: String = "action") -> void:
 banner = message
 banner_time = 1.8
 event_id += 1
 event_kind = kind

func gameplay_time_scale() -> float:
 return BULLET_TIME_SCALE if bullet_time_remaining > 0.0 else 1.0

func acquire_possession(player: int, dramatic: bool = false) -> void:
 owner = player
 players[player].possession_flash = POSSESSION_FLASH_DURATION
 players[player].hold_time = 0.0
 if dramatic:
  bullet_time_remaining = BULLET_TIME_DURATION

func hoop_for(team: int) -> Vector2:
 var right = team == 0
 if quarter >= 3:
  right = not right
 return HOOPS[1 if right else 0]

func rating(i: int, stat: int) -> float:
 var r: Array = Teams.DATA[teams[i / 2]].ratings[i % 2]
 if stat >= r.size():
  if stat == 6:
   return float(r[2])
  return float(r[mini(stat, r.size() - 1)])
 return float(r[stat])

func on_fire(team: int) -> bool:
 return (fire_player >= 0 and fire_player / 2 == team) or (team >= 0 and team < 2 and team_fire_timer[team] > 0.0)

func is_player_on_fire(index: int) -> bool:
 return fire_player == index or (index >= 0 and index < 4 and team_fire_timer[index / 2] > 0.0)

func refresh_heat_summary() -> void:
 for team in range(2):
  streak[team] = maxi(player_streak[team*2],player_streak[team*2+1])

func record_natural_basket(shooter: int, points: int = 2) -> void:
 var previous_fire = fire_player
 var team = shooter / 2
 var opp_team = 1 - team
 team_streak[opp_team] = 0
 if fire_player >= 0 and fire_player / 2 != team:
  fire_player = -1
  fire_points = 0
  fire_shots = 0
 for i in range(4):
  if i != shooter and i != fire_player:
   player_streak[i] = 0
 brick_count[shooter] = 0
 if fire_player == shooter:
  fire_points += points
  fire_shots += 1
  if fire_shots >= 4:
   fire_player = -1
   player_streak[shooter] = 0
   fire_points = 0
   fire_shots = 0
   announce("HE'S COOLED OFF!", "whistle")
 elif not is_player_on_fire(shooter):
  player_streak[shooter] = mini(3,player_streak[shooter]+1)
  if player_streak[shooter] >= 3:
   fire_player = shooter
   fire_points = 0
   fire_shots = 0
   if previous_fire >= 0 and previous_fire != shooter:
    player_streak[previous_fire] = 0
 refresh_heat_summary()

func record_miss(shooter: int) -> void:
 brick_count[shooter] += 1
 # Once ignited, missed shots do not extinguish fire; an opponent's basket does.
 if not is_player_on_fire(shooter):
  player_streak[shooter] = 0
 refresh_heat_summary()

func award_basket(shooter: int, points: int, dunk: bool, natural: bool = true, specialty: bool = false) -> bool:
 var team = shooter / 2
 score[team] += points
 stats[shooter].points += points
 stats[shooter].made += 1
 if dunk:
  stats[shooter].dunks += 1
 if natural:
  record_natural_basket(shooter, points)
  # Authored trigger: the first made specialty dunk per hoop in Q4/overtime.
  if dunk and specialty and quarter >= 4:
   var side = 0 if hoop_for(team).x < 640 else 1
   if board_breaks[side] < 0:
    board_breaks[side] = elapsed
    return true
 return false

func flight_position() -> Vector2:
 if flight.is_empty():
  return ball
 return flight.start.lerp(flight.end,clampf(flight.time/flight.duration,0,1))

func finisher_position(flight_time: float) -> Vector2:
 var progress = clampf(flight_time/flight.duration/0.8,0,1)
 return flight.player_start.lerp(flight.player_end,smoothstep(0,1,progress))

func ball_height() -> float:
 if tipoff.get("active",false):
  var t = maxf(0,tipoff.time-TIP_TOSS)
  return 1.2+7.5*t-5.5*t*t
 if pending_inbound >= 0:
  var age = maxf(0,elapsed-maxf(board_breaks[0],board_breaks[1]))
  return maxf(0.24,3.05-4.0*age*age)
 if not flight.is_empty():
  var t = clampf(flight.time/flight.duration,0,1)
  if flight.kind == "shot":
   return lerpf(flight.get("release_height",1.3),3.05,t)+sin(t*PI)*flight.get("arc_height",1.7 if flight.dunk else 4.6)
  elif flight.kind == "rebound":
   var bounce_count = flight.get("bounces", 0)
   if bounce_count == 0:
    var apex_bonus = flight.get("arc_height", 2.0)
    return maxf(0.24, lerpf(3.05, 0.24, t) + 4.0 * apex_bonus * t * (1.0 - t))
   else:
    return maxf(0.24, 0.24 + sin(t * PI) * flight.get("bounce_height", 0.9))
  elif flight.kind == "loose":
   return maxf(0.24, 0.24 + sin(t * PI) * flight.get("arc_height", 1.1))
  return lerpf(flight.get("start_height",1.1),flight.get("end_height",1.1),t)+sin(t*PI)*(1.4 if flight.get("alley",false) else 0.5)
 if owner >= 0:
  var p_own: Dictionary = players[owner]
  if p_own.receive_jump > 0:
   return 1.1+receive_height(owner)
  elif p_own.charge > 0:
   var jump = sin(clampf(p_own.charge / 1.16, 0.0, 1.0) * PI) * 1.35
   return 1.3 + jump
  elif p_own.jump > 0:
   var jump = sin(clampf((0.75 - p_own.jump) / 0.75, 0.0, 1.0) * PI) * 1.6
   return 1.3 + jump
  return 0.30+absf(sin(elapsed*12.0))*0.9
 return 0.24

func teammate_commands(commands: Dictionary) -> Dictionary:
 var effective = commands.duplicate(true)
 if owner < 0 or commands.has(owner):
  teammate_shot_order = -1
  return effective
 var partner = (owner/2)*2+(1-owner%2)
 if not commands.has(partner):
  teammate_shot_order = -1
  return effective
 var request: Dictionary = commands[partner]
 var shoot: bool = request.get("shoot",false)
 var pass_request: bool = request.get("pass",false)
 var turbo: bool = request.get("turbo",false)
 if pass_request:
  var cpu = ai(owner)
  cpu["pass"] = true
  cpu.shoot = false
  cpu.turbo = turbo
  effective[owner] = cpu
  teammate_shot_order = -1
  announce("CALL FOR PASS!", "pass")
 elif shoot or teammate_shot_order == owner:
  var cpu = ai(owner)
  cpu.shoot = shoot and not pass_request
  cpu["pass"] = false
  cpu.turbo = turbo
  effective[owner] = cpu
  if shoot and teammate_shot_order != owner:
   announce("TAKE THE SHOT!", "shot")
  teammate_shot_order = owner if cpu.shoot else -1
 return effective

func receive_height(i: int) -> float:
 return sin(clampf(1.0-players[i].receive_jump/0.7,0,1)*PI)*1.65

func start_receive_jump(i: int) -> void:
 players[i].receive_jump = 0.7
 players[i].jump = 0.7
 players[i].cooldown = 0.75
 players[i].charge = 0.0
 players[i].fake = 0.0

func prepare_receivers(delta: float, commands: Dictionary, effective: Dictionary) -> void:
 if owner < 0:
  return
 var receiver = (owner/2)*2+(1-owner%2)
 var p: Dictionary = players[receiver]
 if p.stun > delta or p.cooldown > delta:
  return
 var request: Dictionary = effective[receiver]
 var shoot: bool = request.get("shoot",false)
 var pressed: bool = (shoot and not p.shoot_held) or request.get("jump_press",false)
 var sender: Dictionary = effective[owner]
 var turbo: bool = sender.get("turbo",false) and (players[owner].turbo > 0.02 or infinite_turbo or is_player_on_fire(owner))
 if commands.has(receiver):
  # The caller can jump while their Shoot order also starts a CPU shot windup.
  if pressed:
   start_receive_jump(receiver)
 elif sender.get("pass",false) and turbo and players[owner].cooldown <= delta and players[owner].stun <= delta and p.pos.distance_to(hoop_for(receiver/2)) < 220:
  start_receive_jump(receiver)
  effective[receiver].move = Vector2.ZERO

func get_inbound_spots(team: int, after_goal: bool = false) -> Array:
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640
 var inbound_pos = Vector2(75.0 if left_side else 1205.0, own_hoop.y) if after_goal else (own_hoop + Vector2(85 if left_side else -85, 0))
 var spots = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
 for i in range(4):
  var side = i / 2
  var h = hoop_for(1 - side)
  spots[i] = Vector2(h.x + (190 if h.x < 640 else -190), 390 + (i % 2) * 145)
 var teammate = (team * 2) + 1
 spots[teammate] = Vector2(own_hoop.x + (115.0 if left_side else -115.0), own_hoop.y + 15.0) if after_goal else Vector2(own_hoop.x + (140 if left_side else -140), own_hoop.y + 40)
 var opp_team = 1 - team
 spots[opp_team * 2] = Vector2(640.0 + (-150.0 if left_side else 150.0), 405.0) if after_goal else Vector2(640 + (-90 if left_side else 90), 380)
 spots[opp_team * 2 + 1] = Vector2(640.0 + (-150.0 if left_side else 150.0), 535.0) if after_goal else Vector2(640 + (-90 if left_side else 90), 520)
 spots[team * 2] = inbound_pos
 return spots

func start_goal_inbound(team: int) -> void:
 if not tipoff.is_empty():
  tipoff.active = false
 inbounding_team = team
 pending_inbound = -1
 shatter_shooter = -1
 teammate_shot_order = -1
 flight = {}
 shot_clock = 24.0
 acquire_possession(team * 2)
 for i in range(4):
  players[i].charge = 0.0
  players[i].fake = 0.0
  players[i].drive = 0.0
  players[i].swipe = 0.0
  players[i].swipe_resolved = false
  players[i].swipe_shove = false
  players[i].shoot_held = false
  players[i].spin = 0.0
  players[i].elbow = 0.0
  players[i].turbo_flash = 0.0
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
 players[team * 2].cooldown = 0.40
 var spots = get_inbound_spots(team, true)
 inbound_transition = {
  "active": true,
  "team": team,
  "spots": spots,
  "timer": 0.0
 }
 freeze = 1.0

func tick_inbound_transition(delta: float) -> void:
 inbound_transition.timer += delta
 var team: int = inbound_transition.team
 var spots: Array = inbound_transition.spots
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640
 var all_settled = true
 for i in range(4):
  var p: Dictionary = players[i]
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  if p.stun <= 0.0:
   p.shove_kind = ""
   p.shove_time = 0.0
  p.pickup_delay = maxf(0.0, p.get("pickup_delay", 0.0) - delta)
  p.rim_hang = 0.0
  p.receive_jump = 0.0
  # If in the air, land rapidly
  if p.jump > 0.0:
   p.jump = maxf(0.0, p.jump - delta * 4.0)
   all_settled = false
  else:
   p.jump = 0.0
   var target: Vector2 = spots[i]
   var diff = target - p.pos
   var dist = diff.length()
   # Move 2x as fast so we don't waste the player's time
   var run_speed = (125.0 + rating(i, 0) * 7.0) * 2.0
   if dist > 8.0:
    all_settled = false
    var dir = diff / dist
    var step = minf(dist, run_speed * delta)
    p.pos += dir * step
    p.vel = dir * run_speed
    if absf(dir.x) > 0.1:
     p.face = signf(dir.x)
   else:
    p.pos = target
    p.vel = Vector2.ZERO
    p.face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)

 if owner >= 0 and owner < 4:
  ball = players[owner].pos + Vector2(players[owner].face * 14, -7)

 if all_settled or inbound_transition.timer > 2.5:
  for i in range(4):
   players[i].pos = spots[i]
   players[i].vel = Vector2.ZERO
   players[i].jump = 0.0
   players[i].face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  if owner >= 0 and owner < 4:
   ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
  inbound_transition = {}
  freeze = 0.45

func record_quarter_score() -> void:
 var prior = [0, 0]
 for qs in quarter_scores:
  prior[0] += qs[0]
  prior[1] += qs[1]
 var q_pts = [maxi(0, score[0] - prior[0]), maxi(0, score[1] - prior[1])]
 quarter_scores.append(q_pts)

func start_quarter_transition() -> void:
 record_quarter_score()
 var is_final = quarter >= 4 and score[0] != score[1]
 var is_ot = quarter >= 4 and score[0] == score[1]
 var banner_msg = ""
 if is_final:
  banner_msg = "FINAL"
  phase = "finished"
 elif is_ot:
  banner_msg = "OVERTIME" if overtime == 0 else ("DOUBLE OVERTIME" if overtime == 1 else "TRIPLE OVERTIME")
 elif quarter == 2:
  banner_msg = "HALFTIME • SWITCH ENDS"
 else:
  banner_msg = "END OF QUARTER %d" % quarter
 announce(banner_msg, "whistle")
 var dur = 3.6 if period_length >= 60.0 else minf(3.6, maxf(0.8, period_length * 0.15))
 quarter_transition = {
  "active": true,
  "timer": 0.0,
  "duration": dur,
  "quarter": quarter,
  "score_at_end": score.duplicate(),
  "fade_alpha": 0.0,
  "switched": false,
  "is_final": is_final,
  "is_overtime": is_ot,
  "banner": banner_msg
 }

func tick_quarter_transition(delta: float) -> void:
 quarter_transition.timer += delta
 var t: float = quarter_transition.timer
 var dur: float = quarter_transition.duration
 var p_norm = clampf(t / maxf(0.001, dur), 0.0, 1.0)
 for p in players:
  p.vel = Vector2.ZERO
  if p.jump > 0.0:
   p.jump = maxf(0.0, p.jump - delta * 4.0)
  p.cooldown = 0.5
  p.shove_kind = ""
  p.shove_time = 0.0
 if p_norm < 0.60:
  quarter_transition.fade_alpha = 0.0
 elif p_norm < 0.78:
  quarter_transition.fade_alpha = (p_norm - 0.60) / 0.18
 else:
  quarter_transition.fade_alpha = 1.0 - (p_norm - 0.78) / 0.22
 if p_norm >= 0.78 and not quarter_transition.switched:
  quarter_transition.switched = true
  clock_buzzer_sounded = false
  if quarter_transition.is_final:
   phase = "finished"
  else:
   next_period(true)
 if t >= dur:
  quarter_transition = {}

func inbound(team: int, after_goal: bool = false, animated: bool = false) -> void:
 if animated:
  start_goal_inbound(team)
  return
 if not tipoff.is_empty():
  tipoff.active = false
 inbounding_team = team if after_goal else -1
 pending_inbound = -1
 shatter_shooter = -1
 teammate_shot_order = -1
 inbound_transition = {}
 acquire_possession(team * 2)
 flight = {}
 shot_clock = 24.0
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640
 var spots = get_inbound_spots(team, after_goal)
 for i in range(4):
  players[i].pos = spots[i]
  players[i].cooldown = 0.0
  players[i].stun = 0.0
  players[i].charge = 0.0
  players[i].fake = 0.0
  players[i].drive = 0.0
  players[i].swipe = 0.0
  players[i].swipe_resolved = false
  players[i].swipe_shove = false
  players[i].shoot_held = false
  if players[i].get("rim_hang", 0.0) <= 0.0:
   players[i].jump = 0.0
  players[i].receive_jump = 0.0
  players[i].face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
 var teammate = (team * 2) + 1
 players[teammate].face = -1 if left_side else 1
 var opp_team = 1 - team
 players[opp_team * 2].face = -1 if left_side else 1
 players[opp_team * 2 + 1].face = -1 if left_side else 1
 players[owner].face = 1 if left_side else -1
 ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
 freeze = 1.0

func tick(delta: float, commands: Dictionary) -> void:
 if phase != "playing" and not quarter_transition.get("active", false):
  return
 var real_delta = delta
 var time_scale = gameplay_time_scale()
 bullet_time_remaining = maxf(0.0, bullet_time_remaining - real_delta)
 for player in players:
  player.possession_flash = maxf(0.0, player.get("possession_flash", 0.0) - real_delta)
 delta *= time_scale
 elapsed += delta
 banner_time = maxf(0.0, banner_time - delta)
 if assist_window > 0.0:
  assist_window = maxf(0.0, assist_window - delta)
  if assist_window <= 0.0:
   last_passer = -1
 var ctrl_team = owner / 2 if owner >= 0 else -1
 for t in range(2):
  if team_fire_timer[t] > 0.0 and (ctrl_team < 0 or ctrl_team == t):
   team_fire_timer[t] = maxf(0.0, team_fire_timer[t] - delta)
   if team_fire_timer[t] <= 0.0:
    announce("TEAM ZONE EXPIRED!", "whistle")
 if tipoff.get("active",false):
  tick_tipoff(delta,commands)
  return
 if quarter_transition.get("active", false):
  tick_quarter_transition(delta)
  return
 if inbound_transition.get("active", false):
  tick_inbound_transition(delta)
  return
 if inbounding_team >= 0:
  if owner < 0 or owner / 2 != inbounding_team or (players[owner].pos.x >= COURT.position.x and players[owner].pos.x <= COURT.end.x):
   inbounding_team = -1
 if freeze > 0:
  if pending_inbound >= 0:
   for p in players:
    p.jump = maxf(0,p.jump-delta)
  freeze = maxf(0,freeze-delta)
  return
 loose_ball_timer = maxf(0.0, loose_ball_timer - delta)
 in_cylinder_timer = maxf(0.0, in_cylinder_timer - delta)
 must_rebound_timer = maxf(0.0, must_rebound_timer - delta)
 if pending_inbound >= 0:
  inbound(pending_inbound, true)
  return
 # A released shot is allowed to finish after either buzzer. Clock stopped while inbounding.
 if inbounding_team < 0:
  clock = maxf(0.0, clock - delta * CLOCK_TIME_SCALE)
  if clock <= 0.0 and not clock_buzzer_sounded:
   clock_buzzer_sounded = true
   announce("BUZZER", "buzzer")
  if flight.is_empty() or flight.get("kind", "") != "shot":
   if clock >= 24.0:
    shot_clock = maxf(0.0, shot_clock - delta * SHOT_CLOCK_TIME_SCALE)
   else:
    shot_clock = 24.0
 if clock <= 0 and flight.is_empty():
  start_quarter_transition()
  return
 if clock >= 24.0 and shot_clock <= 0 and flight.is_empty():
  var next_team = 1 - (owner / 2 if owner >= 0 else 0)
  announce("SHOT CLOCK VIOLATION", "whistle")
  inbound(next_team)
  return
 var effective_commands = teammate_commands(commands)
 # Cache intent before any player acts so simultaneous jump/pass is slot-order independent.
 for i in range(4):
  if not effective_commands.has(i):
   effective_commands[i] = ai(i)
 prepare_receivers(delta,commands,effective_commands)
 # A dunker may abandon the attempt for a pass or layup before reaching the rim (arcade PLYR.ASM:2915-2950).
 if not flight.is_empty() and flight.kind == "shot" and flight.dunk and not flight.blocked and flight.time < flight.duration*0.85:
  var dunker: int = flight.shooter
  if commands.has(dunker):
   if commands[dunker].get("pass",false):
    stats[dunker].attempts = maxi(0,stats[dunker].attempts-1)
    var mate = (dunker / 2) * 2 + (1 - dunker % 2)
    var is_double_dunk = players[mate].receive_jump > 0.05 or players[mate].jump > 0.05
    pass_ball(dunker,commands[dunker].get("turbo",false))
    if is_double_dunk and not flight.is_empty():
     flight.double_dunk = true
     announce("DOUBLE DUNK!", "dunk")
    else:
     announce("AIRBORNE DISH!", "pass")
    players[dunker].charge = 0.0
    players[dunker].shoot_held = false
   elif commands[dunker].get("jump_press", false) and flight.time >= 0.18 and not flight.get("bailed_to_layup", false):
    flight.dunk = false
    flight.layup = true
    flight.super_dunk = false
    flight.finish = "layup"
    flight.arc_height = 1.0
    flight.bailed_to_layup = true
    var breakdown = calculate_shot_percentage(dunker, 0.58, false, true, false, false, false, false, null, true)
    flight.made = rng.randf() < breakdown.chance
    flight.shot_breakdown = breakdown
    players[dunker].jump = minf(players[dunker].jump, 0.45)
    players[dunker].charge = 0.0
    players[dunker].shoot_held = false
    announce("SWITCHES HANDS! FINGER ROLL!", "shot")
 for i in range(4):
  var p: Dictionary = players[i]
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  if p.stun <= 0.0:
   p.shove_kind = ""
   p.shove_time = 0.0
  p.pickup_delay = maxf(0.0, p.get("pickup_delay", 0.0) - delta)
  p.rim_hang = maxf(0.0, p.get("rim_hang", 0.0) - delta)
  if p.rim_hang <= 0.0:
   p.jump = maxf(0.0, p.jump - delta)
  p.receive_jump = maxf(0.0,p.receive_jump-delta)
  p.fake = maxf(0.0, p.fake - delta)
  p.swipe = maxf(0.0,p.swipe-delta)
  p.spin = maxf(0.0, p.get("spin", 0.0) - delta)
  p.spin_cooldown = maxf(0.0, p.get("spin_cooldown", 0.0) - delta)
  p.elbow = maxf(0.0, p.get("elbow", 0.0) - delta)
  p.steal_immune = maxf(0.0, p.get("steal_immune", 0.0) - delta)
  p.push_keep_ball = maxf(0.0, p.get("push_keep_ball", 0.0) - delta)
  p.pass_off = maxf(0.0, p.get("pass_off", 0.0) - delta)
  p.nasty_timer = maxf(0.0, p.get("nasty_timer", 0.0) - delta)
  p.turbo_burnout = maxf(0.0, p.get("turbo_burnout", 0.0) - real_delta)
  p.turbo_flash = maxf(0.0, p.get("turbo_flash", 0.0) - delta)
  if owner == i and inbounding_team < 0:
   p.hold_time = p.get("hold_time", 0.0) + delta
  else:
   p.hold_time = 0.0
  if p.swipe > 0.0 and not p.get("swipe_resolved", false) and p.swipe <= 0.25:
   p.swipe_resolved = true
   resolve_steal(i, p.get("swipe_shove", false))
  p.drive = maxf(0.0,p.drive-delta)
  var c: Dictionary = effective_commands[i]
  if p.stun > 0:
   p.charge = 0.0
   p.shoot_held = false
   p.receive_jump = 0.0
   p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
   var friction = 420.0 if p.get("shove_kind", "") == "flyback" else 600.0
   p.vel = p.vel.move_toward(Vector2.ZERO, delta * friction)
   continue
  var move: Vector2 = c.get("move", Vector2.ZERO)
  move = move.limit_length()
  var turbo: bool = c.get("turbo", false) and (p.turbo > 0.001 or infinite_turbo or is_player_on_fire(i))
  var spd_stat = clampi(int(rating(i, 0)), 0, 10)
  # Authentic arcade walking speed: BV_TABLE scaled from 800px arcade court to 1050px court at 54 Hz:
  # BV / 1024.0 * 54.0 * (1050.0 / 800.0) = BV * 0.069213867 (283.6 - 338.3 px/s)
  var speed = float(BV_TABLE[spd_stat]) * 0.069213867
  if owner == i:
   speed *= 0.885
   # Backcourt stalling penalty (PLYR.ASM:2188-2210): leading/tied ball-carrier in backcourt with <=10s on shot clock
   if p.pos.distance_to(hoop_for(i / 2)) >= 530.0 and shot_clock <= 10.0 and score[1 - i / 2] <= score[i / 2]:
    speed *= 0.68
  elif owner >= 0 and owner / 2 == i / 2:
   speed *= 0.95
  if clock < 50.0 and score[1 - i / 2] > score[i / 2]:
   speed *= 1.08
  if p.turbo_burnout > 0.0:
   speed *= 0.85
   p.turbo = 0.0
  elif turbo:
   # Authentic arcade turbo boost: +3f00h added to BV_TABLE base speed (PLYR.ASM:2280)
   # 0x3f00 / 0x10020 = +24.6% boost (~1.246x), not +40%
   speed *= 1.246
   if move.length() > 0.01:
    var drain_mult = 0.75 if (score[1 - i / 2] - score[i / 2] >= 8) else 1.0
    # Authentic arcade turbo drain: 390 ticks for full meter (PLYR.ASM:2480)
    # 390 / 53.20488 = 7.33s -> drain rate = 1.0 / 7.3304 = 0.1364/s
    p.turbo = maxf(0.0, p.turbo - delta * 0.1364 * drain_mult)
    if p.turbo <= 0.001 and not infinite_turbo and not is_player_on_fire(i):
     p.turbo = 0.0
     p.turbo_burnout = 0.75
  elif c.get("turbo", false) and p.turbo <= 0.001 and p.turbo_burnout <= 0.0 and not infinite_turbo and not is_player_on_fire(i):
   p.turbo = 0.0
   p.turbo_burnout = 0.75
   speed *= 0.85
  else:
   # Authentic arcade turbo recharge: ~200 ticks for full meter (PLYR.ASM:2482, SCORE.ASM:283)
   # 200 / 53.20488 = 3.76s -> recharge rate = 1.0 / 3.7591 = 0.2660/s
   p.turbo = minf(1.0, p.turbo + delta * 0.2660)
  if infinite_turbo or is_player_on_fire(i):
   p.turbo = 1.0
   p.turbo_burnout = 0.0
  var spin_press: bool = c.get("spin", false)
  if owner == i and spin_press and inbounding_team < 0 and p.jump <= 0.0 and p.receive_jump <= 0.0 and p.cooldown <= 0.0 and p.get("spin", 0.0) <= 0.0 and p.get("elbow", 0.0) <= 0.0:
   if p.turbo > 0.14 or infinite_turbo or is_player_on_fire(i):
    p.turbo = maxf(0.0, p.turbo - (2.0 / 7.0))
    if move.length() > 0.2:
     # Consecutive spin within 2.0s reduces steal immunity to 10 ticks (0.188s) instead of 60 ticks (1.128s) (PLYR.ASM:2424-2436)
     p.steal_immune = (10.0 / ARCADE_TSEC) if p.get("spin_cooldown", 0.0) > 0.0 else (60.0 / ARCADE_TSEC)
     p.spin = 0.45
     p.spin_cooldown = 2.0
     p.cooldown = 0.45
     p.vel = move.normalized() * (speed * 1.35)
     # 0.5% mid-spin fumble chance when leading by 5+ points (PLYRSEQ2.ASM:1111-1180)
     if (score[i / 2] - score[1 - i / 2]) >= 5 and not tournament_mode and not is_player_on_fire(i) and rng.randf() < 0.005:
      owner = -1
      shot_clock = 24.0
      loose_ball_timer = 0.50
      p.pickup_delay = 0.50
      stats[i].turnovers = stats[i].get("turnovers", 0) + 1
      var fumble_dest = (p.pos + move.normalized() * 65.0).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
      flight = {"kind":"loose", "start":p.pos, "end":fumble_dest, "time":0.0, "duration":0.40, "arc_height":0.9}
      announce("LOST THE HANDLE! LOOSE BALL", "steal")
     else:
      announce("SPIN MOVE!", "pass")
    else:
     # Standing elbow grants 140 ticks (2.632s) steal immunity (PLYR2.ASM:4162-4165)
     p.steal_immune = 140.0 / ARCADE_TSEC
     p.elbow = 0.50
     p.push_keep_ball = 80.0 / ARCADE_TSEC
     p.spin_cooldown = 1.2
     p.cooldown = 0.50
     var nearby_defs: Array = []
     for d in range(4):
      # 40 * DIST_REDUCTION (34 ASM units * 1.30 = 45.0 px) (PLYR2.ASM:5995, 6008)
      if d / 2 != i / 2 and players[d].pos.distance_to(p.pos) < 45.0:
       nearby_defs.append(d)
     for d in nearby_defs:
      # 50% per-defender hit roll when multiple defenders crowd in (PLYR2.ASM:5998-6000)
      if nearby_defs.size() == 1 or rng.randf() < 0.50:
       players[d].stun = 0.75
       players[d].shove_kind = "stumble"
       players[d].shove_time = 0.75
       var push_dir = (players[d].pos - p.pos).normalized()
       if push_dir.length() < 0.1:
        push_dir = Vector2.RIGHT * p.face
       var face_dir = -signf(push_dir.x)
       if absf(face_dir) > 0.1:
        players[d].face = face_dir
       players[d].pos = (players[d].pos + push_dir * 18.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
       players[d].vel = push_dir * 180.0
     announce("CLEAR OUT!", "shove")
   else:
    p.turbo_flash = 0.60
    announce("NEED TURBO!", "turbo")
  var shoot: bool = c.get("shoot", false)
  var shooting_this_tick = owner == i and shoot and p.pos.x >= COURT.position.x and p.pos.x <= COURT.end.x and not c.get("pass", false) and p.cooldown <= 0.0
  if shooting_this_tick and (not p.shoot_held or p.charge <= 0.0):
   var was_moving = p.get("still_time", 1.0) < 0.10 or p.vel.length() > 10.0 or move.length() > 0.05
   p.shot_is_moving = was_moving
   if was_moving:
    var drift = p.vel if p.vel.length() > 10.0 else p.get("last_move_vel", Vector2.ZERO)
    if drift.length() < 10.0 and move.length() > 0.05:
     drift = move.normalized() * speed
    p.shot_drift_vel = drift * 0.70
    p.vel = move * speed if move.length() > 0.05 else p.shot_drift_vel
   else:
    p.shot_is_moving = false
    p.shot_drift_vel = Vector2.ZERO
    p.vel = Vector2.ZERO
  var is_moving = not shooting_this_tick and (move.length() > 0.05 or p.vel.length() > 10.0) and p.charge <= 0.0 and p.jump <= 0.0
  if is_moving:
   p.still_time = 0.0
   if p.vel.length() > 10.0:
    p.last_move_vel = p.vel
   elif move.length() > 0.05:
    p.last_move_vel = move.normalized() * speed
  elif p.charge <= 0.0 and p.jump <= 0.0:
   p.still_time += delta
  if p.get("spin", 0.0) > 0.0:
   if move.length() > 0.1:
    p.vel = move.normalized() * (speed * 1.35)
  elif p.get("elbow", 0.0) > 0.0:
   p.vel = Vector2.ZERO
  elif p.get("rebound_glide", 0.0) > 0.0:
   p.rebound_glide = maxf(0.0, p.rebound_glide - delta)
  elif owner == i and (p.charge > 0.0 or shooting_this_tick):
   if p.get("shot_is_moving", false):
    p.vel = move * speed if move.length() > 0.05 else p.get("shot_drift_vel", p.vel)
   else:
    p.vel = Vector2.ZERO
  else:
   p.vel = move * speed
  if p.jump > 0.0 and owner != i and p.receive_jump <= 0.0 and p.get("rebound_glide", 0.0) <= 0.0:
   if p.get("shot_is_moving", false) and p.get("shot_drift_vel", Vector2.ZERO).length() > 0:
    p.vel = p.shot_drift_vel
   else:
    p.vel = Vector2.ZERO
  elif p.jump <= 0.0 and p.charge <= 0.0 and not shooting_this_tick:
   p.shot_is_moving = false
   p.shot_drift_vel = Vector2.ZERO
  if p.get("swipe", 0.0) > 0.0:
   p.vel = Vector2.ZERO
  if p.vel.length() > 40 and p.vel.dot((hoop_for(i/2)-p.pos).normalized()) > 20:
   p.drive = 0.16
  if owner == i and (p.pos.x < COURT.position.x or p.pos.x > COURT.end.x):
   if p.pos.x < COURT.position.x:
    p.pos.x = clampf(p.pos.x + p.vel.x * delta, 50.0, COURT.position.x - 10.0)
   else:
    p.pos.x = clampf(p.pos.x + p.vel.x * delta, COURT.end.x + 10.0, 1225.0)
   p.pos.y = clampf(p.pos.y + p.vel.y * delta, COURT.position.y + 18.0, COURT.end.y - 18.0)
  elif not flight.is_empty() and flight.kind == "shot" and flight.shooter == i and flight.has("player_start"):
   var destination = finisher_position(flight.time+delta)
   p.vel = (destination-p.pos)/maxf(delta,0.0001)
   p.pos = destination
   p.drive = 0.0
  else:
   p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
   if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
    var own_hoop = hoop_for(1 - inbounding_team)
    var left_side = own_hoop.x < 640
    if i / 2 != inbounding_team:
     if left_side:
      p.pos.x = maxf(p.pos.x, 480.0)
     else:
      p.pos.x = minf(p.pos.x, 800.0)
    elif i != owner:
     if left_side:
      p.pos.x = minf(p.pos.x, 420.0)
     else:
      p.pos.x = maxf(p.pos.x, 860.0)
  if owner == i and p.pos.x >= COURT.position.x and p.pos.x <= COURT.end.x:
   inbounding_team = -1
  if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
   var own_hoop = hoop_for(1 - inbounding_team)
   var left_side = own_hoop.x < 640
   p.face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  elif absf(p.vel.x) > 0.1:
   p.face = signf(p.vel.x)
  if owner == i:
   if p.pos.x < COURT.position.x or p.pos.x > COURT.end.x:
    shoot = false
    p.charge = 0.0
   if c.get("pass", false) and p.cooldown <= 0:
    pass_ball(i, turbo)
    p.charge = 0.0
    shoot = false
   elif shoot:
    if p.shot_is_moving:
     p.vel = move * speed if move.length() > 0.05 else p.shot_drift_vel
    else:
     p.vel = Vector2.ZERO
    p.fake = 0.0
    p.charge = minf(1.25, p.charge + delta)
    var finish = finish_kind(i,turbo)
    if (finish == "turbo_dunk" and p.charge >= 0.16) or (finish == "dunk" and p.charge >= 0.35):
     shoot_ball(i,turbo)
     p.charge = 0.0
   elif p.shoot_held and p.charge > 0:
    if p.charge < 0.16 and commands.has(i) and clock >= 4.0:
     p.fake = 0.38
     p.shot_is_moving = false
     p.shot_drift_vel = Vector2.ZERO
     announce("HEAD FAKE!", "fake")
    else:
     var jump_h = sin(clampf(p.charge / 1.16, 0.0, 1.0) * PI) * 1.35
     shoot_ball(i, turbo, false, 1.3 + jump_h)
     p.jump = maxf(0.08, 1.16 - p.charge)
     if not p.shot_is_moving:
      p.vel = Vector2.ZERO
    p.charge = 0.0
  else:
   # Off-ball commands target a CPU ball carrier; never override another human.
   var ordering_cpu = owner >= 0 and owner / 2 == i / 2 and not commands.has(owner)
   if not ordering_cpu and p.receive_jump <= 0:
    if shoot and not p.shoot_held and p.cooldown <= 0:
     defend(i, turbo)
    if c.get("pass", false) and p.cooldown <= 0:
     steal(i, turbo)
  p.shoot_held = shoot
 # Keep athletes separated without pushing them outside bounds.
 for i in range(4):
  for j in range(i + 1, 4):
   var offset: Vector2 = players[j].pos - players[i].pos
   if offset.length() < 27 and offset.length() > 0.01:
    var push = offset.normalized() * (27 - offset.length()) * 0.5
    players[i].pos = (players[i].pos - push).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
    players[j].pos = (players[j].pos + push).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
 if not flight.is_empty():
  tick_flight(delta)
 elif owner >= 0:
  ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
 else:
  if loose_ball_timer <= 0.0 and in_cylinder_timer <= 0.0:
   for i in range(4):
    if players[i].stun <= 0 and players[i].get("pickup_delay", 0.0) <= 0.0 and players[i].pos.distance_to(ball) < 30:
     acquire_possession(i, true)
     players[i].push_keep_ball = 1.33
     players[i].steal_immune = 0.67 if rng.randf() < 0.05 else 0.25
     shot_clock = 24.0
     stats[i].rebounds += 1
     announce("REBOUND!", "catch")
     break

func drone_skill_index(i: int) -> int:
 var team = i / 2
 var opp_team = 1 - team
 var pts_down = score[opp_team] - score[team]
 var adj = (difficulty - 1) * 4
 var heat_bonus = 0
 # Authentic drone toughness boost when heating up / on-fire (DRONE.ASM:2145-2156)
 if player_streak[i] >= 2 or is_player_on_fire(i):
  heat_bonus = 8
 elif streak[team] >= 2 or on_fire(team):
  heat_bonus = 2
 return clampi(15 + pts_down + adj + heat_bonus, 0, 30)

func ai(i: int) -> Dictionary:
 var p: Dictionary = players[i]
 var team = i / 2
 var opp_team = 1 - team
 var deficit = score[opp_team] - score[team]
 var skill_idx = drone_skill_index(i)
 var target: Vector2 = p.pos
 var shoot = false
 var pass_action = false
 var turbo = false
 var spin = false
 if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
  var own_hoop = hoop_for(1 - inbounding_team)
  var left_side = own_hoop.x < 640
  if i == owner:
   return {"move": Vector2.ZERO, "shoot": false, "pass": p.cooldown <= 0, "turbo": false, "spin": false}
  elif i / 2 == inbounding_team:
   # Teammate waits in own zone for the inbound pass (DRONE.ASM:1690-1765, PLYR.ASM:11276-11295)
   var wait_spot = Vector2(own_hoop.x + (115.0 if left_side else -115.0), own_hoop.y + 15.0)
   var diff = wait_spot - p.pos
   var move = diff.normalized() if diff.length() > 15.0 else Vector2.ZERO
   p.face = -1 if left_side else 1
   return {"move": move, "shoot": false, "pass": false, "turbo": false, "spin": false}
  else:
   # Enemy defenders stay back near midcourt during inbound (DRONE.ASM:1690-1765, PLYR.ASM:11276-11295)
   var back_x = 640.0 + (-150.0 if left_side else 150.0)
   var slot_y = 405.0 if (i % 2 == 0) else 535.0
   var def_spot = Vector2(back_x, slot_y)
   var diff = def_spot - p.pos
   var move = diff.normalized() if diff.length() > 20.0 else Vector2.ZERO
   p.face = -1 if left_side else 1
   return {"move": move, "shoot": false, "pass": false, "turbo": false, "spin": false}
 if not flight.is_empty() and flight.kind == "pass" and flight.get("alley",false) and flight.target == i and p.receive_jump > 0:
  target = p.pos
 elif owner == i and (p.pos.x < COURT.position.x or p.pos.x > COURT.end.x):
  return {"move":Vector2.ZERO, "shoot":false, "pass":p.cooldown <= 0, "turbo":false, "spin":false}
 elif owner == i:
  var hoop = hoop_for(team)
  var mate = (team * 2) + (1 - (i % 2))
  var dist: float = p.pos.distance_to(hoop)
  var mate_dist: float = players[mate].pos.distance_to(hoop)
  var near_def = nearest_defender(i)
  # Breakaway check (DRONE.ASM:191-215): no defender closer to hoop than ball carrier
  var breakaway = true
  for j in range(4):
   if j / 2 != team and players[j].stun <= 0.0 and players[j].pos.distance_to(hoop) < dist + 20.0:
    breakaway = false
    break
  # Alley-oop pass priority if teammate is airborne for a lob (DRONE.ASM:220-260)
  if players[mate].receive_jump > 0.05 and players[mate].stun <= 0.0 and mate_dist < 220.0 and p.cooldown <= 0.0:
   return {"move":(hoop - p.pos).normalized(), "shoot":false, "pass":true, "turbo":true, "spin":false}
  target = hoop + Vector2(-90 if hoop.x > 640 else 90, 10 * sin(elapsed + i))
  if p.charge > 0 and dist < 165:
   target = hoop + Vector2(60 if hoop.x > 640 else -60, 0)
  turbo = breakaway or dist < 240 or (deficit > 0 and p.get("turbo", 1.0) > 0.25)
  # Clock management when leading by 6+ in Q4 (DRONE.ASM:259-277)
  if quarter >= 4 and deficit <= -6 and shot_clock > 6.0 and clock > 6.0 and not breakaway:
   shoot = false
   target = hoop + Vector2(-220 if hoop.x > 640 else 220, 25.0 * sin(elapsed + i))
  else:
   # 3-pointer urgency check (DRONE.ASM:710-768 drone_chk3ptr: max 290 ASM units -> 375px, defender 70 ASM units -> 91px)
   var min_3pt_deficit = 3 if clock <= 60.0 else 6
   var need_three = is_three_pointer(p.pos, hoop) and dist < 375.0 and (is_player_on_fire(i) or (not on_fire(opp_team) and deficit >= min_3pt_deficit and (clock < 40.0 or near_def >= 91.0 or rng.randf() < (1.0 / 9.0))))
   if dist < 125 or shot_clock < 3 or clock < 2.0 or need_three or (dist < 370 and fmod(elapsed + i, 5.0) < 0.7):
    shoot = p.charge < 0.56
   # Contested shot windup pump-fake or mid-air pass bailout (DRONE.ASM:536-645 #fake, #injmp: 70 ASM units -> 91px)
   if p.charge > 0.0 and near_def < 91.0 and clock >= 4.0 and shot_clock >= 4.0:
    var jumping_blocker = false
    for j in range(4):
     if j / 2 != team and players[j].pos.distance_to(p.pos) < 91.0 and players[j].get("jump", 0.0) > 0.10:
      jumping_blocker = true
      break
    if jumping_blocker and p.cooldown <= 0.0 and rng.randf() < 0.125:
     shoot = false
     pass_action = true
    elif p.charge < 0.16 and rng.randf() < 0.03125:
     shoot = false
  # Defender avoidance / pass to open teammate (DRONE.ASM:342-502 #goaround)
  if p.cooldown <= 0 and near_def < 55.0:
   if (mate_dist < dist - 30.0 and nearest_defender(mate) > 65.0) or fmod(elapsed, 2.0) < 0.025:
    pass_action = true
   elif p.get("spin_cooldown", 0.0) <= 0.0 and p.get("turbo", 1.0) > 0.35 and rng.randf() < float(DRONE_P_T[skill_idx]) * 0.004:
    spin = true
 elif not flight.is_empty() and flight.get("kind", "") == "shot":
  var shooter: int = flight.shooter
  if shooter / 2 != team:
   target = flight_position()
   var t = clampf(flight.time/flight.duration,0,1)
   var arc: float = flight.get("arc_height",1.7 if flight.dunk else 4.6)
   var descending = 3.05-flight.get("release_height",1.3)+PI*arc*cos(t*PI) < 0
   var reacts: bool = flight.time >= 0.18-0.04*clampi(difficulty,0,2) and flight.get("cpu_block_allowed",[true,true,true,true])[i]
   shoot = reacts and not flight.blocked and p.cooldown <= 0 and p.pos.distance_to(target) < 72 and ball_height() <= 4.6 and (not descending or flight.dunk or is_player_on_fire(i))
  else:
   target = hoop_for(team)
 elif not flight.is_empty() and (flight.get("kind", "") == "rebound" or flight.get("kind", "") == "loose"):
  var intercept_t = clampf((flight.time + REBOUND_GLIDE_DURATION) / maxf(flight.duration, 0.01), 0.0, 1.0)
  var predicted_point = flight.start.lerp(flight.end, intercept_t)
  target = flight.start.lerp(flight.end, clampf((flight.time + 0.35) / maxf(flight.duration, 0.01), 0.0, 1.0))
  var dist_to_target = p.pos.distance_to(target)
  var mate = (team * 2) + (1 - (i % 2))
  var mate_dist_to_target = players[mate].pos.distance_to(target)
  var ball_h = ball_height()
  var dist_to_ball = p.pos.distance_to(ball)
  var dist_to_pred = p.pos.distance_to(predicted_point)
  # Fast-break outlet spacing (DRONE.ASM:1880-1892): when teammate is much closer to rebound/loose ball, sprint to offensive 3pt outlet
  if dist_to_target > mate_dist_to_target + 90.0 and dist_to_target > 140.0 and dist_to_ball > 120.0 and players[mate].stun <= 0.0:
   var hoop = hoop_for(team)
   target = hoop + Vector2(-260.0 if hoop.x > 640 else 260.0, -70.0 if (i % 2 == 0) else 70.0)
   turbo = p.get("turbo", 1.0) > 0.25
  else:
   turbo = p.get("turbo", 1.0) > 0.20 and dist_to_target > 60.0
   var reacts = flight.time >= 0.10 - 0.03 * clampi(difficulty, 0, 2)
   var in_range = dist_to_ball < 95.0 or dist_to_pred < 115.0
   if reacts and in_range and ball_h <= 4.2 and in_cylinder_timer <= 0.0 and p.cooldown <= 0 and p.stun <= 0 and p.jump <= 0:
    shoot = true
 elif owner >= 0 and owner / 2 == team:
  var hoop = hoop_for(team)
  # Off-ball On-Fire drone spaces to 3-point arc instead of crowding the rim (DRONE.ASM:981-984)
  if is_player_on_fire(i):
   target = hoop + Vector2(-315.0 if hoop.x > 640 else 315.0, -90.0 if (i % 2 == 0) else 90.0)
  else:
   target = hoop
  var guard_dist = 1000.0
  var guard_id = -1
  for j in range(4):
   if j / 2 != team:
    var d = p.pos.distance_to(players[j].pos)
    if d < guard_dist:
     guard_dist = d
     guard_id = j
  var dir_to_hoop = (hoop - p.pos).normalized()
  var guard_in_path = guard_id >= 0 and guard_dist <= 50.0 and (players[guard_id].pos - p.pos).normalized().dot(dir_to_hoop) > 0.40
  if guard_in_path and players[guard_id].stun <= 0.0 and not no_pushing and p.cooldown <= 0.0:
   turbo = true
   pass_action = true
   if guard_dist > 25.0:
    target = players[guard_id].pos
  elif not is_player_on_fire(i):
   # Off-ball alley-oop cut & leap governed by DRONE_ALY_T, capped at 3 per period (DRONE.ASM:884-959, PLYR.ASM:4706,4742: 65..165 ASM units -> 84.5..214.5px)
   var dist_to_hoop = p.pos.distance_to(hoop)
   if p.get("alley_cnt", 0) < 3 and dist_to_hoop > 84.5 and dist_to_hoop <= 214.5 and p.get("turbo", 1.0) > 0.15 and p.cooldown <= 0.0 and p.jump <= 0.0 and rng.randf() < float(DRONE_ALY_T[skill_idx]) * 0.0005:
    shoot = true
    turbo = true
 elif owner >= 0:
  var partner = (i / 2) * 2 + (1 - i % 2)
  var own_hoop = hoop_for(1 - team)
  var owner_dist_to_hoop = players[owner].pos.distance_to(own_hoop)
  var partner_beaten = owner_dist_to_hoop < 340.0 and players[partner].pos.distance_to(players[owner].pos) > 95.0
  var help_defense = players[partner].stun > 0.0 or partner_beaten or shot_clock < 5.0 or clock < 8.0 or (quarter >= 4 and deficit > 0)
  var mark = owner if (i % 2 == owner % 2 or help_defense) else (1 - team) * 2 + (1 - (owner % 2))
  if p.get("nasty_timer", 0.0) <= 0.0 and rng.randf() < float(DRONE_NAST_T[skill_idx]) * 0.0015:
   p.nasty_timer = rng.randf_range(0.5, 3.0)
  var nasty = p.get("nasty_timer", 0.0) > 0.0 or (quarter >= 4 and deficit > 0)
  # Authentic DRONE.ASM sag: guard between offensive player and basket with DRONE_DIST_T cushion (DRONE.ASM:1425-1435)
  var to_own_hoop = (own_hoop - players[mark].pos).normalized()
  var sag_cushion = minf(float(DRONE_DIST_T[skill_idx]) * 1.0, owner_dist_to_hoop * 0.65)
  if is_player_on_fire(i) and owner_dist_to_hoop < 420.0:
   target = players[mark].pos.lerp(own_hoop, 0.42)
  elif nasty:
   target = players[mark].pos
  else:
   target = players[mark].pos + to_own_hoop * sag_cushion
  var dist_to_mark = p.pos.distance_to(players[mark].pos)
  var dist_to_owner = p.pos.distance_to(players[owner].pos)

  # Turbo on defense: close out when beaten or trailing in Q4 (DRONE.ASM:1450)
  var has_turbo_fuel = p.get("turbo", 1.0) > 0.15 and p.get("turbo_burnout", 0.0) <= 0.0
  var should_turbo = has_turbo_fuel and ((quarter >= 4 and deficit > 0) or nasty or dist_to_mark > 110.0 or (dist_to_owner <= 85.0 and dist_to_owner > 25.0 and difficulty >= 1) or (owner_dist_to_hoop < 220.0 and dist_to_owner <= 65.0))
  if should_turbo:
   turbo = true

  # Authentic defensive shoving and stealing matched to DRONE_PS_T (DRONE.ASM:1475-1540)
  var can_shove = not no_pushing and (p.get("turbo", 1.0) >= 0.14 or is_player_on_fire(i) or infinite_turbo) and p.cooldown <= 0.0
  var shove_rate = float(DRONE_PS_T[skill_idx]) * 0.0035 + 0.040 * clampi(difficulty, 0, 2)
  if nasty or (quarter >= 4 and deficit > 0):
   shove_rate += clampf(float(maxi(0, deficit)) * 0.015 + 0.04, 0.0, 0.18)
  elif deficit < 0:
   shove_rate *= clampf(1.0 + float(deficit) * 0.08, 0.25, 1.0)

  # 1. Shoving the ball carrier (the player) (DRONE.ASM:1475-1540, PLYR2.ASM:5589)
  if dist_to_owner <= 56.0 and players[owner].stun <= 0.0 and players[owner].get("steal_immune", 0.0) <= 0.0:
   if can_shove and rng.randf() < shove_rate:
    turbo = true
    pass_action = true
    if dist_to_owner > 25.0:
     target = players[owner].pos
   elif p.cooldown <= 0.0:
    var steal_prob = float(DRONE_PS_T[skill_idx]) * 0.0010 + 0.010 * clampi(difficulty, 0, 2)
    if deficit < 0:
     steal_prob *= clampf(1.0 + float(deficit) * 0.08, 0.25, 1.0)
    if rng.randf() < steal_prob:
     pass_action = true

  # 2. Shoving the player's teammate (off-ball defense) (DRONE.ASM:1520-1540, PLYR2.ASM:5605)
  var teammate_id = (1 - team) * 2 + (1 - (owner % 2))
  var dist_to_teammate = p.pos.distance_to(players[teammate_id].pos)
  if not pass_action and dist_to_teammate <= 56.0 and players[teammate_id].stun <= 0.0:
   var offball_shove_rate = float(DRONE_PS_T[skill_idx]) * 0.0025 + 0.040 * clampi(difficulty, 0, 2)
   if nasty or (quarter >= 4 and deficit > 0):
    offball_shove_rate += 0.05
   elif deficit < 0:
    offball_shove_rate *= 0.30
   if can_shove and (difficulty >= 1 or rng.randf() < 0.50) and rng.randf() < offball_shove_rate:
    turbo = true
    pass_action = true
    if dist_to_teammate > 25.0:
     target = players[teammate_id].pos
 else:
  target = ball
 return {"move":(target - p.pos).normalized() if p.pos.distance_to(target) > 9 else Vector2.ZERO, "shoot":shoot, "pass":pass_action, "turbo":turbo, "spin":spin}

func nearest_defender(i: int) -> float:
 var distance = 1000.0
 for j in range(4):
  if j / 2 != i / 2:
   distance = minf(distance, players[j].pos.distance_to(players[i].pos))
 return distance

static func three_point_geometry(side: int) -> Dictionary:
 var hoop: Vector2 = HOOPS[side]
 var direction = 1.0 if side == 0 else -1.0
 var arc_angle = asin(THREE_POINT_CORNER_OFFSET / THREE_POINT_RADIUS)
 var arc_x_offset = sqrt(THREE_POINT_RADIUS * THREE_POINT_RADIUS - THREE_POINT_CORNER_OFFSET * THREE_POINT_CORNER_OFFSET)
 return {
  "hoop": hoop,
  "radius": THREE_POINT_RADIUS,
  "arc_start": -arc_angle if side == 0 else PI - arc_angle,
  "arc_end": arc_angle if side == 0 else PI + arc_angle,
  "arc_join_x": hoop.x + direction * arc_x_offset,
  "top_y": hoop.y - THREE_POINT_CORNER_OFFSET,
  "bottom_y": hoop.y + THREE_POINT_CORNER_OFFSET,
  "baseline_x": COURT.position.x if side == 0 else COURT.end.x,
 }

func is_three_pointer(point: Vector2, hoop: Vector2) -> bool:
 var dy = absf(point.y - hoop.y)
 if dy > THREE_POINT_CORNER_OFFSET:
  return true
 return point.distance_to(hoop) > THREE_POINT_RADIUS

func calculate_defensive_contest(shooter: int, hoop: Vector2) -> Dictionary:
 var shooter_pos: Vector2 = players[shooter].pos
 var shot_vec = hoop - shooter_pos
 var shot_dist = shot_vec.length()
 if shot_dist < 0.001:
  return {"level":0.0,"defenders":[]}
 var shot_dir = shot_vec / shot_dist
 var primary_contest = 0.0
 var secondary_contest = 0.0
 var contesting: Array = []
 for j in range(4):
  if j / 2 == shooter / 2:
   continue
  var p_def: Dictionary = players[j]
  if p_def.get("stun",0.0) > 0.0:
   continue
  var def_vec = p_def.pos - shooter_pos
  var def_dist = def_vec.length()
  if def_dist > 145.0 or def_dist < 0.001:
   continue
  var def_dir = def_vec / def_dist
  var alignment = def_dir.dot(shot_dir)
  # Omnidirectional tight-in contest within 50 ASM units (~58px) (PLYR.ASM:5947-5949)
  if alignment < -0.15 and def_dist > 58.0:
   continue
  var cone = 0.85 if (alignment < -0.15 and def_dist <= 58.0) else clampf((alignment + 0.15) / 1.15, 0.0, 1.0)
  var prox = clampf((145.0 - def_dist) / 145.0, 0.0, 1.0)
  var vertical_mult = 1.5 if p_def.get("jump",0.0) > 0.0 else (1.2 if p_def.get("swipe",0.0) > 0.0 else 0.85)
  var def_skill = 0.75 + rating(j, 3) * 0.035
  var contest_val = cone * prox * vertical_mult * def_skill
  contesting.append({"id":j,"val":contest_val})
 contesting.sort_custom(func(a, b): return a.val > b.val)
 if contesting.size() > 0:
  primary_contest = contesting[0].val
 if contesting.size() > 1:
  secondary_contest = contesting[1].val * 0.45
 var total_contest = clampf(primary_contest + secondary_contest, 0.0, 1.0)
 var defender_ids: Array = []
 for d in contesting:
  defender_ids.append(d.id)
 return {"level":total_contest,"defenders":defender_ids}

func calculate_shot_percentage(i: int, charge: float, dunk: bool, layup: bool, specialty: bool, alley: bool = false, hook: bool = false, fadeaway: bool = false, moving_shot: Variant = null, bailed_to_layup: bool = false) -> Dictionary:
 var hoop = hoop_for(i / 2)
 var distance: float = players[i].pos.distance_to(hoop)
 var three_pointer = not dunk and not layup and not hook and is_three_pointer(players[i].pos, hoop)
 var delta_time = charge - 0.58
 var timing = exp(-(delta_time * delta_time) / (2.0 * 0.18 * 0.18))
 var contest_data = calculate_defensive_contest(i, hoop)
 var contest_level: float = contest_data.level
 var dist_penalty = pow(distance / 750.0, 1.32) * 0.28
 var my_team = i / 2
 var opp_team = 1 - my_team
 var score_diff = score[opp_team] - score[my_team]
 var clamped_diff = clampi(score_diff, -15, 15)
 var rubber_band = 0.0 if tournament_mode else clampf(float(clamped_diff) * 0.014, -0.21, 0.21)
 var base = 0.0
 var chance = 0.0
 var timing_contrib = 0.0
 var fire_bonus = 0.0
 var is_moving_shot = false
 if moving_shot != null:
  is_moving_shot = bool(moving_shot)
 elif fadeaway:
  is_moving_shot = true
 elif i >= 0 and i < players.size():
  var p_shoot: Dictionary = players[i]
  is_moving_shot = p_shoot.get("shot_is_moving", false) or p_shoot.get("still_time", 1.0) < 0.10 or p_shoot.get("vel", Vector2.ZERO).length() > 10.0
 var moving_penalty = 0.14
 var still_bonus = 0.02
 var sht_stat = clampi(int(rating(i, 1)), 0, 10)
 var sht_mult = SHT_TABLE[sht_stat]
 if dunk:
  base = (0.84 if specialty else 0.72) + rating(i, 2) * 0.018
  chance = base - contest_level * 0.14 + rubber_band
 elif bailed_to_layup:
  # Dunk bailout to mid-air layup (DDUNK_STRT2_SEQ in PLYR.ASM:6139-6142): fixed 55% base
  base = 0.55
  timing_contrib = 0.0
  chance = base - contest_level * 0.15 + rubber_band
 elif layup:
  base = 0.66 + rating(i, 1) * 0.024
  # Layup late knockdown when leading/tied and not on fire (PLYR.ASM:6205-6212: 10% chance -> 65%)
  if score_diff <= 0 and not is_player_on_fire(i) and not tournament_mode and rng.randf() < 0.10:
   base = 0.65
  timing_contrib = timing * 0.10
  chance = base + timing_contrib - contest_level * 0.20 + rubber_band
 elif hook:
  base = 0.62 + rating(i, 1) * 0.028
  # Hook shot late knockdown when not on fire (PLYR.ASM:6230-6236: 12% chance -> 50%)
  if not is_player_on_fire(i) and not tournament_mode and rng.randf() < 0.12:
   base = 0.50
  timing_contrib = timing * 0.15
  chance = base + timing_contrib - contest_level * 0.22 + rubber_band
 elif fadeaway:
  base = (0.18 + rating(i, 1) * 0.028) * sht_mult
  timing_contrib = timing * 0.24
  var fade_contest = maxf(0.0, contest_level - 0.25)
  chance = base + timing_contrib - dist_penalty - fade_contest * 0.28 + rubber_band
  if three_pointer:
   if sht_stat <= 6:
    chance -= 0.20
   chance -= 0.15
 else:
  base = (0.21 + rating(i, 1) * 0.030) * sht_mult
  timing_contrib = timing * 0.28
  if is_moving_shot:
   chance = base + timing_contrib - dist_penalty - contest_level * 0.32 + rubber_band - moving_penalty
  else:
   chance = base + timing_contrib - dist_penalty - contest_level * 0.32 + rubber_band + still_bonus
  if three_pointer:
   # Weak 3-point shooter penalty (PLYR.ASM:5913-5915: <= SHT5 on 0-10 scale loses 20%)
   if sht_stat <= 6:
    chance -= 0.20
   # Deep 3-pointer penalty beyond >25 ASM units past the 3pt line (PLYR.ASM:4501, 5499-5505, 5917-5919 @reduce_3ptr)
   if distance >= 345.0:
    chance -= 0.15
  elif distance <= 145.0:
   # Close-in jumper bonus (PLYR.ASM:5925-5927)
   chance += 0.10
 if is_player_on_fire(i):
  fire_bonus = 0.30
  chance += fire_bonus
  var fire_floor = 0.95 if dunk else (0.88 if layup else 0.82)
  chance = maxf(chance, fire_floor)
 elif player_streak[i] == 2:
  fire_bonus = 0.08
  chance += fire_bonus
 # 304 ASM units * 1.30 = 395.0px far-shot cutoff for brick_count mercy make (PLYR.ASM:5995)
 if brick_count[i] >= 3 and distance <= 395.0:
  chance = 0.99
 elif score_diff < 0 and not tournament_mode and rng.randf() < 0.055:
  # 5.5% random knockdown when leading (PLYR.ASM:6015: movi 55, a0; calla RNDPER)
  chance = minf(chance, 0.35)
 # End-of-quarter and Q4 buzzer-beater rules (PLYR.ASM:6020-6117)
 if clock <= 5.0:
  var shot_pts = 2 if dunk else (3 if three_pointer else 2)
  if quarter >= 4:
   if score[0] == score[1]:
    chance = 0.05
   elif clock <= 4.0:
    if score_diff <= -5:
     chance = maxf(chance, 0.30 if clock > 2.0 else 0.12)
    elif score_diff >= 4:
     chance = maxf(chance, 0.30)
    elif score_diff > 0:
     if score_diff == shot_pts:
      chance = maxf(chance, 0.88)
     elif score_diff < shot_pts:
      chance = maxf(chance, 0.80)
     else:
      chance = maxf(chance, 0.38)
  elif clock <= 4.0 and score_diff > 0:
   if score_diff > 5 or score_diff == shot_pts:
    chance = maxf(chance, 0.12)
   else:
    chance = maxf(chance, 0.10)
 if distance > 395.0 and clock <= 4.0:
  chance += 0.15
 # Clutch attribute boost in final 10 seconds (rating index 7 = Clutch)
 if clock <= 10.0 and rating(i, 7) >= 5.0:
  chance += 0.08
 var final_chance = clampf(chance, 0.05, 0.99)
 var percentage = roundf(final_chance * 1000.0) / 10.0
 var quality = "PERFECT" if timing > 0.93 else ("GREAT" if timing > 0.75 else ("GOOD" if timing > 0.50 else ("EARLY" if charge < 0.58 else "LATE")))
 return {
  "chance":final_chance,
  "percentage":percentage,
  "base":base,
  "timing":timing,
  "timing_contrib":timing_contrib,
  "dist_penalty":dist_penalty,
  "contest_penalty":contest_level * (0.14 if dunk else (0.20 if layup else 0.32)),
  "contest_level":contest_level,
  "defenders":contest_data.defenders,
  "rubber_band":rubber_band,
  "fire_bonus":fire_bonus,
  "three_pointer":three_pointer,
  "dunk":dunk,
  "layup":layup,
  "specialty":specialty,
  "hook":hook,
  "fadeaway":fadeaway,
  "moving_shot":is_moving_shot,
  "still_shot":not is_moving_shot,
  "moving_penalty":moving_penalty if is_moving_shot else 0.0,
  "still_bonus":still_bonus if not is_moving_shot else 0.0,
  "quality":quality
 }

func calculate_rim_ricochet(start_pos: Vector2, hoop: Vector2) -> Vector2:
 var left_hoop = hoop.x < 640
 var bounce_x = hoop.x + rng.randf_range(80.0, 240.0) if left_hoop else hoop.x - rng.randf_range(80.0, 240.0)
 var bounce_y = clampf(hoop.y + rng.randf_range(-85.0, 85.0), COURT.position.y + 35.0, COURT.end.y - 35.0)
 return Vector2(bounce_x, bounce_y)

func finish_kind(i: int, turbo: bool, alley: bool = false) -> String:
 if alley:
  return "alley_oop"
 var p: Dictionary = players[i]
 var hoop = hoop_for(i/2)
 var moving: bool = p.drive > 0 or (p.vel.length() > 40 and p.vel.dot((hoop-p.pos).normalized()) > 20)
 var distance: float = p.pos.distance_to(hoop)
 # Skip dunks from behind the hoop along the baseline or within 34 ASM Z-units (~36px) of sidelines (PLYR.ASM:4679-4700, 4745-4749)
 var behind_hoop = (hoop.x > 640 and p.pos.x > hoop.x + 8.0 and absf(p.pos.y - hoop.y) > 25.0) or (hoop.x < 640 and p.pos.x < hoop.x - 8.0 and absf(p.pos.y - hoop.y) > 25.0)
 var extreme_sideline = p.pos.y <= COURT.position.y + 36.0 or p.pos.y >= COURT.end.y - 36.0
 if not moving or distance >= 185 or behind_hoop or extreme_sideline:
  return "jumper"
 var hoop_dir = (hoop - p.pos).normalized()
 var vel_dir = p.vel.normalized() if p.vel.length() > 10.0 else Vector2(p.face, 0.0)
 var directness = vel_dir.dot(hoop_dir)
 if not turbo and distance >= 75.0 and distance <= 185.0 and directness < 0.65 and directness > -0.65 and p.vel.length() > 30.0:
  return "hook_shot"
 if turbo and (p.turbo > 0.1 or infinite_turbo or is_player_on_fire(i)):
  var contest = calculate_defensive_contest(i, hoop)
  var lane_guarded = false
  for j in range(4):
   if j / 2 != i / 2 and players[j].get("stun", 0.0) <= 0.0:
    var def_idx = 11 if is_player_on_fire(j) else clampi(int(rating(j, 3)), 0, 10)
    var rel = players[j].pos - p.pos
    var def_dist = rel.length()
    var def_hoop_dist = players[j].pos.distance_to(hoop)
    if def_dist > 0.001 and def_hoop_dist <= distance and def_dist <= float(DEF_DIST_T[def_idx]) * 1.30:
     var angle_diff = acos(clampf((rel / def_dist).dot(hoop_dir), -1.0, 1.0))
     var max_angle = float(DEF_WIDTH_T[def_idx]) * (TAU / 128.0)
     if angle_diff < max_angle:
      lane_guarded = true
      break
  var pwr_stat = clampi(int(rating(i, 6)), 0, 10)
  var dunk_thru_prob = maxf(0.35, DNKTHRU_T[pwr_stat])
  if (contest.level > 0.45 or lane_guarded) and not is_player_on_fire(i) and rating(i, 2) < 8.0 and rng.randf() >= dunk_thru_prob:
   return "layup"
  return "turbo_dunk"
 if p.charge < 0.35 or distance >= 115:
  return "layup"
 return "dunk"

func shoot_ball(i: int, turbo: bool, alley: bool = false, release_height: float = 1.3) -> void:
 teammate_shot_order = -1
 inbound_transition = {}
 inbounding_team = -1
 var p: Dictionary = players[i]
 p.fake = 0.0
 var hoop = hoop_for(i / 2)
 var distance: float = p.pos.distance_to(hoop)
 var finish = finish_kind(i,turbo,alley)
 var dunk = finish in ["dunk","turbo_dunk","alley_oop"]
 var specialty = finish in ["turbo_dunk","alley_oop"]
 var layup = finish == "layup"
 var hook = finish == "hook_shot"
 var launch_height = receive_height(i) if alley else 0.0
 p.receive_jump = 0.0
 var hoop_vec = hoop - p.pos
 var angle_from_baseline = absf(atan2(hoop_vec.y, hoop_vec.x))
 var any_on_fire = fire_player >= 0 or team_fire_timer[0] > 0.0 or team_fire_timer[1] > 0.0
 # Close bank (<=125px, 20%-25% chance) and long bank (125..270px, 25% chance), suppressed when anyone is on fire (PLYR.ASM:6325-6426)
 var is_close_bank = distance >= 55.0 and distance <= 125.0 and angle_from_baseline > 0.35 and angle_from_baseline < 1.35
 var is_long_bank = distance > 125.0 and distance <= 270.0 and angle_from_baseline > 0.40 and angle_from_baseline < 1.35
 var bank_prob = 0.25 if (is_long_bank or angle_from_baseline > 0.75) else 0.20
 var bank_shot = (is_close_bank or is_long_bank) and not dunk and not alley and not any_on_fire and rng.randf() < bank_prob
 var fadeaway = not dunk and not layup and not hook and not alley and p.vel.length() > 20.0 and p.vel.dot(hoop_vec.normalized()) < -15.0
 var moving_shot = p.get("shot_is_moving", false) if p.has("shot_is_moving") else (p.get("still_time", 1.0) < 0.10 or p.vel.length() > 10.0)
 if fadeaway:
  moving_shot = true
  p.vel = -(hoop_vec.normalized()) * 55.0
  p.jump = 0.52
 var breakdown = calculate_shot_percentage(i, p.charge, dunk, layup, specialty, alley, hook, fadeaway, moving_shot)
 var chance: float = breakdown.chance
 var points = 2 if dunk else (3 if breakdown.three_pointer else 2)
 var burning = is_player_on_fire(i)
 var dunk_style = "standard"
 if dunk:
  if burning or (specialty and rating(i, 2) >= 7.0):
   dunk_style = SIGNATURE_DUNKS[rng.randi_range(0, SIGNATURE_DUNKS.size() - 1)]
 if dunk:
  points = 2
  p.jump = 0.95 if burning else (0.85 if specialty else 0.70)
 else:
  if not fadeaway:
   p.jump = 0.58 if hook else (0.55 if layup else 0.50)
   if not dunk and not layup and not hook:
    if moving_shot:
     if p.get("shot_drift_vel", Vector2.ZERO).length() > 0:
      p.vel = p.shot_drift_vel
     elif p.vel.length() > 10.0:
      p.shot_drift_vel = p.vel * 0.70
      p.vel = p.shot_drift_vel
    else:
     p.vel = Vector2.ZERO
     p.shot_drift_vel = Vector2.ZERO
 p.drive = 0.0
 stats[i].attempts += 1
 var will_make = rng.randf() < chance
 var clank = false
 var airball = false
 var my_team = i / 2
 var opp_team = 1 - my_team
 var pts_down = score[opp_team] - score[my_team]
 var any_fire = fire_player >= 0 or team_fire_timer[0] > 0.0 or team_fire_timer[1] > 0.0
 # Unblocked dunks always make except for 2.5% clank when leading/up by 1 and nobody is on fire (PLYR2.ASM:5357-5373)
 if dunk:
  will_make = true
  if pts_down < 2 and not any_fire and not specialty:
   if rng.randf() < 0.025:
    will_make = false
    clank = true
 elif not layup and not hook and not alley and not bank_shot and pts_down < 2 and not any_fire and nearest_defender(i) <= 56.0:
  # Contested jump-shot airball roll when defender within 50*DIST_REDUCTION (56px), not trailing by 2+, and nobody is on fire (PLYR.ASM:6430-6488)
  var air_prob = 0.12 if (distance > 380.0 and chance < 0.06) else (1.0 / 128.0 if distance < 65.0 else 1.0 / 32.0)
  if rng.randf() < air_prob:
   will_make = false
   airball = true
 var flat_arc = not dunk and not layup and not hook and rng.randf() < 0.016
 # Authentic arcade dunk durations (PLYR2.ASM:5058, DUNK.ASM, PLYRDSEQ.ASM, PLYRDSQ2.ASM):
 # Standard: 62-73 ticks (~1.15s), Specialty/Turbo: 75-85 ticks (~1.40s), On-Fire: 95-110 ticks (~1.75s), Alley-oop catch slam: ~42 ticks (~0.78s)
 var dunk_duration = 1.75 if burning else (0.78 if finish == "alley_oop" else (1.40 if specialty else 1.15))
 var dunk_arc = 4.5 if burning else (3.0 if specialty else 1.6)
 var jumper_arc = 3.3 if flat_arc else 4.6
 # Authentic arcade shot duration (PLYR.ASM:6573-6610):
 # Distance scaled to 800px arcade court, min 50 ticks (0.94s) for normal shot,
 # min 35 ticks (0.66s) for flat arc/layup, scaling up to 75-85 ticks (1.41s-1.60s) for long shots/heaves.
 var shot_arcade_dist = ball.distance_to(hoop) * (800.0 / 1050.0)
 var shot_d = shot_arcade_dist
 if shot_d > 170.0:
  shot_d = 170.0 + (shot_d - 170.0) * 0.125
 var shot_ticks = (shot_d * 110.0) / 256.0
 if flat_arc or layup or hook:
  shot_ticks = maxf(35.0, shot_ticks * 0.75)
 else:
  shot_ticks = maxf(50.0, shot_ticks)
 var shot_duration = shot_ticks / 53.2
 flight = {"kind":"shot", "start":ball, "end":hoop, "time":0.0, "duration":dunk_duration if dunk else shot_duration, "shooter":i, "points":points, "made":will_make, "dunk":dunk, "layup":layup, "hook":hook, "fadeaway":fadeaway, "super_dunk":specialty or burning, "dunk_style":dunk_style, "finish":finish, "arc_height":(3.6 if turbo else 2.5) if hook else (dunk_arc if dunk else (1.0 if layup else jumper_arc)), "blocked":false, "shot_breakdown":breakdown, "clank":clank, "airball":airball, "flat_arc":flat_arc, "bank_shot":bank_shot, "moving_shot":moving_shot}
 if dunk or layup or hook:
  flight.player_start = p.pos
  flight.player_end = hoop+Vector2(-1 if hoop.x > 640 else 1,0)*(28 if dunk else 50)
  flight.player_launch_height = launch_height
 flight.release_height = release_height
 flight.cpu_block_allowed = []
 for defender in range(4):
  var def_skill_idx = drone_skill_index(defender)
  var blk_prob = float(DRONE_BLK_T[def_skill_idx]) * 0.01
  if dunk:
   var def_blk_stat = clampi(int(rating(defender, 3)), 0, 10)
   blk_prob *= 0.5 * (float(TRYBLK_T[def_blk_stat]) / 25.0)
  if players[defender].get("nasty_timer", 0.0) > 0.0:
   blk_prob = minf(0.75, blk_prob * 2.0)
  flight.cpu_block_allowed.append(rng.randf() < blk_prob)
 owner = -1
 p.cooldown = 0.65
 last_shot_feedback = {
  "shooter": i,
  "percentage": breakdown.percentage,
  "quality": breakdown.quality,
  "contest_level": breakdown.contest_level,
  "time": elapsed,
  "points": points,
  "made": will_make,
  "dunk": dunk,
  "moving_shot": moving_shot,
  "still_shot": not moving_shot
 }
 var callout = "UP IT GOES"
 if dunk:
  if burning or specialty:
   match dunk_style:
    "helicopter": callout = "HELICOPTER SLAM!"
    "frontflip": callout = "SOMERSAULT JAM!"
    "backflip": callout = "BACKFLIP DUNK!"
    "spin_360": callout = "360 WINDMILL!"
    "between_legs": callout = "BETWEEN THE LEGS!"
    "behind_back": callout = "BEHIND THE BACK SLAM!"
    _: callout = "BOOMSHAKALAKA!"
  else:
   callout = "SLAM DUNK!"
 elif fadeaway:
  callout = "FADEAWAY JUMPER!"
 elif hook:
  callout = "HOOK SHOT!"
 elif layup:
  callout = "LAY IT UP!"
 elif bank_shot:
  callout = "OFF THE GLASS!"
 elif moving_shot:
  callout = "PERFECT RELEASE!" if breakdown.quality == "PERFECT" else "PULL-UP JUMPER!"
 else:
  callout = "PERFECT RELEASE!" if breakdown.quality == "PERFECT" else ("FROM DOWNTOWN!" if points == 3 else "UP IT GOES")
 announce(callout, "dunk" if dunk else "shot")

func pass_ball(i: int, turbo: bool) -> void:
 teammate_shot_order = -1
 players[i].fake = 0.0
 var release_height = ball_height() if not flight.is_empty() and flight.get("kind","") == "shot" else 1.1
 var mate = (i / 2) * 2 + (1 - i % 2)
 var alley = turbo and players[mate].receive_jump > 0 and players[mate].stun <= 0 and players[mate].pos.distance_to(hoop_for(i / 2)) < 220
 var distance: float = ball.distance_to(players[mate].pos)
 var pass_stat = clampi(int(rating(i, 5)), 0, 10)
 # Authentic arcade pass travel time calculation (PLYR.ASM:8041-8077):
 # Distance scaled to 800px arcade court, table lookups for long (>300) vs short,
 # turbo deduction, and hard floor of 16 ticks (0.30s min duration at 53.2 Hz).
 var arcade_dist = distance * (800.0 / 1050.0)
 var factor = float(LONGPAS_T[pass_stat]) if arcade_dist > 300.0 else float(SHORTPAS_T[pass_stat])
 if turbo:
  factor -= float(TURBOPAS_T[pass_stat])
 var ticks = maxf(16.0, (arcade_dist * factor) / 1024.0)
 var duration = ticks / 53.2
 if fast_passing:
  duration *= 0.50
 if clock <= 10.0 and rating(i, 7) >= 5.0:
  duration *= 0.85
 var pass_vec = players[mate].pos - players[i].pos
 var face_dir = Vector2(players[i].face, 0.0)
 var behind_back = not alley and players[i].jump <= 0.0 and distance >= 80.0 and distance <= 380.0 and rating(i, 5) >= 5.0 and face_dir.dot(pass_vec.normalized()) < -0.30
 flight = {"kind":"pass", "start":ball, "end":players[mate].pos, "start_height":release_height, "end_height":3.8 if alley else 1.1, "time":0.0, "duration":0.38 if alley else duration, "target":mate, "passer":i, "alley":alley, "turbo":turbo, "behind_back":behind_back}
 owner = -1
 inbounding_team = -1
 players[i].cooldown = 0.45
 announce("LOB IT UP!" if alley else ("BEHIND THE BACK PASS!" if behind_back else "NICE PASS"), "pass")

func defend(i: int, turbo: bool) -> void:
 players[i].vel = Vector2.ZERO
 players[i].jump = 0.70
 players[i].cooldown = 0.75
 if must_rebound_timer > 0.0 or (not flight.is_empty() and (flight.get("kind", "") == "rebound" or flight.get("kind", "") == "loose")):
  var shooter = flight.get("shooter", -1)
  var is_defense = (shooter < 0 or shooter / 2 != i / 2)
  # Authentic arcade auto-rebound restriction (PLYR.ASM:8439-8446):
  # Offense (shooter and teammate) cannot trigger magnetic auto-rebound glide
  if not is_defense and flight.get("kind", "") == "rebound":
   players[i].jump = 0.75
   return
  players[i].jump = 0.75
  if not flight.is_empty():
   var intercept_t = clampf((flight.time + REBOUND_GLIDE_DURATION) / maxf(flight.duration, 0.01), 0.0, 1.0)
   var predicted_point = flight.start.lerp(flight.end, intercept_t)
   var delta_pos = predicted_point - players[i].pos
   if delta_pos.length() > 0.1:
    var rebound_vel = delta_pos / REBOUND_GLIDE_DURATION
    players[i].vel = rebound_vel.limit_length(260.0)
    players[i].rebound_glide = REBOUND_GLIDE_DURATION
  return
 if not flight.is_empty() and flight.get("kind", "") == "shot":
  var shooter: int = flight.shooter
  if shooter / 2 == i / 2 or flight.blocked:
   return
  var t = clampf(flight.time/flight.duration,0,1)
  var contact = flight_position()
  var reach = players[i].pos.distance_to(contact)
  var arc: float = flight.get("arc_height",1.7 if flight.dunk else 4.6)
  var v_vert = 3.05-flight.get("release_height",1.3)+PI*arc*cos(t*PI)
  var def_team = i / 2
  var off_team = shooter / 2
  var pts_down = score[off_team] - score[def_team]
  # Allow ball to be blocked right at peak of arc (PLYR2.ASM:2678-2705)
  var desc_threshold = -1.5 if pts_down >= 5 else -1.0
  var descending = v_vert < desc_threshold
  var at_rim = contact.distance_to(flight.end) < 115
  var blk_reach_bonus = float(BLK_REACH_T[clampi(int(rating(i, 3)), 0, 10)] - 12) * 3.0
  if descending and at_rim and reach < 78 + maxf(0.0, blk_reach_bonus) and ball_height() <= 4.6:
   var uncalled = flight.get("airball", false)
   if not uncalled and pts_down >= 1 and not tournament_mode:
    var uncalled_chance = float(GOALT_T[clampi(pts_down, 0, 15)]) / 1000.0
    if rng.randf() < uncalled_chance:
     uncalled = true
   if flight.dunk or is_player_on_fire(i) or uncalled:
    flight.made = false
    flight.blocked = true
    stats[i].blocks += 1
    record_miss(shooter)
    if flight.dunk:
     var def_pwr = 10 if (maximum_power or is_player_on_fire(i)) else clampi(int(rating(i, 6)), 0, 10)
     var dnk_pwr = clampi(int(rating(shooter, 6)), 0, 10)
     var td_idx = clampi((def_pwr - dnk_pwr) + 10, 0, TAKEDUNK_T.size() - 1)
     if def_pwr > 4 and rng.randf() < float(TAKEDUNK_T[td_idx]) / 1000.0:
      players[shooter].stun = 0.85
      stats[shooter].injury += 1
      announce("STUFFED AT THE RIM!", "block")
     else:
      announce("DENIED AT THE RIM!", "block")
    else:
     announce("NO CALL! REJECTED AT THE RIM!" if uncalled else "FIRE BLOCK! NO GOALTENDING!", "block")
   else:
    var points: int = flight.points
    stats[i].goaltends += 1
    award_basket(shooter,points,false,false)
    announce("GOALTENDING! %d POINTS" % points,"whistle")
    inbound(i/2, true)
  elif not descending and reach < 85 + blk_reach_bonus and ball_height() <= 4.6:
   flight.made = false
   flight.blocked = true
   stats[i].blocks += 1
   record_miss(shooter)
   if flight.dunk:
    var def_pwr = 10 if (maximum_power or is_player_on_fire(i)) else clampi(int(rating(i, 6)), 0, 10)
    var dnk_pwr = clampi(int(rating(shooter, 6)), 0, 10)
    var td_idx = clampi((def_pwr - dnk_pwr) + 10, 0, TAKEDUNK_T.size() - 1)
    if def_pwr > 4 and rng.randf() < float(TAKEDUNK_T[td_idx]) / 1000.0:
     players[shooter].stun = 0.85
     stats[shooter].injury += 1
     announce("STUFFED AT THE RIM!", "block")
    else:
     announce("REJECTED!", "block")
   else:
    announce("REJECTED!", "block")
 elif owner >= 0 and owner / 2 != i / 2:
  steal(i, turbo)

func steal(i: int, shove: bool) -> void:
 if shove and no_pushing:
  announce("NO PUSHING!", "whistle")
  return
 if shove and not is_player_on_fire(i) and not infinite_turbo:
  if players[i].turbo < 0.14:
   shove = false
  else:
   # Authentic shove turbo cost: (TURBO_CNT*2)/13 (PLYR2.ASM:5945)
   players[i].turbo = maxf(0.0, players[i].turbo - (2.0 / 13.0))
 players[i].cooldown = 0.65
 players[i].swipe = 0.45
 players[i].swipe_resolved = false
 players[i].swipe_shove = shove
 players[i].vel = Vector2.ZERO
 var team = i / 2
 if shove:
  var closest_opp = -1
  var min_d = 56.0
  for j in range(4):
   if j / 2 != team:
    var d = players[i].pos.distance_to(players[j].pos)
    if d <= min_d:
     min_d = d
     closest_opp = j
  if closest_opp >= 0:
   var to_opp = players[closest_opp].pos - players[i].pos
   if absf(to_opp.x) > 0.1:
    players[i].face = 1 if to_opp.x >= 0 else -1
 elif owner >= 0:
  var to_target = players[owner].pos - players[i].pos
  if absf(to_target.x) > 0.1:
   players[i].face = 1 if to_target.x >= 0 else -1
 elif not flight.is_empty():
  var to_target = flight_position() - players[i].pos
  if absf(to_target.x) > 0.1:
   players[i].face = 1 if to_target.x >= 0 else -1
 if not flight.is_empty() and flight.kind == "pass" and not flight.get("tip",false) and int(flight.target)/2 != i/2:
  if players[i].pos.distance_to(flight_position()) < (68 if shove else 56) and ball_height() <= 2.5:
   # Authentic arcade pass ticks: flight.time * 53.2 (PLYR2.ASM:3221-3226)
   var pass_ticks = int(flight.time * ARCADE_TSEC)
   var base_pct = 1.0 + absf(pass_ticks - 3) * 0.5
   var def_team = i / 2
   var off_team = int(flight.target) / 2
   var pts_down = clampi(score[off_team] - score[def_team], 0, 15)
   var ptsdown_bonus = INT_T[pts_down]
   if tournament_mode:
    ptsdown_bonus = 0
   var alley_bonus = 25.0 if flight.get("alley", false) else 0.0
   var intercept_chance = clampf(0.22 + rating(i, 4) * 0.03 + (base_pct + ptsdown_bonus + alley_bonus) * 0.006, 0.20, 0.78)
   if rng.randf() < intercept_chance:
    intercept_pass(i)
  return
 if shove:
  resolve_steal(i, true)

func resolve_steal(i: int, shove: bool) -> void:
 var team = i / 2
 if shove:
  var victims: Array = []
  for j in range(4):
   if j / 2 != team:
    var dist = players[i].pos.distance_to(players[j].pos)
    if dist <= 56.0:
     victims.append(j)
  if victims.is_empty():
   return
  players[i].swipe_resolved = true
  var hit_count = 0
  var any_turnover = false
  var any_kept = false
  var any_flyback = false
  var pusher_power = 9.0 if (maximum_power or is_player_on_fire(i)) else rating(i, 6)
  for victim in victims:
   # Vertical height difference check (PLYR2.ASM:5729-5734)
   if absf(players[i].get("jump", 0.0) - players[victim].get("jump", 0.0)) > 0.45:
    continue
   # Spin/elbow/rebound shove resistance (85%, PLYR2.ASM:5710-5725)
   if (players[victim].get("spin", 0.0) > 0.0 or players[victim].get("elbow", 0.0) > 0.0 or players[victim].get("rebound_glide", 0.0) > 0.0) and rng.randf() < 0.85:
    continue
   # Layup shove resistance (50%, PLYR2.ASM:5704-5708)
   if not flight.is_empty() and flight.get("kind", "") == "shot" and flight.get("shooter", -1) == victim and flight.get("layup", false) and rng.randf() < 0.50:
    continue

   hit_count += 1
   var victim_power = rating(victim, 6)
   var power_diff = pusher_power - victim_power
   var push_dir = (players[victim].pos - players[i].pos).normalized()
   if push_dir.length() < 0.1:
    push_dir = Vector2.RIGHT * players[i].face
   var face_dir = -signf(push_dir.x)
   if absf(face_dir) > 0.1:
    players[victim].face = face_dir

   var is_flyback = true
   if not maximum_power and not is_player_on_fire(i):
    var flyback_chance = 0.65
    if power_diff >= 3.0:
     flyback_chance = 0.90
    elif power_diff >= 1.0:
     flyback_chance = 0.75
    elif power_diff <= -3.0:
     flyback_chance = 0.20
    elif power_diff <= -1.0:
     flyback_chance = 0.40
    is_flyback = rng.randf() < flyback_chance

   if is_flyback:
    any_flyback = true

   stats[victim].injury += 1
   players[victim].charge = 0.0
   players[victim].fake = 0.0
   if is_flyback:
    players[victim].shove_kind = "flyback"
    players[victim].shove_time = 0.95
    players[victim].stun = 0.95
    players[victim].pickup_delay = 0.67
    players[victim].pos = (players[victim].pos + push_dir * 22.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
    players[victim].vel = push_dir * 380.0
   else:
    players[victim].shove_kind = "stumble"
    players[victim].shove_time = 0.40
    players[victim].stun = 0.40
    players[victim].pickup_delay = 0.35
    players[victim].pos = (players[victim].pos + push_dir * 12.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
    players[victim].vel = push_dir * 180.0

   if victim == owner:
    # Ball retention on shove knockdown (FLYBACKWB_SEQ in PLYR.ASM:1626-1683)
    var v_pts_down = score[i / 2] - score[victim / 2]
    var keep_prob = 0.0
    if v_pts_down > 0:
     keep_prob = KPBALL_T[clampi(int(victim_power), 0, 10)] + FLYB_T[clampi(v_pts_down, 0, 15)]
    if players[victim].get("push_keep_ball", 0.0) > 0.0 or (v_pts_down > 0 and rng.randf() < keep_prob):
     any_kept = true
    else:
     any_turnover = true
     stats[i].steals += 1
     stats[victim].turnovers = stats[victim].get("turnovers", 0) + 1
     acquire_possession(i, true)
     shot_clock = 24.0

  if hit_count == 0:
   return
  players[i].cooldown = 0.80
  if hit_count > 1:
   if any_turnover:
    announce("DOUBLE KNOCKDOWN! TURNOVER!", "steal")
   elif any_kept:
    announce("DOUBLE SHOVE! KEEPS THE BALL!", "shove")
   else:
    announce("DOUBLE KNOCKDOWN! NO FOULS!", "shove")
  else:
   if any_turnover:
    announce("SHOVED! NO FOULS!" if any_flyback else "STUMBLED! LOST THE BALL!", "steal")
   elif any_kept:
    announce("SHOVED! KEEPS THE BALL!" if any_flyback else "STUMBLED! KEEPS THE BALL!", "shove")
   else:
    announce("SHOVED! NO FOULS!" if any_flyback else "STAGGERED!", "shove")
  return
 var victim = -1
 if owner >= 0 and owner / 2 != team:
  var ball_pos = players[owner].pos + Vector2(players[owner].face * 18.0, 0.0)
  var dist_to_ball = players[i].pos.distance_to(ball_pos)
  var dist_to_owner = players[i].pos.distance_to(players[owner].pos)
  if dist_to_ball <= 46.0 or dist_to_owner <= 46.0:
   victim = owner
 if victim < 0:
  return
 if players[victim].get("steal_immune", 0.0) > 0.0:
  return
 players[i].swipe_resolved = true
 var stl_stat = clampi(int(rating(i, 4)), 0, 10)
 var clutch_steal_bonus = 0.03 if (clock <= 10.0 and rating(i, 7) >= 5.0) else 0.0
 var steal_chance = STL1[stl_stat] + clutch_steal_bonus
 # Holding ball too long without dribbling/moving penalty (PLYR2.ASM:3038-3041: >220 ticks = 4.135s at 53.2 Hz -> 35% steal)
 if players[victim].get("hold_time", 0.0) >= (220.0 / ARCADE_TSEC) and players[victim].get("still_time", 0.0) >= 2.0:
  steal_chance = maxf(steal_chance, 0.35)
 if rng.randf() < steal_chance:
  var clean_steal = rng.randf() < STL2[stl_stat]
  stats[i].steals += 1
  stats[victim].turnovers = stats[victim].get("turnovers", 0) + 1
  players[i].cooldown = 0.75
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  if clean_steal:
   acquire_possession(i, true)
   players[i].steal_immune = 0.67
   players[i].pass_off = 0.42
   players[i].push_keep_ball = 1.33
   shot_clock = 24.0
   announce("PICKED THEIR POCKET!", "steal")
  else:
   owner = -1
   shot_clock = 24.0
   loose_ball_timer = 0.65
   players[i].pickup_delay = 0.50
   players[victim].pickup_delay = 0.50
   var loose_dir = (players[victim].pos - players[i].pos).normalized()
   if loose_dir.length() < 0.1:
    loose_dir = Vector2.RIGHT * players[i].face
   var loose_dest = (ball + loose_dir * rng.randf_range(60.0, 110.0) + Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-30.0, 30.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
   flight = {"kind":"loose", "start":ball, "end":loose_dest, "time":0.0, "duration":0.45, "arc_height":1.2}
   announce("LOOSE BALL!", "steal")

func intercept_pass(i: int) -> void:
 stats[i].steals += 1
 var passer = int(flight.get("passer", -1))
 if passer >= 0 and passer < stats.size():
  stats[passer].turnovers = stats[passer].get("turnovers", 0) + 1
 if rng.randf() < 0.04:
  owner = -1
  var tip_dest = (ball + Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(-40.0, 40.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
  flight = {"kind":"loose", "start":ball, "end":tip_dest, "time":0.0, "duration":0.65, "arc_height":4.8, "tip":true}
  loose_ball_timer = 0.60
  players[i].cooldown = 0.5
  players[i].swipe = 0.25
  players[i].pickup_delay = 0.40
  announce("TIPPED PASS! LOOSE BALL", "steal")
  return
 acquire_possession(i, true)
 flight = {}
 ball = players[i].pos
 shot_clock = 24.0
 players[i].cooldown = 0.8
 players[i].swipe = 0.25
 players[i].push_keep_ball = 1.33
 announce("PASS PICKED OFF!", "steal")

func tick_flight(delta: float) -> void:
 if flight.is_empty():
  return
 flight.time += delta
 var t = clampf(flight.time / flight.duration, 0, 1)
 ball = flight.start.lerp(flight.end, t)
 if flight.kind == "pass" and not flight.get("tip",false) and t > 0.12 and t < 0.88 and ball_height() <= 2.5:
  for i in range(4):
   if i/2 == int(flight.target)/2 or players[i].stun > 0 or players[i].cooldown > 0:
    continue
   # Authentic arcade pass ticks: flight.time * 53.2 (PLYR2.ASM:3221-3226)
   var pass_ticks = int(flight.time * ARCADE_TSEC)
   var base_pct = 1.0 + absf(pass_ticks - 3) * 0.5
   var def_team = i / 2
   var off_team = int(flight.target) / 2
   var pts_down = clampi(score[off_team] - score[def_team], 0, 15)
   var ptsdown_bonus = INT_T[pts_down]
   if tournament_mode:
    ptsdown_bonus = 0
   var alley_bonus = 25.0 if flight.get("alley", false) else 0.0
   var rate = (base_pct + ptsdown_bonus + alley_bonus + rating(i, 4) * 2.5) * 0.15
   if players[i].pos.distance_to(ball) < 42 and rng.randf() < 1.0-exp(-rate*delta):
    intercept_pass(i)
    return
 elif flight.kind == "rebound" or flight.kind == "loose":
  if flight.kind == "loose" and loose_ball_timer > 0.0:
   pass
  else:
   var candidates: Array = []
   for i in range(4):
    var p: Dictionary = players[i]
    if p.stun <= 0 and p.jump > 0 and p.get("pickup_delay", 0.0) <= 0.0:
     var p_h = 1.2 + sin(clampf((0.75 - p.jump) / 0.75, 0, 1) * PI) * 1.6
     var ball_h = ball_height()
     var d = p.pos.distance_to(ball)
     var shooter = flight.get("shooter", -1)
     var is_defense = (shooter < 0 or shooter / 2 != i / 2)
     var is_rebound = flight.kind == "rebound"
     # Defender reach bonus & priority in crowd (PLYR2.ASM:2480-2620, ATTRACT.ASM:2546-2552)
     var def_stat = rating(i, 3)
     var reach_limit = (62.0 + def_stat * 1.5) if (is_defense and is_rebound) else 48.0
     if d < reach_limit and absf(ball_h - p_h) < 1.4:
      var def_bonus = (-28.0 - def_stat * 2.0) if (is_defense and is_rebound) else 0.0
      candidates.append({"id": i, "score": d + absf(ball_h - p_h) * 15.0 + def_bonus})
   if candidates.size() > 0:
    candidates.sort_custom(func(a, b): return a.score < b.score)
    var winner = candidates[0].id
    var is_rebound = flight.kind == "rebound"
    var p_win: Dictionary = players[winner]
    acquire_possession(winner, true)
    flight = {}
    p_win.vel = Vector2.ZERO
    p_win.rebound_glide = 0.0
    p_win.push_keep_ball = 1.33
    p_win.steal_immune = 0.67 if rng.randf() < 0.05 else 0.25
    shot_clock = 24.0
    if is_rebound:
     stats[winner].rebounds += 1
     announce("REBOUND!", "catch")
    else:
     announce("LOOSE BALL!", "catch")
    return
 if t < 1:
  return
 if flight.kind == "rebound":
  if flight.get("bounces", 0) == 0:
   flight.bounces = 1
   flight.start = flight.end
   flight.end = (flight.end + Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-35.0, 35.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
   flight.time = 0.0
   flight.duration = REBOUND_BOUNCE_DURATION
   flight.bounce_height = 0.75
  else:
   ball = flight.end
   flight = {}
   loose_ball_timer = 0.0
  return
 if flight.kind == "loose":
  ball = flight.end
  flight = {}
  return
 if flight.kind == "pass":
  var receiver: int = flight.target
  var alley: bool = flight.alley
  var double_dunk: bool = flight.get("double_dunk", false)
  var catch_height = ball_height()
  var catchable: bool = players[receiver].receive_jump > 0 and players[receiver].stun <= 0 and players[receiver].pos.distance_to(flight.end) < 70 and players[receiver].pos.distance_to(hoop_for(receiver/2)) < 220
  if (alley or double_dunk) and not catchable:
   owner = -1
   flight = {}
   loose_ball_timer = 0.45
   players[receiver].pickup_delay = 0.45
   announce("LOB MISSED! LOOSE BALL","miss")
   return
  acquire_possession(receiver)
  ball = players[owner].pos
  last_passer = flight.get("passer", -1)
  assist_window = 3.5 if last_passer >= 0 else 0.0
  flight = {}
  if alley or double_dunk:
   players[owner].alley_cnt = players[owner].get("alley_cnt", 0) + 1
   players[owner].charge = 0.58
   shoot_ball(owner, true, true, catch_height)
   announce("DOUBLE DUNK!" if double_dunk else "ALLEY-OOP!","dunk")
  return
 var shooter: int = flight.shooter
 var team = shooter / 2
 if flight.made and not flight.blocked:
  if flight.dunk:
   players[shooter].rim_hang = 0.35
   players[shooter].jump = maxf(players[shooter].jump, 0.35)
   players[shooter].pos = hoop_for(team) + Vector2(-15 if hoop_for(team).x > 640 else 15, 0)
   var super_facial = is_player_on_fire(shooter) or flight.get("super_dunk", false)
   for d in range(4):
    # Authentic dunk facial radius: 35*DIST_REDUCTION = 29.75 ASM units -> 48.0px from rim (PLYR2.ASM:5406, 5409)
    if d / 2 != team and players[d].pos.distance_to(hoop_for(team)) < 48.0:
     var facial_dir = (players[d].pos - hoop_for(team)).normalized()
     if facial_dir.length() < 0.1:
      facial_dir = Vector2.RIGHT * (1 if hoop_for(team).x < 640 else -1)
     var face_dir = -signf(facial_dir.x)
     if absf(face_dir) > 0.1:
      players[d].face = face_dir
     if super_facial:
      players[d].stun = 1.2
      players[d].shove_kind = "flyback"
      players[d].shove_time = 1.2
      players[d].pos = (players[d].pos + facial_dir * 28.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = facial_dir * 300.0
     else:
      players[d].stun = maxf(players[d].stun, 0.8)
      players[d].shove_kind = "stumble"
      players[d].shove_time = 0.8
      players[d].pos = (players[d].pos + facial_dir * 16.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = facial_dir * 160.0
  var assisted = false
  if assist_window > 0.0 and last_passer >= 0 and last_passer / 2 == team and last_passer != shooter:
   stats[last_passer].assists += 1
   assisted = true
   last_passer = -1
   assist_window = 0.0
  if flight.get("alley", false) or flight.get("double_dunk", false) or assisted:
   team_streak[team] += 1
   if team_streak[team] >= 3:
    team_fire_timer[team] = 25.0
    team_streak[team] = 0
    fire_player = -1
    fire_points = 0
    fire_shots = 0
    announce("TEAM IN THE ZONE! 25 SECONDS!", "fire")
  var was_on_fire = is_player_on_fire(shooter)
  var shattered = award_basket(shooter,flight.points,flight.dunk,true,flight.get("super_dunk",false))
  var ignited = is_player_on_fire(shooter) and not was_on_fire
  var name_text: String = Teams.DATA[teams[team]].players[shooter%2]
  var message = "OFF THE GLASS!" if flight.get("bank_shot", false) else ("HE'S ON FIRE! " + name_text if ignited else ("HE'S HEATING UP! " + name_text if player_streak[shooter] == 2 else "BOOMSHAKALAKA!" if flight.get("super_dunk",false) else "SLAM DUNK!" if flight.dunk else "FROM DOWNTOWN!" if flight.points == 3 else "NOTHING BUT NET!"))
  if shattered:
   players[shooter].rim_hang = 0.0
   players[shooter].jump = 0.0
   announce("BOOM! BACKBOARD SHATTERED!","shatter")
   flight = {}
   owner = -1
   ball = hoop_for(team)
   shot_clock = 24.0
   pending_inbound = 1-team
   shatter_shooter = shooter
   freeze = 1.65
  else:
   announce(message,"fire" if ignited else ("dunk" if flight.dunk else "score"))
   inbound(1-team, true, true)
 else:
  record_miss(shooter)
  last_passer = -1
  assist_window = 0.0
  in_cylinder_timer = 0.20
  must_rebound_timer = 2.0
  loose_ball_timer = maxf(loose_ball_timer, 0.20)
  var was_bank_shot = flight.get("bank_shot", false)
  var was_clank = flight.get("clank", false)
  var was_airball = flight.get("airball", false)
  var ricochet = calculate_rim_ricochet(flight.start, flight.end)
  var arc_h = 2.8 if was_clank else (1.2 if was_airball else 2.2)
  if was_bank_shot:
   ricochet = hoop_for(team) + (ricochet - hoop_for(team)) * 0.65
   arc_h = 1.6
  if delta >= 1.5:
   ball = ricochet
   flight = {}
   owner = -1
   shot_clock = 24.0
   loose_ball_timer = 0.0
   in_cylinder_timer = 0.0
   announce("AIRBALL!" if was_airball else ("OFF THE GLASS!" if was_bank_shot else "OFF THE RIM!"), "miss")
  else:
   flight = {"kind":"rebound", "start":hoop_for(team), "end":ricochet, "time":0.0, "duration":REBOUND_FLIGHT_DURATION, "shooter":shooter, "arc_height":arc_h, "bounces":0}
   owner = -1
   shot_clock = 24.0
   announce("AIRBALL!" if was_airball else ("OFF THE GLASS!" if was_bank_shot else ("OFF THE BACK IRON!" if was_clank else "OFF THE RIM!")), "miss")

func next_period(from_transition: bool = false) -> void:
 if not from_transition and quarter_scores.size() < quarter:
  record_quarter_score()
 if quarter >= 4:
  if score[0] != score[1]:
   phase = "finished"
   if not from_transition:
    announce("FINAL", "whistle")
   return
  overtime += 1
  clock = minf(60.0, period_length)
  if not from_transition:
   announce("OVERTIME" if overtime == 1 else ("DOUBLE OVERTIME" if overtime == 2 else "TRIPLE OVERTIME"), "whistle")
 else:
  quarter += 1
  clock = period_length
  if not from_transition:
   announce("HALFTIME • SWITCH ENDS" if quarter == 3 else "QUARTER %d" % quarter, "whistle")
 for p in players:
  p.turbo = 1.0
  p.turbo_burnout = 0.0
  p.turbo_flash = 0.0
  p.alley_cnt = 0
  p.shove_kind = ""
  p.shove_time = 0.0
 inbound(quarter % 2)

func snapshot() -> Dictionary:
 return {"tipoff":tipoff.duplicate(true), "board_breaks":board_breaks.duplicate(), "pending_inbound":pending_inbound, "shatter_shooter":shatter_shooter, "players":players.duplicate(true), "teams":teams.duplicate(), "score":score.duplicate(), "streak":streak.duplicate(), "player_streak":player_streak.duplicate(), "team_streak":team_streak.duplicate(), "team_fire_timer":team_fire_timer.duplicate(), "fire_player":fire_player, "fire_points":fire_points, "fire_shots":fire_shots, "last_passer":last_passer, "assist_window":assist_window, "brick_count":brick_count.duplicate(), "inbounding_team":inbounding_team, "teammate_shot_order":teammate_shot_order, "stats":stats.duplicate(true), "ball":ball, "owner":owner, "flight":flight.duplicate(true), "clock":clock, "shot_clock":shot_clock, "quarter":quarter, "overtime":overtime, "phase":phase, "freeze":freeze, "banner":banner, "banner_time":banner_time, "event_id":event_id, "event_kind":event_kind, "elapsed":elapsed, "big_heads":big_heads, "infinite_turbo":infinite_turbo, "tournament_mode":tournament_mode, "no_pushing":no_pushing, "fast_passing":fast_passing, "maximum_power":maximum_power, "last_shot_feedback":last_shot_feedback.duplicate(true), "loose_ball_timer":loose_ball_timer, "in_cylinder_timer":in_cylinder_timer, "must_rebound_timer":must_rebound_timer, "bullet_time_remaining":bullet_time_remaining, "inbound_transition":inbound_transition.duplicate(true), "quarter_transition":quarter_transition.duplicate(true), "quarter_scores":quarter_scores.duplicate(true), "clock_buzzer_sounded":clock_buzzer_sounded}

func apply_snapshot(data: Dictionary) -> void:
 for key in data:
  set(key, data[key])
