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

func fresh(period: int = 4) -> MatchState:
 var s = MatchState.new()
 s.start(0,1)
 s.inbound(0) # Stage ordinary play before testing scored dunks.
 s.quarter = period
 s.elapsed = 10
 s.freeze = 0
 return s

func dunk(s: MatchState, shooter: int, made: bool = true, blocked: bool = false) -> void:
 s.freeze = 0
 s.owner = shooter
 var hoop = s.hoop_for(shooter/2)
 s.players[shooter].pos = hoop+Vector2(110 if hoop.x < 640 else -110,0)
 s.players[shooter].charge = 0.58
 s.players[shooter].vel = (hoop-s.players[shooter].pos).normalized()*200
 s.ball = s.players[shooter].pos
 s.shoot_ball(shooter,true)
 s.flight.made = made
 s.flight.blocked = blocked
 for frame in range(120):
  if s.flight.is_empty():
   break
  s.tick(1.0/60.0,{0:{},1:{},2:{},3:{}})

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var s = fresh(3)
 dunk(s,0)
 check(s.board_breaks == [-1.0,-1.0] and s.score == [2,0],"early-quarter dunks score without shattering glass")
 s = fresh()
 dunk(s,0,false)
 check(s.board_breaks == [-1.0,-1.0],"missed late dunks cannot break a backboard")
 s = fresh()
 dunk(s,0,true,true)
 check(s.board_breaks == [-1.0,-1.0] and s.score == [0,0],"blocked dunks cannot break a backboard")
 s = fresh()
 s.award_basket(0,3,false)
 check(s.board_breaks == [-1.0,-1.0],"ordinary late-game baskets do not shatter glass")
 s.award_basket(0,2,false,false)
 check(s.board_breaks == [-1.0,-1.0],"goaltending awards do not shatter glass")
 s = fresh()
 dunk(s,0)
 check(is_equal_approx(s.board_breaks[0],s.elapsed) and s.board_breaks[1] == -1,"a successful fourth-quarter dunk shatters the physical attacking backboard after sides switch")
 check(s.score == [2,0] and s.stats[0].made == 1 and s.stats[0].attempts == 1 and s.stats[0].dunks == 1,"the shattering dunk counts exactly once as a normal two-point field goal")
 check(s.pending_inbound == 1 and s.shatter_shooter == 0 and s.owner == -1 and s.phase == "playing","shattering delays the opposing inbound without ending the game")
 check(s.event_kind == "shatter" and s.banner.contains("SHATTERED"),"shattering emits dedicated banner and sound event")
 var copy = MatchState.new()
 copy.apply_snapshot(s.snapshot())
 check(copy.board_breaks == s.board_breaks and copy.pending_inbound == 1 and copy.shatter_shooter == 0,"snapshots preserve glass state, event time and pending inbound")
 var clock: float = s.clock
 var height: float = s.ball_height()
 s.tick(0.3,{})
 check(s.clock == clock and s.shot_clock == 24 and s.pending_inbound == 1,"spectacle pauses both clocks")
 check(s.ball_height() < height and s.players[0].jump == 0,"the ball drops and the dunker lands during the spectacle")
 s.tick(2.0,{})
 s.tick(0.01,{})
 check(s.owner == 2 and s.pending_inbound == -1 and s.freeze > 0 and s.score == [2,0],"normal opposing inbound resumes after the spectacle without duplicate scoring")
 var first_break: float = s.board_breaks[0]
 dunk(s,0)
 check(s.board_breaks[0] == first_break and s.pending_inbound == -1 and s.stats[0].dunks == 2,"a broken hoop accepts later dunks without retriggering shattering")
 dunk(s,2)
 check(s.board_breaks[0] >= 0 and s.board_breaks[1] >= 0 and s.score == [4,2],"the other physical backboard can independently shatter")
 s = fresh()
 s.overtime = 1
 dunk(s,2)
 check(s.board_breaks[1] >= 0,"overtime dunks can shatter an intact backboard")
 s = fresh()
 s.clock = 0
 dunk(s,0)
 s.tick(0.5,{})
 check(s.phase == "playing" and s.pending_inbound == 1,"a buzzer dunk presents the spectacle before ending the match")
 s.tick(2,{})
 s.tick(0.01,{})
 s.tick(2,{})
 s.tick(0.01,{})
 check(s.phase == "finished" and s.score == [2,0] and s.board_breaks[0] >= 0,"a shattering buzzer basket reaches the final score and retains the broken board")
 var arena = ArenaView.new()
 root.add_child(arena)
 s = fresh()
 arena.present(s,[],s.ball,[0],0.1,false)
 check(arena.baskets.size() == 2 and arena.baskets[0].shards.size() == 70,"each modeled board contains 70 prebuilt triangular glass shards")
 check(arena.baskets[0].glass.visible and not arena.baskets[0].pieces.visible,"intact glass hides all debris")
 dunk(s,0)
 var before = s.snapshot()
 arena.present(s,[],s.ball,[0],0.1,false)
 check(not arena.baskets[0].glass.visible and not arena.baskets[0].target.visible and arena.baskets[0].pieces.visible and arena.baskets[1].glass.visible,"shattering removes glass and its target markings only from the impacted hoop")
 check(s.snapshot() == before,"glass presentation cannot change authoritative match state")
 s.elapsed += 0.3
 arena.present(s,[],s.ball,[0],0.1,false)
 var piece: Dictionary = arena.baskets[0].shards[0]
 check(piece.mesh.position.distance_to(piece.origin) > 0.3 and piece.mesh.rotation.length() > 0,"glass fragments burst outward and tumble")
 var position: Vector3 = piece.mesh.position
 arena.present(s,[],s.ball,[0],0.5,true)
 check(piece.mesh.position == position,"paused glass fragments retain their positions")
 copy.apply_snapshot(s.snapshot())
 var replica = ArenaView.new()
 root.add_child(replica)
 replica.present(copy,[],copy.ball,[0],0.1,false)
 var identical = true
 for i in range(70):
  identical = identical and replica.baskets[0].shards[i].mesh.transform.is_equal_approx(arena.baskets[0].shards[i].mesh.transform)
 check(identical,"a fresh client view reconstructs all 70 identical shards from a retained timestamp")
 s.elapsed = s.board_breaks[0]+3.0
 arena.present(s,[],s.ball,[0],0.1,false)
 var landed = true
 for shard in arena.baskets[0].shards:
  landed = landed and is_equal_approx(shard.mesh.position.y,0.035) and absf(shard.mesh.basis.x.dot(Vector3.UP)) > 0.99
 check(landed,"fragments settle above the floor instead of falling through it")
 s.elapsed = s.board_breaks[0]+6.1
 arena.present(s,[],s.ball,[0],0.1,false)
 check(not arena.baskets[0].pieces.visible and not arena.baskets[0].glass.visible,"debris expires while the broken board remains visible as an empty frame")
 s.start(0,1)
 arena.present(s,[],s.ball,[0],0.1,false)
 check(s.board_breaks == [-1.0,-1.0] and s.pending_inbound == -1 and s.shatter_shooter == -1 and arena.baskets[0].glass.visible and arena.baskets[0].target.visible,"a rematch repairs glass, markings and authoritative break state")
 print("BACKBOARD TESTS: ",checks," checks, ","PASS" if failures == 0 else "FAIL")
 arena.queue_free()
 replica.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
