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
var show_shot_percentage = true
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
var snapshot_received_time: float = 0.0
var turbo_sound_cooldown: float = 0.0
var font: Font
var sounds: Dictionary = {}
var sound_players: Array = []
var sound_player_idx: int = 0
var sound_player: AudioStreamPlayer
var status_label: Label
var last_lt: Array = [0.0, 0.0, 0.0, 0.0]

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
   game.apply_snapshot(data)
   snapshot_received_time = visual_time)
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
 sound_players.clear()
 for i in range(8):
  var sp = AudioStreamPlayer.new()
  add_child(sp)
  sound_players.append(sp)
 sound_player = sound_players[0]
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
 var mapping = {
  "up": [KEY_W, KEY_UP],
  "down": [KEY_S, KEY_DOWN],
  "left": [KEY_A, KEY_LEFT],
  "right": [KEY_D, KEY_RIGHT],
  "shoot": [KEY_J, KEY_KP_1],
  "pass": [KEY_K, KEY_KP_2],
  "shove": [KEY_L, KEY_KP_5],
  "turbo": [KEY_SEMICOLON, KEY_KP_0],
  "switch": [KEY_F, KEY_KP_3],
  "spin": [KEY_APOSTROPHE, KEY_KP_6]
 }
 var dpad_buttons = {
  "up": JOY_BUTTON_DPAD_UP,
  "down": JOY_BUTTON_DPAD_DOWN,
  "left": JOY_BUTTON_DPAD_LEFT,
  "right": JOY_BUTTON_DPAD_RIGHT
 }
 var action_buttons = {
  "shoot": [JOY_BUTTON_X, JOY_BUTTON_Y],
  "pass": [JOY_BUTTON_A, JOY_BUTTON_B],
  "turbo": [JOY_BUTTON_RIGHT_SHOULDER],
  "switch": [JOY_BUTTON_LEFT_SHOULDER],
  "shove": [JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_RIGHT_STICK],
  "spin": [JOY_BUTTON_B, JOY_BUTTON_Y, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_LEFT_STICK]
 }
 for action in mapping:
  for p in range(4):
   var name_action = "p%d_%s" % [p, action]
   if not InputMap.has_action(name_action):
    InputMap.add_action(name_action)
   if p < mapping[action].size():
    var key = InputEventKey.new()
    key.physical_keycode = mapping[action][p]
    InputMap.action_add_event(name_action, key)
   if p == 0:
    if action == "turbo":
     var space_key = InputEventKey.new()
     space_key.physical_keycode = KEY_SPACE
     InputMap.action_add_event(name_action, space_key)
    elif action == "switch":
     var tab_key = InputEventKey.new()
     tab_key.physical_keycode = KEY_TAB
     InputMap.action_add_event(name_action, tab_key)
    elif action == "spin":
     for alt_key in [KEY_P, KEY_O, KEY_I, KEY_H, KEY_U, KEY_KP_ENTER]:
      var k = InputEventKey.new()
      k.physical_keycode = alt_key
      InputMap.action_add_event(name_action, k)
   if dpad_buttons.has(action):
    var button = InputEventJoypadButton.new()
    button.device = p
    button.button_index = dpad_buttons[action]
    InputMap.action_add_event(name_action, button)
   if action_buttons.has(action):
    for btn_index in action_buttons[action]:
     var button = InputEventJoypadButton.new()
     button.device = p
     button.button_index = btn_index
     InputMap.action_add_event(name_action, button)
   if action == "turbo":
    var motion = InputEventJoypadMotion.new()
    motion.device = p
    motion.axis = JOY_AXIS_TRIGGER_RIGHT
    motion.axis_value = 1.0
    InputMap.action_add_event(name_action, motion)
   elif action == "switch":
    var motion = InputEventJoypadMotion.new()
    motion.device = p
    motion.axis = JOY_AXIS_TRIGGER_LEFT
    motion.axis_value = 1.0
    InputMap.action_add_event(name_action, motion)
 if not InputMap.action_get_events("ui_accept").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A):
  var btn_a = InputEventJoypadButton.new()
  btn_a.device = -1
  btn_a.button_index = JOY_BUTTON_A
  InputMap.action_add_event("ui_accept", btn_a)
 if not InputMap.action_get_events("ui_cancel").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B):
  var btn_b = InputEventJoypadButton.new()
  btn_b.device = -1
  btn_b.button_index = JOY_BUTTON_B
  InputMap.action_add_event("ui_cancel", btn_b)


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

