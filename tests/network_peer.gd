extends SceneTree
var net: JamNetwork
var state = MatchState.new()
var time = 0.0
var count = 0
var peak = 0
var is_host = false
var ready_sent = false
var finished = false
var started = false
var broadcast_elapsed = 0.0

func _initialize() -> void:
 call_deferred("setup")

func setup() -> void:
 net = JamNetwork.new()
 net.name = "Network"
 root.add_child(net)
 is_host = OS.get_cmdline_user_args().has("--host")
 net.game_started.connect(func(options):
  state.start(options.teams[0],options.teams[1],30)
  if is_host:
   for basket in range(3):
    state.record_natural_basket(0)
   state.stats[2].goaltends = 1
  started = true
  print("STARTED slot=",net.local_slot))
 net.state_received.connect(func(data):
  state.apply_snapshot(data)
  count += 1
  if count >= 45 and not finished:
   if state.players.size() == 4 and state.clock < 30 and state.teams == [3,5] and state.players[net.local_slot].pos.x < (420 if net.local_slot < 2 else 860)-30 and state.fire_player == 0 and state.player_streak == [3,0,0,0] and state.stats[2].goaltends == 1:
    print("NETWORK CLIENT PASS slot=",net.local_slot," snapshots=",count)
    finished = true
    call_deferred("finish_client")
   else:
    push_error("Bad authoritative state")
    quit(1))
 if is_host:
  var error = net.host_game("HOST")
  if error != OK:
   quit(1)
  net.selections = [3,5]
 else:
  net.join_game("127.0.0.1","CLIENT")

func _process(delta: float) -> bool:
 time += delta
 if not is_instance_valid(net):
  return false
 peak = maxi(peak,net.members.size())
 if is_host:
  if net.members.size() == 4 and net.can_start() and not started:
   net.start_game({"seconds":30,"level":1})
  if started:
   state.tick(delta,net.commands())
   broadcast_elapsed += delta
   if broadcast_elapsed >= 0.05:
    broadcast_elapsed = 0.0
    net.broadcast(state.snapshot())
   count += 1
  if started and peak == 4 and net.members.size() == 1:
   print("NETWORK HOST PASS: four player lobby, ready, selection, snapshots and disconnect")
   net.leave()
   quit(0)
 else:
  var id = net.multiplayer.get_unique_id()
  if net.members.has(id) and not ready_sent:
   net.ready_up()
   ready_sent = true
  if started:
   net.send_command({"move":Vector2.LEFT,"shoot":false,"pass":false,"turbo":true})
 if time > 15:
  push_error("NETWORK TIMEOUT peak=%d snapshots=%d" % [peak,count])
  quit(1)
 return false


func finish_client() -> void:
 net.leave()
 quit(0)

