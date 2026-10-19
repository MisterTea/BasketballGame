class_name MatchState
extends RefCounted

const COURT = Rect2(115, 265, 1050, 410)
const HOOPS = [Vector2(165, 465), Vector2(1115, 465)]
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
var fire_player = -1
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
var period_length = QUARTER_SECONDS
var board_breaks: Array = [-1.0,-1.0]
var pending_inbound = -1
var shatter_shooter = -1
var tipoff: Dictionary = {}
var last_shot_feedback: Dictionary = {}

func start(a: int, b: int, seconds: float = QUARTER_SECONDS, level: int = 1) -> void:
 rng.randomize()
 teams = [a, b]
 score = [0, 0]
 streak = [0, 0]
 player_streak = [0, 0, 0, 0]
 fire_player = -1
 teammate_shot_order = -1
 board_breaks = [-1.0,-1.0]
 pending_inbound = -1
 shatter_shooter = -1
 last_shot_feedback = {}
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
  players.append({"pos":Vector2(420 if t == 0 else 860, 400 + (i % 2) * 140), "vel":Vector2.ZERO, "turbo":1.0, "jump":0.0, "receive_jump":0.0, "stun":0.0, "cooldown":0.0, "charge":0.0, "fake":0.0, "drive":0.0, "swipe":0.0, "shoot_held":false, "face":1 if t == 0 else -1})
  stats.append({"points":0, "attempts":0, "made":0, "dunks":0, "steals":0, "blocks":0, "rebounds":0, "goaltends":0})
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

func hoop_for(team: int) -> Vector2:
 var right = team == 0
 if quarter >= 3:
  right = not right
 return HOOPS[1 if right else 0]

func rating(i: int, stat: int) -> float:
 return float(Teams.DATA[teams[i / 2]].ratings[i % 2][stat])

func on_fire(team: int) -> bool:
 return fire_player >= 0 and fire_player / 2 == team

func is_player_on_fire(index: int) -> bool:
 return fire_player == index

func refresh_heat_summary() -> void:
 for team in range(2):
  streak[team] = maxi(player_streak[team*2],player_streak[team*2+1])

func record_natural_basket(shooter: int) -> void:
 var previous_fire = fire_player
 if fire_player >= 0 and fire_player / 2 != shooter / 2:
  fire_player = -1
 for i in range(4):
  if i != shooter and i != fire_player:
   player_streak[i] = 0
 player_streak[shooter] = mini(3,player_streak[shooter]+1)
 if player_streak[shooter] >= 3:
  fire_player = shooter
  if previous_fire >= 0 and previous_fire != shooter:
   player_streak[previous_fire] = 0
 refresh_heat_summary()

func record_miss(shooter: int) -> void:
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
  record_natural_basket(shooter)
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
  return lerpf(flight.get("start_height",1.1),flight.get("end_height",1.1),t)+sin(t*PI)*(1.4 if flight.get("alley",false) else 0.5)
 if owner >= 0:
  if players[owner].receive_jump > 0:
   return 1.1+receive_height(owner)
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
 if shoot or pass_request or teammate_shot_order == owner:
  var cpu = ai(owner)
  cpu.shoot = shoot and not pass_request
  cpu["pass"] = pass_request
  cpu.turbo = request.get("turbo",false)
  effective[owner] = cpu
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

func inbound(team: int) -> void:
 if not tipoff.is_empty():
  tipoff.active = false
 pending_inbound = -1
 shatter_shooter = -1
 teammate_shot_order = -1
 owner = team * 2
 flight = {}
 shot_clock = 24.0
 var own_hoop = hoop_for(1 - team)
 for i in range(4):
  var side = i / 2
  var h = hoop_for(1 - side)
  players[i].pos = Vector2(h.x + (190 if h.x < 640 else -190), 390 + (i % 2) * 145)
  players[i].charge = 0.0
  players[i].fake = 0.0
  players[i].drive = 0.0
  players[i].swipe = 0.0
  players[i].shoot_held = false
  players[i].jump = 0.0
  players[i].receive_jump = 0.0
 players[owner].pos = own_hoop + Vector2(85 if own_hoop.x < 640 else -85, 0)
 ball = players[owner].pos
 freeze = 1.0

