extends SceneTree

var net: JamNetwork
var state = MatchState.new()
var hosting = false
var started = false
var ready_sent = false
var stage = 0
var stage_time = 0.0
var elapsed = 0.0
var broadcast_time = 0.0
var host_fake = false
var host_dunk = false
var host_dish = false
var dish_received_at = -1.0
var shatter_ready = false
var host_shatter = false

func neutral() -> Dictionary:
 return {"move":Vector2.ZERO,"shoot":false,"pass":false,"turbo":true}

func _initialize() -> void:
 call_deferred("setup")

func setup() -> void:
 net = JamNetwork.new()
 net.name = "Network"
 root.add_child(net)
 hosting = OS.get_cmdline_user_args().has("--host")
 net.game_started.connect(func(_options):
  state.start(0,1,30)
  state.freeze = 0
  state.owner = 2
  state.players[2].pos = Vector2(275,465)
  state.players[3].pos = Vector2(450,580)
  state.players[0].pos = Vector2(900,300)
  state.players[1].pos = Vector2(900,600)
  state.ball = state.players[2].pos
  started = true)
 net.state_received.connect(receive)
 if hosting:
  if net.host_game("ACTION HOST") != OK:
   quit(1)
 else:
  net.join_game("127.0.0.1","ACTION CLIENT")

func receive(data: Dictionary) -> void:
 state.apply_snapshot(data)
 if stage == 1 and state.players[2].fake > 0 and state.owner == 2 and state.stats[2].attempts == 0:
  print("NETWORK ACTION PASS: client tap produces authoritative head-fake")
  stage = 2
  stage_time = 0
 if stage == 3 and state.flight.get("dunk",false) and state.flight.get("shooter",-1) == 2 and state.flight.time >= 0.25:
  var command = neutral()
  command["pass"] = true
  net.send_command(command)
  stage = 4
 if stage == 4 and state.flight.get("kind","") == "pass" and state.flight.target == 3 and state.flight.start_height > 3.0 and state.stats[2].attempts == 0:
  print("NETWORK ACTION PASS: reliable client Pass cancels dunk into a dish")
  stage = 5
 if stage == 5 and state.owner == 3 and state.score == [0,0]:
  print("NETWORK ACTION PASS: teammate receives the airborne dish")
  stage = 6
 if stage == 6 and state.banner == "SHATTER TEST READY":
  stage = 7
  stage_time = 0
 if stage == 8 and state.board_breaks[1] >= 0 and state.pending_inbound == 0 and state.event_kind == "shatter" and state.score == [0,2] and state.stats[2].dunks == 1:
  print("NETWORK ACTION PASS: remote fourth-quarter dunk shatters the correct physical board")
  stage = 9
 if stage == 9 and state.pending_inbound == -1 and state.owner == 0 and state.board_breaks[1] >= 0 and state.board_breaks[0] < 0:
  print("NETWORK ACTION CLIENT PASS: inbound resumes with persistent glass state")
  net.leave()
  quit(0)

func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 18:
  push_error("NETWORK ACTION TIMEOUT stage=%d" % stage)
  quit(1)
 if not is_instance_valid(net):
  return false
 if hosting:
  if not started and net.members.size() == 2 and net.can_start():
   net.start_game({"seconds":30,"level":1})
  if started:
   var commands = net.commands()
   commands[1] = neutral()
   commands[3] = neutral()
   state.tick(delta,commands)
   if host_dish and state.owner == 3 and not shatter_ready:
    if dish_received_at < 0:
     dish_received_at = elapsed
    if elapsed-dish_received_at > 0.35:
     shatter_ready = true
     state.quarter = 4
     state.owner = 2
     state.players[2].pos = Vector2(1020,465)
     state.players[2].charge = 0
     state.players[2].shoot_held = false
     state.players[2].jump = 0
     state.players[0].pos = Vector2(300,300)
     state.players[1].pos = Vector2(300,600)
     state.ball = state.players[2].pos
     state.announce("SHATTER TEST READY")
   # This fixture guarantees a made shot; the remote peer supplies every input.
   if shatter_ready and state.flight.get("dunk",false):
    state.flight.made = true
   host_fake = host_fake or state.players[2].fake > 0
   host_dunk = host_dunk or state.flight.get("dunk",false)
   host_dish = host_dish or state.banner == "AIRBORNE DISH!"
   host_shatter = host_shatter or state.board_breaks[1] >= 0
   broadcast_time += delta
   if broadcast_time >= 0.05:
    broadcast_time = 0
    net.broadcast(state.snapshot())
   if host_fake and host_dunk and host_dish and host_shatter and net.members.size() == 1:
    print("NETWORK ACTION HOST PASS: input, simulation, snapshot and disconnect")
    net.leave()
    quit(0)
 else:
  var id = net.multiplayer.get_unique_id()
  if net.members.has(id) and not ready_sent:
   net.ready_up()
   ready_sent = true
  if started:
   stage_time += delta
   var command = neutral()
   if stage == 0:
    command.shoot = true
    if stage_time >= 0.08:
     stage = 1
   elif stage == 2:
    command.shoot = true
    if stage_time >= 0.58:
     stage = 3
   elif stage == 7:
    command.shoot = true
    if stage_time >= 0.58:
     stage = 8
   net.send_command(command)
 return false
