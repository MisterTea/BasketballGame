extends Node2D

const ArenaView = preload("res://scripts/arena_3d.gd")
var arena: SubViewport

const BG = Color("091321")
const INK = Color("e9f3ff")
const MUTED = Color("8195ae")
const GOLD = Color("ffcb68")
var game = MatchState.new()
var net: JamNetwork
var ui: Control
var screen = "menu"
var picks: Array = [0, 1]
var selection_side = 0
var mode = "solo"
var local_two = false
var controlled: Array = [0, 2]
var seconds = 180.0
var level = 1
var big_heads = false
var infinite_turbo = false
var tournament_round = 0
var tournament_wins = 0
var initials = "ACE"
var address = "127.0.0.1"
var status = ""
var profile: Dictionary = {"wins":0, "losses":0, "best":0, "championships":0}
var saved_result = false
var muted = false
var last_event = -1
var send_elapsed = 0.0
var shake = 0.0
var visual_time = 0.0
var paused = false
var rendered_positions: Array = []
var rendered_ball = Vector2.ZERO
var font: Font
var sounds: Dictionary = {}
var sound_player: AudioStreamPlayer
var status_label: Label

func _ready() -> void:
 font = ThemeDB.fallback_font
 load_profile()
 setup_input()
 net = JamNetwork.new()
 net.name = "Network"
 add_child(net)
 net.lobby_changed.connect(func():
  if screen == "lobby":
   picks = net.selections.duplicate()
   show_lobby())
 net.game_started.connect(begin_match)
 net.state_received.connect(func(data):
  if screen == "game":
   game.apply_snapshot(data))
 net.status_changed.connect(func(message):
  status = message
  if screen == "lobby":
   show_lobby()
  elif screen == "game" and not net.online:
   show_disconnected())
 var layer = CanvasLayer.new()
 add_child(layer)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(ui)
 sound_player = AudioStreamPlayer.new()
 add_child(sound_player)
 make_sounds()
 game.start(picks[0], picks[1])
 arena = ArenaView.new()
 arena.name = "ArenaViewport"
 add_child(arena)
 show_menu()
 # CLI hooks for repeatable engine/network smoke tests.
 var args = OS.get_cmdline_user_args()
 if args.has("--test-host"):
  net.host_game("HOST")
  screen = "lobby"
  show_lobby()
 if args.has("--test-client"):
  screen = "lobby"
  net.join_game("127.0.0.1", "CLIENT")
  show_lobby()
 if args.has("--autoplay"):
  begin_match({"teams":[0,1], "seconds":15.0, "level":1})

func setup_input() -> void:
 var mapping = {"up":[KEY_W,KEY_UP], "down":[KEY_S,KEY_DOWN], "left":[KEY_A,KEY_LEFT], "right":[KEY_D,KEY_RIGHT], "shoot":[KEY_J,KEY_KP_1], "pass":[KEY_K,KEY_KP_2], "turbo":[KEY_SPACE,KEY_KP_0], "switch":[KEY_TAB,KEY_KP_3]}
 for action in mapping:
  for p in range(2):
   var name_action = "p%d_%s" % [p,action]
   InputMap.add_action(name_action)
   var key = InputEventKey.new()
   key.physical_keycode = mapping[action][p]
   InputMap.action_add_event(name_action,key)
   var buttons = {"shoot":JOY_BUTTON_A,"pass":JOY_BUTTON_X,"turbo":JOY_BUTTON_RIGHT_SHOULDER,"switch":JOY_BUTTON_LEFT_SHOULDER}
   if buttons.has(action):
    var button = InputEventJoypadButton.new()
    button.device = p
    button.button_index = buttons[action]
    InputMap.action_add_event(name_action,button)

func clear_ui() -> void:
 for child in ui.get_children():
  ui.remove_child(child)
  child.queue_free()
 status_label = null

func label_at(text: String, x: float, y: float, size: int = 20, color: Color = INK, width: float = 0) -> Label:
 var label = Label.new()
 label.text = text
 label.position = Vector2(x,y)
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 if width > 0:
  label.size.x = width
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 ui.add_child(label)
 return label