func tick(delta: float, commands: Dictionary) -> void:
 if phase != "playing":
  return
 elapsed += delta
 banner_time = maxf(0.0, banner_time - delta)
 if tipoff.get("active",false):
  tick_tipoff(delta,commands)
  return
 if freeze > 0:
  if pending_inbound >= 0:
   for p in players:
    p.jump = maxf(0,p.jump-delta)
  freeze = maxf(0,freeze-delta)
  return
 if pending_inbound >= 0:
  inbound(pending_inbound)
  return
 # A released shot is allowed to finish after either buzzer.
 clock = maxf(0.0, clock - delta)
 if flight.is_empty() or flight.get("kind", "") != "shot":
  shot_clock = maxf(0.0, shot_clock - delta)
 if clock <= 0 and flight.is_empty():
  next_period()
  return
 if shot_clock <= 0 and flight.is_empty():
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
 # A dunker may abandon the attempt for a pass before reaching the rim.
 # The existing reliable Pass event also carries this action online.
 if not flight.is_empty() and flight.kind == "shot" and flight.dunk and not flight.blocked and flight.time < flight.duration*0.85:
  var dunker: int = flight.shooter
  if commands.has(dunker) and commands[dunker].get("pass",false):
   stats[dunker].attempts = maxi(0,stats[dunker].attempts-1)
   pass_ball(dunker,commands[dunker].get("turbo",false))
   players[dunker].charge = 0.0
   players[dunker].shoot_held = false
   announce("AIRBORNE DISH!", "pass")
 for i in range(4):
  var p: Dictionary = players[i]
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  p.jump = maxf(0.0, p.jump - delta)
  p.receive_jump = maxf(0.0,p.receive_jump-delta)
  p.fake = maxf(0.0, p.fake - delta)
  p.swipe = maxf(0.0,p.swipe-delta)
  p.drive = maxf(0.0,p.drive-delta)
  var c: Dictionary = effective_commands[i]
  if p.stun > 0:
   p.charge = 0.0
   p.shoot_held = false
   p.receive_jump = 0.0
   continue
  var move: Vector2 = c.get("move", Vector2.ZERO)
  move = move.limit_length()
  var turbo: bool = c.get("turbo", false) and (p.turbo > 0.02 or infinite_turbo or is_player_on_fire(i))
  var speed = 125.0 + rating(i, 0) * 7.0
  if turbo:
   speed *= 1.6
   p.turbo = maxf(0.0, p.turbo - delta * 0.27)
  else:
   p.turbo = minf(1.0, p.turbo + delta * 0.17)
  if infinite_turbo or is_player_on_fire(i):
   p.turbo = 1.0
  p.vel = move * speed
  if p.vel.length() > 40 and p.vel.dot((hoop_for(i/2)-p.pos).normalized()) > 20:
   p.drive = 0.16
  if not flight.is_empty() and flight.kind == "shot" and flight.shooter == i and flight.has("player_start"):
   var destination = finisher_position(flight.time+delta)
   p.vel = (destination-p.pos)/maxf(delta,0.0001)
   p.pos = destination
   p.drive = 0.0
  else:
   p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
  if absf(p.vel.x) > 0.1:
   p.face = signf(p.vel.x)
  var shoot: bool = c.get("shoot", false)
  if owner == i:
   if c.get("pass", false) and p.cooldown <= 0:
    pass_ball(i, turbo)
    p.charge = 0.0
    shoot = false
   elif shoot:
    p.fake = 0.0
    p.charge = minf(1.25, p.charge + delta)
    var finish = finish_kind(i,turbo)
    if (finish == "turbo_dunk" and p.charge >= 0.16) or (finish == "dunk" and p.charge >= 0.35):
     shoot_ball(i,turbo)
     p.charge = 0.0
   elif p.shoot_held and p.charge > 0:
    if p.charge < 0.16 and commands.has(i):
     p.fake = 0.38
     announce("HEAD FAKE!", "fake")
    else:
     shoot_ball(i, turbo)
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
  for i in range(4):
   if players[i].stun <= 0 and players[i].pos.distance_to(ball) < 30:
    owner = i
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
 elif owner == i:
  var hoop = hoop_for(team)
  target = hoop + Vector2(-90 if hoop.x > 640 else 90, 10 * sin(elapsed + i))
  if p.charge > 0 and p.pos.distance_to(hoop) < 165:
   target = hoop+Vector2(60 if hoop.x > 640 else -60,0)
  var dist: float = p.pos.distance_to(hoop)
  turbo = dist < 240
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
  var mark = owner if i % 2 == owner % 2 else (1 - team) * 2 + i % 2
  target = players[mark].pos.lerp(hoop_for(1-team), 0.12)
  if p.pos.distance_to(players[owner].pos) < 65 and p.cooldown <= 0:
   pass_action = rng.randf() < (0.018 + difficulty * 0.012)
 else:
  target = ball
 return {"move":(target - p.pos).normalized() if p.pos.distance_to(target) > 9 else Vector2.ZERO, "shoot":shoot, "pass":pass_action, "turbo":turbo}

