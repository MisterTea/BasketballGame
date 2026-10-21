extends SceneTree
var net: JamNetwork
var state = MatchState.new()
var hosting = false
var started = false
var ready_sent = false
var elapsed = 0.0
var broadcast_time = 0.0
var home_passed = false
var away_staged = false
var home_scored_at = -1.0
var jump_sent = false
var away_passed = false
var saw_home_lob = false
var saw_away_lob = false
var saw_home_dunk = false
var saw_away_dunk = false

func neutral() -> Dictionary:
 return {"move":Vector2.ZERO,"shoot":false,"jump_press":false,"pass":false,"turbo":false}

func stage(team: int) -> void:
 state.inbound(team)
 state.freeze = 0
 var hoop = state.hoop_for(team)
 var direction = 1 if hoop.x > 640 else -1
 state.players[team*2].pos = hoop-Vector2(direction*330,0)
 state.players[team*2+1].pos = hoop-Vector2(direction*100,0)
 for i in [2,3] if team == 0 else [0,1]:
  state.players[i].pos = Vector2(250 if team == 0 else 1030,300 if i%2 == 0 else 600)
 state.ball = state.players[state.owner].pos
 state.announce("HOME LOB READY" if team == 0 else "AWAY LOB READY")

func _initialize() -> void:
 call_deferred("setup")

func setup() -> void:
 net = JamNetwork.new()
 net.name = "Network"
 root.add_child(net)
 hosting = OS.get_cmdline_user_args().has("--host")
 net.game_started.connect(func(_options):
  state.start(0,1,30)
  stage(0)
  started = true)
 net.state_received.connect(func(data):
  state.apply_snapshot(data)
  if state.flight.get("kind","") == "pass" and state.flight.get("alley",false):
   saw_home_lob = saw_home_lob or state.flight.target == 1
   saw_away_lob = saw_away_lob or state.flight.target == 3
  if state.flight.get("finish","") == "alley_oop" and state.flight.release_height == 3.8 and state.flight.player_launch_height > 0.5:
   saw_home_dunk = saw_home_dunk or state.flight.shooter == 1
   saw_away_dunk = saw_away_dunk or state.flight.shooter == 3
  if state.score == [2,2] and saw_home_lob and saw_away_lob and saw_home_dunk and saw_away_dunk:
   if state.stats[1].dunks != 1 or state.stats[3].dunks != 1 or state.stats[0].attempts != 0 or state.stats[2].attempts != 0:
    push_error("Alley-oop network statistics were duplicated or credited to passers")
    quit(1)
   print("NETWORK ALLEY CLIENT PASS slot=",net.local_slot," both coordinated lob/catch/dunk sequences received")
   net.leave()
   quit(0))
 if hosting:
  if net.host_game("LOB HOST") != OK:
   quit(1)
 else:
  net.join_game("127.0.0.1","LOB CLIENT")

func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 24:
  push_error("NETWORK ALLEY TIMEOUT")
  quit(1)
 if not is_instance_valid(net):
  return false
 if hosting:
  if not started and net.members.size() == 4 and net.can_start():
   net.start_game({"seconds":30,"level":1})
  if started:
   var command = neutral()
   if not home_passed and state.owner == 0 and state.players[1].receive_jump > 0:
    command["pass"] = true
    command.turbo = true
    home_passed = true
   net.send_command(command)
   state.tick(delta,net.commands())
   if state.flight.get("finish","") == "alley_oop":
    state.flight.made = true # Controlled score fixture; all jump/pass inputs are real.
   if state.score[0] == 2 and not away_staged:
    if home_scored_at < 0:
     home_scored_at = elapsed
    if elapsed-home_scored_at > 0.3:
     away_staged = true
     stage(1)
   broadcast_time += delta
   if broadcast_time >= 0.05:
    broadcast_time = 0
    net.broadcast(state.snapshot())
   if state.score == [2,2] and net.members.size() == 1:
    print("NETWORK ALLEY HOST PASS: four humans, both teams, reliable jumps/passes, catches, scoring and disconnect")
    net.leave()
    quit(0)
 else:
  var id = net.multiplayer.get_unique_id()
  if net.members.has(id) and not ready_sent:
   net.ready_up()
   ready_sent = true
  if started:
   var command = neutral()
   if not jump_sent and ((net.local_slot == 1 and state.banner == "HOME LOB READY") or (net.local_slot == 3 and state.banner == "AWAY LOB READY")):
    command.jump_press = true # No held Shoot packets: exercise reliable off-ball input.
    jump_sent = true
   if net.local_slot == 2 and not away_passed and state.owner == 2 and state.players[3].receive_jump > 0:
    command["pass"] = true
    command.turbo = true
    away_passed = true
   net.send_command(command)
 return false