func style(color: Color, border: Color = Color("2b3d55")) -> StyleBoxFlat:
 var box = StyleBoxFlat.new()
 box.bg_color = color
 box.border_color = border
 box.set_border_width_all(1)
 box.set_corner_radius_all(8)
 box.content_margin_left = 18
 box.content_margin_right = 18
 return box

func panel(x: float, y: float, w: float, h: float, color: Color = Color("101e30")) -> Panel:
 var p = Panel.new()
 p.position = Vector2(x,y)
 p.size = Vector2(w,h)
 p.add_theme_stylebox_override("panel",style(color))
 ui.add_child(p)
 return p

func button(text: String, x: float, y: float, w: float, callback: Callable, accent = false, h: float = 48) -> Button:
 var b = Button.new()
 b.text = text
 b.position = Vector2(x,y)
 b.size = Vector2(w,h)
 b.add_theme_font_size_override("font_size",17)
 b.add_theme_stylebox_override("normal",style(GOLD if accent else Color("15273d")))
 b.add_theme_stylebox_override("hover",style(Color("ffe0a0") if accent else Color("294969"),GOLD))
 b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),GOLD))
 b.add_theme_stylebox_override("pressed",style(Color("9f7637") if accent else Color("102037")))
 b.add_theme_color_override("font_color",BG if accent else INK)
 b.add_theme_color_override("font_hover_color",BG if accent else INK)
 b.pressed.connect(callback)
 ui.add_child(b)
 return b

func edit(text: String, placeholder: String, x: float, y: float, w: float, changed: Callable) -> LineEdit:
 var field = LineEdit.new()
 field.position = Vector2(x,y)
 field.size = Vector2(w,46)
 field.text = text
 field.placeholder_text = placeholder
 field.add_theme_font_size_override("font_size",18)
 field.add_theme_stylebox_override("normal",style(Color("081321")))
 field.text_changed.connect(changed)
 ui.add_child(field)
 return field

func header(kicker: String, title: String) -> void:
 label_at(kicker,60,28,15,GOLD)
 label_at(title,58,48,42)
 button("← MENU",1080,40,140,show_menu)

func show_menu() -> void:
 if net.online:
  net.leave()
 screen = "menu"
 paused = false
 clear_ui()

 label_at("2 ON 2  /  FULL COURT  /  NO FOULS",80,60,16,GOLD)
 label_at("RIM",76,98,100)
 label_at("RUMBLE",76,192,100,GOLD)
 label_at("BIG AIR. HOT HANDS. ZERO MERCY.",83,310,20,MUTED)
 button("QUICK PLAY   →",82,376,440,func(): mode = "solo"; local_two = false; show_selection(),true,58)
 button("LOCAL VERSUS",82,448,212,func(): mode = "local"; local_two = true; show_selection())
 button("ARCADE LADDER",308,448,214,func(): mode = "ladder"; local_two = false; tournament_round = 0; tournament_wins = 0; show_selection())
 button("NETWORK PLAY",82,510,440,show_network)
 button("HOW TO PLAY",82,574,212,show_help)
 button("OPTIONS",308,574,214,show_options)
 label_at("%s   •   %d W / %d L   •   BEST %d   •   %d TITLES" % [initials,profile.wins,profile.losses,profile.best,profile.championships],83,660,16,MUTED)
 label_at("ORIGINAL ARCADE BASKETBALL  /  GODOT 4",83,724,12,MUTED)
 label_at("THE COURT IS CALLING.",702,583,25)
 label_at("8 TEAMS  ·  16 ATHLETES\n1–4 PLAYERS  ·  CPU TEAMMATES",703,626,17,MUTED)