func nearest_defender(i: int) -> float:
 var distance = 1000.0
 for j in range(4):
  if j / 2 != i / 2:
   distance = minf(distance, players[j].pos.distance_to(players[i].pos))
 return distance

func is_three_pointer(point: Vector2, hoop: Vector2) -> bool:
 var dx = absf(point.x - hoop.x)
 var dy = absf(point.y - hoop.y)
 if dy > 140.0:
  return dx > 255.0
 return point.distance_to(hoop) > 295.0

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

func calculate_shot_percentage(i: int, charge: float, dunk: bool, layup: bool, specialty: bool, alley: bool = false) -> Dictionary:
 var hoop = hoop_for(i / 2)
 var distance: float = players[i].pos.distance_to(hoop)
 var three_pointer = not dunk and not layup and is_three_pointer(players[i].pos, hoop)
 var delta_time = charge - 0.58
 var timing = exp(-(delta_time * delta_time) / (2.0 * 0.18 * 0.18))
 var contest_data = calculate_defensive_contest(i, hoop)
 var contest_level: float = contest_data.level
 var dist_penalty = pow(distance / 750.0, 1.32) * 0.28
 var my_team = i / 2
 var opp_team = 1 - my_team
 var score_diff = score[opp_team] - score[my_team]
 var rubber_band = clampf((float(score_diff) / 22.0) * 0.08, -0.08, 0.08)
 var base = 0.0
 var chance = 0.0
 var timing_contrib = 0.0
 var fire_bonus = 0.0
 if dunk:
  base = (0.84 if specialty else 0.72) + rating(i, 2) * 0.018
  chance = base - contest_level * 0.14 + rubber_band
 elif layup:
  base = 0.66 + rating(i, 1) * 0.024
  timing_contrib = timing * 0.10
  chance = base + timing_contrib - contest_level * 0.20 + rubber_band
 else:
  base = 0.24 + rating(i, 1) * 0.038
  timing_contrib = timing * 0.28
  chance = base + timing_contrib - dist_penalty - contest_level * 0.32 + rubber_band
 if is_player_on_fire(i):
  fire_bonus = 0.30
  chance += fire_bonus
  var fire_floor = 0.95 if dunk else (0.88 if layup else 0.82)
  chance = maxf(chance, fire_floor)
 elif player_streak[i] == 2:
  fire_bonus = 0.08
  chance += fire_bonus
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
  "quality":quality
 }

