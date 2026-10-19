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
const SIGNATURE_DUNKS = ["helicopter", "frontflip", "backflip", "spin_360", "between_legs", "behind_back"]
const QUARTER_SECONDS = 180.0
const TIP_TOSS = 1.0
const TIP_IDEAL_JUMP = 1.42
const TIP_DECISION = 2.05
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
var brick_count: Array = [0, 0, 0, 0]
var inbounding_team: int = -1
var loose_ball_timer: float = 0.0
var in_cylinder_timer: float = 0.0
var must_rebound_timer: float = 0.0
var bullet_time_remaining: float = 0.0
var tipoff: Dictionary = {}
var last_shot_feedback: Dictionary = {}
var inbound_transition: Dictionary = {}

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
  players.append({"pos":Vector2(420 if t == 0 else 860, 400 + (i % 2) * 140), "vel":Vector2.ZERO, "turbo":1.0, "turbo_burnout":0.0, "jump":0.0, "receive_jump":0.0, "stun":0.0, "cooldown":0.0, "charge":0.0, "fake":0.0, "drive":0.0, "swipe":0.0, "swipe_resolved":false, "swipe_shove":false, "rebound_glide":0.0, "possession_flash":0.0, "shoot_held":false, "face":1 if t == 0 else -1, "spin":0.0, "spin_cooldown":0.0, "elbow":0.0, "steal_immune":0.0, "rim_hang":0.0, "still_time":1.0, "shot_is_moving":false, "shot_drift_vel":Vector2.ZERO, "last_move_vel":Vector2.ZERO})
  stats.append({"points":0, "attempts":0, "made":0, "dunks":0, "steals":0, "blocks":0, "rebounds":0, "goaltends":0, "assists":0, "injury":0})
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
 if dramatic:
  bullet_time_remaining = BULLET_TIME_DURATION

func hoop_for(team: int) -> Vector2:
 var right = team == 0
 if quarter >= 3:
  right = not right
 return HOOPS[1 if right else 0]

func rating(i: int, stat: int) -> float:
 return float(Teams.DATA[teams[i / 2]].ratings[i % 2][stat])

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
 for i in range(4):
  if i != shooter and i != fire_player:
   player_streak[i] = 0
 brick_count[shooter] = 0
 if is_player_on_fire(shooter):
  fire_points += points
  if fire_points >= 8:
   fire_player = -1
   player_streak[shooter] = 0
   fire_points = 0
   announce("HE'S COOLED OFF!", "whistle")
 else:
  player_streak[shooter] = mini(3,player_streak[shooter]+1)
  if player_streak[shooter] >= 3:
   fire_player = shooter
   fire_points = 0
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
  if players[owner].receive_jump > 0:
   return 1.1+receive_height(owner)
  elif players[owner].charge > 0:
   var jump = sin(clampf(players[owner].charge / 1.16, 0.0, 1.0) * PI) * 1.35
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
 spots[teammate] = Vector2(own_hoop.x + (140 if left_side else -140), own_hoop.y + 40)
 var opp_team = 1 - team
 spots[opp_team * 2] = Vector2(640 + (-90 if left_side else 90), 380)
 spots[opp_team * 2 + 1] = Vector2(640 + (-90 if left_side else 90), 520)
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
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
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
    p.face = 1 if left_side else -1

 if owner >= 0 and owner < 4:
  ball = players[owner].pos + Vector2(players[owner].face * 14, -7)

 if all_settled or inbound_transition.timer > 2.5:
  for i in range(4):
   players[i].pos = spots[i]
   players[i].vel = Vector2.ZERO
   players[i].jump = 0.0
   players[i].face = 1 if left_side else -1
  if owner >= 0 and owner < 4:
   ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
  inbound_transition = {}
  freeze = 0.45

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
  players[i].face = 1 if left_side else -1
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
 var teammate = (team * 2) + 1
 players[teammate].face = 1 if left_side else -1
 var opp_team = 1 - team
 players[opp_team * 2].face = -1 if left_side else 1
 players[opp_team * 2 + 1].face = -1 if left_side else 1
 players[owner].face = 1 if left_side else -1
 ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
 freeze = 1.0