func show_network() -> void:
 screen = "network"
 clear_ui()
 header("PLAY TOGETHER", "NETWORK PLAY")
 panel(60,144,560,540)
 label_at("YOUR CALLSIGN",88,172,16,GOLD)
 edit(initials,"ACE",88,205,500,func(value): initials = value.strip_edges().to_upper().left(12))
 label_at("HOST A COURT",88,285,26)
 label_at("Up to four humans. Empty slots are filled by CPU players.",88,330,18,MUTED,490)
 button("HOST GAME",88,402,500,func():
  var error = net.host_game(initials if not initials.is_empty() else "ACE")
  if error == OK:
   net.selections = picks.duplicate()
   status = "Hosting on UDP 27888. Share your LAN address."
   screen = "lobby"
   show_lobby()
  else:
   status_label.text = "Cannot host: " + error_string(error),true)
 label_at("JOIN A COURT",690,172,26)
 label_at("HOST IP ADDRESS",690,226,16,GOLD)
 edit(address,"192.168.1.10",690,262,500,func(value): address = value.strip_edges())
 button("CONNECT",690,330,500,func():
  screen = "lobby"
  var error = net.join_game(address,initials if not initials.is_empty() else "ACE")
  status = "Connecting…" if error == OK else "Cannot connect: " + error_string(error)
  show_lobby(),true)
 label_at("LAN: connect to the host's local IP.\nINTERNET: the host must forward UDP 27888 and allow the game through their firewall.\n\nNo matchmaking or relay service is included.",690,420,19,MUTED,490)
 status_label = label_at("",88,580,18,GOLD,500)

func show_selection() -> void:
 screen = "selection"
 clear_ui()
 header("CHOOSE YOUR CREW", "TEAM SELECT")
 button("HOME: " + Teams.DATA[picks[0]].name,60,120,560,func(): selection_side = 0; show_selection(),selection_side == 0)
 button("AWAY: " + Teams.DATA[picks[1]].name,650,120,570,func(): selection_side = 1; show_selection(),selection_side == 1)
 draw_team_cards(false)
 label_at("%s  vs  %s" % [Teams.DATA[picks[0]].city,Teams.DATA[picks[1]].city],60,670,22)
 label_at("%d SECOND QUARTERS  •  %s" % [int(seconds),["EASY","NORMAL","HARD"][level]],60,710,16,MUTED)
 button("TIP OFF   →",940,680,280,func():
  if mode == "ladder":
   picks[1] = ladder_opponent()
  begin_match({"teams":picks,"seconds":seconds,"level":level}),true,60)

func draw_team_cards(networked: bool) -> void:
 for i in range(Teams.DATA.size()):
  var data: Dictionary = Teams.DATA[i]
  var x = 60 + (i % 4) * 296
  var y = 195 + (i / 4) * 223
  var selected = picks[selection_side] == i
  panel(x,y,274,205,Color("1b3044") if selected else Color("101e30"))
  var stripe = ColorRect.new()
  stripe.position = Vector2(x+1,y+1)
  stripe.size = Vector2(272,4)
  stripe.color = Teams.color_for(i)
  ui.add_child(stripe)
  label_at(data.city,x+16,y+16,14,MUTED)
  label_at(data.name,x+16,y+40,23,Teams.color_for(i))
  label_at("%s  /  %s" % data.players,x+16,y+80,14)
  var ratings: Array = data.ratings
  label_at("SPD %d   SHOT %d   DUNK %d" % [ratings[0][0],ratings[0][1],ratings[0][2]],x+16,y+108,13,MUTED)
  label_at("SPD %d   SHOT %d   DUNK %d" % [ratings[1][0],ratings[1][1],ratings[1][2]],x+16,y+130,13,MUTED)
  var team_index = i
  button("SELECTED" if selected else "SELECT",x+14,y+158,246,func():
   if networked:
    net.choose(team_index)
   else:
    picks[selection_side] = team_index
    show_selection(),selected,34)

func show_lobby() -> void:
 screen = "lobby"
 clear_ui()
 header("UP TO FOUR PLAYERS  /  UDP %d" % JamNetwork.PORT,"THE LOCKER ROOM")
 if not net.online:
  label_at(status,60,150,22,GOLD,1100)
  button("RECONNECT",60,240,270,show_network,true)
  return
 selection_side = net.local_slot / 2
 picks = net.selections.duplicate()
 for slot in range(4):
  var text = "CPU"
  var ready = true
  for id in net.members:
   var member: Dictionary = net.members[id]
   if member.slot == slot:
    text = member.name + (" (YOU)" if id == multiplayer.get_unique_id() else "")
    ready = member.ready
  label_at("%s  ·  %s  ·  %s" % ["HOME" if slot < 2 else "AWAY",text,"READY" if ready else "WAITING"],60+(slot%2)*590,112+(slot/2)*32,17,GOLD if ready else MUTED)
 draw_team_cards(true)
 status_label = label_at(status,60,665,16,MUTED,830)
 if net.hosting:
  var start_button = button("START MATCH   →",940,680,280,func(): net.start_game({"seconds":seconds,"level":level,"big_heads":big_heads,"infinite_turbo":infinite_turbo}),true,60)
  start_button.disabled = not net.can_start()
  label_at("Host starts once every human is ready.",60,722,15,MUTED)
 else:
  button("TOGGLE READY",940,680,280,net.ready_up,true,60)
  label_at("First player on each side chooses the team. Wait for host to start.",60,722,15,MUTED)