func calculate_rim_ricochet(start_pos: Vector2, hoop: Vector2) -> Vector2:
 var to_hoop = hoop - start_pos
 var dir = to_hoop.normalized() if to_hoop.length() > 0.01 else Vector2.RIGHT
 var side = dir.orthogonal()
 var hit_type = rng.randi_range(0, 2)
 var bounce_vec = Vector2.ZERO
 if hit_type == 0:
  bounce_vec = -dir * rng.randf_range(40.0, 130.0) + side * rng.randf_range(-45.0, 45.0)
 elif hit_type == 1:
  bounce_vec = dir * rng.randf_range(35.0, 115.0) + side * rng.randf_range(-40.0, 40.0)
 else:
  var side_dir = 1.0 if rng.randf() > 0.5 else -1.0
  bounce_vec = side * (side_dir * rng.randf_range(50.0, 130.0)) + dir * rng.randf_range(-25.0, 35.0)
 return (hoop + bounce_vec).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))

func finish_kind(i: int, turbo: bool, alley: bool = false) -> String:
 if alley:
  return "alley_oop"
 var p: Dictionary = players[i]
 var hoop = hoop_for(i/2)
 var moving: bool = p.drive > 0 or (p.vel.length() > 40 and p.vel.dot((hoop-p.pos).normalized()) > 20)
 var distance: float = p.pos.distance_to(hoop)
 if not moving or distance >= 165:
  return "jumper"
 if turbo and (p.turbo > 0.1 or infinite_turbo or is_player_on_fire(i)):
  return "turbo_dunk"
 if p.charge < 0.35 or distance >= 115:
  return "layup"
 return "dunk"

func shoot_ball(i: int, turbo: bool, alley: bool = false, release_height: float = 1.3) -> void:
 teammate_shot_order = -1
 var p: Dictionary = players[i]
 p.fake = 0.0
 var hoop = hoop_for(i / 2)
 var distance: float = p.pos.distance_to(hoop)
 var finish = finish_kind(i,turbo,alley)
 var dunk = finish in ["dunk","turbo_dunk","alley_oop"]
 var specialty = finish in ["turbo_dunk","alley_oop"]
 var layup = finish == "layup"
 var launch_height = receive_height(i) if alley else 0.0
 p.receive_jump = 0.0
 var breakdown = calculate_shot_percentage(i, p.charge, dunk, layup, specialty, alley)
 var chance: float = breakdown.chance
 var points = 2 if dunk else (3 if breakdown.three_pointer else 2)
 if dunk:
  points = 2
  p.jump = 0.85 if specialty else 0.70
 else:
  p.jump = 0.55 if layup else 0.50
 p.drive = 0.0
 stats[i].attempts += 1
 var will_make = rng.randf() < chance
 flight = {"kind":"shot", "start":ball, "end":hoop, "time":0.0, "duration":0.75 if specialty else 0.60 if dunk else 0.62 if layup else 1.05, "shooter":i, "points":points, "made":will_make, "dunk":dunk, "layup":layup, "super_dunk":specialty, "finish":finish, "arc_height":1.7 if specialty else 1.1 if dunk else 1.0 if layup else 4.6, "blocked":false, "shot_breakdown":breakdown}
 if dunk or layup:
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
  "dunk": dunk
 }
 announce("SUPER JAM!" if specialty else "SLAM DUNK!" if dunk else "LAY IT UP!" if layup else ("PERFECT RELEASE!" if breakdown.quality == "PERFECT" else "FROM DOWNTOWN!" if points == 3 else "UP IT GOES"), "dunk" if dunk else "shot")