func header(kicker: String, title: String) -> Button:
 label_at(kicker,60,28,15,GOLD)
 label_at(title,58,48,42)
 return button("← MENU",1080,40,140,show_menu)

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
 var qp_btn = button("QUICK PLAY   →",82,376,440,func(): mode = "solo"; local_two = false; show_selection(),true,58)
 button("LOCAL VERSUS",82,448,212,func(): mode = "local"; local_two = true; show_selection())
 button("ARCADE LADDER",308,448,214,func(): mode = "ladder"; local_two = false; tournament_round = 0; tournament_wins = 0; show_selection())
 button("NETWORK PLAY",82,510,440,show_network)
 button("HOW TO PLAY",82,574,212,show_help)
 button("OPTIONS",308,574,214,show_options)
 qp_btn.grab_focus()
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
 var tip_btn = button("TIP OFF   →",940,680,280,func():
  if mode == "ladder":
   picks[1] = ladder_opponent()
  begin_match({"teams":picks,"seconds":seconds,"level":level}),true,60)
 tip_btn.grab_focus()

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
 var back_btn = header("ARCADE CONTROLS. ENDLESS HIGHLIGHTS.","HOW TO PLAY")
 panel(60,150,555,540)
 panel(645,150,575,540)
 label_at("PLAYER ONE",88,176,22,GOLD)
 label_at("MOVE     W A S D\nSHOOT / BLOCK     J\nPASS / STEAL     K\nSHOVE (TURBO+STEAL)     L\nTURBO     ;  (or SPACE)\nSPIN / ELBOWS     '  (or P / O / I / H)\nSWITCH ATHLETE     F  (or TAB)",88,214,18,INK)
 label_at("PLAYER TWO — LOCAL VERSUS",88,430,20,GOLD)
 label_at("MOVE     ARROWS\nSHOOT / BLOCK     NUMPAD 1\nPASS / STEAL     NUMPAD 2\nTURBO     NUMPAD 0    •    SWITCH     NUMPAD 3",88,475,18)
 label_at("GAMEPAD",675,172,21,GOLD)
 label_at("Left stick or D-pad moves  •  Start: Pause\nRT (Right Trigger) or RB: Boost / Turbo\n4 Face Buttons (Right Thumb):\n  X: Shoot / Layup / Dunk / Fake  •  Y: Block / Rebound / Shove\n  A: Pass / Dish / Alley-Oop Lob  •  B: Steal / Shove / Spin\n  Right / Left Stick (RS/LS): Spin Move / Elbow Clearout\nLB or LT: Switch athlete",675,202,15,INK,515)
 label_at("MAKE THE HIGHLIGHT REEL",675,330,22,GOLD)
 label_at("Tap SHOOT to fake; release jump shots at the gold mark.\nRun + short SHOOT hold: layup. Hold longer close for a dunk.\nAdd TURBO for a super dunk; PASS mid-dunk to dish.\nAlley-oop: receiver SHOOT, passer TURBO + PASS.\nDefense: SHOOT blocks; PASS steals or intercepts.\nTURBO + PASS shoves. CPU teammate has the ball?\nSHOOT jumps + starts CPU shot; quick TURBO + PASS lobs.\nThree unanswered baskets by one athlete ignite FIRE.\nFire survives misses; an opponent basket ends it.\nQ4 / overtime: specialty dunks can shatter a backboard.\nTip-off: tap SHOOT as the tossed ball rises.\nESC: pause offline / leave menu online. M: mute.",675,378,16,INK,510)
 label_at("Network players use player-one controls. Missing teammates are controlled by the CPU.",60,723,16,MUTED)
 back_btn.grab_focus()

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
 var stat_columns = [530,610,705,790,875,960,1045,1130]
 for column in range(8):
  label_at(["PTS","FG","DUNKS","AST","STL","BLK","REB","GT"][column],stat_columns[column],235,17,MUTED)
 for i in range(4):
  var s: Dictionary = game.stats[i]
  label_at(Teams.DATA[picks[i/2]].players[i%2],88,290+i*60,22,Teams.color_for(picks[i/2]))
  var values = [str(s.points),"%d/%d" % [s.made,s.attempts],str(s.dunks),str(s.get("assists", 0)),str(s.steals),str(s.blocks),str(s.rebounds),str(s.goaltends)]
  for column in range(8):
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