func begin_match(settings: Dictionary) -> void:
 picks = settings.teams.duplicate()
 game.start(picks[0],picks[1],settings.get("seconds",seconds),settings.get("level",level))
 game.big_heads = settings.get("big_heads",big_heads)
 game.infinite_turbo = settings.get("infinite_turbo",infinite_turbo)
 screen = "game"
 paused = false
 saved_result = false
 last_event = -1
 controlled = [0,2]
 rendered_positions = []
 arena.reset_camera()
 clear_ui()

func show_options() -> void:
 screen = "options"
 clear_ui()
 header("TUNE YOUR GAME", "OPTIONS")
 panel(60,150,1160,555)
 label_at("PLAYER INITIALS",92,180,18,GOLD)
 edit(initials,"ACE",92,218,420,func(value): set_initials(value))
 label_at("QUARTER LENGTH",92,305,18,GOLD)
 for i in range(3):
  var duration: float = [60.0,120.0,180.0][i]
  button("%d MIN" % int(duration/60),92+i*145,345,130,func(): seconds = duration; show_options(),seconds == duration)
 label_at("CPU DIFFICULTY",92,435,18,GOLD)
 for i in range(3):
  var difficulty = i
  button(["EASY","NORMAL","HARD"][i],92+i*145,475,130,func(): level = difficulty; show_options(),level == i)
 button("BIG HEADS: " + ("ON" if big_heads else "OFF"),666,218,490,func(): big_heads = not big_heads; show_options(),big_heads)
 button("INFINITE TURBO: " + ("ON" if infinite_turbo else "OFF"),666,300,490,func(): infinite_turbo = not infinite_turbo; show_options(),infinite_turbo)
 button("SOUND: " + ("OFF" if muted else "ON"),666,382,490,func(): muted = not muted; show_options(),not muted)
 label_at("House rules apply to the whole court.\nThe host supplies network match settings.",666,478,19,MUTED,470)
 label_at("Records are saved locally with your initials.",92,608,17,MUTED)

func show_help() -> void:
 screen = "help"
 clear_ui()
 header("THREE BUTTONS. ENDLESS HIGHLIGHTS.","HOW TO PLAY")
 panel(60,150,555,540)
 panel(645,150,575,540)
 label_at("PLAYER ONE",88,176,22,GOLD)
 label_at("MOVE     W A S D\nSHOOT / BLOCK     J\nPASS / STEAL     K\nTURBO     SPACE\nSWITCH ATHLETE     TAB",88,226,21,INK)
 label_at("PLAYER TWO — LOCAL VERSUS",88,430,20,GOLD)
 label_at("MOVE     ARROWS\nSHOOT / BLOCK     NUMPAD 1\nPASS / STEAL     NUMPAD 2\nTURBO     NUMPAD 0    •    SWITCH     NUMPAD 3",88,475,18)
 label_at("GAMEPAD",675,176,22,GOLD)
 label_at("Left stick to move • A to shoot / block\nX to pass / steal • RB or RT for turbo\nLB to switch your active athlete",675,222,19,INK,510)
 label_at("MAKE THE HIGHLIGHT REEL",675,330,22,GOLD)
 label_at("Tap SHOOT to fake; release jump shots at the gold mark.\nRun + short SHOOT hold: layup. Hold longer close for a dunk.\nAdd TURBO for a super dunk; PASS mid-dunk to dish.\nTURBO + PASS: faster pass / lob to a teammate near the rim.\nDefense: SHOOT blocks; PASS steals or intercepts.\nTURBO + PASS shoves. CPU teammate has the ball?\nPASS calls for it; hold/release SHOOT orders their shot.\nThree unanswered baskets by one athlete ignite FIRE.\nFire survives misses; an opponent basket ends it.\nQ4 / overtime: specialty dunks can shatter a backboard.\nTip-off: tap SHOOT as the tossed ball rises.\nESC: pause offline / leave menu online. M: mute.",675,378,16,INK,510)
 label_at("Network players use player-one controls. Missing teammates are controlled by the CPU.",60,723,16,MUTED)

