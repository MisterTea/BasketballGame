extends SceneTree
var failures = 0

func check(condition: bool, message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error("FAIL: "+message)
  failures += 1

func _initialize() -> void:
 var state = MatchState.new()
 state.start(0,1,2.0)
 check(state.players.size() == 4 and state.score == [0,0],"fresh two-on-two match")
 state.inbound(0) # Isolate ordinary basketball; full CPU match below includes tip-off.
 state.freeze = 0
 state.players[0].pos = Vector2(500,450)
 state.tick(0.1,{0:{"move":Vector2.RIGHT,"turbo":true}})
 check(state.players[0].pos.x > 520 and state.players[0].turbo < 1,"turbo changes speed and drains meter")
 state.owner = 0
 state.ball = state.players[0].pos
 state.players[0].charge = 0.58
 state.shoot_ball(0,false)
 check(state.owner == -1 and state.flight.kind == "shot","release launches a shot")
 state.flight.made = true
 state.tick_flight(2.0)
 check(state.score[0] == 3 and state.owner == 2,"three pointer scores and changes possession")
 for basket in range(2):
  state.owner = 0
  state.players[0].charge = 0.58
  state.shoot_ball(0,false)
  state.flight.made = true
  state.tick_flight(2.0)
 check(state.on_fire(0),"three consecutive baskets by one athlete ignite fire")
 state.owner = 2
 state.players[2].charge = 0.58
 state.shoot_ball(2,false)
 state.flight.made = true
 state.tick_flight(2.0)
 check(not state.on_fire(0) and state.streak[1] == 1,"opponent basket extinguishes fire")
 state.owner = 0
 state.ball = state.players[0].pos
 state.players[1].pos = state.hoop_for(0)+Vector2(-100,0)
 state.pass_ball(0,true)
 state.tick_flight(1.0)
 check(state.flight.get("dunk",false) and state.flight.shooter == 1,"alley-oop becomes teammate dunk")
 state.players[2].pos = state.flight.start
 state.defend(2,false)
 check(state.flight.blocked and state.stats[2].blocks == 1,"defender blocks an early shot")
 state.tick_flight(2.0)
 check(state.owner == -1 and state.flight.is_empty(),"miss creates a loose rebound")
 state.players[2].pos = state.ball
 state.players[0].pos = Vector2(300,300)
 state.players[1].pos = Vector2(300,350)
 state.freeze = 0
 state.clock = 2
 state.tick(0.01,{2:{"move":Vector2.ZERO}})
 check(state.owner == 2 and state.stats[2].rebounds == 1,"loose ball can be rebounded")
 state.owner = 0
 state.players[2].pos = state.players[0].pos+Vector2(40,0)
 state.steal(2,true)
 check(state.owner == 2 and state.players[0].stun > 0,"turbo shove forces a turnover")
 state.clock = 0
 state.flight = {}
 state.quarter = 2
 state.next_period()
 check(state.quarter == 3 and state.hoop_for(0).x < 640,"halftime switches ends")
 state.quarter = 4
 state.score = [10,10]
 state.next_period()
 check(state.overtime == 1 and state.phase == "playing","ties trigger overtime")
 state.score = [12,10]
 state.next_period()
 check(state.phase == "finished","non-tied final ends match")
 var copy = MatchState.new()
 copy.apply_snapshot(state.snapshot())
 check(copy.score == state.score and copy.players == state.players and copy.phase == "finished","snapshot restores full match")
 # Accelerated complete CPU match exercises thousands of simulation frames.
 state.start(3,5,8.0,2)
 state.rng.seed = 20261018
 var frames = 0
 while state.phase == "playing" and frames < 36000:
  state.tick(1.0/60.0,{})
  frames += 1
 check(state.phase == "finished" and state.quarter == 4,"CPU match reaches a final buzzer")
 if state.phase != "finished":
  print("CPU DIAGNOSTIC: overtime=",state.overtime," stats=",state.stats)
 check(state.score[0]+state.score[1] > 0,"CPU players generate scoring gameplay")
 print("SIMULATION TESTS: ","PASS" if failures == 0 else "FAIL", " • final ",state.score," • frames ",frames)
 quit(0 if failures == 0 else 1)

