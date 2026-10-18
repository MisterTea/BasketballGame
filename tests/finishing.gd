extends SceneTree
const ArenaView = preload("res://scripts/arena_3d.gd")
var checks = 0
var failures = 0

func check(value: bool, message: String) -> void:
 checks += 1
 if value:
  print("PASS: ",message)
 else:
  failures += 1
  push_error("FAIL: "+message)

func fresh() -> MatchState:
 var s = MatchState.new()
 s.start(0,1)
 s.inbound(0)
 s.freeze = 0
 s.rng.seed = 3111
 s.players[1].pos = Vector2(500,600)
 s.players[2].pos = Vector2(300,300)
 s.players[3].pos = Vector2(300,600)
 return s

func neutral() -> Dictionary:
 return {0:{},1:{},2:{},3:{}}

func drive(s: MatchState, seconds: float, turbo: bool, moving: bool = true) -> void:
 var commands = neutral()
 commands[0] = {"move":Vector2.RIGHT if moving else Vector2.ZERO,"shoot":true,"turbo":turbo}
 for frame in range(int(ceil(seconds*60))):
  s.tick(1.0/60.0,commands)
  if not s.flight.is_empty():
   return
 commands[0].shoot = false
 s.tick(1.0/60.0,commands)

func stage_pass(seed_value: int, turbo: bool) -> MatchState:
 var s = fresh()
 s.players[0].pos = Vector2(200,465)
 s.players[1].pos = Vector2(800,465)
 s.players[2].pos = Vector2(500,465)
 s.players[3].pos = Vector2(1100,650)
 s.ball = s.players[0].pos
 s.rng.seed = seed_value
 s.pass_ball(0,turbo)
 return s

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var s = fresh()
 s.players[0].pos = Vector2(1015,465)
 s.ball = s.players[0].pos
 drive(s,0.58,true,false)
 check(s.flight.get("finish","") == "jumper" and not s.flight.dunk,"holding Turbo and Shoot while standing cannot create a dunk")
 s = fresh()
 s.players[0].pos = Vector2(955,465)
 s.ball = s.players[0].pos
 drive(s,0.22,false)
 check(s.flight.get("finish","") == "layup" and s.flight.layup and not s.flight.dunk,"a short running Shoot hold releases a layup")
 check(s.flight.points == 2 and s.flight.arc_height == 1.0 and s.stats[0].attempts == 1,"layups use a lower two-point trajectory and one field-goal attempt")
 var layup = MatchState.new()
 layup.apply_snapshot(s.snapshot())
 check(layup.flight.finish == "layup" and layup.flight.arc_height == 1.0,"finish type and trajectory survive host snapshot restoration")
 var arena = ArenaView.new()
 root.add_child(arena)
 var before = s.snapshot()
 arena.present(s,[],s.ball,[0],0.1,false)
 check(arena.athletes[0].body.action == "layup" and s.snapshot() == before,"layups select the actual generated HY-Motion clip without changing simulation state")
 s.flight.made = true
 s.tick_flight(1)
 check(s.score == [2,0] and s.stats[0].dunks == 0,"a made layup scores without increasing dunk statistics")
 s = fresh()
 s.players[0].pos = Vector2(965,465)
 s.ball = s.players[0].pos
 drive(s,0.5,false)
 check(s.flight.get("finish","") == "dunk" and not s.flight.super_dunk,"holding Shoot on a close approach launches a regular dunk without Turbo")
 var normal_duration: float = s.flight.duration
 var normal_arc: float = s.flight.arc_height
 s = fresh()
 s.players[0].pos = Vector2(965,465)
 s.ball = s.players[0].pos
 drive(s,0.5,true)
 check(s.flight.get("finish","") == "turbo_dunk" and s.flight.super_dunk,"Turbo and a moving Shoot hold launch the specialty dunk before release")
 check(s.players[0].pos == s.flight.player_start,"a finisher starts from its actual launch point instead of teleporting toward the rim")
 check(s.flight.duration > normal_duration and s.flight.arc_height > normal_arc,"specialty dunks have a higher, longer flight than regular dunks")
 var attempts: int = s.stats[0].attempts
 var launch_position: Vector2 = s.players[0].pos
 s.tick(0.1,{0:{"move":Vector2.LEFT,"shoot":true,"turbo":true},1:{},2:{},3:{}})
 check(s.stats[0].attempts == attempts,"continuing to hold Shoot cannot relaunch an airborne dunk")
 check(s.players[0].pos.x > launch_position.x and s.players[0].pos.x <= s.flight.player_end.x,"a launched dunk glides toward the basket despite opposite movement input")
 s = fresh()
 s.players[0].pos = Vector2(960,465)
 s.ball = s.players[0].pos
 drive(s,0.10,false)
 check(s.flight.is_empty() and s.players[0].fake > 0 and s.owner == 0,"a quick tap still head-fakes while running")
 s = fresh()
 s.players[0].pos = Vector2(800,465)
 s.ball = s.players[0].pos
 drive(s,0.2,true)
 check(s.flight.get("finish","") == "jumper","running shots outside the finishing range remain jump shots")
 s = fresh()
 s.quarter = 4
 s.players[0].pos = s.hoop_for(0)+Vector2(100,0)
 s.players[0].vel = Vector2.LEFT*200
 s.players[0].charge = 0.58
 s.ball = s.players[0].pos
 s.shoot_ball(0,false)
 s.flight.made = true
 s.tick_flight(1)
 check(s.stats[0].dunks == 1 and s.board_breaks == [-1.0,-1.0],"regular late-game dunks score but only specialty dunks can shatter glass")
 var normal = stage_pass(1,false)
 var fast = stage_pass(1,true)
 check(not fast.flight.alley and fast.flight.duration < normal.flight.duration and fast.flight.turbo,"Turbo makes a regular chest pass travel faster over the same distance")
 var normal_picks = 0
 var fast_picks = 0
 for seed_value in range(500):
  for turbo in [false,true]:
   var trial = stage_pass(seed_value,turbo)
   while not trial.flight.is_empty():
    trial.tick_flight(1.0/120.0)
   if trial.owner == 2:
    if turbo:
     fast_picks += 1
    else:
     normal_picks += 1
 print("PASS LANE TRIALS: normal interceptions=",normal_picks,"/500 turbo=",fast_picks,"/500")
 check(normal_picks > fast_picks+15,"faster passes reduce interception exposure in the same stationary passing lane")
 var active_catches = 0
 var active_misses = 0
 var valid_catches = true
 for seed_value in range(20):
  s = stage_pass(seed_value,false)
  s.flight.time = s.flight.duration*0.5
  s.ball = s.flight_position()
  s.steal(2,false)
  if s.owner == 2:
   active_catches += 1
   valid_catches = valid_catches and s.flight.is_empty() and s.stats[2].steals == 1 and s.score == [0,0] and s.shot_clock == 24
  else:
   active_misses += 1
 check(active_catches > 0 and active_misses > 0,"active lane swipes can succeed or miss instead of guaranteeing a steal")
 check(valid_catches,"active pass interceptions record exactly one turnover and a fresh shot clock")
 s = fresh()
 s.players[0].pos = Vector2(1010,465)
 s.players[0].vel = Vector2.RIGHT*200
 s.players[0].turbo = 0
 s.players[0].charge = 0.58
 check(s.finish_kind(0,true) == "dunk","an empty Turbo meter cannot grant a specialty dunk")
 s = fresh()
 s.players[0].pos = Vector2(955,465)
 s.ball = s.players[0].pos
 var commands = neutral()
 commands[0] = {"move":Vector2.RIGHT,"shoot":true}
 for frame in range(13):
  s.tick(1.0/60.0,commands)
 commands[0] = {"move":Vector2.ZERO,"shoot":false}
 s.tick(1.0/60.0,commands)
 check(s.flight.get("finish","") == "layup","releasing movement and Shoot together preserves recent drive momentum")
 s.flight.time = s.flight.duration*0.92
 s.ball = s.flight_position()
 s.players[2].pos = s.ball
 s.defend(2,false)
 check(s.stats[2].goaltends == 1 and s.score[0] == 2,"descending released layups retain normal goaltending rules")
 s = stage_pass(1,false)
 s.players[2].stun = 1
 while not s.flight.is_empty():
  s.tick_flight(1.0/120.0)
 check(s.owner == 1 and s.stats[2].steals == 0,"a stunned defender cannot passively intercept a passing lane")
 s = stage_pass(1,false)
 s.players[1].pos = s.players[2].pos
 s.flight.time = s.flight.duration*0.5
 s.steal(1,true)
 check(s.owner == -1 and not s.flight.is_empty() and s.stats[1].steals == 0,"teammates cannot intercept their own pass")
 s = stage_pass(1,true)
 s.flight.start_height = 4.0
 s.flight.time = s.flight.duration*0.5
 s.steal(2,true)
 check(s.owner == -1 and not s.flight.is_empty(),"ground swipes cannot intercept high airborne dishes")
 s = stage_pass(1,false)
 s.flight.tip = true
 s.flight.time = s.flight.duration*0.5
 s.steal(2,true)
 check(s.owner == -1 and not s.flight.is_empty(),"the opening tip pass stays protected from ordinary lane steals")
 print("FINISHING TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