func show_results() -> void:
 if screen == "results":
  return
 screen = "results"
 clear_ui()
 var won: bool = game.score[0] > game.score[1]
 if not saved_result:
  if net.online:
   var side = net.local_slot / 2
   won = game.score[side] > game.score[1-side]
  profile["wins" if won else "losses"] += 1
  profile.best = maxi(profile.best,game.score[net.local_slot / 2 if net.online else 0])
  if mode == "ladder" and won:
   tournament_wins += 1
   if tournament_round == 6:
    profile.championships += 1
  save_profile()
  saved_result = true
 header("FINAL BUZZER", "COURT CONQUERED" if won else "RUN IT BACK")
 label_at("%s   %d  —  %d   %s" % [Teams.DATA[picks[0]].name,game.score[0],game.score[1],Teams.DATA[picks[1]].name],60,137,34,GOLD)
 panel(60,214,1160,360)
 label_at("ATHLETE",88,235,17,MUTED)
 var stat_columns = [580,670,780,890,980,1070,1150]
 for column in range(7):
  label_at(["PTS","FG","DUNKS","STL","BLK","REB","GT"][column],stat_columns[column],235,17,MUTED)
 for i in range(4):
  var s: Dictionary = game.stats[i]
  label_at(Teams.DATA[picks[i/2]].players[i%2],88,290+i*60,22,Teams.color_for(picks[i/2]))
  var values = [str(s.points),"%d/%d" % [s.made,s.attempts],str(s.dunks),str(s.steals),str(s.blocks),str(s.rebounds),str(s.goaltends)]
  for column in range(7):
   label_at(values[column],stat_columns[column],292+i*60,20)
 if mode == "ladder" and won and tournament_round < 6 and not net.online:
  label_at("ARCADE LADDER   •   %d / 7 TEAMS DEFEATED" % tournament_wins,60,625,20,GOLD)
  button("NEXT CHALLENGER   →",870,652,350,func(): tournament_round += 1; picks[1] = ladder_opponent(); begin_match({"teams":picks,"seconds":seconds,"level":mini(2,level+tournament_round/3)}),true,60)
 elif net.online and not net.hosting:
  label_at("The host can start the rematch. You can return to the menu at any time.",60,630,20,MUTED,780)
 else:
  button("REMATCH   →",940,652,280,func():
   if net.hosting:
    net.start_game(net.options)
   else:
    begin_match({"teams":picks,"seconds":seconds,"level":level}),true,60)
 if mode == "ladder" and tournament_round == 6 and won:
  label_at("ALL SEVEN TEAMS DEFEATED. YOU ARE THE CHAMPION!",60,600,22,GOLD)

func ladder_opponent() -> int:
 return posmod(picks[0]+tournament_round+1,Teams.DATA.size())

func show_disconnected() -> void:
 paused = true
 panel(330,265,620,230)
 label_at("CONNECTION CLOSED",365,293,29,GOLD)
 label_at(status,365,345,18,INK,545)
 button("RETURN TO MENU",365,423,545,show_menu,true)

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_M:
   muted = not muted
  if event.keycode == KEY_ESCAPE and screen == "game":
   if net.online:
    if ui.get_child_count() == 0:
     panel(390,300,500,170)
     label_at("NETWORK MATCH CONTINUES",420,322,22,GOLD)
     button("KEEP PLAYING",420,391,205,clear_ui)
     button("LEAVE MATCH",640,391,220,show_menu)
    else:
     clear_ui()
   else:
    paused = not paused
    clear_ui()
    if paused:
     panel(390,280,500,225)
     label_at("TIME OUT",420,305,32,GOLD)
     button("RESUME",420,375,440,func(): paused = false; clear_ui(),true)
     button("END GAME",420,436,440,show_menu)