func toggle_pause() -> void:
 if screen != "game":
  return
 if net.online:
  if ui.get_child_count() == 0:
   panel(390,300,500,170)
   label_at("NETWORK MATCH CONTINUES",420,322,22,GOLD)
   var keep_btn = button("KEEP PLAYING",420,391,205,clear_ui)
   button("LEAVE MATCH",640,391,220,show_menu)
   keep_btn.grab_focus()
  else:
   clear_ui()
 else:
  paused = not paused
  clear_ui()
  if paused:
   panel(390,280,500,225)
   label_at("TIME OUT",420,305,32,GOLD)
   var resume_btn = button("RESUME",420,375,440,func(): paused = false; clear_ui(),true)
   button("END GAME",420,436,440,show_menu)
   resume_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_M:
   muted = not muted
  if event.keycode == KEY_O:
   show_shot_percentage = not show_shot_percentage
  if event.keycode == KEY_ESCAPE and screen == "game":
   toggle_pause()
 elif event is InputEventJoypadButton and event.pressed:
  if event.button_index == JOY_BUTTON_START:
   if screen == "game":
    toggle_pause()
   elif screen == "selection":
    if mode == "ladder":
     picks[1] = ladder_opponent()
    begin_match({"teams":picks,"seconds":seconds,"level":level})
   elif screen == "results":
    if mode == "ladder" and tournament_round < 6 and game.score[0] > game.score[1]:
     tournament_round += 1
     picks[1] = ladder_opponent()
     begin_match({"teams":picks,"seconds":seconds,"level":mini(2,level+tournament_round/3)})
    elif not net.online or net.hosting:
     begin_match({"teams":picks,"seconds":seconds,"level":level})
  elif event.button_index == JOY_BUTTON_BACK:
   if screen == "game" and paused:
    toggle_pause()
   elif screen in ["selection", "options", "help", "network", "results"]:
    show_menu()
  elif event.button_index == JOY_BUTTON_B and screen == "game" and paused:
   toggle_pause()