func pass_ball(i: int, turbo: bool) -> void:
 teammate_shot_order = -1
 players[i].fake = 0.0
 var release_height = ball_height() if not flight.is_empty() and flight.get("kind","") == "shot" else 1.1
 var mate = (i / 2) * 2 + (1 - i % 2)
 var alley = turbo and players[mate].receive_jump > 0 and players[mate].stun <= 0 and players[mate].pos.distance_to(hoop_for(i / 2)) < 220
 var distance: float = ball.distance_to(players[mate].pos)
 var duration = clampf(distance/2300.0,0.10,0.42) if turbo else clampf(distance/1400.0,0.16,0.65)
 flight = {"kind":"pass", "start":ball, "end":players[mate].pos, "start_height":release_height, "end_height":3.8 if alley else 1.1, "time":0.0, "duration":0.38 if alley else duration, "target":mate, "passer":i, "alley":alley, "turbo":turbo}
 owner = -1
 players[i].cooldown = 0.45
 announce("LOB IT UP!" if alley else "NICE PASS", "pass")

func defend(i: int, turbo: bool) -> void:
 players[i].jump = 0.62
 players[i].cooldown = 0.70
 if not flight.is_empty() and flight.get("kind", "") == "shot":
  var shooter: int = flight.shooter
  if shooter / 2 == i / 2 or flight.blocked:
   return
  var t = clampf(flight.time/flight.duration,0,1)
  var contact = flight_position()
  var reach = players[i].pos.distance_to(contact)
  var arc: float = flight.get("arc_height",1.7 if flight.dunk else 4.6)
  var descending = 3.05-flight.get("release_height",1.3)+PI*arc*cos(t*PI) < 0
  var at_rim = contact.distance_to(flight.end) < 115
  if descending and at_rim and reach < 78 and ball_height() <= 4.6:
   if flight.dunk or is_player_on_fire(i):
    flight.made = false
    flight.blocked = true
    stats[i].blocks += 1
    record_miss(shooter)
    announce("DENIED AT THE RIM!" if flight.dunk else "FIRE BLOCK! NO GOALTENDING!", "block")
   else:
    var points: int = flight.points
    stats[i].goaltends += 1
    award_basket(shooter,points,false,false)
    announce("GOALTENDING! %d POINTS" % points,"whistle")
    inbound(i/2)
  elif not descending and reach < 85 and ball_height() <= 4.6:
   flight.made = false
   flight.blocked = true
   stats[i].blocks += 1
   record_miss(shooter)
   announce("REJECTED!", "block")
 elif owner >= 0 and owner / 2 != i / 2:
  steal(i, turbo)

func steal(i: int, shove: bool) -> void:
 players[i].cooldown = 0.65
 players[i].swipe = 0.25
 if not flight.is_empty() and flight.kind == "pass" and not flight.get("tip",false) and int(flight.target)/2 != i/2:
  if players[i].pos.distance_to(flight_position()) < (68 if shove else 56) and ball_height() <= 2.5 and rng.randf() < 0.45+rating(i,3)*0.04:
   intercept_pass(i)
  return
 if owner < 0 or owner / 2 == i / 2:
  return
 var victim = owner
 if players[i].pos.distance_to(players[victim].pos) > (66 if shove else 48):
  return
 if shove:
  players[victim].stun = 0.85
  players[victim].pos += (players[victim].pos - players[i].pos).normalized() * 20
 if rng.randf() < 0.30 + rating(i, 3) * 0.045 or shove:
  owner = i
  shot_clock = 24.0
  stats[i].steals += 1
  players[i].cooldown = 0.8
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  announce("SHOVED! NO FOULS!" if shove else "PICKED THEIR POCKET!", "steal")

func intercept_pass(i: int) -> void:
 owner = i
 flight = {}
 ball = players[i].pos
 shot_clock = 24.0
 players[i].cooldown = 0.8
 players[i].swipe = 0.25
 stats[i].steals += 1
 announce("PASS PICKED OFF!", "steal")

