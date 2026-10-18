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

func neutral() -> Dictionary:
 return {0:{},1:{},2:{},3:{}}

func fresh(passer: int = 0) -> MatchState:
 var s = MatchState.new()
 s.start(0,1)
 s.inbound(passer/2)
 s.owner = passer
 s.freeze = 0
 s.rng.seed = 275
 var team = passer/2
 var receiver = team*2+(1-passer%2)
 var hoop = s.hoop_for(team)
 var direction = 1 if hoop.x > 640 else -1
 s.players[passer].pos = hoop-Vector2(direction*330,0)
 s.players[receiver].pos = hoop-Vector2(direction*100,0)
 for opponent in [2,3] if team == 0 else [0,1]:
  s.players[opponent].pos = Vector2(250 if team == 0 else 1030,300 if opponent%2 == 0 else 600)
 s.ball = s.players[passer].pos
 return s

func launch(s: MatchState, passer: int = 0, jump: bool = true, turbo: bool = true) -> void:
 var receiver = (passer/2)*2+(1-passer%2)
 var commands = neutral()
 commands[passer] = {"pass":true,"turbo":turbo}
 commands[receiver] = {"shoot":jump}
 s.tick(1.0/60.0,commands)

func receive(s: MatchState, commands: Dictionary) -> void:
 for frame in range(120):
  if s.flight.get("kind","") != "pass":
   break
  s.tick(1.0/60.0,commands)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var s = fresh()
 launch(s,0,false)
 check(not s.flight.alley and s.players[1].receive_jump == 0,"Turbo Pass to a grounded human near the rim remains a regular pass")
 receive(s,neutral())
 check(s.owner == 1 and s.stats[1].attempts == 0,"a grounded human catch never forces an automatic dunk")
 for passer in range(4):
  s = fresh(passer)
  var receiver = (passer/2)*2+(1-passer%2)
  launch(s,passer)
  check(s.flight.get("alley",false) and s.flight.target == receiver and s.flight.passer == passer and s.players[receiver].receive_jump > 0,"simultaneous human jump/pass works for passer slot %d" % passer)
  receive(s,neutral())
  check(s.flight.get("finish","") == "alley_oop" and s.flight.shooter == receiver and s.stats[receiver].attempts == 1 and s.stats[passer].attempts == 0,"slot %d's lob becomes the receiver's single dunk attempt" % passer)
 s = fresh()
 launch(s)
 var copy = MatchState.new()
 copy.apply_snapshot(s.snapshot())
 check(copy.players[1].receive_jump == s.players[1].receive_jump and copy.flight == s.flight,"snapshots retain jump readiness, passer and lob trajectory")
 var arena = ArenaView.new()
 root.add_child(arena)
 while s.flight.kind == "pass" and s.flight.time < 0.25:
  s.tick(1.0/60.0,neutral())
 var before = s.snapshot()
 arena.present(s,[],s.ball,[0,1],0.1,false)
 check(arena.athletes[1].body.action == "block" and arena.athletes[1].control.text == "LOB!" and arena.athletes[1].body.position.y > 1,"receiver uses a generated reaching pose and visible lob cue")
 check(s.snapshot() == before,"receiver presentation cannot decide the catch or mutate gameplay")
 var height_before = s.receive_height(1)
 receive(s,neutral())
 arena.present(s,[],s.ball,[0,1],0.1,false)
 check(s.flight.release_height == 3.8 and absf(s.ball_height()-3.8) < 0.01,"alley-oop starts from the actual elevated catch height")
 check(s.flight.player_launch_height > 1 and absf(arena.athletes[1].body.position.y-height_before) < 0.3,"the catch-to-dunk transition stays airborne rather than restarting on the floor")
 check(arena.athletes[1].body.action == "dunk" and s.players[1].receive_jump == 0,"a caught lob transitions to the generated dunk and clears receiver readiness")
 s.flight.made = true
 for frame in range(90):
  if s.flight.is_empty():
   break
  s.tick(1.0/60.0,neutral())
 check(s.score == [2,0] and s.stats[1].dunks == 1 and s.stats[1].made == 1 and s.stats[0].made == 0,"the completed alley-oop awards two points and one made dunk to the receiver")
 s = fresh()
 launch(s,0,true,false)
 check(not s.flight.alley and s.players[1].receive_jump > 0,"a receiver's jump cannot turn a non-Turbo pass into a lob")
 receive(s,neutral())
 check(s.owner == 1 and s.stats[1].attempts == 0,"an airborne ordinary catch does not force a shot")
 s = fresh()
 s.players[1].receive_jump = 0.05
 s.players[1].jump = 0.05
 launch(s,0,false)
 receive(s,neutral())
 check(s.owner == -1 and s.flight.is_empty() and s.banner.contains("LOB MISSED"),"a receiver who lands before arrival leaves a loose lob")
 check(s.stats[1].attempts == 0 and s.stats[1].dunks == 0 and s.score == [0,0],"a missed lob creates no artificial shot or dunk statistics")
 s = fresh()
 launch(s)
 s.players[1].stun = 1
 receive(s,neutral())
 check(s.owner == -1 and s.players[1].receive_jump == 0 and s.stats[1].attempts == 0,"stunning a receiver breaks the alley-oop")
 s = fresh()
 launch(s)
 var commands = neutral()
 commands[1] = {"move":Vector2.UP,"turbo":true}
 receive(s,commands)
 check(s.owner == -1 and s.players[1].pos.distance_to(s.ball) >= 70,"moving out of the catch area makes the lob miss")
 s = fresh()
 s.tick(1.0/60.0,{0:{"pass":true,"turbo":true},2:{},3:{}})
 check(s.flight.alley and s.players[1].receive_jump > 0,"a CPU receiver jumps in response to a valid turbo lob request")
 var receiver_position: Vector2 = s.players[1].pos
 receive(s,{0:{},2:{},3:{}})
 check(s.flight.get("finish","") == "alley_oop" and s.players[1].pos == receiver_position,"a CPU receiver holds the catch area and completes the coordinated catch")
 s = fresh()
 s.players[0].cooldown = 0.5
 s.tick(1.0/60.0,{0:{"pass":true,"turbo":true},2:{},3:{}})
 check(s.flight.is_empty() and s.players[1].receive_jump == 0,"CPU receivers do not jump for an unavailable passer")
 s = fresh(1)
 s.tick(1.0/60.0,{0:{"shoot":true},2:{},3:{}})
 check(s.players[1].charge > 0 and s.players[0].receive_jump > 0,"a human receiver can jump while retaining the CPU ball-carrier's Shoot order")
 s.tick(0.05,{0:{"shoot":true,"pass":true,"turbo":true},2:{},3:{}})
 check(s.flight.get("alley",false) and s.flight.target == 0 and s.stats[1].attempts == 0,"a quick solo Turbo Pass order cancels the CPU windup into a lob")
 receive(s,{0:{},2:{},3:{}})
 check(s.flight.get("finish","") == "alley_oop" and s.flight.shooter == 0,"the human receiver can finish a CPU teammate's coordinated lob")
 s = fresh()
 commands = neutral()
 commands[1] = {"jump_press":true,"shoot":false}
 s.tick(1.0/60.0,commands)
 check(s.players[1].receive_jump > 0,"a reliable off-ball jump press works without held-button packets")
 var first_jump: float = s.players[1].receive_jump
 s.tick(0.1,commands)
 check(s.players[1].receive_jump < first_jump,"repeated press events cannot restart a jump during recovery")
 s.inbound(0)
 check(s.players[1].receive_jump == 0,"inbounds reset receiver jump state")
 print("ALLEY-OOP TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
