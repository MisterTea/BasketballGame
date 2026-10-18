class_name JamNetwork
extends Node

signal lobby_changed
signal game_started(options: Dictionary)
signal state_received(data: Dictionary)
signal status_changed(message: String)
const PORT = 27888
var online = false
var hosting = false
var active_match = false
var members: Dictionary = {}
var inputs: Dictionary = {}
var pending_pass: Dictionary = {}
var selections: Array = [0, 1]
var local_slot = 0
var local_name = "ACE"
var options: Dictionary = {}

func _ready() -> void:
 # This is a host-authoritative star topology; clients never address one another.
 multiplayer.server_relay = false
 multiplayer.peer_connected.connect(_peer_connected)
 multiplayer.peer_disconnected.connect(_peer_left)
 multiplayer.connected_to_server.connect(func(): register.rpc_id(1, local_name))
 multiplayer.connection_failed.connect(func(): leave(); status_changed.emit("Connection failed. Check address, firewall and UDP port 27888."))
 multiplayer.server_disconnected.connect(func(): leave(); status_changed.emit("The host disconnected. Return to the menu to play again."))

func host_game(player_name: String) -> Error:
 leave()
 var peer = ENetMultiplayerPeer.new()
 var error = peer.create_server(PORT, 3)
 if error != OK:
  return error
 multiplayer.multiplayer_peer = peer
 online = true
 hosting = true
 local_name = player_name
 local_slot = 0
 members = {1:{"name":player_name, "slot":0, "ready":true}}
 lobby_changed.emit()
 return OK

func join_game(address: String, player_name: String) -> Error:
 leave()
 var peer = ENetMultiplayerPeer.new()
 var error = peer.create_client(address, PORT)
 if error != OK:
  return error
 multiplayer.multiplayer_peer = peer
 online = true
 local_name = player_name
 status_changed.emit("Connecting to %s…" % address)
 return OK

func leave() -> void:
 var old_peer = multiplayer.multiplayer_peer
 multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 if old_peer:
  old_peer.close()
 online = false
 hosting = false
 active_match = false
 members = {}
 inputs = {}
 pending_pass = {}
 local_slot = 0

func _peer_connected(id: int) -> void:
 if hosting and active_match:
  multiplayer.multiplayer_peer.disconnect_peer(id)

func _peer_left(id: int) -> void:
 if not hosting:
  return
 if members.has(id):
  inputs.erase(members[id].slot)
  members.erase(id)
  get_tree().create_timer(0.1).timeout.connect(publish_lobby)
  status_changed.emit("Player left. A CPU takes over their slot.")

@rpc("any_peer", "call_remote", "reliable")
func register(player_name: String) -> void:
 if not hosting or active_match:
  return
 var id = multiplayer.get_remote_sender_id()
 if members.has(id) or members.size() >= 4:
  return
 var used: Array = []
 for member in members.values():
  used.append(member.slot)
 for slot in [2, 1, 3]:
  if not used.has(slot):
   members[id] = {"name":player_name.strip_edges().left(12), "slot":slot, "ready":false}
   break
 publish_lobby()

func publish_lobby() -> void:
 if hosting:
  lobby_state.rpc(members, selections)
 lobby_changed.emit()

@rpc("authority", "call_remote", "reliable")
func lobby_state(roster: Dictionary, picks: Array) -> void:
 members = roster
 selections = picks
 var id = multiplayer.get_unique_id()
 if members.has(id):
  local_slot = members[id].slot
 lobby_changed.emit()

func choose(team: int) -> void:
 if hosting:
  selections[local_slot / 2] = clampi(team, 0, Teams.DATA.size()-1)
  publish_lobby()
 else:
  request_team.rpc_id(1, team)

@rpc("any_peer", "call_remote", "reliable")
func request_team(team: int) -> void:
 var id = multiplayer.get_remote_sender_id()
 if not hosting or active_match or not members.has(id):
  return
 var side: int = members[id].slot / 2
 # The first human on a side is its captain.
 if members[id].slot == 2 or (members[id].slot == 3 and not _slot_used(2)):
  selections[side] = clampi(team, 0, Teams.DATA.size()-1)
  for member in members.values():
   if member.slot / 2 == side:
    member.ready = false
  publish_lobby()

func _slot_used(slot: int) -> bool:
 for member in members.values():
  if member.slot == slot:
   return true
 return false

func ready_up() -> void:
 if hosting:
  return
 toggle_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func toggle_ready() -> void:
 var id = multiplayer.get_remote_sender_id()
 if hosting and not active_match and members.has(id):
  members[id].ready = not members[id].ready
  publish_lobby()

func can_start() -> bool:
 if not hosting:
  return false
 for member in members.values():
  if not member.ready:
   return false
 return true

func start_game(settings: Dictionary) -> void:
 if not can_start():
  return
 options = settings.duplicate(true)
 options.teams = selections.duplicate()
 active_match = true
 begin.rpc(options)
 game_started.emit(options)

@rpc("authority", "call_remote", "reliable")
func begin(settings: Dictionary) -> void:
 options = settings
 active_match = true
 game_started.emit(settings)

func send_command(command: Dictionary) -> void:
 if hosting:
  inputs[local_slot] = {"command":command, "at":Time.get_ticks_msec()}
 elif online and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
  submit_input.rpc_id(1, command.get("move", Vector2.ZERO), command.get("shoot", false), false, command.get("turbo", false))
  if command.get("pass", false):
   submit_pass.rpc_id(1)

@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func submit_input(move: Vector2, shoot: bool, pass_button: bool, turbo: bool) -> void:
 if not hosting or not active_match:
  return
 var id = multiplayer.get_remote_sender_id()
 if not members.has(id) or not move.is_finite():
  return
 var slot: int = members[id].slot
 inputs[slot] = {"command":{"move":move.limit_length(), "shoot":shoot, "pass":pass_button, "turbo":turbo}, "at":Time.get_ticks_msec()}

func commands() -> Dictionary:
 var result = {}
 for member in members.values():
  var slot: int = member.slot
  if inputs.has(slot) and Time.get_ticks_msec() - inputs[slot].at < 350:
   result[slot] = inputs[slot].command.duplicate()
  else:
   result[slot] = {"move":Vector2.ZERO, "shoot":false, "pass":false, "turbo":false}
  if pending_pass.has(slot):
   result[slot]["pass"] = true
   pending_pass.erase(slot)
 return result

func broadcast(data: Dictionary) -> void:
 if hosting and members.size() > 1:
  var payload = var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE)
  receive_state.rpc(payload)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func receive_state(payload: PackedByteArray) -> void:
 if not hosting and active_match and payload.size() < 65536:
  var decoded = payload.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE)
  var data = bytes_to_var(decoded)
  if data is Dictionary:
   state_received.emit(data)


@rpc("any_peer", "call_remote", "reliable", 0)
func submit_pass() -> void:
 var id = multiplayer.get_remote_sender_id()
 if hosting and active_match and members.has(id):
  pending_pass[members[id].slot] = true


