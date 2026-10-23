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
 check(s.player_streak[2] == 1,"a miss leaves the make counter alone")
 s = fresh()
 s.record_natural_basket(2)
 s.record_natural_basket(2)
 var whistled = false
 var whiffed = false
 for n in range(80):
  s = fresh()
  s.rng.seed = 3000 + n
  s.record_natural_basket(2)
  s.record_natural_basket(2)
  shot(s,0,true)
  s.flight.made = false
  s.players[2].pos = s.flight_position()
  s.defend(2,false)
  if s.stats[2].goaltends == 1:
   whistled = whistled or (s.score[0] == 3 and s.owner == 2 and s.flight.is_empty() and s.stats[2].blocks == 0 and s.player_streak[2] == 2 and s.player_streak[0] == 0 and is_equal_approx(s.shot_clock, MatchState.SHOT_CLOCK_SECONDS) and s.freeze > 0)
  elif not s.flight.get("blocked", false) and s.stats[2].blocks == 0 and s.score[0] == 0:
   whiffed = true
 check(whistled,"a fast downward swat that wins the 1-in-4 mask is goaltending")
 check(whiffed,"three of four fast downward swats miss the ball entirely")
 s = fresh()
 shot(s,0,false)
 s.players[2].pos = s.flight_position()
 s.defend(2,false)
 check(s.flight.blocked and s.stats[2].blocks == 1 and s.score == [0,0],"ascending contact is a legal block")
 check(s.banner != "REJECTED!","an early swat is not called rejected before the rim")
 while s.flight.get("kind", "") == "shot":
  s.tick_flight(1.0/30.0)
 check(s.banner == "REJECTED!","the rejection is called when the ball reaches the rim")
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
 check(s.ai(2).shoot,"a cold CPU defender still contests a descending shot")
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
 var cold_base = s.snapshot()
 var cold_whistle = false
 for n in range(80):
  s.apply_snapshot(cold_base)
  s.rng.seed = 8000 + n
  shot(s,0,true)
  s.players[3].pos = s.flight_position()
  s.defend(3,false)
  if s.stats[3].goaltends == 1 and s.score[0] == 3:
   cold_whistle = true
   break
 check(cold_whistle,"a burning teammate does not grant another defender goaltending immunity")
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
 s.players[0].pos = s.hoop_for(0) + Vector2(-180, 0)
 s.ball = s.players[0].pos
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 s.tick(0.10,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.owner == 0 and s.flight.is_empty() and s.stats[0].attempts == 0 and s.players[0].fake > 0 and not s.players[0].dribble_locked,"a short Shoot tap head-fakes and keeps the ball")
 var planted = s.players[0].pos
 call[0].move = Vector2.RIGHT
 for _step in range(6):
  s.tick(1.0/60.0, call)
 check(s.players[0].fake > 0.0 and s.players[0].vel == Vector2.ZERO and s.players[0].pos.distance_to(planted) < 1.0, "a head fake plants the shooter in place")
 call[0].move = Vector2.ZERO
 check(s.player_streak[0] == 2,"the head fake does not change heat")
 s.clock = 3.5
 s.players[0].fake = 0.0
 s.players[0].shoot_held = false
 call[0].shoot = true
 s.tick(0.10,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.flight.get("shooter",-1) == 0 and s.stats[0].attempts == 1,"under 4 seconds a short Shoot tap releases the shot")
 s = fresh()
 s.owner = 1
 s.players[1].pos = s.hoop_for(0) + Vector2(-180, 0)
 s.ball = s.players[1].pos
 call = {0:neutral(),2:neutral(),3:neutral()}
 call[0].shoot = true
 s.tick(0.05,call)
 call[0].shoot = false
 s.tick(1.0/60.0,call)
 check(s.flight.get("shooter",-1) == 1 and s.players[1].fake == 0,"a tapped CPU teammate order shoots rather than head-faking")
 s = fresh()
 var dish_hoop = s.hoop_for(0)
 s.players[0].pos = dish_hoop + Vector2(-170, 0)
 s.players[1].pos = dish_hoop + Vector2(-400, 160)
 s.players[2].pos = dish_hoop + Vector2(-420, -180)
 s.players[3].pos = dish_hoop + Vector2(-280, 220)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.players[0].vel = (dish_hoop-s.players[0].pos).normalized()*200
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
 s.players[0].vel = (s.hoop_for(0)-s.players[0].pos).normalized()*200
 s.shoot_ball(0,true)
 s.flight.time = 0.25
 s.flight.blocked = true
 s.tick(1.0/60.0,call)
 check(s.flight.kind == "shot" and s.flight.blocked,"a blocked dunk cannot be rescued with a pass")
 s = fresh()
 var cpu_hoop = s.hoop_for(0)
 s.owner = -1
 s.players[0].pos = cpu_hoop + Vector2(-180, 40)
 s.players[1].pos = cpu_hoop + Vector2(-80, 0)
 s.stats[1].attempts = 1
 s.flight = {
  "kind": "shot", "start": s.players[1].pos, "end": cpu_hoop,
  "time": 0.20, "duration": 1.15, "shooter": 1, "points": 2,
  "made": true, "dunk": true, "blocked": false, "in_hand_until": 1.15 * MatchState.DUNK_HAND_RELEASE,
  "release_height": 1.3, "arc_height": 1.6
 }
 s.ball = s.flight_position()
 call = {0:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 s.tick(1.0/60.0, call)
 check(s.flight.get("kind","") == "pass" and s.flight.get("target", -1) == 0 and s.stats[1].attempts == 0,"pressing Pass while a CPU teammate is dunking makes him dish before the slam")
 s = fresh()
 var hand_hoop = s.hoop_for(0)
 s.owner = 0
 s.players[0].pos = hand_hoop + Vector2(-420, 0)
 s.players[1].pos = hand_hoop + Vector2(-200, 80)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.4
 s.players[0].shoot_held = true
 s.players[0].shot_finish = "jumper"
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 s.tick(1.0/60.0,call)
 check(s.flight.get("kind","") == "pass" and s.flight.target == 1 and s.stats[0].attempts == 0,"a pass during a jump-shot windup dishes before the ball leaves the hand")
 s = fresh()
 s.players[0].pos = hand_hoop + Vector2(-420, 0)
 s.players[1].pos = hand_hoop + Vector2(-200, 80)
 s.ball = s.players[0].pos
 s.shoot_ball(0, false)
 s.flight.time = 0.05
 s.ball = s.flight_position()
 var early_height = s.ball_height()
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 s.tick(1.0/60.0,call)
 check(s.flight.get("kind","") == "pass" and s.stats[0].attempts == 0 and s.flight.start_height == early_height,"a jumper can be dished in the 12 ticks before plyr_shoot")
 s = fresh()
 s.players[0].pos = hand_hoop + Vector2(-70, 0)
 s.players[0].vel = Vector2(180, 0)
 s.players[1].pos = hand_hoop + Vector2(-220, 40)
 s.players[2].pos = hand_hoop + Vector2(-400, -200)
 s.players[3].pos = hand_hoop + Vector2(-400, 200)
 s.ball = s.players[0].pos
 s.shoot_ball(0, false)
 s.flight.time = s.flight.duration * MatchState.DUNK_HAND_RELEASE
 s.ball = s.flight_position()
 call = {0:neutral(),1:neutral(),2:neutral(),3:neutral()}
 call[0]["pass"] = true
 s.tick(1.0/60.0,call)
 check(s.flight.get("kind","") == "shot" and s.flight.dunk,"a pass after the ball leaves the dunking hand does not cancel the dunk")
 s = fresh()
 var late_hoop = s.hoop_for(0)
 s.players[0].pos = late_hoop + Vector2(-170, 0)
 s.players[1].pos = late_hoop + Vector2(-400, 160)
 s.players[2].pos = late_hoop + Vector2(-420, -180)
 s.players[3].pos = late_hoop + Vector2(-280, 220)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.players[0].vel = (late_hoop-s.players[0].pos).normalized()*200
 s.shoot_ball(0,true)
 # An alley dunk sets the shot meter and then launches. A denial must clear it,
 # or the meter holds the dunker in the air after the play.
 s.players[0].charge = 0.58
 s.flight.time = s.flight.duration*0.92
 s.ball = s.flight_position()
 s.players[2].pos = s.ball
 s.flight.cpu_block_allowed = [true,true,true,true]
 check(s.ai(2).shoot,"a cold CPU defender may challenge a descending dunk held by its shooter")
 var late_dunk = s.snapshot()
 var rejected = false
 for n in range(40):
  s.apply_snapshot(late_dunk)
  s.rng.seed = 7000 + n
  s.defend(2,false)
  if s.flight.blocked and s.stats[2].blocks == 1 and s.stats[2].goaltends == 0 and s.score == [0,0]:
   rejected = true
   break
 check(rejected,"late dunk contact is a legal rejection rather than jump-shot goaltending")
 if rejected:
  check(s.players[0].jump == 0.0 and s.players[0].charge == 0.0 and s.players[0].vel == Vector2.ZERO and s.players[0].get("rim_hang", 0.0) == 0.0,"a blocked dunker drops out of the dunk")
 s = fresh()
 var mid_hoop = s.hoop_for(0)
 s.players[0].pos = mid_hoop + Vector2(-220, 0)
 s.players[1].pos = mid_hoop + Vector2(-400, 160)
 s.players[2].pos = mid_hoop + Vector2(-420, -180)
 s.players[3].pos = mid_hoop + Vector2(-280, 220)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.players[0].vel = (mid_hoop - s.players[0].pos).normalized() * 220.0
 s.shoot_ball(0, true)
 s.flight.time = s.flight.duration * 0.35
 s.ball = s.flight_position()
 s.players[0].pos = s.finisher_position(s.flight.time)
 s.players[2].pos = s.ball
 var mid_dunk = s.snapshot()
 var stopped = false
 for n in range(40):
  s.apply_snapshot(mid_dunk)
  s.rng.seed = 8100 + n
  s.defend(2, false)
  if not s.flight.blocked:
   continue
  var scripted = s.finisher_position(s.flight.time + 0.25)
  s.tick(0.2, {0:neutral(), 1:neutral(), 2:neutral(), 3:neutral()})
  # Body separation can nudge the dunker off the defender. The dunk glide would carry them to the rim.
  stopped = s.players[0].jump <= 0.0 and s.players[0].pos.distance_to(scripted) > 30.0
  break
 check(stopped, "a blocked dunker stays down instead of floating the rest of the dunk path")
 s = fresh()
 var mid = MatchState.COURT.position.x + MatchState.COURT.size.x * 0.5
 s.owner = 0
 s.players[0].pos = Vector2(mid - 40.0, 465)
 s.ball = s.players[0].pos
 s.shoot_ball(0, false)
 check(s.flight.is_empty() and s.owner == 0, "a direct shot from beyond half court does not leave the hand")
 var hold = {0: {"move": Vector2.ZERO, "shoot": true, "pass": false, "turbo": false}, 1: neutral(), 2: neutral(), 3: neutral()}
 s.tick(0.2, hold)
 check(s.flight.is_empty() and s.owner == 0 and s.players[0].charge == 0.0, "holding Shoot beyond half court is ignored")
 s.players[0].pos = Vector2(mid + 40.0, 465)
 s.ball = s.players[0].pos
 s.tick(0.2, hold)
 check(s.flight.is_empty() and s.players[0].charge > 0.0, "holding Shoot on the near side of half court still charges")
 s.quarter = 3
 s.players[0].charge = 0.5
 s.players[0].shot_finish = "jumper"
 s.tick(0.05, hold)
 check(s.flight.is_empty() and s.owner == 0 and s.players[0].charge == 0.0, "after the baskets flip, the other side of midcourt cannot shoot")
 s = fresh()
 var glass_hoop = s.hoop_for(0)
 s.owner = 0
 s.players[0].pos = glass_hoop + Vector2(48, 0)
 s.players[1].pos = glass_hoop + Vector2(-400, 180)
 s.players[2].pos = glass_hoop + Vector2(-420, -180)
 s.players[3].pos = glass_hoop + Vector2(-280, 220)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.shoot_ball(0, false)
 s.flight.made = true
 var glass_plane = s.glass_plane_x(glass_hoop)
 while not s.flight.is_empty() and s.flight.get("kind", "") == "shot" and s.flight.time < s.flight.duration:
  s.tick_flight(1.0 / 60.0)
 check(s.flight.get("glass_back", false) and not s.flight.get("made", false) and s.score == [0, 0], "a shot from behind the glass bounces off the backboard")
 var away_from_court = 1.0 if glass_hoop.x > 640.0 else -1.0
 check((s.flight.end.x - glass_plane) * away_from_court > 5.0, "the bounce sends the ball back behind the glass")
 s = fresh()
 var swat_hoop = s.hoop_for(0)
 s.owner = 0
 s.players[0].pos = swat_hoop + Vector2(-280, 0)
 s.players[1].pos = swat_hoop + Vector2(-500, 200)
 s.players[3].pos = swat_hoop + Vector2(-500, -200)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.shoot_ball(0, false)
 s.flight.duration = 8.0
 s.flight.time = 0.2
 s.ball = s.flight_position()
 s.players[2].pos = s.ball + Vector2(0, 75)
 s.players[2].cooldown = 0.0
 s.defend(2, false)
 check(not s.flight.get("blocked", false), "a jump block just outside arm's reach does not swat on the button frame")
 var reached = false
 for _step in range(40):
  s.tick(1.0 / 60.0, {0: neutral(), 1: neutral(), 2: neutral(), 3: neutral()})
  if s.flight.get("blocked", false) or s.stats[2].goaltends > 0:
   reached = true
   break
 check(reached, "the block jump slides toward the ball and can meet it")
 check(is_equal_approx(s.shot_flight_ticks(80.0 * 640.0 / 950.0, false, false, false), 52.0), "a short shot stays airborne for 52 cabinet ticks")
 check(is_equal_approx(s.shot_flight_ticks(80.0 * 640.0 / 950.0, true, false, false), 37.0), "a flat arc floors at 37 cabinet ticks")
 check(is_equal_approx(s.shot_flight_ticks(80.0 * 640.0 / 950.0, false, true, false), 67.0), "a hook adds 15 ticks after the 50-tick floor")
 s = fresh()
 var pace_hoop = s.hoop_for(0)
 s.owner = 0
 s.players[0].pos = pace_hoop + Vector2(-80, 0)
 s.players[0].shot_finish = "layup"
 s.ball = s.players[0].pos
 s.shoot_ball(0, false)
 var lay_ticks = s.flight.duration * MatchState.ARCADE_TSEC
 var lay_ok = is_equal_approx(lay_ticks, 37.0) or is_equal_approx(lay_ticks, 52.0) or is_equal_approx(lay_ticks, 72.0)
 check(s.flight.layup and lay_ok, "a layup uses the cabinet flight instead of the 35-tick flat shortcut")
 s = fresh()
 s.players[0].pos = Vector2(700, 465)
 s.players[1].pos = Vector2(1100, 465)
 s.ball = s.players[0].pos
 s.pass_ball(0, false)
 var pass_ticks = 400.0 * 640.0 / 950.0 * float(MatchState.SHORTPAS_T[7]) / 1024.0
 var pass_expect = pass_ticks / MatchState.ARCADE_TSEC
 check(is_equal_approx(s.flight.duration, pass_expect), "a chest pass lasts dist*shortpas/1024 ticks at the cabinet rate")
 var pass_speed = 400.0 / s.flight.duration
 check(absf(pass_speed - 762.9) < 1.0, "that pass covers 763 court pixels per second")
 var slam = s.dunk_body_lift(1.0, 37.0)
 check(is_equal_approx(slam + MatchState.DUNK_HAND_REACH, MatchState.RIM_HEIGHT), "a rim hang puts the hands on the rim")
 var crest = 0.0
 for step in range(21):
  crest = maxf(crest, s.dunk_body_lift(step / 20.0, 74.0))
 check(crest > slam + 1.0, "a long dunk arcs above the rim before the slam")
 s = fresh()
 var dunk_hoop = s.hoop_for(0)
 s.owner = 0
 s.players[0].pos = dunk_hoop + Vector2(-70, 0)
 s.players[0].vel = Vector2(80, 0)
 s.ball = s.players[0].pos
 s.players[0].charge = 0.58
 s.shoot_ball(0, false)
 check(s.flight.dunk and MatchState.DUNK_TICKS.has(s.flight.dunk_style), "an under-hoop dunk picks a cabinet motion")
 check(s.flight.duration * MatchState.ARCADE_TSEC < 50.0, "an under-hoop dunk reaches the rim in under 50 ticks")
 print("ARCADE RULE TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