func read_command(index: int) -> Dictionary:
 var prefix = "p%d_" % index
 var move = Input.get_vector(prefix+"left",prefix+"right",prefix+"up",prefix+"down")
 var turbo = Input.is_action_pressed(prefix+"turbo")
 var shove = Input.is_action_just_pressed(prefix+"shove")
 var pass_pressed = Input.is_action_just_pressed(prefix+"pass")
 var spin = Input.is_action_just_pressed(prefix+"spin")
 if shove:
  turbo = true
  pass_pressed = true
 var joypads = Input.get_connected_joypads()
 var joy_id = joypads[index] if index < joypads.size() else index
 if joypads.has(joy_id):
  var stick = Vector2(Input.get_joy_axis(joy_id,JOY_AXIS_LEFT_X),Input.get_joy_axis(joy_id,JOY_AXIS_LEFT_Y))
  if stick.length() > 0.18:
   move = stick.limit_length()
  if Input.get_joy_axis(joy_id,JOY_AXIS_TRIGGER_RIGHT) > 0.2:
   turbo = true
  if Input.is_joy_button_pressed(joy_id, JOY_BUTTON_RIGHT_STICK) or Input.is_joy_button_pressed(joy_id, JOY_BUTTON_LEFT_STICK):
   spin = true
 return {"move":move,"shoot":Input.is_action_pressed(prefix+"shoot"),"jump_press":Input.is_action_just_pressed(prefix+"shoot"),"pass":pass_pressed,"turbo":turbo,"shove":shove,"spin":spin}

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
     var joypads = Input.get_connected_joypads()
     var joy_id = joypads[p] if p < joypads.size() else p
     var lt_pressed = false
     if joypads.has(joy_id):
      var lt_val = Input.get_joy_axis(joy_id, JOY_AXIS_TRIGGER_LEFT)
      lt_pressed = lt_val > 0.3 and last_lt[p] <= 0.3
      last_lt[p] = lt_val
     if Input.is_action_just_pressed("p%d_switch" % p) or lt_pressed:
      controlled[p] = (controlled[p]/2)*2 + (1-controlled[p]%2)
     commands[controlled[p]] = read_command(p)
   game.tick(delta,commands)
  var p0_cmd = read_command(0)
  turbo_sound_cooldown = maxf(0.0, turbo_sound_cooldown - delta)
  if p0_cmd.turbo and p0_cmd.move.length() > 0.25 and turbo_sound_cooldown <= 0.0:
   play_sound("turbo")
   turbo_sound_cooldown = 1.3

  if game.event_id != last_event:
   last_event = game.event_id
   if game.event_kind in ["score","dunk","shatter","fire"]:
    shake = 0.45 if game.event_kind == "shatter" else 0.18
   if game.event_kind == "whistle" and (game.banner.contains("FINAL") or game.banner.contains("CLOCK")):
    play_sound("buzzer")
   else:
    play_sound(game.event_kind)
   if game.event_kind in ["dunk","shatter","fire"] or (game.event_kind == "score" and game.flight.get("super_dunk",false)):
    play_sound("cheer")
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
 var sound_defs = [
  ["shot",0.10],["pass",0.08],["score",0.26],["dunk",0.44],["steal",0.14],
  ["block",0.22],["miss",0.30],["whistle",0.38],["catch",0.08],["start",0.18],
  ["shatter",0.75],["buzzer",0.65],["fire",0.55],["cheer",0.60],["turbo",0.22]
 ]
 for def in sound_defs:
  var kind: String = def[0]
  var duration: float = def[1]
  var sample = AudioStreamWAV.new()
  sample.format = AudioStreamWAV.FORMAT_16_BITS
  sample.mix_rate = 22050
  var frames = int(22050.0*duration)
  var bytes = PackedByteArray()
  bytes.resize(frames*2)
  for frame in range(frames):
   var t = float(frame)/22050.0
   var progress = float(frame)/float(frames)
   var wave = 0.0
   match kind:
    "score":
     var net_friction = (noise.randf_range(-1.0,1.0)*0.30+sin(TAU*3400.0*t)*0.12)*exp(-t*16.0)
     var airy_whip = sin(TAU*420.0*(1.0+t*2.0)*t)*exp(-t*22.0)*0.14
     wave = net_friction+airy_whip
    "dunk":
     var sub_bass = sin(TAU*maxf(28.0,58.0-t*45.0)*t)*exp(-t*7.5)*0.38
     var rim_snap = (sin(TAU*480.0*t)*0.18+sin(TAU*820.0*t)*0.14)*exp(-t*24.0)
     var slam_crunch = noise.randf_range(-1.0,1.0)*exp(-t*32.0)*0.22
     wave = sub_bass+rim_snap+slam_crunch
    "miss":
     var iron_ring = (sin(TAU*840.0*t)*0.28+sin(TAU*1380.0*t)*0.18+sin(TAU*2200.0*t)*0.08)*exp(-t*16.0)
     var wood_thud = sin(TAU*170.0*t)*exp(-t*28.0)*0.14
     wave = iron_ring+wood_thud
    "shatter":
     var glass = (noise.randf_range(-1.0,1.0)*0.32+sin(TAU*3100.0*t)*sin(TAU*150.0*t)*0.14)*exp(-t*5.5)
     var bass = sin(TAU*52.0*t)*exp(-t*18.0)*0.28
     wave = glass+bass
    "fire":
     var burst = noise.randf_range(-1.0,1.0)*exp(-t*8.5)*(0.28+0.15*sin(TAU*20.0*t))
     var roar = (sin(TAU*110.0*t)*0.20+sin(TAU*65.0*t)*0.18)*exp(-t*4.2)
     var sparks = noise.randf_range(-1.0,1.0)*sin(TAU*3600.0*t)*exp(-t*7.5)*0.12
     wave = burst+roar+sparks
    "whistle":
     var flutter = 1.0+0.12*sin(TAU*18.0*t)
     var tone = (sin(TAU*2150.0*flutter*t)*0.18+sin(TAU*2580.0*flutter*t)*0.14)
     wave = tone*minf(t*35.0,1.0)*exp(-t*3.6)
    "buzzer":
     var sq1 = 1.0 if sin(TAU*165.0*t) > 0.0 else -1.0
     var sq2 = 1.0 if sin(TAU*248.0*t) > 0.0 else -1.0
     var sq3 = 1.0 if sin(TAU*330.0*t) > 0.0 else -1.0
     wave = (sq1*0.16+sq2*0.11+sq3*0.06)*minf(t*40.0,1.0)*clampf((duration-t)*8.0,0.0,1.0)
    "cheer":
     var swell = sin(clampf(progress,0.0,1.0)*PI)
     wave = (noise.randf_range(-1.0,1.0)*0.20+sin(TAU*280.0*t)*0.05)*swell
    "turbo":
     var freq = lerpf(300.0,920.0,progress)
     wave = (sin(TAU*freq*t)*0.12+noise.randf_range(-1.0,1.0)*0.15)*sin(progress*PI)
    "steal":
     wave = (noise.randf_range(-1.0,1.0)*0.24+sin(TAU*440.0*t)*0.14)*exp(-t*26.0)
    "block":
     wave = (sin(TAU*95.0*t)*0.32+noise.randf_range(-1.0,1.0)*0.24)*exp(-t*20.0)
    "pass":
     wave = (sin(TAU*320.0*t)*0.20+noise.randf_range(-1.0,1.0)*0.09)*exp(-t*35.0)
    "shot":
     wave = sin(TAU*520.0*t*(1.0+t*0.6))*exp(-t*26.0)*0.22
    "catch":
     wave = sin(TAU*180.0*t)*exp(-t*40.0)*0.24
    "start":
     wave = sin(TAU*660.0*t*(1.0+t*0.8))*pow(1.0-progress,2)*0.18
    _:
     wave = sin(TAU*440.0*t)*pow(1.0-progress,2)*0.16
   wave = clampf(wave,-0.98,0.98)
   bytes.encode_s16(frame*2,int(wave*32767.0))
  sample.data = bytes
  sounds[kind] = sample