func tick(delta: float, commands: Dictionary) -> void:
 if phase != "playing":
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
 for t in range(2):
  if team_fire_timer[t] > 0.0:
   team_fire_timer[t] = maxf(0.0, team_fire_timer[t] - delta)
   if team_fire_timer[t] <= 0.0:
    announce("TEAM ZONE EXPIRED!", "whistle")
 if tipoff.get("active",false):
  tick_tipoff(delta,commands)
  return
 if inbound_transition.get("active", false):
  tick_inbound_transition(delta)
  return
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
  clock = maxf(0.0, clock - delta)
  if flight.is_empty() or flight.get("kind", "") != "shot":
   if clock >= 24.0:
    shot_clock = maxf(0.0, shot_clock - delta)
   else:
    shot_clock = 24.0
 if clock <= 0 and flight.is_empty():
  next_period()
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
    var breakdown = calculate_shot_percentage(dunker, 0.58, false, true, false, false)
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
  p.turbo_burnout = maxf(0.0, p.get("turbo_burnout", 0.0) - delta)
  if p.swipe > 0.0 and not p.get("swipe_resolved", false) and p.swipe <= 0.25:
   p.swipe_resolved = true
   resolve_steal(i, p.get("swipe_shove", false))
  p.drive = maxf(0.0,p.drive-delta)
  var c: Dictionary = effective_commands[i]
  if p.stun > 0:
   p.charge = 0.0
   p.shoot_held = false
   p.receive_jump = 0.0
   continue
  var move: Vector2 = c.get("move", Vector2.ZERO)
  move = move.limit_length()
  var turbo: bool = c.get("turbo", false) and (p.turbo > 0.001 or infinite_turbo or is_player_on_fire(i))
  var speed = 125.0 + rating(i, 0) * 7.0
  if p.turbo_burnout > 0.0:
   speed *= 0.85
   p.turbo = 0.0
  elif turbo:
   speed *= 1.6
   var drain_mult = 0.75 if (score[1 - i / 2] - score[i / 2] >= 8) else 1.0
   p.turbo = maxf(0.0, p.turbo - delta * 0.27 * drain_mult)
   if p.turbo <= 0.001 and not infinite_turbo and not is_player_on_fire(i):
    p.turbo = 0.0
    p.turbo_burnout = 0.75
  elif c.get("turbo", false) and p.turbo <= 0.001 and p.turbo_burnout <= 0.0 and not infinite_turbo and not is_player_on_fire(i):
   p.turbo = 0.0
   p.turbo_burnout = 0.75
   speed *= 0.85
  else:
   p.turbo = minf(1.0, p.turbo + delta * 0.17)
  if infinite_turbo or is_player_on_fire(i):
   p.turbo = 1.0
   p.turbo_burnout = 0.0
  var spin_press: bool = c.get("spin", false)
  if owner == i and spin_press and inbounding_team < 0 and p.jump <= 0.0 and p.receive_jump <= 0.0 and p.cooldown <= 0.0 and p.spin_cooldown <= 0.0:
   p.turbo = maxf(0.0, p.turbo - (2.0 / 7.0))
   p.steal_immune = 1.0
   if move.length() > 0.2:
    p.spin = 0.45
    p.spin_cooldown = 2.0
    p.cooldown = 0.45
    p.vel = move.normalized() * (speed * 1.35)
    announce("SPIN MOVE!", "pass")
   else:
    p.elbow = 0.50
    p.spin_cooldown = 1.2
    p.cooldown = 0.50
    for d in range(4):
     if d / 2 != i / 2 and players[d].pos.distance_to(p.pos) < 75.0:
      players[d].stun = 0.75
      var push_dir = (players[d].pos - p.pos).normalized()
      if push_dir.length() < 0.1:
       push_dir = Vector2.RIGHT * p.face
      players[d].pos = (players[d].pos + push_dir * 38.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = push_dir * 120.0
    announce("CLEAR OUT!", "shove")
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
  elif owner == i and (p.charge > 0.0 or shooting_this_tick):
   if p.get("shot_is_moving", false):
    p.vel = move * speed if move.length() > 0.05 else p.get("shot_drift_vel", p.vel)
   else:
    p.vel = Vector2.ZERO
  else:
   p.vel = move * speed
  if p.get("rebound_glide", 0.0) > 0.0:
   p.rebound_glide = maxf(0.0, p.rebound_glide - delta)
  elif p.jump > 0.0 and owner != i and p.receive_jump <= 0.0:
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
  if owner == i and p.pos.x >= COURT.position.x and p.pos.x <= COURT.end.x:
   inbounding_team = -1
  if absf(p.vel.x) > 0.1:
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
    if p.charge < 0.16 and commands.has(i):
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
    if players[i].stun <= 0 and players[i].pos.distance_to(ball) < 30:
     acquire_possession(i, true)
     shot_clock = 24.0
     stats[i].rebounds += 1
     announce("REBOUND!", "catch")
     break

func ai(i: int) -> Dictionary:
 var p: Dictionary = players[i]
 var team = i / 2
 var target: Vector2 = p.pos
 var shoot = false
 var pass_action = false
 var turbo = false
 if not flight.is_empty() and flight.kind == "pass" and flight.get("alley",false) and flight.target == i and p.receive_jump > 0:
  target = p.pos
 elif owner == i and (p.pos.x < COURT.position.x or p.pos.x > COURT.end.x):
  return {"move":Vector2.ZERO, "shoot":false, "pass":p.cooldown <= 0, "turbo":false}
 elif owner == i:
  var hoop = hoop_for(team)
  target = hoop + Vector2(-90 if hoop.x > 640 else 90, 10 * sin(elapsed + i))
  if p.charge > 0 and p.pos.distance_to(hoop) < 165:
   target = hoop+Vector2(60 if hoop.x > 640 else -60,0)
  var dist: float = p.pos.distance_to(hoop)
  turbo = dist < 240
  var opp_team = 1 - team
  var deficit = score[opp_team] - score[team]
  if quarter >= 4 and deficit <= -6 and shot_clock > 6.0 and clock > 6.0:
   shoot = false
   target = hoop + Vector2(-220 if hoop.x > 640 else 220, 25.0 * sin(elapsed + i))
  else:
   if dist < 125 or shot_clock < 3 or (dist < 370 and fmod(elapsed + i, 5.0) < 0.7):
    shoot = p.charge < 0.56
  if p.cooldown <= 0 and nearest_defender(i) < 45 and fmod(elapsed, 2.0) < 0.025:
   pass_action = true
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
 elif owner >= 0 and owner / 2 == team:
  target = hoop_for(team) + Vector2(-180 if hoop_for(team).x > 640 else 180, 115 if i % 2 else -110)
 elif owner >= 0:
  var partner = (i / 2) * 2 + (1 - i % 2)
  var opp_team = 1 - team
  var deficit = score[opp_team] - score[team]
  var help_defense = players[partner].stun > 0.0 or shot_clock < 5.0 or clock < 8.0 or (quarter >= 4 and deficit > 0)
  var mark = owner if (i % 2 == owner % 2 or help_defense) else (1 - team) * 2 + i % 2
  target = players[mark].pos.lerp(hoop_for(1-team), 0.12)
  if p.pos.distance_to(players[owner].pos) < 65 and p.cooldown <= 0:
   var steal_prob = 0.018 + difficulty * 0.012
   if quarter >= 4 and deficit > 0:
    steal_prob += clampf(float(deficit) * 0.035, 0.0, 0.35)
    turbo = true
   pass_action = rng.randf() < steal_prob
 else:
  target = ball
 return {"move":(target - p.pos).normalized() if p.pos.distance_to(target) > 9 else Vector2.ZERO, "shoot":shoot, "pass":pass_action, "turbo":turbo}

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
  if alignment < -0.15:
   continue
  var cone = clampf((alignment + 0.15) / 1.15, 0.0, 1.0)
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

func calculate_shot_percentage(i: int, charge: float, dunk: bool, layup: bool, specialty: bool, alley: bool = false, hook: bool = false, fadeaway: bool = false, moving_shot: Variant = null) -> Dictionary:
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
 var rubber_band = 0.0 if tournament_mode else clampf(float(score_diff) * 0.014, -0.12, 0.14)
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
 if dunk:
  base = (0.84 if specialty else 0.72) + rating(i, 2) * 0.018
  chance = base - contest_level * 0.14 + rubber_band
 elif layup:
  base = 0.66 + rating(i, 1) * 0.024
  timing_contrib = timing * 0.10
  chance = base + timing_contrib - contest_level * 0.20 + rubber_band
 elif hook:
  base = 0.62 + rating(i, 1) * 0.028
  timing_contrib = timing * 0.15
  chance = base + timing_contrib - contest_level * 0.22 + rubber_band
 elif fadeaway:
  base = 0.20 + rating(i, 1) * 0.035
  timing_contrib = timing * 0.24
  var fade_contest = maxf(0.0, contest_level - 0.25)
  chance = base + timing_contrib - dist_penalty - fade_contest * 0.28 + rubber_band
 else:
  base = 0.24 + rating(i, 1) * 0.038
  timing_contrib = timing * 0.28
  if is_moving_shot:
   chance = base + timing_contrib - dist_penalty - contest_level * 0.32 + rubber_band - moving_penalty
  else:
   chance = base + timing_contrib - dist_penalty - contest_level * 0.32 + rubber_band + still_bonus
 if is_player_on_fire(i):
  fire_bonus = 0.30
  chance += fire_bonus
  var fire_floor = 0.95 if dunk else (0.88 if layup else 0.82)
  chance = maxf(chance, fire_floor)
 elif player_streak[i] == 2:
  fire_bonus = 0.08
  chance += fire_bonus
 if brick_count[i] >= 3 and distance <= 450.0:
  chance = 0.99
 elif score_diff <= -4 and not tournament_mode and rng.randf() < 0.55:
  chance = minf(chance, 0.35)
 if quarter >= 4 and clock <= 5.0:
  if score[0] == score[1]:
   chance = 0.05
  elif score_diff in [1, 2] and clock <= 4.0:
   chance = maxf(chance, 0.88)
 if distance > 450.0 and clock <= 4.0:
  chance += 0.15
 if clock <= 10.0 and rating(i, 3) >= 5.0:
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
 if not moving or distance >= 185:
  return "jumper"
 var hoop_dir = (hoop - p.pos).normalized()
 var vel_dir = p.vel.normalized() if p.vel.length() > 10.0 else Vector2(p.face, 0.0)
 var directness = vel_dir.dot(hoop_dir)
 if not turbo and distance >= 75.0 and distance <= 185.0 and directness < 0.65 and directness > -0.65 and p.vel.length() > 30.0:
  return "hook_shot"
 if turbo and (p.turbo > 0.1 or infinite_turbo or is_player_on_fire(i)):
  var contest = calculate_defensive_contest(i, hoop)
  if contest.level > 0.45 and not is_player_on_fire(i) and rating(i, 2) < 8.0 and rng.randf() >= 0.35:
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
 var is_bank_angle = distance >= 85.0 and distance <= 270.0 and angle_from_baseline > 0.40 and angle_from_baseline < 1.35
 var bank_shot = is_bank_angle and not dunk and not alley and rng.randf() < 0.28
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
 if dunk and will_make:
  var my_team = i / 2
  var opp_team = 1 - my_team
  var pts_down = score[opp_team] - score[my_team]
  if pts_down < 2 and not is_player_on_fire(i) and not specialty:
   if rng.randf() < 0.025:
    will_make = false
    clank = true
 var dunk_duration = 0.92 if burning else (0.75 if specialty else 0.60)
 var dunk_arc = 4.2 if burning else (2.6 if specialty else 1.1)
 flight = {"kind":"shot", "start":ball, "end":hoop, "time":0.0, "duration":dunk_duration if dunk else (0.62 if layup else (0.85 if hook else 1.05)), "shooter":i, "points":points, "made":will_make, "dunk":dunk, "layup":layup, "hook":hook, "fadeaway":fadeaway, "super_dunk":specialty or burning, "dunk_style":dunk_style, "finish":finish, "arc_height":(3.6 if turbo else 2.5) if hook else (dunk_arc if dunk else (1.0 if layup else 4.6)), "blocked":false, "shot_breakdown":breakdown, "clank":clank, "bank_shot":bank_shot, "moving_shot":moving_shot}
 if dunk or layup or hook:
  flight.player_start = p.pos
  flight.player_end = hoop+Vector2(-1 if hoop.x > 640 else 1,0)*(28 if dunk else 50)
  flight.player_launch_height = launch_height
 flight.release_height = release_height
 flight.cpu_block_allowed = []
 for defender in range(4):
  flight.cpu_block_allowed.append(rng.randf() < 0.15+0.10*clampi(difficulty,0,2))
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
 var duration = clampf(distance/2300.0,0.10,0.42) if turbo else clampf(distance/1400.0,0.16,0.65)
 if fast_passing:
  duration *= 0.50
 if clock <= 10.0 and rating(i, 3) >= 5.0:
  duration *= 0.85
 var pass_vec = players[mate].pos - players[i].pos
 var face_dir = Vector2(players[i].face, 0.0)
 var behind_back = not alley and distance >= 80.0 and distance <= 380.0 and rating(i, 3) >= 4.0 and face_dir.dot(pass_vec.normalized()) < -0.30
 flight = {"kind":"pass", "start":ball, "end":players[mate].pos, "start_height":release_height, "end_height":3.8 if alley else 1.1, "time":0.0, "duration":0.38 if alley else duration, "target":mate, "passer":i, "alley":alley, "turbo":turbo, "behind_back":behind_back}
 owner = -1
 inbounding_team = -1
 players[i].cooldown = 0.45
 announce("LOB IT UP!" if alley else ("BEHIND THE BACK PASS!" if behind_back else "NICE PASS"), "pass")

func defend(i: int, turbo: bool) -> void:
 players[i].vel = Vector2.ZERO
 players[i].jump = 0.70
 players[i].cooldown = 0.75
 if must_rebound_timer > 0.0 or (not flight.is_empty() and flight.get("kind", "") == "rebound"):
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
  var desc_threshold = -1.5 if pts_down >= 5 else 0.0
  var descending = v_vert < desc_threshold
  var at_rim = contact.distance_to(flight.end) < 115
  if descending and at_rim and reach < 78 and ball_height() <= 4.6:
   var uncalled = false
   if pts_down >= 1:
    var uncalled_chance = minf(0.09, 0.035 + float(pts_down - 1) * 0.004)
    if rng.randf() < uncalled_chance:
     uncalled = true
   if flight.dunk or is_player_on_fire(i) or uncalled:
    flight.made = false
    flight.blocked = true
    stats[i].blocks += 1
    record_miss(shooter)
    announce("NO CALL! REJECTED AT THE RIM!" if uncalled else ("DENIED AT THE RIM!" if flight.dunk else "FIRE BLOCK! NO GOALTENDING!"), "block")
   else:
    var points: int = flight.points
    stats[i].goaltends += 1
    award_basket(shooter,points,false,false)
    announce("GOALTENDING! %d POINTS" % points,"whistle")
    inbound(i/2, true)
  elif not descending and reach < 85 and ball_height() <= 4.6:
   flight.made = false
   flight.blocked = true
   stats[i].blocks += 1
   record_miss(shooter)
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
   players[i].turbo = maxf(0.0, players[i].turbo - 0.15)
 players[i].cooldown = 0.65
 players[i].swipe = 0.45
 players[i].swipe_resolved = false
 players[i].swipe_shove = shove
 players[i].vel = Vector2.ZERO
 if not flight.is_empty() and flight.kind == "pass" and not flight.get("tip",false) and int(flight.target)/2 != i/2:
  if players[i].pos.distance_to(flight_position()) < (68 if shove else 56) and ball_height() <= 2.5 and rng.randf() < 0.45+rating(i,3)*0.04:
   intercept_pass(i)
  return
 if shove:
  resolve_steal(i, true)

func resolve_steal(i: int, shove: bool) -> void:
 if owner < 0 or owner / 2 == i / 2:
  return
 var victim = owner
 if players[victim].get("steal_immune", 0.0) > 0.0:
  return
 if players[i].pos.distance_to(players[victim].pos) > (68.0 if shove else 50.0):
  return
 if shove:
  var pusher_power = 9.0 if (maximum_power or is_player_on_fire(i)) else rating(i, 2)
  var victim_power = 9.0 if (maximum_power or is_player_on_fire(victim)) else rating(victim, 2)
  var power_diff = pusher_power - victim_power
  if power_diff < -2.5 and rng.randf() < 0.50:
   players[victim].stun = 0.35
   var stagger_dir = (players[victim].pos - players[i].pos).normalized() * 14.0
   players[victim].pos = (players[victim].pos + stagger_dir).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
   players[victim].charge = 0.0
   players[victim].fake = 0.0
   players[i].cooldown = 0.75
   stats[i].steals += 1
   acquire_possession(i, true)
   shot_clock = 24.0
   announce("STAGGERED!", "steal")
   return
  players[victim].stun = 0.95
  stats[victim].injury += 1
  var knock_dir = (players[victim].pos - players[i].pos).normalized() * 28.0
  players[victim].pos = (players[victim].pos + knock_dir).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  players[i].cooldown = 0.80
  stats[i].steals += 1
  acquire_possession(i, true)
  shot_clock = 24.0
  announce("SHOVED! NO FOULS!", "steal")
  return
 var clutch_steal_bonus = 0.12 if (clock <= 10.0 and rating(i, 3) >= 5.0) else 0.0
 var steal_chance = 0.18 + rating(i, 3) * 0.015 + clutch_steal_bonus
 if rng.randf() < steal_chance:
  var clean_chance = 0.18 + rating(i, 3) * 0.012
  var clean_steal = rng.randf() < clean_chance
  stats[i].steals += 1
  players[i].cooldown = 0.75
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  if clean_steal:
   acquire_possession(i, true)
   shot_clock = 24.0
   announce("PICKED THEIR POCKET!", "steal")
  else:
   owner = -1
   shot_clock = 24.0
   loose_ball_timer = 0.50
   var loose_dir = (players[victim].pos - players[i].pos).normalized()
   if loose_dir.length() < 0.1:
    loose_dir = Vector2.RIGHT * players[i].face
   var loose_dest = (ball + loose_dir * rng.randf_range(50.0, 95.0) + Vector2(rng.randf_range(-25.0, 25.0), rng.randf_range(-25.0, 25.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
   flight = {"kind":"loose", "start":ball, "end":loose_dest, "time":0.0, "duration":0.40, "arc_height":0.95}
   announce("LOOSE BALL!", "steal")

func intercept_pass(i: int) -> void:
 stats[i].steals += 1
 if rng.randf() < 0.04:
  owner = -1
  var tip_dest = (ball + Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(-40.0, 40.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
  flight = {"kind":"loose", "start":ball, "end":tip_dest, "time":0.0, "duration":0.65, "arc_height":4.8, "tip":true}
  loose_ball_timer = 0.40
  players[i].cooldown = 0.5
  players[i].swipe = 0.25
  announce("TIPPED PASS! LOOSE BALL", "steal")
  return
 acquire_possession(i, true)
 flight = {}
 ball = players[i].pos
 shot_clock = 24.0
 players[i].cooldown = 0.8
 players[i].swipe = 0.25
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
   var rate = 2.5+rating(i,3)*0.25
   var def_team = i / 2
   var off_team = int(flight.target) / 2
   var pts_down = score[off_team] - score[def_team]
   if pts_down > 0:
    var int_bonus = clampf(float(pts_down) * 0.015, 0.0, 0.19)
    rate += int_bonus * 10.0
   if flight.get("alley", false):
    rate += 2.5
   if players[i].pos.distance_to(ball) < 42 and rng.randf() < 1.0-exp(-rate*delta):
    intercept_pass(i)
    return
 elif flight.kind == "rebound":
  for i in range(4):
   var p: Dictionary = players[i]
   if p.stun <= 0 and p.jump > 0:
    var p_h = 1.2 + sin(clampf((0.75 - p.jump) / 0.75, 0, 1) * PI) * 1.6
    var ball_h = ball_height()
    if p.pos.distance_to(ball) < 55.0 and absf(ball_h - p_h) < 1.4:
     acquire_possession(i, true)
     flight = {}
     p.vel = Vector2.ZERO
     p.rebound_glide = 0.0
     shot_clock = 24.0
     stats[i].rebounds += 1
     announce("REBOUND!", "catch")
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
   announce("LOB MISSED! LOOSE BALL","miss")
   return
  acquire_possession(receiver)
  ball = players[owner].pos
  last_passer = flight.get("passer", -1)
  assist_window = 3.5 if last_passer >= 0 else 0.0
  flight = {}
  if alley or double_dunk:
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
    if d / 2 != team and players[d].pos.distance_to(hoop_for(team)) < 78.0:
     if super_facial:
      players[d].stun = 1.2
      players[d].pos = (players[d].pos + (players[d].pos - hoop_for(team)).normalized() * 32.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = Vector2.ZERO
     else:
      players[d].stun = maxf(players[d].stun, 0.8)
      players[d].pos = (players[d].pos + (players[d].pos - hoop_for(team)).normalized() * 20.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = Vector2.ZERO
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
  var ricochet = calculate_rim_ricochet(flight.start, flight.end)
  var arc_h = 2.8 if was_clank else 2.2
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
   announce("OFF THE GLASS!" if was_bank_shot else "OFF THE RIM!", "miss")
  else:
   flight = {"kind":"rebound", "start":hoop_for(team), "end":ricochet, "time":0.0, "duration":REBOUND_FLIGHT_DURATION, "shooter":shooter, "arc_height":arc_h, "bounces":0}
   owner = -1
   shot_clock = 24.0
   announce("OFF THE GLASS!" if was_bank_shot else ("OFF THE BACK IRON!" if was_clank else "OFF THE RIM!"), "miss")

func next_period() -> void:
 if quarter >= 4:
  if score[0] != score[1]:
   phase = "finished"
   announce("FINAL", "whistle")
   return
  overtime += 1
  clock = minf(60.0, period_length)
  announce("OVERTIME" if overtime == 1 else ("DOUBLE OVERTIME" if overtime == 2 else "TRIPLE OVERTIME"), "whistle")
 else:
  quarter += 1
  clock = period_length
  announce("HALFTIME • SWITCH ENDS" if quarter == 3 else "QUARTER %d" % quarter, "whistle")
 inbound(quarter % 2)

func snapshot() -> Dictionary:
 return {"tipoff":tipoff.duplicate(true), "board_breaks":board_breaks.duplicate(), "pending_inbound":pending_inbound, "shatter_shooter":shatter_shooter, "players":players.duplicate(true), "teams":teams.duplicate(), "score":score.duplicate(), "streak":streak.duplicate(), "player_streak":player_streak.duplicate(), "team_streak":team_streak.duplicate(), "team_fire_timer":team_fire_timer.duplicate(), "fire_player":fire_player, "fire_points":fire_points, "last_passer":last_passer, "assist_window":assist_window, "brick_count":brick_count.duplicate(), "inbounding_team":inbounding_team, "teammate_shot_order":teammate_shot_order, "stats":stats.duplicate(true), "ball":ball, "owner":owner, "flight":flight.duplicate(true), "clock":clock, "shot_clock":shot_clock, "quarter":quarter, "overtime":overtime, "phase":phase, "freeze":freeze, "banner":banner, "banner_time":banner_time, "event_id":event_id, "event_kind":event_kind, "elapsed":elapsed, "big_heads":big_heads, "infinite_turbo":infinite_turbo, "tournament_mode":tournament_mode, "no_pushing":no_pushing, "fast_passing":fast_passing, "maximum_power":maximum_power, "last_shot_feedback":last_shot_feedback.duplicate(true), "loose_ball_timer":loose_ball_timer, "in_cylinder_timer":in_cylinder_timer, "must_rebound_timer":must_rebound_timer, "bullet_time_remaining":bullet_time_remaining, "inbound_transition":inbound_transition.duplicate(true)}

func apply_snapshot(data: Dictionary) -> void:
 for key in data:
  set(key, data[key])