func read_command(index: int) -> Dictionary:
 var prefix = "p%d_" % index
 var move = Input.get_vector(prefix+"left",prefix+"right",prefix+"up",prefix+"down")
 var turbo = Input.is_action_pressed(prefix+"turbo")
 if Input.get_connected_joypads().has(index):
  var stick = Vector2(Input.get_joy_axis(index,JOY_AXIS_LEFT_X),Input.get_joy_axis(index,JOY_AXIS_LEFT_Y))
  if stick.length() > 0.18:
   move = stick.limit_length()
  turbo = turbo or Input.get_joy_axis(index,JOY_AXIS_TRIGGER_RIGHT) > 0.3
 return {"move":move,"shoot":Input.is_action_pressed(prefix+"shoot"),"tip_jump":game.tipoff.get("active",false) and Input.is_action_just_pressed(prefix+"shoot"),"pass":Input.is_action_just_pressed(prefix+"pass"),"turbo":turbo}

func _physics_process(delta: float) -> void:
 visual_time += delta
 if screen == "game" and not paused:
  if net.online:
   # Inputs are sent each physics frame; state is broadcast at 20 Hz.
   var command = read_command(0)
   net.send_command(command)
   if net.hosting:
    game.tick(delta,net.commands())
    send_elapsed += delta
    if send_elapsed >= 0.05:
     send_elapsed = 0.0
     net.broadcast(game.snapshot())
  else:
   var commands = {}
   var count = 2 if local_two else 1
   if not OS.get_cmdline_user_args().has("--autoplay"):
    for p in range(count):
     if Input.is_action_just_pressed("p%d_switch" % p):
      controlled[p] = (controlled[p]/2)*2 + (1-controlled[p]%2)
     commands[controlled[p]] = read_command(p)
   game.tick(delta,commands)
  if game.event_id != last_event:
   last_event = game.event_id
   if game.event_kind in ["score","dunk","shatter"]:
    shake = 0.45 if game.event_kind == "shatter" else 0.18
   play_sound(game.event_kind)
  if game.phase == "finished":
   if net.hosting:
    net.broadcast(game.snapshot())
   show_results()
 # Continue final snapshots while result screen is open so a lost packet cannot strand clients.
 elif screen == "results" and net.hosting:
  send_elapsed += delta
  if send_elapsed > 0.25:
   send_elapsed = 0.0
   net.broadcast(game.snapshot())
 if OS.get_cmdline_user_args().has("--test-client") and net.online and not net.active_match and net.members.size() > 1:
  var id = multiplayer.get_unique_id()
  if net.members.has(id) and not net.members[id].ready:
   net.ready_up()
 if OS.get_cmdline_user_args().has("--test-host") and net.members.size() > 1 and net.can_start() and not net.active_match:
  net.start_game({"seconds":5.0,"level":1})
 shake = maxf(0,shake-delta)
 queue_redraw()

func load_profile() -> void:
 var file = ConfigFile.new()
 if file.load("user://records.cfg") == OK:
  initials = file.get_value("player","initials","ACE")
  for key in profile:
   profile[key] = int(file.get_value(initials,key,0))

func save_profile() -> void:
 var file = ConfigFile.new()
 file.load("user://records.cfg")
 file.set_value("player","initials",initials)
 for key in profile:
  file.set_value(initials,key,profile[key])
 file.save("user://records.cfg")

func make_sounds() -> void:
 var noise = RandomNumberGenerator.new()
 noise.seed = 1993
 for entry in [["shot",620,0.08],["pass",390,0.06],["score",880,0.25],["dunk",140,0.2],["steal",280,0.12],["block",120,0.18],["miss",190,0.1],["whistle",1100,0.30],["catch",440,0.05],["start",660,0.16],["shatter",85,0.7]]:
  var sample = AudioStreamWAV.new()
  sample.format = AudioStreamWAV.FORMAT_16_BITS
  sample.mix_rate = 22050
  var frames = int(22050*entry[2])
  var bytes = PackedByteArray()
  bytes.resize(frames*2)
  for frame in range(frames):
   var t = float(frame)/22050
   var envelope = pow(1.0-float(frame)/frames,2)
   var wave = sin(TAU*float(entry[1])*t*(1.0+t*0.8)) * envelope * 0.16
   if entry[0] == "shatter":
    wave = (noise.randf_range(-1,1)*0.30+sin(TAU*2960*t)*sin(TAU*130*t)*0.12)*exp(-t*6)+sin(TAU*85*t)*exp(-t*25)*0.18
   bytes.encode_s16(frame*2,int(wave*32767))
  sample.data = bytes
  sounds[entry[0]] = sample

