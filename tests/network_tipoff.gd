extends SceneTree
var net: JamNetwork
var state = MatchState.new()
var hosting = false
var started = false
var ready_sent = false
var elapsed = 0.0
var broadcast_time = 0.0
var saw_toss = false
var saw_jump = false
var saw_award = false
var caught = false
var jump_sent = false

func _initialize() -> void:
 call_deferred("setup")

func setup() -> void:
 net = JamNetwork.new()
 net.name = "Network"
 root.add_child(net)
 hosting = OS.get_cmdline_user_args().has("--host")
 net.game_started.connect(func(_options):
  state.start(0,1,30)
  started = true)
 net.state_received.connect(func(data):
  state.apply_snapshot(data)
  if state.tipoff.active:
   saw_toss = true
   if state.clock != 30 or not is_equal_approx(state.shot_clock, MatchState.SHOT_CLOCK_SECONDS) or state.owner != -1:
    push_error("Tip-off leaked match time or possession")
    quit(1)
  saw_jump = saw_jump or state.tipoff.jumps[1] >= 0
  saw_award = saw_award or state.tipoff.winner == 1 and state.flight.get("tip",false)
  if saw_toss and saw_jump and saw_award and state.owner == 3:
   if state.score != [0,0] or state.stats[2].attempts != 0 or state.clock >= 30:
    push_error("Tip-off altered basketball statistics or failed to resume clocks")
    quit(1)
   print("NETWORK TIP CLIENT PASS: remote Shoot wins the toss, partner catches, clocks resume")
   net.leave()
   quit(0))
 if hosting:
  if net.host_game("TIP HOST") != OK:
   quit(1)
 else:
  net.join_game("127.0.0.1","TIP CLIENT")

func _process(delta: float) -> bool:
 elapsed += delta
 if elapsed > 12:
  push_error("NETWORK TIP TIMEOUT")
  quit(1)
 if not is_instance_valid(net):
  return false
 if hosting:
  if not started and net.members.size() == 2 and net.can_start():
   net.start_game({"seconds":30,"level":1})
  if started:
   state.tick(delta,net.commands())
   caught = caught or state.owner == 3 and state.tipoff.winner == 1
   broadcast_time += delta
   if broadcast_time >= 0.05:
    broadcast_time = 0
    net.broadcast(state.snapshot())
   if caught and net.members.size() == 1:
    print("NETWORK TIP HOST PASS: authoritative judgment, catch and disconnect")
    net.leave()
    quit(0)
 else:
  var id = net.multiplayer.get_unique_id()
  if net.members.has(id) and not ready_sent:
   net.ready_up()
   ready_sent = true
  if started:
   var jump: bool = not jump_sent and state.tipoff.active and state.tipoff.time >= 1.4 and state.tipoff.time < 1.6
   jump_sent = jump_sent or jump
   # Deliberately omit held Shoot: only the reliable one-shot event can win.
   net.send_command({"move":Vector2.ZERO,"shoot":false,"jump_press":jump,"pass":false,"turbo":false})
 return false
