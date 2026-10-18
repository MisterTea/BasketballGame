class_name MatchState
extends RefCounted

const COURT = Rect2(115, 265, 1050, 410)
const HOOPS = [Vector2(165, 465), Vector2(1115, 465)]
const QUARTER_SECONDS = 180.0
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

func start(a: int, b: int, seconds: float = QUARTER_SECONDS, level: int = 1) -> void:
 rng.randomize()
 teams = [a, b]
 score = [0, 0]
 streak = [0, 0]
 player_streak = [0, 0, 0, 0]
 fire_player = -1
 teammate_shot_order = -1
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
  players.append({"pos":Vector2(420 if t == 0 else 860, 400 + (i % 2) * 140), "vel":Vector2.ZERO, "turbo":1.0, "jump":0.0, "stun":0.0, "cooldown":0.0, "charge":0.0, "shoot_held":false, "face":1 if t == 0 else -1})
  stats.append({"points":0, "attempts":0, "made":0, "dunks":0, "steals":0, "blocks":0, "rebounds":0, "goaltends":0})
 owner = 0
 ball = players[0].pos
 announce("TIP OFF!", "start")

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

func award_basket(shooter: int, points: int, dunk: bool, natural: bool = true) -> void:
 var team = shooter / 2
 score[team] += points
 stats[shooter].points += points
 stats[shooter].made += 1
 if dunk:
  stats[shooter].dunks += 1
 if natural:
  record_natural_basket(shooter)

func flight_position() -> Vector2:
 if flight.is_empty():
  return ball
 return flight.start.lerp(flight.end,clampf(flight.time/flight.duration,0,1))

func ball_height() -> float:
 if not flight.is_empty():
  var t = clampf(flight.time/flight.duration,0,1)
  if flight.kind == "shot":
   return lerpf(1.3,3.05,t)+sin(t*PI)*(1.7 if flight.dunk else 4.6)
  return 1.1+sin(t*PI)*(2.2 if flight.get("alley",false) else 0.5)
 if owner >= 0:
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

func inbound(team: int) -> void:
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
  players[i].shoot_held = false
  players[i].jump = 0.0
 players[owner].pos = own_hoop + Vector2(85 if own_hoop.x < 640 else -85, 0)
 ball = players[owner].pos
 freeze = 1.0

func tick(delta: float, commands: Dictionary) -> void:
 if phase != "playing":
  return
 elapsed += delta
 banner_time = maxf(0.0, banner_time - delta)
 if freeze > 0:
  freeze -= delta
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
 for i in range(4):
  var p: Dictionary = players[i]
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  p.jump = maxf(0.0, p.jump - delta)
  var c: Dictionary = effective_commands[i] if effective_commands.has(i) else ai(i)
  if p.stun > 0:
   p.charge = 0.0
   p.shoot_held = false
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
  p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
  if absf(move.x) > 0.1:
   p.face = signf(move.x)
  var shoot: bool = c.get("shoot", false)
  if owner == i:
   if c.get("pass", false) and p.cooldown <= 0:
    pass_ball(i, turbo)
    p.charge = 0.0
    shoot = false
   elif shoot:
    p.charge = minf(1.25, p.charge + delta)
   elif p.shoot_held and p.charge > 0:
    shoot_ball(i, turbo)
    p.charge = 0.0
  else:
   # Off-ball commands target a CPU ball carrier; never override another human.
   var ordering_cpu = owner >= 0 and owner / 2 == i / 2 and not commands.has(owner)
   if not ordering_cpu:
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
 if owner == i:
  var hoop = hoop_for(team)
  target = hoop + Vector2(-90 if hoop.x > 640 else 90, 10 * sin(elapsed + i))
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
   var arc = 1.7 if flight.dunk else 4.6
   var descending = 1.75+PI*arc*cos(t*PI) < 0
   shoot = not flight.blocked and p.cooldown <= 0 and p.pos.distance_to(target) < 72 and ball_height() <= 4.6 and (not descending or is_player_on_fire(i))
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

