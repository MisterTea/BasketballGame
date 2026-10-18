extends SceneTree
const ArenaView = preload("res://scripts/arena_3d.gd")
var failures = 0
var checks = 0

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
 s.rng.seed = 1993
 return s

func neutral() -> Dictionary:
 return {0:{},1:{},2:{},3:{}}

func until(s: MatchState, time: float, commands: Dictionary) -> void:
 while s.tipoff.active and s.tipoff.time < time:
  s.tick(minf(0.01,time-s.tipoff.time),commands)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var s = fresh()
 check(s.tipoff.active and s.owner == -1 and s.ball == Vector2(640,465),"opening starts with an unowned center-court ball")
 check(s.players[0].pos.x < 640 and s.players[2].pos.x > 640 and s.players[1].pos != s.players[0].pos,"opposing jumpers line up inside the center circle with partners outside")
 var positions = s.players.duplicate(true)
 var command = neutral()
 command[0] = {"move":Vector2.RIGHT,"shoot":true,"turbo":true,"pass":true}
 until(s,0.5,command)
 check(s.clock == 180 and s.shot_clock == 24 and s.players[0].pos == positions[0].pos and s.players[0].turbo == 1,"ready phase locks clocks, movement and turbo consumption")
 check(s.tipoff.jumps[0] < 0 and s.flight.is_empty() and s.players[0].charge == 0,"early Shoot and Pass cannot create a jump, shot or pass")
 until(s,1.1,command)
 check(s.tipoff.jumps[0] < 0,"holding Shoot before the toss cannot auto-win the tip")
 command[0].shoot = false
 s.tick(0.01,command)
 command[0].shoot = true
 s.tick(0.01,command)
 var first_jump: float = s.tipoff.jumps[0]
 check(first_jump > 1 and s.players[0].jump > 0 and s.stats[0].attempts == 0,"a fresh Shoot press after the toss jumps without recording a field-goal attempt")
 command[0].shoot = false
 s.tick(0.01,command)
 command[0].shoot = true
 s.tick(0.01,command)
 check(s.tipoff.jumps[0] == first_jump,"button mashing cannot replace the team's first valid jump")
 until(s,MatchState.TIP_DECISION,neutral())
 check(not s.tipoff.active and s.tipoff.winner == 0 and s.flight.get("tip",false) and s.flight.target == 1,"the only valid human jump tips the ball to its partner")
 check(s.clock == 180 and s.score == [0,0] and s.stats[0].rebounds == 0,"tip-off awards no score, shot, rebound or elapsed match time")
 s.tick(0.4,neutral())
 check(s.owner == 1 and s.flight.is_empty() and s.clock < 180 and s.shot_clock < 24,"the winner's partner catches the tip and normal clocks begin")
 s = fresh()
 until(s,1.09,neutral())
 s.tick(0.01,{0:{},2:{"shoot":true}})
 until(s,1.41,neutral())
 s.tick(0.01,{0:{"shoot":true},2:{}})
 until(s,MatchState.TIP_DECISION,neutral())
 check(s.tipoff.winner == 0,"a well-timed home jump beats an early away jump")
 s = fresh()
 until(s,1.09,neutral())
 s.tick(0.01,{0:{"shoot":true},2:{}})
 until(s,1.41,neutral())
 s.tick(0.01,{0:{},2:{"shoot":true}})
 until(s,MatchState.TIP_DECISION,neutral())
 check(s.tipoff.winner == 1 and s.flight.target == 3,"a well-timed away jump can win possession equally")
 s = fresh()
 until(s,1.41,neutral())
 s.tick(0.01,{1:{"shoot":true},2:{}})
 check(s.tipoff.jumps[0] > 0 and s.players[0].jump > 0 and s.players[1].jump == 0,"a human partner may order their CPU center to jump")
 s = fresh()
 until(s,1.41,neutral())
 s.tick(0.01,{0:{},1:{"shoot":true},2:{}})
 check(s.tipoff.jumps[0] < 0,"a partner cannot override a human-controlled center")
 s = fresh()
 until(s,1.41,neutral())
 s.tick(0.01,{0:{"tip_jump":true,"shoot":false},2:{}})
 check(s.tipoff.jumps[0] > 0,"a reliable tip-off press survives independently of held Shoot packets")
 s = fresh()
 until(s,MatchState.TIP_DECISION,{})
 check(s.tipoff.jumps[0] >= MatchState.TIP_TOSS and s.tipoff.jumps[1] >= MatchState.TIP_TOSS and s.tipoff.winner in [0,1],"two CPU teams contest the toss and resolve possession")
 for level in range(3):
  var match_state = MatchState.new()
  match_state.start(3,5,12.0,level)
  match_state.rng.seed = 1993+level
  var frames = 0
  while match_state.phase == "playing" and frames < 18000:
   match_state.tick(1.0/60.0,{})
   frames += 1
  check(match_state.phase == "finished" and match_state.score[0]+match_state.score[1] > 0,"CPU difficulty %d completes a scoring match from the actual opening toss" % level)
 var winners: Array = []
 for seed_value in range(12):
  s = fresh()
  s.rng.seed = seed_value
  s.tick(3.0,neutral())
  if not winners.has(s.tipoff.winner):
   winners.append(s.tipoff.winner)
 check(winners.size() == 2 and s.flight.start_height > 0,"no-input ties resolve for either team without deadlock or a below-floor toss")
 s = fresh()
 until(s,1.1,{0:{}})
 var copy = MatchState.new()
 copy.apply_snapshot(s.snapshot())
 check(copy.tipoff == s.tipoff,"snapshots preserve the toss phase, CPU schedules, held input and jump timestamps")
 until(s,MatchState.TIP_DECISION,{0:{}})
 until(copy,MatchState.TIP_DECISION,{0:{}})
 check(copy.tipoff.winner == s.tipoff.winner and copy.flight == s.flight,"a restored mid-toss state resolves the same CPU contest")
 copy.tipoff.jumps[0] = 99
 check(s.tipoff.jumps[0] != 99,"restored tip-off arrays do not alias the host snapshot")
 s = fresh()
 until(s,1.41,neutral())
 s.tick(0.01,{0:{"shoot":true},2:{}})
 until(s,1.62,neutral())
 var arena = ArenaView.new()
 root.add_child(arena)
 var before = s.snapshot()
 arena.present(s,[],s.ball,[0],0.1,false)
 check(arena.athletes[0].body.action == "block" and arena.athletes[0].body.position.y > 1,"tip-off jump uses the generated HY-Motion block pose with smooth elevation")
 check(arena.camera.position.x == 0 and arena.basketball.position.y > 3,"the sideline view frames a genuinely airborne center-court toss")
 check(s.snapshot() == before,"tip-off rendering never changes the host's judgment")
 var ball_position: Vector3 = arena.basketball.position
 arena.present(s,[],s.ball,[0],0.5,true)
 check(arena.basketball.position == ball_position and s.snapshot() == before,"pausing preserves the toss and its presentation")
 s.inbound(0)
 check(not s.tipoff.active and s.owner == 0,"ordinary period inbounds do not restart the opening contest")
 s.start(0,1)
 check(s.tipoff.active and s.tipoff.time == 0 and s.tipoff.winner == -1 and s.tipoff.jumps == [-1.0,-1.0],"rematches create a fresh contest with no prior jumps or winner")
 arena.queue_free()
 await process_frame
 print("TIP-OFF TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