func play_sound(kind: String) -> void:
 if not muted and sounds.has(kind):
  sound_player.stream = sounds[kind]
  sound_player.play()

func text_at(text: String, pos: Vector2, size: int = 20, color: Color = INK, centered = false) -> void:
 var origin = pos
 if centered:
  origin.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2
 draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
 if font == null:
  return
 if screen == "game" or screen == "results":
  draw_arena()
  if screen == "game":
   draw_hud()
 else:
  draw_rect(Rect2(0,0,1280,800),BG)
  for x in range(0,1280,40):
   draw_line(Vector2(x,0),Vector2(x,800),Color(0.08,0.15,0.23,0.3))
  if screen == "menu":
   # Hero medallion with oversized ball, hoop, and court markings.
   draw_arc(Vector2(936,350),219,0,TAU,100,Color("233c51"),2,true)
   draw_arc(Vector2(936,350),195,0,TAU,100,Color("18354b"),1,true)
   draw_circle(Vector2(936,350),150,Color("ff7a3e"))
   draw_arc(Vector2(936,350),150,0,TAU,90,GOLD,4,true)
   draw_line(Vector2(786,350),Vector2(1086,350),Color("6d3629"),5,true)
   draw_line(Vector2(936,200),Vector2(936,500),Color("6d3629"),5,true)
   draw_arc(Vector2(794,350),165,-0.93,0.93,45,Color("6d3629"),5,true)
   draw_arc(Vector2(1078,350),165,PI-0.93,PI+0.93,45,Color("6d3629"),5,true)
   text_at("EST. 2026",Vector2(936,161),16,MUTED,true)
   text_at("★  ARCADE BASKETBALL  ★",Vector2(936,548),16,GOLD,true)

func draw_arena() -> void:
 # A true 3D viewport is composited between the existing HUD and controls.
 draw_rect(Rect2(0,133,1280,600),BG)
 if is_instance_valid(arena):
  draw_texture_rect(arena.get_texture(),Rect2(0,133,1280,600),false)
  for i in range(game.players.size()):
   var indicator: Dictionary = arena.player_indicator(i)
   if screen == "game" and indicator.visible:
    var edge: Vector2 = indicator.point+Vector2(0,133)
    var direction: Vector2 = indicator.direction
    var side = direction.orthogonal()
    var color = Teams.color_for(game.teams[i/2])
    draw_colored_polygon(PackedVector2Array([edge+direction*12,edge-direction*9+side*8,edge-direction*9-side*8]),color)
    text_at("%d %s" % [i+1,Teams.DATA[game.teams[i/2]].players[i%2]],edge-direction*48+Vector2(0,5),12,color,true)
   var player: Dictionary = game.players[i]
   if player.charge <= 0:
    continue
   var point: Vector2 = arena.shot_meter_position(i)+Vector2(0,133)
   draw_rect(Rect2(point-Vector2(29,5),Vector2(58,10)),BG)
   draw_rect(Rect2(point-Vector2(27,3),Vector2(54*minf(player.charge/1.16,1),6)),GOLD)
   draw_line(point+Vector2(0,-6),point+Vector2(0,6),INK,2)

