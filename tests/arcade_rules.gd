extends SceneTree
var failures = 0
var checks = 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if condition:
  print("PASS: ",message)
 else:
  push_error("FAIL: "+message)
  failures += 1

func neutral() -> Dictionary:
 return {"move":Vector2.ZERO,"shoot":false,"pass":false,"turbo":false}

func fresh() -> MatchState:
 var state = MatchState.new()
 state.start(0,1)
 state.inbound(0) # Ordinary-play fixture; tip-off has its own full-flow suite.
 state.rng.seed = 1993
 state.freeze = 0
 return state

func shot(state: MatchState, shooter: int, late: bool) -> void:
 state.owner = shooter
 state.players[shooter].pos = Vector2(700,465) if shooter < 2 else Vector2(580,465)
 state.players[shooter].charge = 0.58
 state.ball = state.players[shooter].pos
 state.shoot_ball(shooter,false)
 state.flight.time = state.flight.duration*(0.92 if late else 0.18)
 state.flight.cpu_block_allowed = [true,true,true,true] # Guaranteed defensive opportunity fixture.
 state.ball = state.flight_position()

func _initialize() -> void:
 var s = fresh()
 check(s.clock == 180.0,"default arcade quarters last three minutes")
 for scorer in [0,1,0]:
  s.record_natural_basket(scorer)
 check(s.fire_player == -1 and s.player_streak == [1,0,0,0],"alternating teammates cannot combine baskets into fire")
 s.record_natural_basket(0)
 check(s.player_streak[0] == 2 and not s.on_fire(0),"two unanswered baskets heat up the named scorer")
 s.record_natural_basket(0)
 check(s.is_player_on_fire(0) and not s.is_player_on_fire(1),"fire belongs only to the individual scorer")
 s.record_miss(0)
 check(s.is_player_on_fire(0),"an already-burning athlete remains on fire after a miss")
 s.players[0].turbo = 0.0
 s.players[1].turbo = 0.0
 var controls = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 controls[0].turbo = true
 controls[0].move = Vector2.RIGHT
 controls[1].turbo = true
 controls[1].move = Vector2.RIGHT
 s.tick(0.1,controls)
 check(s.players[0].turbo == 1.0 and s.players[1].turbo < 0.1,"only the burning athlete receives unlimited turbo")
 check(s.players[0].vel.length() > s.players[1].vel.length(),"fire turbo works immediately even from an empty meter")
 s.record_natural_basket(1)
 check(s.is_player_on_fire(0),"teammate baskets do not extinguish established fire")
 s.record_natural_basket(2)
 check(s.fire_player == -1 and s.player_streak[0] == 0,"an opponent's natural basket extinguishes fire")
 s.record_miss(2)
 check(s.player_streak[2] == 0,"misses reset a cold athlete's heating streak")
 s = fresh()
 s.record_natural_basket(2)
 s.record_natural_basket(2)
 shot(s,0,true)
 s.flight.made = false
 s.players[2].pos = s.flight_position()
 s.defend(2,false)
 check(s.score[0] == 3 and s.owner == 2 and s.flight.is_empty(),"descending three-point shot contact awards goaltending points even on a miss")
 check(s.stats[2].goaltends == 1 and s.stats[2].blocks == 0,"goaltends are recorded separately from legal blocks")
 check(s.player_streak[2] == 2 and s.player_streak[0] == 0,"goaltending points neither advance nor reset heating streaks")
 check(s.shot_clock == 24.0 and s.freeze > 0,"goaltending gives the defender a fresh inbound possession")
 s = fresh()
 shot(s,0,false)
 s.players[2].pos = s.flight_position()
 s.defend(2,false)
 check(s.flight.blocked and s.stats[2].blocks == 1 and s.score == [0,0],"ascending contact is a legal block")
 s = fresh()
 shot(s,0,false)
 s.players[2].pos = s.flight_position()
 check(s.ai(2).shoot,"CPU defenders recognize reachable ascending shots without a ball owner")
 var reaction_time: float = s.flight.time
 s.flight.time = 0.02
 s.players[2].pos = s.flight_position()
 check(not s.ai(2).shoot,"CPU defenders cannot block immediately on shot release")
 s.flight.time = reaction_time
 s.players[2].pos = s.flight_position()
 s.flight.cpu_block_allowed[2] = false
 var declined = true
 for attempt in range(12):
  declined = declined and not s.ai(2).shoot
 check(declined,"a declined CPU block decision is not rerolled every frame")
 s.flight.cpu_block_allowed[2] = true
 s.tick(1.0/60.0,{0:neutral(),1:neutral(),3:neutral()})
 check(s.flight.blocked and s.stats[2].blocks == 1,"CPU shot-blocking commands execute through the normal simulation")
 s = fresh()
 shot(s,0,true)
 s.players[2].pos = s.flight_position()
 check(not s.ai(2).shoot,"a cold CPU defender avoids intentional descending-shot goaltending")
 for basket in range(3):
  s.record_natural_basket(2)
 check(s.ai(2).shoot,"a burning CPU defender can attempt a legal descending-shot block")
 s = fresh()
 shot(s,0,true)
 s.players[1].pos = s.flight_position()
 s.defend(1,false)
 check(s.score == [0,0] and not s.flight.blocked,"offensive teammates cannot trigger goaltending")
 s = fresh()
 for basket in range(3):
  s.record_natural_basket(2)
 shot(s,0,true)
 s.flight.made = true
 s.players[2].pos = s.flight_position()
 s.defend(2,false)
 check(s.flight.blocked and s.score == [0,0] and s.stats[2].blocks == 1,"the burning defender may legally block a descending rim shot")
 s.tick_flight(1.0)
 check(s.is_player_on_fire(2) and s.owner == -1,"a legal fire block produces a rebound without extinguishing fire")
 s = fresh()
 for basket in range(3):
  s.record_natural_basket(2)
 shot(s,0,true)
 s.players[3].pos = s.flight_position()
 s.defend(3,false)
 check(s.score[0] == 3 and s.stats[3].goaltends == 1,"a burning teammate does not grant another defender goaltending immunity")
 var restored = MatchState.new()
 restored.apply_snapshot(s.snapshot())
 check(restored.fire_player == s.fire_player and restored.player_streak == s.player_streak and restored.stats == s.stats,"snapshots preserve individual fire and goaltending statistics")
 s = fresh()
 s.owner = 1
 s.ball = s.players[1].pos
 s.players[1].charge = 0.4
 s.players[1].shoot_held = true
 var call = {0:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 var unchanged = call.duplicate(true)
 s.tick(1.0/60.0,call)
 check(s.flight.get("kind","") == "pass" and s.flight.target == 0,"off-ball Pass calls for the ball from a CPU teammate")
 check(s.stats[1].attempts == 0 and s.players[1].charge == 0,"the pass order takes priority over an in-progress CPU shot")
 check(s.players[0].jump == 0 and call == unchanged,"teammate commands do not jump the caller or mutate inputs")
 s = fresh()
 s.owner = 1
 s.players[1].pos = Vector2(780,465)
 s.ball = s.players[1].pos
 call = {0:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 s.tick(0.2,call)
 check(s.players[1].charge > 0 and s.teammate_shot_order == 1,"off-ball Shoot charges a CPU teammate's shot")
 var copy = MatchState.new()
 copy.apply_snapshot(s.snapshot())
 check(copy.teammate_shot_order == 1,"an in-progress teammate shot order survives snapshot restoration")
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.flight.get("shooter",-1) == 1 and s.teammate_shot_order == -1,"releasing Shoot orders the CPU teammate to release the ball")
 s = fresh()
 s.owner = 1
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 call[0]["pass"] = true
 s.tick(1.0/60.0,call)
 check(s.owner == 1 and s.flight.is_empty() and s.players[1].charge == 0,"off-ball requests never commandeer a human teammate")
 s = fresh()
 s.record_natural_basket(0)
 s.record_natural_basket(0)
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 s.tick(0.10,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.owner == 0 and s.flight.is_empty() and s.players[0].fake > 0,"a short Shoot tap head-fakes without releasing possession")
 check(s.stats[0].attempts == 0 and s.player_streak[0] == 2,"head-fakes do not count as missed shots or reset heat")
 copy.apply_snapshot(s.snapshot())
 check(copy.players[0].fake == s.players[0].fake,"head-fake animation state survives snapshot restoration")
 call[0].shoot = true
 s.tick(0.58,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.flight.get("shooter",-1) == 0 and s.stats[0].attempts == 1,"a held shot after a fake still releases normally")
 s = fresh()
 s.owner = 1
 call = {0:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 s.tick(0.05,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.flight.get("shooter",-1) == 1 and s.players[1].fake == 0,"a tapped CPU teammate order shoots rather than head-faking")
 s = fresh()
 s.players[0].pos = Vector2(1020,465)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.shoot_ball(0,true)
 s.flight.time = 0.25
 s.ball = s.flight_position()
 var release_point = s.ball
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 s.tick(1.0/60.0,call)
 check(s.flight.get("kind","") == "pass" and s.flight.target == 1 and s.flight.start == release_point,"Pass during a dunk dishes from the current airborne ball position")
 check(s.flight.start_height > 3.0 and s.ball_height() > 3.0,"airborne dishes preserve ball elevation instead of snapping to chest height")
 check(s.stats[0].attempts == 0 and s.score == [0,0] and s.players[0].jump > 0,"abandoned dunks retain the leap without adding a shot or score")
 s.tick_flight(1.0)
 check(s.owner == 1 and s.flight.is_empty(),"the airborne dish reaches the teammate using normal pass flight")
 s.owner = 0
 s.ball = s.players[0].pos
 s.shoot_ball(0,true)
 s.flight.time = 0.25
 s.flight.blocked = true
 s.tick(1.0/60.0,call)
 check(s.flight.kind == "shot" and s.flight.blocked,"a blocked dunk cannot be rescued with a pass")
 s = fresh()
 s.players[0].pos = Vector2(1020,465)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.shoot_ball(0,true)
 s.flight.time = s.flight.duration*0.92
 s.ball = s.flight_position()
 s.players[2].pos = s.ball
 s.flight.cpu_block_allowed = [true,true,true,true]
 check(s.ai(2).shoot,"a cold CPU defender may challenge a descending dunk held by its shooter")
 s.defend(2,false)
 check(s.flight.blocked and s.stats[2].blocks == 1 and s.stats[2].goaltends == 0 and s.score == [0,0],"late dunk contact is a legal rejection rather than jump-shot goaltending")
 print("ARCADE RULE TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