func play_sound(kind: String) -> void:
 if not muted and sounds.has(kind) and sound_players.size() > 0:
  var sp: AudioStreamPlayer = sound_players[sound_player_idx]
  sound_player_idx = (sound_player_idx+1)%sound_players.size()
  sp.stream = sounds[kind]
  sp.play()

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
  if show_shot_percentage and game.last_shot_feedback.size() > 0:
   var age = game.elapsed - game.last_shot_feedback.get("time", 0.0)
   if age >= 0.0 and age < 1.35:
    var shooter_idx: int = game.last_shot_feedback.get("shooter", 0)
    var badge_pos: Vector2 = arena.shot_badge_position(shooter_idx) + Vector2(0, 133)
    badge_pos.y -= age * 18.0
    var alpha = clampf(1.0 - (age - 0.95) / 0.40, 0.0, 1.0) if age > 0.95 else 1.0
    var pct: float = game.last_shot_feedback.get("percentage", 0.0)
    var quality: String = game.last_shot_feedback.get("quality", "GOOD")
    var is_dunk: bool = game.last_shot_feedback.get("dunk", false)
    var contest: float = game.last_shot_feedback.get("contest_level", 0.0)
    var badge_text = "%d%% DUNK" % int(pct) if is_dunk else ("%d%% OPEN" % int(pct) if contest < 0.2 else ("%d%% SMOTHERED" % int(pct) if contest > 0.55 else "%d%% %s" % [int(pct), quality]))
    var badge_color = Color(0.2, 0.9, 0.45, alpha) if pct >= 70.0 else (Color(1.0, 0.8, 0.2, alpha) if pct >= 50.0 else Color(1.0, 0.4, 0.3, alpha))
    var text_size = font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
    var box_w = text_size.x + 18
    var box_rect = Rect2(badge_pos - Vector2(box_w * 0.5, 12), Vector2(box_w, 22))
    draw_rect(box_rect, Color(0.04, 0.08, 0.14, 0.88 * alpha))
    draw_rect(box_rect, badge_color, false, 1.5)
    text_at(badge_text, badge_pos + Vector2(0, 5), 13, badge_color, true)

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
  if game.team_fire_timer[side] > 0.0:
   text_at("TEAM ZONE: %02d" % int(ceil(game.team_fire_timer[side])),Vector2(x+20,105),15,Color("ff8822"))
  elif game.on_fire(side):
   text_at("FIRE: "+str(Teams.DATA[game.teams[side]].players[game.fire_player%2]),Vector2(x+20,105),15,GOLD)
  else:
   for pip in range(3):
    draw_circle(Vector2(x+27+pip*18,100),5,color if pip < game.streak[side] else Color("334255"))
 draw_rect(Rect2(515,12,250,110),Color("08111c"))
 draw_rect(Rect2(515,12,250,110),Color("22364c"),false,1.5)
 var q_text = ("OVERTIME %d" % game.overtime) if game.overtime > 0 else ("QUARTER %d" % game.quarter)
 text_at(q_text,Vector2(640,31),13,GOLD,true)
 if game.clock < 10.0:
  var sec = int(game.clock)
  var tenths = int(fmod(game.clock * 10.0, 10.0))
  text_at("%02d.%d" % [sec, tenths],Vector2(640,78),42,Color("ff4c3b"),true)
 else:
  var remaining = int(ceil(game.clock))
  text_at("%d:%02d" % [remaining/60,remaining%60],Vector2(640,78),42,INK,true)
 if game.clock < 24.0:
  text_at("SHOT  --",Vector2(640,107),16,Color(0.55,0.6,0.68,0.7),true)
 elif game.shot_clock < 5.0:
  var sc_sec = int(game.shot_clock)
  var sc_tenths = int(fmod(game.shot_clock * 10.0, 10.0))
  text_at("SHOT  %d.%d" % [sc_sec, sc_tenths],Vector2(640,107),16,Color("ff4433"),true)
 else:
  text_at("SHOT  %02d" % int(ceil(game.shot_clock)),Vector2(640,107),16,GOLD,true)
 if game.tipoff.get("active",false):
  draw_rect(Rect2(445,225,390,58),Color(0.03,0.06,0.1,0.88))
  text_at("SHOOT TO JUMP AS THE BALL RISES",Vector2(640,246),15,INK,true)
  draw_rect(Rect2(470,260,340,7),Color("334255"))
  var progress = clampf((game.tipoff.time-MatchState.TIP_TOSS)/(MatchState.TIP_DECISION-MatchState.TIP_TOSS),0,1)
  draw_rect(Rect2(470,260,340*progress,7),GOLD)
  var mark = 470+340*(MatchState.TIP_IDEAL_JUMP-MatchState.TIP_TOSS)/(MatchState.TIP_DECISION-MatchState.TIP_TOSS)
  draw_line(Vector2(mark,256),Vector2(mark,271),INK,3)
 for i in range(4):
  var x = 50 + i * 298
  var team_idx = game.teams[i / 2]
  var team_color = Teams.color_for(team_idx)
  var is_burning = game.is_player_on_fire(i)
  var is_heating = game.player_streak[i] == 2
  var p_name = Teams.DATA[team_idx].players[i % 2]
  var bg_col = Color(0.24, 0.08, 0.04, 0.90) if is_burning else (Color(0.16, 0.12, 0.06, 0.88) if is_heating else Color(0.06, 0.10, 0.16, 0.88))
  var border_col = Color("ff772c") if is_burning else (GOLD if is_heating else Color("22364c"))
  var plate_rect = Rect2(x, 756, 284, 36)
  draw_rect(plate_rect, bg_col)
  draw_rect(plate_rect, border_col, false, 1.5)
  var status_text = "★ ON FIRE! ★" if is_burning else ("🔥 HEATING UP" if is_heating else "P%d" % (i + 1))
  var status_col = GOLD if (is_burning or is_heating) else team_color
  text_at(status_text, Vector2(x + 10, 771), 11, status_col)
  text_at(p_name, Vector2(x + 95, 771), 12, INK)
  var turbo_bg = Rect2(x + 10, 778, 264, 8)
  draw_rect(turbo_bg, Color("14202e"))
  var turbo_w = 264.0 * game.players[i].turbo
  if turbo_w > 0:
   var turbo_fill_color = Color("ff5522") if is_burning else (GOLD if game.players[i].turbo < 0.25 else team_color)
   draw_rect(Rect2(x + 10, 778, turbo_w, 8), turbo_fill_color)
   for tick in range(1, 10):
    var tx = x + 10 + tick * 26.4
    if tx < x + 10 + turbo_w:
     draw_line(Vector2(tx, 778), Vector2(tx, 786), Color(0.05, 0.08, 0.12, 0.6), 1.0)
 if game.banner_time > 0:
  var offset = Vector2(sin(visual_time*60)*shake*18,0)
  draw_rect(Rect2(Vector2(280,155)+offset,Vector2(720,62)),Color(0.03,0.06,0.1,0.88))
  text_at(game.banner,Vector2(640,197)+offset,30,GOLD,true)
 draw_rect(Rect2(180,696,920,30),Color(0.03,0.06,0.1,0.88))
 draw_rect(Rect2(180,696,920,30),Color("22364c"),false,1.0)
 text_at("J  SHOOT/BLOCK    K  PASS/STEAL    L  SHOVE    ;  TURBO    F  SWITCH    O  SHOT %% (%s)    ESC  MENU" % ("ON" if show_shot_percentage else "OFF"),Vector2(640,716),12,INK,true)

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
  var dt_snap: float = clampf(visual_time - snapshot_received_time, 0.0, 0.25)
  var factor = 1.0 - exp(-delta * 26.0)
  for i in range(game.players.size()):
   var p_snap = game.players[i]
   var predicted_pos = p_snap.pos + p_snap.vel * dt_snap
   predicted_pos.x = clampf(predicted_pos.x, 90.0, 1190.0)
   predicted_pos.y = clampf(predicted_pos.y, 230.0, 700.0)
   if rendered_positions[i].distance_to(predicted_pos) > 220.0:
    rendered_positions[i] = predicted_pos
   else:
    rendered_positions[i] = rendered_positions[i].lerp(predicted_pos, factor)
  if not game.flight.is_empty():
   var fl = game.flight
   var t_flight = clampf((fl.time + dt_snap) / maxf(fl.duration, 0.01), 0.0, 1.0)
   var predicted_ball = fl.start.lerp(fl.end, t_flight)
   rendered_ball = predicted_ball if rendered_ball.distance_to(predicted_ball) > 280.0 else rendered_ball.lerp(predicted_ball, factor)
  elif game.owner >= 0 and game.owner < rendered_positions.size():
   var owner_pos = rendered_positions[game.owner]
   var face_dir = 1.0 if game.players[game.owner].face > 0 else -1.0
   var carried_ball = owner_pos + Vector2(face_dir * 18.0, 0.0)
   rendered_ball = carried_ball if rendered_ball.distance_to(carried_ball) > 200.0 else rendered_ball.lerp(carried_ball, factor)
  else:
   rendered_ball = game.ball if rendered_ball.distance_to(game.ball) > 280.0 else rendered_ball.lerp(game.ball, factor)
  positions = rendered_positions
  ball_position = rendered_ball
 var active: Array = [net.local_slot] if net.online else ([controlled[0],controlled[1]] if local_two else [controlled[0]])
 arena.present(game,positions,ball_position,active,delta,paused or screen == "results")
 queue_redraw()