func draw_hud() -> void:
 draw_rect(Rect2(0,0,1280,133),Color("0d1b2c"))
 draw_rect(Rect2(0,130,1280,3),Color("34465e"))
 for side in range(2):
  var x = 56 if side == 0 else 890
  var color = Teams.color_for(game.teams[side])
  draw_rect(Rect2(x,24,5,79),color)
  text_at(Teams.DATA[game.teams[side]].city,Vector2(x+20,42),14,MUTED)
  text_at(Teams.DATA[game.teams[side]].name,Vector2(x+20,75),25,color)
  text_at("%02d" % game.score[side],Vector2(x+265,93),53,INK)
  if game.on_fire(side):
   text_at("FIRE: "+str(Teams.DATA[game.teams[side]].players[game.fire_player%2]),Vector2(x+20,105),15,GOLD)
  else:
   for pip in range(3):
    draw_circle(Vector2(x+27+pip*18,100),5,color if pip < game.streak[side] else Color("334255"))
 text_at("OT %d" % game.overtime if game.overtime > 0 else "QUARTER %d" % game.quarter,Vector2(640,31),14,MUTED,true)
 var remaining = int(ceil(game.clock))
 text_at("%d:%02d" % [remaining/60,remaining%60],Vector2(640,83),44,INK,true)
 text_at("SHOT  %02d" % int(ceil(game.shot_clock)),Vector2(640,114),17,Color("ff7554") if game.shot_clock < 5 else GOLD,true)
 if game.tipoff.get("active",false):
  draw_rect(Rect2(445,225,390,58),Color(0.03,0.06,0.1,0.88))
  text_at("SHOOT TO JUMP AS THE BALL RISES",Vector2(640,246),15,INK,true)
  draw_rect(Rect2(470,260,340,7),Color("334255"))
  var progress = clampf((game.tipoff.time-MatchState.TIP_TOSS)/(MatchState.TIP_DECISION-MatchState.TIP_TOSS),0,1)
  draw_rect(Rect2(470,260,340*progress,7),GOLD)
  var mark = 470+340*(MatchState.TIP_IDEAL_JUMP-MatchState.TIP_TOSS)/(MatchState.TIP_DECISION-MatchState.TIP_TOSS)
  draw_line(Vector2(mark,256),Vector2(mark,271),INK,3)
 for i in range(4):
  var x = 70+i*307
  text_at("%s  ·  %s" % [Teams.DATA[game.teams[i/2]].players[i%2],"ON FIRE!" if game.is_player_on_fire(i) else "HEATING UP" if game.player_streak[i] == 2 else "TURBO"],Vector2(x,776),12,GOLD if game.player_streak[i] >= 2 else MUTED)
  draw_rect(Rect2(x,785,210,5),Color("263d52"))
  draw_rect(Rect2(x,785,210*game.players[i].turbo,5),Teams.color_for(game.teams[i/2]))
 if game.banner_time > 0:
  var offset = Vector2(sin(visual_time*60)*shake*18,0)
  draw_rect(Rect2(Vector2(280,155)+offset,Vector2(720,62)),Color(0.03,0.06,0.1,0.88))
  text_at(game.banner,Vector2(640,197)+offset,30,GOLD,true)
 draw_rect(Rect2(250,692,780,32),Color(0.03,0.06,0.1,0.88))
 text_at("J  SHOOT / BLOCK    K  PASS / STEAL    SPACE  TURBO    TAB  SWITCH    ESC  MENU",Vector2(640,714),13,INK,true)

func set_initials(value: String) -> void:
 initials = value.to_upper().strip_edges().left(12)
 var records = ConfigFile.new()
 records.load("user://records.cfg")
 for key in profile:
  profile[key] = int(records.get_value(initials,key,0))
 save_profile()


func _process(delta: float) -> void:
 if not is_instance_valid(arena):
  return
 if screen != "game" and screen != "results":
  arena.render_target_update_mode = SubViewport.UPDATE_DISABLED
  return
 var positions: Array = []
 var ball_position: Vector2 = game.ball
 if net.online and not net.hosting:
  if rendered_positions.size() != game.players.size():
   rendered_positions = []
   for player in game.players:
    rendered_positions.append(player.pos)
   rendered_ball = game.ball
  var factor = 1.0-exp(-delta*24.0)
  for i in range(game.players.size()):
   var target: Vector2 = game.players[i].pos
   rendered_positions[i] = target if rendered_positions[i].distance_to(target) > 260 else rendered_positions[i].lerp(target,factor)
  rendered_ball = game.ball if rendered_ball.distance_to(game.ball) > 300 else rendered_ball.lerp(game.ball,factor)
  positions = rendered_positions
  ball_position = rendered_ball
 var active: Array = [net.local_slot] if net.online else ([controlled[0],controlled[1]] if local_two else [controlled[0]])
 arena.present(game,positions,ball_position,active,delta,paused or screen == "results")
 queue_redraw()