func tick_flight(delta: float) -> void:
 flight.time += delta
 var t = clampf(flight.time / flight.duration, 0, 1)
 ball = flight.start.lerp(flight.end, t)
 if flight.kind == "pass" and not flight.get("tip",false) and t > 0.12 and t < 0.88 and ball_height() <= 2.5:
  for i in range(4):
   if i/2 == int(flight.target)/2 or players[i].stun > 0 or players[i].cooldown > 0:
    continue
   var rate = 2.5+rating(i,3)*0.25
   if players[i].pos.distance_to(ball) < 42 and rng.randf() < 1.0-exp(-rate*delta):
    intercept_pass(i)
    return
 if t < 1:
  return
 if flight.kind == "pass":
  var receiver: int = flight.target
  var alley: bool = flight.alley
  var catch_height = ball_height()
  var catchable: bool = players[receiver].receive_jump > 0 and players[receiver].stun <= 0 and players[receiver].pos.distance_to(flight.end) < 70 and players[receiver].pos.distance_to(hoop_for(receiver/2)) < 220
  if alley and not catchable:
   owner = -1
   flight = {}
   announce("LOB MISSED! LOOSE BALL","miss")
   return
  owner = receiver
  ball = players[owner].pos
  flight = {}
  if alley:
   players[owner].charge = 0.58
   shoot_ball(owner, true, true, catch_height)
   announce("ALLEY-OOP!","dunk")
  return
 var shooter: int = flight.shooter
 var team = shooter / 2
 if flight.made and not flight.blocked:
  var was_on_fire = is_player_on_fire(shooter)
  var shattered = award_basket(shooter,flight.points,flight.dunk,true,flight.get("super_dunk",false))
  var name_text: String = Teams.DATA[teams[team]].players[shooter%2]
  var message = "HE'S ON FIRE! " + name_text if is_player_on_fire(shooter) and not was_on_fire else ("HE'S HEATING UP! " + name_text if player_streak[shooter] == 2 else "BOOMSHAKALAKA!" if flight.get("super_dunk",false) else "SLAM DUNK!" if flight.dunk else "FROM DOWNTOWN!" if flight.points == 3 else "NOTHING BUT NET!")
  if shattered:
   announce("BOOM! BACKBOARD SHATTERED!","shatter")
   flight = {}
   owner = -1
   ball = hoop_for(team)
   shot_clock = 24.0
   pending_inbound = 1-team
   shatter_shooter = shooter
   freeze = 1.65
  else:
   announce(message,"score")
   inbound(1-team)
 else:
  record_miss(shooter)
  ball = calculate_rim_ricochet(flight.start, flight.end)
  flight = {}
  owner = -1
  shot_clock = 24.0
  announce("OFF THE RIM!", "miss")

func next_period() -> void:
 if quarter >= 4:
  if score[0] != score[1]:
   phase = "finished"
   announce("FINAL", "whistle")
   return
  overtime += 1
  clock = minf(60.0, period_length)
  announce("OVERTIME %d" % overtime, "whistle")
 else:
  quarter += 1
  clock = period_length
  announce("HALFTIME • SWITCH ENDS" if quarter == 3 else "QUARTER %d" % quarter, "whistle")
 inbound(quarter % 2)

func snapshot() -> Dictionary:
 return {"tipoff":tipoff.duplicate(true), "board_breaks":board_breaks.duplicate(), "pending_inbound":pending_inbound, "shatter_shooter":shatter_shooter, "players":players.duplicate(true), "teams":teams.duplicate(), "score":score.duplicate(), "streak":streak.duplicate(), "player_streak":player_streak.duplicate(), "fire_player":fire_player, "teammate_shot_order":teammate_shot_order, "stats":stats.duplicate(true), "ball":ball, "owner":owner, "flight":flight.duplicate(true), "clock":clock, "shot_clock":shot_clock, "quarter":quarter, "overtime":overtime, "phase":phase, "freeze":freeze, "banner":banner, "banner_time":banner_time, "event_id":event_id, "event_kind":event_kind, "elapsed":elapsed, "big_heads":big_heads, "infinite_turbo":infinite_turbo, "last_shot_feedback":last_shot_feedback.duplicate(true)}

func apply_snapshot(data: Dictionary) -> void:
 for key in data:
  set(key, data[key])