func shoot_ball(i: int, turbo: bool) -> void:
 teammate_shot_order = -1
 var p: Dictionary = players[i]
 var hoop = hoop_for(i / 2)
 var distance: float = p.pos.distance_to(hoop)
 var dunk = turbo and distance < 165 and p.turbo > 0.1
 var timing = maxf(0.0, 1.0 - absf(p.charge - 0.58) / 0.58)
 var contest = clampf((95 - nearest_defender(i)) / 95.0, 0.0, 1.0)
 var chance = 0.24 + rating(i, 1) * 0.038 + timing * 0.27 - distance * 0.0006 - contest * 0.22
 if dunk:
  chance = 0.82 + rating(i, 2) * 0.015 - contest * 0.12
 if is_player_on_fire(i):
  chance += 0.30
 var points = 3 if distance > 300 else 2
 if dunk:
  points = 2
  p.jump = 0.85
  p.pos = p.pos.lerp(hoop, 0.58)
 else:
  p.jump = 0.50
 stats[i].attempts += 1
 flight = {"kind":"shot", "start":ball, "end":hoop, "time":0.0, "duration":0.75 if dunk else 1.05, "shooter":i, "points":points, "made":rng.randf() < clampf(chance, 0.05, 0.99), "dunk":dunk, "blocked":false}
 owner = -1
 p.cooldown = 0.65
 announce("BOOMSHAKA!" if dunk else ("PERFECT RELEASE!" if timing > 0.94 else "FROM DOWNTOWN!" if points == 3 else "UP IT GOES"), "dunk" if dunk else "shot")

func pass_ball(i: int, turbo: bool) -> void:
 teammate_shot_order = -1
 var mate = (i / 2) * 2 + (1 - i % 2)
 var alley = turbo and players[mate].pos.distance_to(hoop_for(i / 2)) < 220
 flight = {"kind":"pass", "start":ball, "end":players[mate].pos, "time":0.0, "duration":0.38 if alley else 0.25, "target":mate, "alley":alley}
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
  var arc = 1.7 if flight.dunk else 4.6
  var descending = 1.75+PI*arc*cos(t*PI) < 0
  var at_rim = contact.distance_to(flight.end) < 115
  if descending and at_rim and reach < 78 and ball_height() <= 4.6:
   if is_player_on_fire(i):
    flight.made = false
    flight.blocked = true
    stats[i].blocks += 1
    record_miss(shooter)
    announce("FIRE BLOCK! NO GOALTENDING!", "block")
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
  announce("SHOVED! NO FOULS!" if shove else "PICKED THEIR POCKET!", "steal")

func tick_flight(delta: float) -> void:
 flight.time += delta
 var t = clampf(flight.time / flight.duration, 0, 1)
 ball = flight.start.lerp(flight.end, t)
 if t < 1:
  return
 if flight.kind == "pass":
  var receiver: int = flight.target
  var alley: bool = flight.alley
  owner = receiver
  ball = players[owner].pos
  flight = {}
  if alley:
   players[owner].charge = 0.58
   shoot_ball(owner, true)
  return
 var shooter: int = flight.shooter
 var team = shooter / 2
 if flight.made and not flight.blocked:
  var was_on_fire = is_player_on_fire(shooter)
  award_basket(shooter,flight.points,flight.dunk)
  var name_text: String = Teams.DATA[teams[team]].players[shooter%2]
  var message = "HE'S ON FIRE! " + name_text if is_player_on_fire(shooter) and not was_on_fire else ("HE'S HEATING UP! " + name_text if player_streak[shooter] == 2 else "BOOMSHAKA!" if flight.dunk else "THREE POINTER!" if flight.points == 3 else "NOTHING BUT NET!")
  announce(message,"score")
  inbound(1-team)
 else:
  record_miss(shooter)
  ball = (flight.end + Vector2(rng.randf_range(-135,135), rng.randf_range(-100,100))).clamp(COURT.position + Vector2(30,30), COURT.end - Vector2(30,30))
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
 return {"players":players.duplicate(true), "teams":teams.duplicate(), "score":score.duplicate(), "streak":streak.duplicate(), "player_streak":player_streak.duplicate(), "fire_player":fire_player, "teammate_shot_order":teammate_shot_order, "stats":stats.duplicate(true), "ball":ball, "owner":owner, "flight":flight.duplicate(true), "clock":clock, "shot_clock":shot_clock, "quarter":quarter, "overtime":overtime, "phase":phase, "freeze":freeze, "banner":banner, "banner_time":banner_time, "event_id":event_id, "event_kind":event_kind, "elapsed":elapsed, "big_heads":big_heads, "infinite_turbo":infinite_turbo}

func apply_snapshot(data: Dictionary) -> void:
 for key in data:
  set(key, data[key])
