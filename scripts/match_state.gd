class_name MatchState
extends RefCounted

const COURT = Rect2(115, 265, 1050, 410)
const HOOPS = [Vector2(165, 465), Vector2(1115, 465)]
const THREE_POINT_RADIUS = 300.0
const THREE_POINT_CORNER_OFFSET = 180.0
const REBOUND_FLIGHT_DURATION = 1.65
const REBOUND_BOUNCE_DURATION = 0.60
const REBOUND_GLIDE_DURATION = 0.50
const POSSESSION_FLASH_DURATION = 0.60
const BULLET_TIME_DURATION = 0.50
const BULLET_TIME_SCALE = 0.30
const TE_SHOVE_RANGE = 65.0
# seq_elbo reaches opponents inside 40 world units (PLYR2.ASM:5174).
const TE_ELBOW_RANGE = 40.0 * (950.0 / 640.0)
const SIGNATURE_DUNKS = ["helicopter", "frontflip", "spin_360", "between_legs", "behind_back", "behind_head", "windmill", "tomahawk", "cradle", "switch"]
# seq_strtdunk gravity. The ani point is at HOOPY+12 when seq_slamball fires,
# and a longer sequence arcs above that before coming back down to the rim.
const DUNK_GRAVITY = 9728.0 / 65536.0
const DUNK_SLAM_PX = 108.0
const DUNK_METERS_PER_PX = 3.05 / 120.0
# Rim is at 3.05m. In the overhead hang the wrists sit 2.12m above the body
# origin, so the body has to hang about 0.93m up for the hands to meet the rim.
const RIM_HEIGHT = 3.05
const DUNK_HAND_REACH = 2.124
const DUNK_SLAM_LIFT = RIM_HEIGHT - DUNK_HAND_REACH
# Ticks until the rim, then ticks of hang, taken from the sequence that plays
# that motion (DUNKB2, DUNKLAY, w2swdu, w1spdu, w3wmdu, DUNKQ).
const DUNK_TICKS = {
	"standard": 37, "leaner": 44, "reverse": 48, "cradle": 58, "switch": 66,
	"between_legs": 64, "spin_360": 63, "tomahawk": 70, "windmill": 75,
	"behind_head": 74, "behind_back": 74, "frontflip": 72, "helicopter": 74,
}
const DUNK_HANG_TICKS = {
	"standard": 64, "leaner": 36, "reverse": 40, "cradle": 42, "switch": 40,
	"between_legs": 48, "spin_360": 40, "tomahawk": 44, "windmill": 48,
	"behind_head": 50, "behind_back": 50, "frontflip": 44, "helicopter": 48,
}
# getdunkseq's five facing buckets, mirrored the same way as #d1..#d5.
const DUNK_UNDER = [
	["standard", "standard", "reverse"],
	["standard", "leaner"],
	["standard", "leaner", "reverse"],
	["leaner", "reverse"],
	["reverse"],
]
const DUNK_SHORT = [
	["standard", "cradle", "between_legs"],
	["standard", "switch", "spin_360"],
	["cradle", "between_legs", "switch"],
	["leaner", "cradle"],
	["reverse", "leaner"],
]
const DUNK_FANCY = [
	["frontflip", "cradle", "helicopter"],
	["spin_360", "windmill", "tomahawk", "between_legs"],
	["windmill", "behind_head", "helicopter", "tomahawk"],
	["tomahawk", "spin_360", "behind_head"],
	["behind_head", "frontflip", "cradle"],
]
const QUARTER_SECONDS = 180.0
const TIP_TOSS = 1.0
const TIP_IDEAL_JUMP = 1.42
const TIP_DECISION = 2.05
# Master arcade hardware refresh rate (DISP.EQU:36, TSEC .equ 53)
const ARCADE_TSEC = 53.20488
# push_t cardinal entries (#1/#3/#5) run 24 ticks and call seq_push on frame 12.
# Diagonal entries (#2/#4) run 20 ticks and call seq_push on frame 8.
# Both leave 12 ticks after contact.
const TE_SHOVE_DURATION = 24.0 / ARCADE_TSEC
const TE_SHOVE_DIAGONAL_DURATION = 20.0 / ARCADE_TSEC
const TE_SHOVE_CONTACT_REMAINING = 12.0 / ARCADE_TSEC
const TE_PUSH_PROTECTION = 80.0 / ARCADE_TSEC
# seq_strtdunk's tick argument is the frame sum until seq_slamball (PLYR2.ASM:4359, 4573).
# The dunker still owns the ball until that rim frame, so the release is the end of the flight.
const DUNK_RELEASE_FRACTION = 1.0
# The dunk keeps the ball on the hands until the slam. seq_slamball is that
# release; the view lets go of the ball at 0.88 of the trip to the rim.
const DUNK_HAND_RELEASE = 0.88
# The player loop will not call plyr_shoot before 12 jump ticks, and a pass
# edge is checked before that release. A jumper, layup, or hook can still be
# dished during that window.
const SHOT_HAND_TICKS = 12.0
# PLYR2.ASM:4963 rejects a target more than 0x54 pixels above the pusher.
# Ground is 0 and HOOPY is -120, and a dunk climbs that full rim rise (1.8m).
const TE_SHOVE_ABOVE = 1.8 * (84.0 / 120.0)
# Arcade quarter timer speedup factor: BASETM = 0x5100 per tick (SCORE.ASM:196)
# 65536 / 20736 = 3.1604 ticks per 0.1s = 31.604 ticks/s -> 31.604 / 53.20488 = 0.5940 real sec per clock sec
const CLOCK_TIME_SCALE = 1.6835
# Visible shot-clock digits decrement every SLEEP 32 (SCORE.ASM clock24).
# 32 / 53.20488 = 0.60145 real sec per displayed shot-clock second.
const SHOT_CLOCK_TIME_SCALE = 1.6628
# clock24 waits 7*40 ticks, two SLEEPK 10s, then 11*32 ticks from the [1,0] start.
# 652 ticks / 32 = 20.375 displayed seconds. shot_clock() does not start at 24.
const SHOT_CLOCK_SECONDS = 652.0 / 32.0
# Authentic NBA Jam arcade tables
# Base velocity table (PLYRAT.ASM:390-400 BV..BV10)
const BV_TABLE = [0x1002, 0x1044, 0x1086, 0x10c8, 0x110a, 0x114c, 0x118e, 0x11d0, 0x1274, 0x12c6, 0x1318]
# Base shooting skill (PLYRAT.ASM SHT0..SHT10). plyr_shoot uses these per-thousand values directly.
const SHT_PERMILLE = [860, 890, 920, 970, 1040, 1070, 1080, 1100, 1130, 1150, 1200]
# HOOPRX-HOOPLX is 640 (PLYR.EQU). Our rims are 950px apart.
const PX_PER_ASM = 950.0 / 640.0
# Power dunk-through defender table (PLYR.ASM:5363 dnkthru_t)
const DNKTHRU_T = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.10, 0.15, 0.25, 0.35]
# Dunk-lane distance and width (PLYR.ASM plyr_startjmp #dist_t / #width_t). The 12th entry is an on-fire defender.
const DEF_DIST_T = [40, 43, 46, 49, 50, 52, 54, 56, 68, 70, 72, 95]
const DEF_WIDTH_T = [27, 29, 31, 33, 36, 37, 38, 39, 40, 43, 45, 70]
# Mid-air dunk block & strip tables (PLYR.ASM tryblk_t, PLYR2.ASM takedunk_t).
# takedunk_t is indexed by (dunker power - stripper power) + 10 and is the
# chance the dunker keeps the ball. Power 3 and below can never strip a dunk.
const TRYBLK_T = [1, 2, 3, 10, 15, 18, 22, 23, 24, 25, 25]
const TAKEDUNK_T = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 100, 150, 300, 400, 500, 600, 700, 800, 999, 999]
# Tournament Edition ball-retention tables (PLYR.ASM:2569-2591).
const KPBALL_T = [0.190, 0.200, 0.220, 0.280, 0.300, 0.450, 0.550, 0.600, 0.650, 0.650, 0.650]
const FLYB_T = [0.0, 0.025, 0.050, 0.075, 0.100, 0.125, 0.150, 0.175, 0.200, 0.225, 0.250, 0.275, 0.275, 0.275, 0.275, 0.275]
# PLYR.ASM #shortfly_t / #winshortfly_t. A hit quarters the flyback that seq_push already applied.
const SHORTFLY_T = [0.140, 0.160, 0.180, 0.200, 0.250, 0.300, 0.400, 0.550, 0.650, 0.650, 0.650]
const WINSHORTFLY_T = [0.025, 0.050, 0.050, 0.060, 0.075, 0.075, 0.100, 0.150, 0.225, 0.275, 0.275]
const NOBLFLAIL_T = [0.085, 0.100, 0.105, 0.110, 0.115, 0.120, 0.150, 0.190, 0.250, 0.250, 0.300]
const TE_SHORT_FLY_TICKS = 35.0
# Pass speed tables indexed by PAT_PASS (PLYR.ASM:8409-8417 #longpas_t, #shortpas_t, #turbopas_t)
const LONGPAS_T = [103, 101, 99, 97, 95, 93, 91, 89, 87, 85, 83]
const SHORTPAS_T = [127, 124, 121, 118, 115, 112, 109, 106, 103, 100, 97]
const TURBOPAS_T = [28, 29, 30, 31, 32, 33, 35, 38, 41, 44, 44]
# Defensive steal ability (PLYR2.ASM stl1), per-thousand RNDPER scaled to 0-1.
const STL1 = [0.160, 0.170, 0.180, 0.195, 0.200, 0.205, 0.215, 0.245, 0.260, 0.285, 0.300]
# Clean steal vs knockaway (PLYR2.ASM stl2). A successful roll sticks the ball.
const STL2 = [0.160, 0.170, 0.180, 0.195, 0.200, 0.205, 0.215, 0.225, 0.230, 0.235, 0.250]
# Intercept bonus for the losing team (PLYR2.ASM #int_t), added to the percent gate.
const INT_T = [0, 4, 7, 10, 12, 15, 19, 20, 20, 20, 20, 20, 22, 25, 27, 30]
const TE_STEAL_LOCKOUT = 30.0 / ARCADE_TSEC
# steal_t (PLYRSEQ.ASM). seqdir order is #1,#2,#3,#4,#5,#4,#3,#2.
# A released pass button hits seq_stealstand and stands: 9 ticks on
# #1/#4/#5 and 10 on #2/#3. Holding pass plays the 25- or 26-tick return.
# Pass is a tap here, so the gesture ends at that first stand.
const STEAL_REACH_TICKS = [9, 10, 10, 9, 9, 9, 10, 10]
const TE_PASS_OFF = 25.0 / ARCADE_TSEC
const TE_POKE_DELAY = 15.0 / ARCADE_TSEC
# lay_perc: RNDPER(700) sets every player's shtdly to TSEC*2 so the ball cannot be touched.
const TE_LAYUP_TOUCH_LOCK = 106.0 / ARCADE_TSEC
# ply_turbo is 0..0x2f. Holding turbo subtracts one unit every 8 ticks
# (PLYR.ASM:1848). Replenish adds one unit every 6 ticks once used_turbo
# (set to 4 on each drain) has counted down (SCORE.ASM:237-291).
const TE_TURBO_UNITS = 47.0
const TE_TURBO_DRAIN_PER_SEC = ARCADE_TSEC / (TE_TURBO_UNITS * 8.0)
const TE_TURBO_RECHARGE_PER_SEC = ARCADE_TSEC / (TE_TURBO_UNITS * 6.0)
const TE_TURBO_RECOVER = 24.0 / ARCADE_TSEC
# #goalt_t is assembled beside #int_t but ball_chkpcollide never reads it.
# A fast downward swat is a goaltend only when rnd's mask of 6 is zero.
const GOALT_T = [0, 35, 45, 55, 60, 65, 70, 75, 75, 75, 80, 90, 90, 90, 90, 90]
# ball_chkpcollide Z radii and BLOCKREB hand reach (PLYR2.ASM:2960-2965).
# tbl1 is the high or fast ball. tbl2 is the low, slow ball. tbl4 is the hand X limit.
const TBL1_Z = [16, 17, 18, 18, 18, 18, 18, 19, 20, 21, 22]
const TBL2_Z = [32, 33, 34, 35, 35, 35, 35, 36, 37, 38, 39]
const BLK_REACH_T = [11, 12, 12, 12, 12, 12, 12, 13, 14, 15, 16]
# seq_block clamps the intercept slide to 30 pixels (PLYR2.ASM:4149).
const BLOCK_GLIDE_ASM = 30.0
# ball_bbcollision #chkbb. The glass sits 12 past the rim, 34 wide of center.
const GLASS_BEHIND_ASM = 12.0
const GLASS_Z_ASM = 34.0
# Drone AI 31-entry skill tables (DRONE.ASM:1047-1065, 1642-1684)
const DRONE_P_T = [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 8, 10, 13, 15, 17, 18, 20, 20, 25, 30, 35, 40, 50]
const DRONE_ALY_T = [1, 2, 3, 4, 5, 15, 20, 25, 25, 30, 30, 30, 30, 32, 35, 35, 35, 36, 38, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 100, 109]
# DRONE2.ASM #nast_t. Per-thousand chance, while not already nasty, to enter it for one second.
const DRONE_NAST_T = [0, 0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 6, 8, 10, 11, 12, 13, 14, 15, 17, 20, 25, 26, 27, 28, 29, 30, 35]
# DRONE2.ASM #skt_t. Ticks a defender waits before the next push/steal decision.
const DRONE_SKT_T = [60, 60, 58, 55, 52, 48, 44, 40, 36, 32, 28, 24, 22, 18, 16, 15, 15, 15, 14, 14, 14, 14, 14, 14, 13, 13, 13, 13, 13, 12, 12]
const DRONE_DIST_T = [110, 100, 100, 100, 100, 90, 90, 80, 80, 80, 80, 70, 70, 60, 60, 60, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50]
const DRONE_PS_T = [1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 6, 8, 10, 13, 15, 17, 18, 20, 30, 40, 60, 80, 150, 250]
const DRONE_BLK_T = [1, 1, 2, 3, 3, 3, 3, 4, 4, 5, 6, 7, 8, 10, 12, 14, 16, 18, 20, 25, 30, 35, 40, 45, 50, 50, 50, 50, 50, 50, 50]
var rng = RandomNumberGenerator.new()
var players: Array = []
var teams: Array = [0, 1]
var score: Array = [0, 0]
var streak: Array = [0, 0]
var player_streak: Array = [0, 0, 0, 0]
var fire_player = -1
var last_passer: int = -1
var assist_window: float = 0.0
var teammate_shot_order = -1
var stats: Array = []
var ball = Vector2.ZERO
var owner = 0
var flight: Dictionary = {}
var clock = QUARTER_SECONDS
var shot_clock = -1.0
var quarter = 1
var overtime = 0
var phase = "playing"
var freeze = 1.5
var banner = "TIP OFF!"
var banner_time = 2.0
# Player the current banner is about, or -1. Presentation prepends that
# player's name clip. SPEECH.ASM stores the name chunk ahead of the phrase.
var banner_player: int = -1
var event_id = 0
var event_kind = "start"
var elapsed = 0.0
var difficulty = 1
var big_heads = false
var infinite_turbo = false
var tournament_mode = false
var no_pushing = false
var fast_passing = false
var maximum_power = false
var period_length = QUARTER_SECONDS
var board_breaks: Array = [-1.0,-1.0]
var pending_inbound = -1
var shatter_shooter = -1
var fire_points: int = 0
var fire_shots: int = 0
var brick_count: Array = [0, 0, 0, 0]
var inbounding_team: int = -1
var loose_ball_timer: float = 0.0
var ball_touch_lock: float = 0.0
var in_cylinder_timer: float = 0.0
var must_rebound_timer: float = 0.0
var bullet_time_remaining: float = 0.0
var tipoff: Dictionary = {}
var last_shot_feedback: Dictionary = {}
var inbound_transition: Dictionary = {}
var quarter_transition: Dictionary = {}
var quarter_scores: Array = []
var clock_buzzer_sounded: bool = false

func start(a: int, b: int, seconds: float = QUARTER_SECONDS, level: int = 1) -> void:
 rng.randomize()
 teams = [a, b]
 score = [0, 0]
 streak = [0, 0]
 player_streak = [0, 0, 0, 0]
 fire_player = -1
 fire_points = 0
 fire_shots = 0
 last_passer = -1
 assist_window = 0.0
 brick_count = [0, 0, 0, 0]
 inbounding_team = -1
 loose_ball_timer = 0.0
 ball_touch_lock = 0.0
 in_cylinder_timer = 0.0
 must_rebound_timer = 0.0
 bullet_time_remaining = 0.0
 teammate_shot_order = -1
 board_breaks = [-1.0,-1.0]
 pending_inbound = -1
 shatter_shooter = -1
 last_shot_feedback = {}
 inbound_transition = {}
 quarter_transition = {}
 quarter_scores = []
 clock_buzzer_sounded = false
 tournament_mode = false
 no_pushing = false
 fast_passing = false
 maximum_power = false
 stats = []
 players = []
 difficulty = level
 period_length = seconds
 clock = seconds
 reset_shot_clock()
 quarter = 1
 overtime = 0
 phase = "playing"
 freeze = 1.5
 elapsed = 0.0
 flight = {}
 for i in range(4):
  var t = i / 2
  players.append({"pos":Vector2(420 if t == 0 else 860, 400 + (i % 2) * 140), "vel":Vector2.ZERO, "turbo":1.0, "turbo_burnout":0.0, "jump":0.0, "receive_jump":0.0, "stun":0.0, "cooldown":0.0, "charge":0.0, "fake":0.0, "dribble_locked":false, "drive":0.0, "swipe":0.0, "swipe_resolved":false, "swipe_shove":false, "swipe_dir":Vector2.ZERO, "rebound_glide":0.0, "possession_flash":0.0, "shoot_held":false, "face":1 if t == 0 else -1, "spin":0.0, "spin_cooldown":0.0, "elbow":0.0, "steal_immune":0.0, "push_keep_ball":0.0, "pass_off":0.0, "alley_cnt":0, "hold_time":0.0, "nasty_timer":0.0, "drone_seek":0, "rim_hang":0.0, "still_time":1.0, "shot_is_moving":false, "shot_drift_vel":Vector2.ZERO, "last_move_vel":Vector2.ZERO, "pickup_delay":0.0, "turbo_flash":0.0, "shove_kind":"", "shove_time":0.0, "dir_time":0.0, "dir_sector":-1, "human":false, "shot_finish":""})
  stats.append({"points":0, "attempts":0, "made":0, "dunks":0, "steals":0, "blocks":0, "rebounds":0, "goaltends":0, "assists":0, "injury":0, "turnovers":0})
 begin_tipoff()

# clock24 dies immediately when the period is already at or under 0:15 (SCORE.ASM).
func reset_shot_clock() -> void:
 shot_clock = -1.0 if clock <= 15.0 else SHOT_CLOCK_SECONDS

func begin_tipoff() -> void:
 owner = -1
 freeze = 0
 ball = Vector2(640,465)
 players[0].pos = Vector2(610,465)
 players[2].pos = Vector2(670,465)
 players[1].pos = Vector2(490,565)
 players[3].pos = Vector2(790,365)
 var spread = 0.25-0.05*clampi(difficulty,0,2)
 tipoff = {"active":true,"time":0.0,"started_at":elapsed,"jumps":[-1.0,-1.0],"held":[false,false],"cpu_at":[TIP_IDEAL_JUMP+rng.randf_range(-spread,spread),TIP_IDEAL_JUMP+rng.randf_range(-spread,spread)],"winner":-1}
 announce("CENTER COURT — SHOOT TO JUMP", "start")

func tick_tipoff(delta: float, commands: Dictionary) -> void:
 var previous: float = tipoff.time
 tipoff.time = minf(TIP_DECISION,tipoff.time+delta)
 for i in range(4):
  players[i].vel = Vector2.ZERO
  players[i].charge = 0.0
  players[i].jump = maxf(0,players[i].jump-delta)
  players[i].shoot_held = commands.get(i,{}).get("shoot",false)
 for team in range(2):
  var jumper = team*2
  var controller = jumper if commands.has(jumper) else jumper+1
  var human = commands.has(controller)
  var shoot: bool = commands.get(controller,{}).get("shoot",false)
  var pressed: bool = (shoot and not tipoff.held[team]) or commands.get(controller,{}).get("jump_press",false)
  tipoff.held[team] = shoot
  if tipoff.jumps[team] >= 0:
   continue
  var jump_at = -1.0
  if human and pressed and tipoff.time >= TIP_TOSS and tipoff.time <= TIP_DECISION:
   jump_at = tipoff.time
  elif not human and tipoff.time >= tipoff.cpu_at[team]:
   jump_at = tipoff.cpu_at[team]
  if jump_at >= 0:
   tipoff.jumps[team] = jump_at
   players[jumper].jump = 0.62
 if previous < TIP_TOSS and tipoff.time >= TIP_TOSS:
  announce("BALL UP! SHOOT TO JUMP", "whistle")
 if tipoff.time < TIP_DECISION:
  return
 var errors: Array = []
 for team in range(2):
  errors.append(absf(tipoff.jumps[team]-TIP_IDEAL_JUMP) if tipoff.jumps[team] >= 0 else 100.0)
 var winner = rng.randi_range(0,1) if is_equal_approx(errors[0],errors[1]) else (0 if errors[0] < errors[1] else 1)
 var height = ball_height()
 tipoff.active = false
 tipoff.winner = winner
 var receiver = winner*2+1
 flight = {"kind":"pass","start":ball,"end":players[receiver].pos,"start_height":height,"time":0.0,"duration":0.35,"target":receiver,"alley":false,"tip":true}
 announce("%s WINS THE TIP!" % Teams.DATA[teams[winner]].name,"catch")

func announce(message: String, kind: String = "action", player: int = -1) -> void:
 banner = message
 banner_time = 1.8
 banner_player = player
 event_id += 1
 event_kind = kind

func gameplay_time_scale() -> float:
 return BULLET_TIME_SCALE if bullet_time_remaining > 0.0 else 1.0

func acquire_possession(player: int, dramatic: bool = false) -> void:
 owner = player
 players[player].possession_flash = POSSESSION_FLASH_DURATION
 players[player].hold_time = 0.0
 players[player].dribble_locked = false
 if dramatic:
  bullet_time_remaining = BULLET_TIME_DURATION

func hoop_for(team: int) -> Vector2:
 var right = team == 0
 if quarter >= 3:
  right = not right
 return HOOPS[1 if right else 0]

# Intentional discrepancy with NBA Jam TE. plyr_shoot takes the shot from
# anywhere, and a full-court heave only changes the make chance. This game
# ignores a shot taken on the far side of midcourt.
func shot_past_half_court(team: int, pos: Vector2) -> bool:
 var mid = COURT.position.x + COURT.size.x * 0.5
 if hoop_for(team).x > mid:
  return pos.x < mid
 return pos.x > mid

func rating(i: int, stat: int) -> float:
 var r: Array = Teams.DATA[teams[i / 2]].ratings[i % 2]
 if stat >= r.size():
  if stat == 6:
   return float(r[2])
  return float(r[mini(stat, r.size() - 1)])
 return float(r[stat])

func on_fire(team: int) -> bool:
 return fire_player >= 0 and fire_player / 2 == team

func is_player_on_fire(index: int) -> bool:
 return fire_player == index

func refresh_heat_summary() -> void:
 for team in range(2):
  streak[team] = maxi(player_streak[team*2],player_streak[team*2+1])

func record_natural_basket(shooter: int, points: int = 2) -> void:
 var team = shooter / 2
 brick_count[shooter] = 0
 # ballnumscored is one shared make-counter (PLYR2.ASM score path). A miss does not touch it.
 # fire_flags is never stored, so ignition stays at 3. The ball loop then forces the count to 4,
 # and the same player making a basket that would push it to 8 extinguishes fire and leaves 1.
 if fire_player >= 0 and fire_player / 2 != team:
  fire_player = -1
  fire_points = 0
  fire_shots = 0
  for i in range(4):
   player_streak[i] = 1 if i == shooter else 0
  refresh_heat_summary()
  return
 if fire_player >= 0 and fire_player != shooter:
  refresh_heat_summary()
  return
 if fire_player == shooter:
  fire_points += points
  fire_shots += 1
  if fire_shots >= 4:
   fire_player = -1
   player_streak[shooter] = 1
   fire_points = 0
   fire_shots = 0
   announce("HE'S COOLED OFF!", "whistle")
  refresh_heat_summary()
  return
 for i in range(4):
  if i != shooter:
   player_streak[i] = 0
 player_streak[shooter] = mini(3, player_streak[shooter] + 1)
 if player_streak[shooter] >= 3:
  fire_player = shooter
  fire_points = 0
  fire_shots = 0
 refresh_heat_summary()

func record_miss(shooter: int) -> void:
 brick_count[shooter] += 1
 refresh_heat_summary()

func award_basket(shooter: int, points: int, dunk: bool, natural: bool = true, specialty: bool = false) -> bool:
 var team = shooter / 2
 score[team] += points
 # score_add credits assist_plyr on every basket until the 210-frame window ends.
 if assist_window > 0.0 and last_passer >= 0:
  stats[last_passer].assists += 1
 stats[shooter].points += points
 stats[shooter].made += 1
 if dunk:
  stats[shooter].dunks += 1
 if natural:
  record_natural_basket(shooter, points)
  # Authored trigger: the first made specialty dunk per hoop in Q4/overtime.
  if dunk and specialty and quarter >= 4:
   var side = 0 if hoop_for(team).x < 640 else 1
   if board_breaks[side] < 0:
    board_breaks[side] = elapsed
    return true
 return false

func flight_position() -> Vector2:
 if flight.is_empty():
  return ball
 return flight.start.lerp(flight.end,clampf(flight.time/flight.duration,0,1))

func finisher_position(flight_time: float) -> Vector2:
 var progress = clampf(flight_time/flight.duration/0.8,0,1)
 return flight.player_start.lerp(flight.player_end,smoothstep(0,1,progress))

func ball_height() -> float:
 if tipoff.get("active",false):
  var t = maxf(0,tipoff.time-TIP_TOSS)
  return 1.2+7.5*t-5.5*t*t
 if pending_inbound >= 0:
  var age = maxf(0,elapsed-maxf(board_breaks[0],board_breaks[1]))
  return maxf(0.24,3.05-4.0*age*age)
 if not flight.is_empty():
  var t = clampf(flight.time/flight.duration,0,1)
  if flight.kind == "shot":
   return lerpf(flight.get("release_height",1.3),3.05,t)+sin(t*PI)*flight.get("arc_height",1.7 if flight.dunk else 4.6)
  elif flight.kind == "rebound":
   var bounce_count = flight.get("bounces", 0)
   if bounce_count == 0:
    var apex_bonus = flight.get("arc_height", 2.0)
    return maxf(0.24, lerpf(3.05, 0.24, t) + 4.0 * apex_bonus * t * (1.0 - t))
   else:
    return maxf(0.24, 0.24 + sin(t * PI) * flight.get("bounce_height", 0.9))
  elif flight.kind == "loose":
   return maxf(0.24, 0.24 + sin(t * PI) * flight.get("arc_height", 1.1))
  return lerpf(flight.get("start_height",1.1),flight.get("end_height",1.1),t)+sin(t*PI)*(1.4 if flight.get("alley",false) else 0.5)
 if owner >= 0:
  var p_own: Dictionary = players[owner]
  if p_own.receive_jump > 0:
   return 1.1+receive_height(owner)
  elif p_own.charge > 0:
   var jump = sin(clampf(p_own.charge / 1.16, 0.0, 1.0) * PI) * 1.35
   return 1.3 + jump
  elif p_own.jump > 0:
   var jump = sin(clampf((0.75 - p_own.jump) / 0.75, 0.0, 1.0) * PI) * 1.6
   return 1.3 + jump
  return 0.30+absf(sin(elapsed*12.0))*0.9
 return 0.24

func teammate_commands(commands: Dictionary) -> Dictionary:
 var effective = commands.duplicate(true)
 # A dunk or shot still in the shooter's hand counts as possession. owner is
 # cleared when the attempt starts, which was dropping the partner's pass order.
 var carrier = owner
 if carrier < 0 and shot_still_in_hand():
  carrier = int(flight.get("shooter", -1))
 if carrier < 0 or commands.has(carrier):
  teammate_shot_order = -1
  return effective
 var partner = (carrier / 2) * 2 + (1 - carrier % 2)
 if not commands.has(partner):
  teammate_shot_order = -1
  return effective
 var request: Dictionary = commands[partner]
 var shoot: bool = request.get("shoot",false)
 var pass_request: bool = request.get("pass",false)
 var turbo: bool = request.get("turbo",false)
 if pass_request:
  var cpu = ai(carrier)
  cpu["pass"] = true
  cpu.shoot = false
  cpu.turbo = turbo
  effective[carrier] = cpu
  teammate_shot_order = -1
  if owner >= 0:
   announce("CALL FOR PASS!", "pass")
 elif shoot or teammate_shot_order == carrier:
  var cpu = ai(carrier)
  cpu.shoot = shoot and not pass_request
  cpu["pass"] = false
  cpu.turbo = turbo
  effective[carrier] = cpu
  if shoot and teammate_shot_order != carrier:
   announce("TAKE THE SHOT!", "shot")
  teammate_shot_order = carrier if cpu.shoot else -1
 return effective

# True while this shot's ball is still in the shooter's hand.
func shot_still_in_hand() -> bool:
 if flight.is_empty() or str(flight.get("kind", "")) != "shot":
  return false
 if flight.get("blocked", false):
  return false
 return float(flight.time) < float(flight.get("in_hand_until", 0.0))

func controls_ball(i: int) -> bool:
 if i < 0 or i >= players.size():
  return false
 if owner == i:
  return true
 return shot_still_in_hand() and int(flight.get("shooter", -1)) == i

func receive_height(i: int) -> float:
 return sin(clampf(1.0-players[i].receive_jump/0.7,0,1)*PI)*1.65

func start_receive_jump(i: int) -> void:
 players[i].receive_jump = 0.7
 players[i].jump = 0.7
 players[i].cooldown = 0.75
 players[i].charge = 0.0
 players[i].fake = 0.0

func prepare_receivers(delta: float, commands: Dictionary, effective: Dictionary) -> void:
 if owner < 0:
  return
 var receiver = (owner/2)*2+(1-owner%2)
 var p: Dictionary = players[receiver]
 if p.stun > delta or p.cooldown > delta:
  return
 var request: Dictionary = effective[receiver]
 var shoot: bool = request.get("shoot",false)
 var pressed: bool = (shoot and not p.shoot_held) or request.get("jump_press",false)
 var sender: Dictionary = effective[owner]
 var turbo: bool = sender.get("turbo",false) and (players[owner].turbo > 0.02 or infinite_turbo or is_player_on_fire(owner))
 if commands.has(receiver):
  # The caller can jump while their Shoot order also starts a CPU shot windup.
  if pressed:
   start_receive_jump(receiver)
 elif sender.get("pass",false) and turbo and players[owner].cooldown <= delta and players[owner].stun <= delta and p.pos.distance_to(hoop_for(receiver/2)) < 220:
  start_receive_jump(receiver)
  effective[receiver].move = Vector2.ZERO

# WRLDMID/CZMID map to our center. Offsets are the signed world deltas in PLYR.ASM.
func asm_spot(x_asm: float, z_asm: float) -> Vector2:
 return Vector2(640.0 + x_asm * PX_PER_ASM, 465.0 + z_asm * PX_PER_ASM)

func choose_inbounder(team: int, mode: String) -> int:
 if mode == "roster" or mode == "fixed":
  return team * 2 if mode == "roster" else (0 if team == 0 else 3)
 var first = team * 2
 var second = first + 1
 var target = ball if mode == "ball" else hoop_for(1 - team)
 if players[first].pos.distance_to(target) <= players[second].pos.distance_to(target):
  return first
 return second

# plyr_takeoutball2 teleports to #t1_setup_table / #t2_setup_table.
# plyrtob_moveo3 walks a made basket, a shot-clock turnover, and the halftime inbound.
func inbound_spots_for(team: int, inbounder: int, teleport: bool) -> Array:
 var own_hoop = hoop_for(1 - team)
 var toward_baseline = -1.0 if own_hoop.x < 640.0 else 1.0
 var in_x = 365.0 if teleport else 355.0
 var mate_x = 280.0 if teleport else 270.0
 var def_x = 160.0 if teleport else 150.0
 var mate_z = 15.0 if teleport else 10.0
 var spots = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
 var mate = inbounder ^ 1
 var opp = (1 - team) * 2
 spots[inbounder] = asm_spot(toward_baseline * in_x, -20.0)
 spots[mate] = asm_spot(toward_baseline * mate_x, mate_z)
 spots[opp] = asm_spot(toward_baseline * def_x, -50.0)
 spots[opp + 1] = asm_spot(toward_baseline * def_x, 70.0)
 return spots

# A bare inbound() puts the ball in play. Scored baskets, period openings, and
# shot-clock turnovers use the PLYR.ASM take-out tables instead.
func resume_spots(team: int) -> Array:
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640.0
 var spots = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
 for i in range(4):
  var h = hoop_for(1 - i / 2)
  spots[i] = Vector2(h.x + (190.0 if h.x < 640.0 else -190.0), 390.0 + float(i % 2) * 145.0)
 var mate = team * 2 + 1
 spots[mate] = Vector2(own_hoop.x + (140.0 if left_side else -140.0), own_hoop.y + 40.0)
 var opp = (1 - team) * 2
 spots[opp] = Vector2(640.0 + (-90.0 if left_side else 90.0), 380.0)
 spots[opp + 1] = Vector2(640.0 + (-90.0 if left_side else 90.0), 520.0)
 spots[team * 2] = own_hoop + Vector2(85.0 if left_side else -85.0, 0.0)
 return spots

func start_goal_inbound(team: int) -> void:
 if not tipoff.is_empty():
  tipoff.active = false
 inbounding_team = team
 pending_inbound = -1
 shatter_shooter = -1
 teammate_shot_order = -1
 flight = {}
 reset_shot_clock()
 for i in range(4):
  players[i].charge = 0.0
  players[i].fake = 0.0
  players[i].dribble_locked = false
  players[i].drive = 0.0
  players[i].swipe = 0.0
  players[i].swipe_resolved = false
  players[i].swipe_shove = false
  players[i].swipe_dir = Vector2.ZERO
  players[i].shoot_held = false
  players[i].spin = 0.0
  players[i].elbow = 0.0
  players[i].turbo_flash = 0.0
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
  players[i].dir_time = 0.0
  players[i].dir_sector = -1
 var inbounder = choose_inbounder(team, "ball")
 acquire_possession(inbounder)
 players[inbounder].cooldown = 0.40
 var spots = inbound_spots_for(team, inbounder, false)
 inbound_transition = {
  "active": true,
  "team": team,
  "spots": spots,
  "timer": 0.0
 }
 freeze = 1.0

func tick_inbound_transition(delta: float) -> void:
 inbound_transition.timer += delta
 var team: int = inbound_transition.team
 var spots: Array = inbound_transition.spots
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640
 var all_settled = true
 for i in range(4):
  var p: Dictionary = players[i]
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  if p.stun <= 0.0:
   p.shove_kind = ""
   p.shove_time = 0.0
  p.pickup_delay = maxf(0.0, p.get("pickup_delay", 0.0) - delta)
  p.receive_jump = 0.0
  # seq_slamball holds the dunker on the rim for the rest of that sequence.
  if p.get("rim_hang", 0.0) > 0.0:
   p.rim_hang = maxf(0.0, p.rim_hang - delta)
   p.jump = p.rim_hang
   p.vel = Vector2.ZERO
   all_settled = false
   continue
  # If in the air, land rapidly
  if p.jump > 0.0:
   p.jump = maxf(0.0, p.jump - delta * 4.0)
   all_settled = false
  else:
   p.jump = 0.0
   var target: Vector2 = spots[i]
   var diff = target - p.pos
   var dist = diff.length()
   # Move 2x as fast so we don't waste the player's time
   var run_speed = (125.0 + rating(i, 0) * 7.0) * 2.0
   if dist > 8.0:
    all_settled = false
    var dir = diff / dist
    var step = minf(dist, run_speed * delta)
    p.pos += dir * step
    p.vel = dir * run_speed
    if absf(dir.x) > 0.1:
     p.face = signf(dir.x)
   else:
    p.pos = target
    p.vel = Vector2.ZERO
    p.face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)

 if owner >= 0 and owner < 4:
  ball = players[owner].pos + Vector2(players[owner].face * 14, -7)

 if all_settled or inbound_transition.timer > 2.5:
  for i in range(4):
   players[i].pos = spots[i]
   players[i].vel = Vector2.ZERO
   players[i].jump = 0.0
   players[i].face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  if owner >= 0 and owner < 4:
   ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
  inbound_transition = {}
  freeze = 0.45

func record_quarter_score() -> void:
 var prior = [0, 0]
 for qs in quarter_scores:
  prior[0] += qs[0]
  prior[1] += qs[1]
 var q_pts = [maxi(0, score[0] - prior[0]), maxi(0, score[1] - prior[1])]
 quarter_scores.append(q_pts)

func start_quarter_transition() -> void:
 record_quarter_score()
 var is_final = quarter >= 4 and score[0] != score[1]
 var is_ot = quarter >= 4 and score[0] == score[1]
 var banner_msg = ""
 if is_final:
  banner_msg = "FINAL"
  phase = "finished"
 elif is_ot:
  banner_msg = "OVERTIME" if overtime == 0 else ("DOUBLE OVERTIME" if overtime == 1 else "TRIPLE OVERTIME")
 elif quarter == 2:
  banner_msg = "HALFTIME • SWITCH ENDS"
 else:
  banner_msg = "END OF QUARTER %d" % quarter
 announce(banner_msg, "whistle")
 var dur = 3.6 if period_length >= 60.0 else minf(3.6, maxf(0.8, period_length * 0.15))
 quarter_transition = {
  "active": true,
  "timer": 0.0,
  "duration": dur,
  "quarter": quarter,
  "score_at_end": score.duplicate(),
  "fade_alpha": 0.0,
  "switched": false,
  "is_final": is_final,
  "is_overtime": is_ot,
  "banner": banner_msg
 }

func tick_quarter_transition(delta: float) -> void:
 quarter_transition.timer += delta
 var t: float = quarter_transition.timer
 var dur: float = quarter_transition.duration
 var p_norm = clampf(t / maxf(0.001, dur), 0.0, 1.0)
 for p in players:
  p.vel = Vector2.ZERO
  if p.jump > 0.0:
   p.jump = maxf(0.0, p.jump - delta * 4.0)
  p.cooldown = 0.5
  p.shove_kind = ""
  p.shove_time = 0.0
 if p_norm < 0.60:
  quarter_transition.fade_alpha = 0.0
 elif p_norm < 0.78:
  quarter_transition.fade_alpha = (p_norm - 0.60) / 0.18
 else:
  quarter_transition.fade_alpha = 1.0 - (p_norm - 0.78) / 0.22
 if p_norm >= 0.78 and not quarter_transition.switched:
  quarter_transition.switched = true
  clock_buzzer_sounded = false
  if quarter_transition.is_final:
   phase = "finished"
  else:
   next_period(true)
 if t >= dur:
  quarter_transition = {}

func inbound(team: int, after_goal: bool = false, animated: bool = false, quarter_opening: bool = false, shot_clock: bool = false) -> void:
 if animated:
  start_goal_inbound(team)
  return
 if not tipoff.is_empty():
  tipoff.active = false
 inbounding_team = team if after_goal else -1
 pending_inbound = -1
 shatter_shooter = -1
 teammate_shot_order = -1
 inbound_transition = {}
 var teleport = quarter_opening and quarter != 3
 var mode = "roster"
 if teleport:
  mode = "fixed"
 elif after_goal or (quarter_opening and quarter == 3):
  mode = "ball"
 elif shot_clock:
  mode = "hoop"
 var inbounder = choose_inbounder(team, mode)
 acquire_possession(inbounder)
 flight = {}
 reset_shot_clock()
 var own_hoop = hoop_for(1 - team)
 var left_side = own_hoop.x < 640
 var spots = resume_spots(team) if mode == "roster" else inbound_spots_for(team, inbounder, teleport)
 for i in range(4):
  players[i].pos = spots[i]
  players[i].cooldown = 0.0
  players[i].stun = 0.0
  players[i].charge = 0.0
  players[i].fake = 0.0
  players[i].dribble_locked = false
  players[i].drive = 0.0
  players[i].swipe = 0.0
  players[i].swipe_resolved = false
  players[i].swipe_shove = false
  players[i].swipe_dir = Vector2.ZERO
  players[i].shoot_held = false
  if players[i].get("rim_hang", 0.0) <= 0.0:
   players[i].jump = 0.0
  players[i].receive_jump = 0.0
  players[i].face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  players[i].still_time = 1.0
  players[i].shot_is_moving = false
  players[i].shot_drift_vel = Vector2.ZERO
  players[i].last_move_vel = Vector2.ZERO
  players[i].dir_time = 0.0
  players[i].dir_sector = -1
 var teammate = owner ^ 1
 players[teammate].face = -1 if left_side else 1
 var opp_team = 1 - team
 players[opp_team * 2].face = -1 if left_side else 1
 players[opp_team * 2 + 1].face = -1 if left_side else 1
 players[owner].face = 1 if left_side else -1
 ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
 freeze = 1.0

func tick(delta: float, commands: Dictionary) -> void:
 if phase != "playing" and not quarter_transition.get("active", false):
  return
 var real_delta = delta
 var time_scale = gameplay_time_scale()
 bullet_time_remaining = maxf(0.0, bullet_time_remaining - real_delta)
 for player in players:
  player.possession_flash = maxf(0.0, player.get("possession_flash", 0.0) - real_delta)
 delta *= time_scale
 elapsed += delta
 banner_time = maxf(0.0, banner_time - delta)
 if assist_window > 0.0:
  assist_window = maxf(0.0, assist_window - delta)
  if assist_window <= 0.0:
   last_passer = -1
 if tipoff.get("active",false):
  tick_tipoff(delta,commands)
  return
 if quarter_transition.get("active", false):
  tick_quarter_transition(delta)
  return
 if inbound_transition.get("active", false):
  tick_inbound_transition(delta)
  return
 if inbounding_team >= 0:
  if owner < 0 or owner / 2 != inbounding_team or (players[owner].pos.x >= COURT.position.x and players[owner].pos.x <= COURT.end.x):
   inbounding_team = -1
 if freeze > 0:
  if pending_inbound >= 0:
   for p in players:
    p.jump = maxf(0,p.jump-delta)
  freeze = maxf(0,freeze-delta)
  return
 loose_ball_timer = maxf(0.0, loose_ball_timer - delta)
 in_cylinder_timer = maxf(0.0, in_cylinder_timer - delta)
 must_rebound_timer = maxf(0.0, must_rebound_timer - delta)
 if pending_inbound >= 0:
  inbound(pending_inbound, true)
  return
 # A released shot is allowed to finish after either buzzer. Clock stopped while inbounding.
 if inbounding_team < 0:
  clock = maxf(0.0, clock - delta * CLOCK_TIME_SCALE)
  if clock <= 0.0 and not clock_buzzer_sounded:
   clock_buzzer_sounded = true
   announce("BUZZER", "buzzer")
  if flight.is_empty() or flight.get("kind", "") != "shot":
   if shot_clock >= 0.0:
    shot_clock = maxf(0.0, shot_clock - delta * SHOT_CLOCK_TIME_SCALE)
 if clock <= 0 and flight.is_empty():
  start_quarter_transition()
  return
 if shot_clock >= 0.0 and shot_clock <= 0.0 and flight.is_empty():
  var next_team = 1 - (owner / 2 if owner >= 0 else 0)
  announce("SHOT CLOCK VIOLATION", "whistle")
  inbound(next_team, false, false, false, true)
  return
 var effective_commands = teammate_commands(commands)
 # Cache intent before any player acts so simultaneous jump/pass is slot-order independent.
 for i in range(4):
  if not effective_commands.has(i):
   effective_commands[i] = ai(i)
 prepare_receivers(delta,commands,effective_commands)
 # plyr_startpass runs on a pass edge while the shooter still owns the ball.
 # Dunks own it until seq_slamball. Jump shots, layups, and hooks own it until
 # plyr_shoot, which the player loop will not call before 12 jump ticks, and
 # a pass on that frame is taken first.
 if shot_still_in_hand():
  var shooter: int = int(flight.shooter)
  var shot_cmd: Dictionary = commands.get(shooter, effective_commands.get(shooter, {}))
  if shot_cmd.get("pass", false) and players[shooter].get("pass_off", 0.0) <= 0.0:
   var was_dunk = flight.get("dunk", false)
   stats[shooter].attempts = maxi(0, stats[shooter].attempts - 1)
   var mate = (shooter / 2) * 2 + (1 - shooter % 2)
   var is_double_dunk = was_dunk and (players[mate].receive_jump > 0.05 or players[mate].jump > 0.05)
   ball_touch_lock = 0.0
   pass_ball(shooter, shot_cmd.get("turbo", false))
   if is_double_dunk and not flight.is_empty():
    flight.double_dunk = true
    announce("DOUBLE DUNK!", "dunk")
   else:
    announce("AIRBORNE DISH!", "pass")
   players[shooter].charge = 0.0
   players[shooter].shoot_held = false
   players[shooter].shot_finish = ""
  elif flight.get("dunk", false) and not flight.get("bailed_to_layup", false) and flight.time >= 0.18 and shot_cmd.get("jump_press", false):
   flight.dunk = false
   flight.layup = true
   flight.super_dunk = false
   flight.finish = "layup"
   flight.arc_height = 1.0
   flight.bailed_to_layup = true
   var breakdown = calculate_shot_percentage(shooter, 0.58, false, true, false, false, false, false, null, true)
   flight.made = rng.randf() < breakdown.chance
   flight.shot_breakdown = breakdown
   roll_layup_touch_lock()
   players[shooter].jump = minf(players[shooter].jump, 0.45)
   players[shooter].charge = 0.0
   players[shooter].shoot_held = false
   announce("SWITCHES HANDS! FINGER ROLL!", "shot")
 ball_touch_lock = maxf(0.0, ball_touch_lock - delta)
 for i in range(4):
  var p: Dictionary = players[i]
  p.human = commands.has(i)
  p.cooldown = maxf(0.0, p.cooldown - delta)
  p.stun = maxf(0.0, p.stun - delta)
  if p.stun <= 0.0:
   p.shove_kind = ""
   p.shove_time = 0.0
  p.pickup_delay = maxf(0.0, p.get("pickup_delay", 0.0) - delta)
  p.rim_hang = maxf(0.0, p.get("rim_hang", 0.0) - delta)
  if p.rim_hang <= 0.0:
   p.jump = maxf(0.0, p.jump - delta)
  if p.jump <= 0.0:
   p.blocking = false
  elif p.get("blocking", false):
   try_shot_block(i)
  p.receive_jump = maxf(0.0,p.receive_jump-delta)
  p.fake = maxf(0.0, p.fake - delta)
  var swipe_before = p.swipe
  p.swipe = maxf(0.0, p.swipe - delta)
  p.spin = maxf(0.0, p.get("spin", 0.0) - delta)
  p.spin_cooldown = maxf(0.0, p.get("spin_cooldown", 0.0) - delta)
  p.elbow = maxf(0.0, p.get("elbow", 0.0) - delta)
  p.steal_immune = maxf(0.0, p.get("steal_immune", 0.0) - delta)
  p.push_keep_ball = maxf(0.0, p.get("push_keep_ball", 0.0) - delta)
  p.pass_off = maxf(0.0, p.get("pass_off", 0.0) - delta)
  p.nasty_timer = maxf(0.0, p.get("nasty_timer", 0.0) - delta)
  p.turbo_burnout = maxf(0.0, p.get("turbo_burnout", 0.0) - real_delta)
  p.turbo_flash = maxf(0.0, p.get("turbo_flash", 0.0) - delta)
  if owner == i and inbounding_team < 0:
   p.hold_time = p.get("hold_time", 0.0) + delta
  else:
   p.hold_time = 0.0
  # The extended hand is the last 2 ticks before seq_stealstand.
  var contact_remaining = TE_SHOVE_CONTACT_REMAINING if p.get("swipe_shove", false) else (2.0 / ARCADE_TSEC)
  if not p.get("swipe_resolved", false) and swipe_before > contact_remaining and p.swipe <= contact_remaining:
   p.swipe_resolved = true
   resolve_steal(i, p.get("swipe_shove", false))
   # seq_stealstand goes straight to seq_stand once this player has the ball.
   if not p.get("swipe_shove", false) and owner == i:
    p.swipe = 0.0
  p.drive = maxf(0.0,p.drive-delta)
  var c: Dictionary = effective_commands[i]
  if p.stun > 0:
   p.charge = 0.0
   p.shoot_held = false
   p.receive_jump = 0.0
   p.dir_time = 0.0
   p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
   var friction = 420.0 if p.get("shove_kind", "") == "flyback" else 600.0
   p.vel = p.vel.move_toward(Vector2.ZERO, delta * friction)
   continue
  var move: Vector2 = c.get("move", Vector2.ZERO)
  move = move.limit_length()
  if owner == i and p.get("dribble_locked", false):
   move = Vector2.ZERO
   p.vel = Vector2.ZERO
  note_dir_time(p, move, delta)
  var turbo: bool = c.get("turbo", false) and (p.turbo > 0.0 or infinite_turbo or is_player_on_fire(i))
  var diagonal = absf(move.x) > 0.2 and absf(move.y) > 0.2
  var speed = terminal_speed(i, turbo, diagonal)
  if turbo:
   if not infinite_turbo and not is_player_on_fire(i):
    p.turbo = maxf(0.0, p.turbo - delta * TE_TURBO_DRAIN_PER_SEC)
    p.turbo_burnout = TE_TURBO_RECOVER
    if p.turbo <= 0.001:
     p.turbo = 0.0
  elif p.turbo_burnout > 0.0:
   pass
  else:
   p.turbo = minf(1.0, p.turbo + delta * TE_TURBO_RECHARGE_PER_SEC)
  if infinite_turbo or is_player_on_fire(i):
   p.turbo = 1.0
   p.turbo_burnout = 0.0
  var spin_press: bool = (c.get("spin", false) or c.get("shove", false)) and not p.get("dribble_locked", false)
  if owner == i and spin_press and inbounding_team < 0 and p.jump <= 0.0 and p.receive_jump <= 0.0 and p.cooldown <= 0.0 and p.get("spin", 0.0) <= 0.0 and p.get("elbow", 0.0) <= 0.0:
   # Offensive L is ELBO. Holding Turbo is the double-tap elbow, ELBO2.
   if c.get("turbo", false):
    if p.turbo + 0.0001 < (5.0 / TE_TURBO_UNITS) and not infinite_turbo and not is_player_on_fire(i):
     p.turbo_flash = 0.60
     announce("NEED TURBO!", "turbo")
    else:
     if not infinite_turbo and not is_player_on_fire(i):
      p.turbo = maxf(0.0, p.turbo - (4.0 / TE_TURBO_UNITS))
     var spin_dir = move
     if spin_dir.length() < 0.1:
      spin_dir = p.get("last_move_vel", Vector2.ZERO)
     if spin_dir.length() < 0.1:
      spin_dir = Vector2(p.face, 0.0)
     # ELBO2 always locks steals for 60 ticks (PLYR.ASM:1820).
     p.steal_immune = 60.0 / ARCADE_TSEC
     p.spin = 0.45
     p.spin_cooldown = 2.0
     p.cooldown = 0.45
     p.vel = spin_dir.normalized() * (speed * 1.35)
     announce("SPIN MOVE!", "pass")
   else:
    # seq_stand starts ELBO with steals_off 140 and pushing_delay 80 (PLYR2.ASM:3666).
    p.steal_immune = 140.0 / ARCADE_TSEC
    p.elbow = 0.50
    p.push_keep_ball = TE_PUSH_PROTECTION
    p.spin_cooldown = 1.2
    p.cooldown = 0.50
    var nearby_defs: Array = []
    for d in range(4):
     if d / 2 != i / 2 and players[d].pos.distance_to(p.pos) < TE_ELBOW_RANGE:
      nearby_defs.append(d)
    # Both opponents share one HCOUNT bit, so the clear-out hits both or neither.
    if rng.randi() % 2 == 0:
     for d in nearby_defs:
      players[d].stun = 0.75
      players[d].shove_kind = "stumble"
      players[d].shove_time = 0.75
      var push_dir = (players[d].pos - p.pos).normalized()
      if push_dir.length() < 0.1:
       push_dir = Vector2.RIGHT * p.face
      var face_dir = -signf(push_dir.x)
      if absf(face_dir) > 0.1:
       players[d].face = face_dir
      players[d].pos = (players[d].pos + push_dir * 18.0).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
      players[d].vel = push_dir * 180.0
    announce("CLEAR OUT!", "shove")
  var shoot: bool = c.get("shoot", false)
  if owner == i and shot_past_half_court(i / 2, p.pos):
   shoot = false
   p.charge = 0.0
   p.shot_finish = ""
  var shooting_this_tick = owner == i and shoot and p.pos.x >= COURT.position.x and p.pos.x <= COURT.end.x and not c.get("pass", false) and p.cooldown <= 0.0
  if shooting_this_tick and (not p.shoot_held or p.charge <= 0.0):
   var was_moving = p.get("still_time", 1.0) < 0.10 or p.vel.length() > 10.0 or move.length() > 0.05
   p.shot_is_moving = was_moving
   if was_moving:
    var drift = p.vel if p.vel.length() > 10.0 else p.get("last_move_vel", Vector2.ZERO)
    if drift.length() < 10.0 and move.length() > 0.05:
     drift = move.normalized() * speed
    p.shot_drift_vel = drift * 0.70
    p.vel = move * speed if move.length() > 0.05 else p.shot_drift_vel
   else:
    p.shot_is_moving = false
    p.shot_drift_vel = Vector2.ZERO
    p.vel = Vector2.ZERO
  var is_moving = not shooting_this_tick and (move.length() > 0.05 or p.vel.length() > 10.0) and p.charge <= 0.0 and p.jump <= 0.0
  if is_moving:
   p.still_time = 0.0
   if p.vel.length() > 10.0:
    p.last_move_vel = p.vel
   elif move.length() > 0.05:
    p.last_move_vel = move.normalized() * speed
  elif p.charge <= 0.0 and p.jump <= 0.0:
   p.still_time += delta
  if p.get("spin", 0.0) > 0.0:
   if move.length() > 0.1:
    p.vel = move.normalized() * (speed * 1.35)
  elif p.get("elbow", 0.0) > 0.0:
   p.vel = Vector2.ZERO
  elif p.get("rebound_glide", 0.0) > 0.0:
   p.rebound_glide = maxf(0.0, p.rebound_glide - delta)
  elif owner == i and (p.charge > 0.0 or shooting_this_tick):
   if p.get("shot_is_moving", false):
    p.vel = move * speed if move.length() > 0.05 else p.get("shot_drift_vel", p.vel)
   else:
    p.vel = Vector2.ZERO
  else:
   p.vel = move * speed
  if p.jump > 0.0 and owner != i and p.receive_jump <= 0.0 and p.get("rebound_glide", 0.0) <= 0.0:
   if p.get("shot_is_moving", false) and p.get("shot_drift_vel", Vector2.ZERO).length() > 0:
    p.vel = p.shot_drift_vel
   else:
    p.vel = Vector2.ZERO
  elif p.jump <= 0.0 and p.charge <= 0.0 and not shooting_this_tick:
   p.shot_is_moving = false
   p.shot_drift_vel = Vector2.ZERO
  if p.get("swipe", 0.0) > 0.0:
   p.vel = Vector2.ZERO
  var ordered_cpu = not commands.has(i) and commands.has(i ^ 1)
  if owner == i and (p.get("fake", 0.0) > 0.0 or head_fake_release(i, shoot, ordered_cpu)):
   p.vel = Vector2.ZERO
   p.shot_is_moving = false
   p.shot_drift_vel = Vector2.ZERO
  if p.vel.length() > 40 and p.vel.dot((hoop_for(i/2)-p.pos).normalized()) > 20:
   p.drive = 0.16
  if owner == i and (p.pos.x < COURT.position.x or p.pos.x > COURT.end.x):
   if p.pos.x < COURT.position.x:
    p.pos.x = clampf(p.pos.x + p.vel.x * delta, 50.0, COURT.position.x - 10.0)
   else:
    p.pos.x = clampf(p.pos.x + p.vel.x * delta, COURT.end.x + 10.0, 1225.0)
   p.pos.y = clampf(p.pos.y + p.vel.y * delta, COURT.position.y + 18.0, COURT.end.y - 18.0)
   p.shot_finish = ""
  elif not flight.is_empty() and flight.kind == "shot" and flight.shooter == i and flight.has("player_start") and not flight.get("blocked", false):
   var destination = finisher_position(flight.time+delta)
   p.vel = (destination-p.pos)/maxf(delta,0.0001)
   p.pos = destination
   p.drive = 0.0
  else:
   p.pos = (p.pos + p.vel * delta).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
   if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
    var own_hoop = hoop_for(1 - inbounding_team)
    var left_side = own_hoop.x < 640
    if i / 2 != inbounding_team:
     # plyrtob_moveo3 parks defenders 150 world units off center, not on the baseline.
     var defend_line = 640.0 + (-150.0 if left_side else 150.0) * PX_PER_ASM
     if left_side:
      p.pos.x = maxf(p.pos.x, defend_line)
     else:
      p.pos.x = minf(p.pos.x, defend_line)
    elif i != owner:
     if left_side:
      p.pos.x = minf(p.pos.x, 420.0)
     else:
      p.pos.x = maxf(p.pos.x, 860.0)
  if owner == i and p.pos.x >= COURT.position.x and p.pos.x <= COURT.end.x:
   inbounding_team = -1
  if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
   var own_hoop = hoop_for(1 - inbounding_team)
   var left_side = own_hoop.x < 640
   p.face = (1 if left_side else -1) if i == owner else (-1 if left_side else 1)
  elif absf(p.vel.x) > 0.1:
   p.face = signf(p.vel.x)
  if owner == i:
   if p.pos.x < COURT.position.x or p.pos.x > COURT.end.x:
    shoot = false
    p.charge = 0.0
    p.shot_finish = ""
   if c.get("pass", false) and p.cooldown <= 0 and not spin_press:
    pass_ball(i, turbo)
    p.charge = 0.0
    p.shot_finish = ""
    shoot = false
   elif shoot:
    if p.shot_is_moving:
     p.vel = move * speed if move.length() > 0.05 else p.shot_drift_vel
    else:
     p.vel = Vector2.ZERO
    p.fake = 0.0
    # plyr_startjmp picks the dunk, layup, hook, or jumper as the player leaves
    # the floor. Releasing later does not choose a different finish.
    if p.charge <= 0.0 and str(p.get("shot_finish", "")) == "":
     p.shot_finish = finish_kind(i, turbo)
    p.charge = minf(1.25, p.charge + delta)
    if str(p.shot_finish) in ["dunk", "turbo_dunk"]:
     shoot_ball(i, turbo)
     p.charge = 0.0
     p.shot_finish = ""
   elif p.shoot_held and p.charge > 0:
    # shoot_t reaches seq_jump after three N=3 frames (9 ticks). Button up there
    # goes to seq_stand and keeps the ball. Layups, hooks, and dunks do not.
    # Under 4 seconds seq_jump always jumps. A human teammate's drone never
    # lets go (#fake), so that order still releases. The shtbutn 3-8 skip is
    # commented out and is not this check.
    if head_fake_release(i, false, ordered_cpu):
     p.fake = 0.38
     p.charge = 0.0
     p.shot_finish = ""
     p.vel = Vector2.ZERO
     p.shot_is_moving = false
     p.shot_drift_vel = Vector2.ZERO
     announce("HEAD FAKE!", "shot")
    else:
     var jump_h = sin(clampf(p.charge / 1.16, 0.0, 1.0) * PI) * 1.35
     shoot_ball(i, turbo, false, 1.3 + jump_h)
     p.jump = maxf(0.08, 1.16 - p.charge)
     if not p.shot_is_moving:
      p.vel = Vector2.ZERO
     p.charge = 0.0
  else:
   # Off-ball commands target a CPU ball carrier; never override another human.
   var ordering_cpu = owner >= 0 and owner / 2 == i / 2 and not commands.has(owner)
   if not ordering_cpu and p.receive_jump <= 0:
    if shoot and not p.shoot_held and p.cooldown <= 0:
     defend(i, turbo)
  # A human's Turbo+Pass is a shove. A drone's closing-out turbo is not;
  # drone_defence sets shove only for the #ps push half.
  var contact_shove = c.get("shove", false) or (commands.has(i) and c.get("pass", false) and turbo)
  if (c.get("pass", false) or contact_shove) and p.cooldown <= 0:
   steal(i, contact_shove)
  p.shoot_held = shoot
 # Keep athletes separated without pushing them outside bounds.
 for i in range(4):
  for j in range(i + 1, 4):
   var offset: Vector2 = players[j].pos - players[i].pos
   if offset.length() < 27 and offset.length() > 0.01:
    var push = offset.normalized() * (27 - offset.length()) * 0.5
    players[i].pos = (players[i].pos - push).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
    players[j].pos = (players[j].pos + push).clamp(COURT.position + Vector2(18,18), COURT.end - Vector2(18,18))
 if not flight.is_empty():
  tick_flight(delta)
 elif owner >= 0:
  ball = players[owner].pos + Vector2(players[owner].face * 14, -7)
 else:
  if ball_touch_lock <= 0.0 and loose_ball_timer <= 0.0 and in_cylinder_timer <= 0.0:
   for i in range(4):
    if players[i].stun <= 0 and players[i].get("pickup_delay", 0.0) <= 0.0 and players[i].pos.distance_to(ball) < 30:
     acquire_possession(i, true)
     players[i].push_keep_ball = TE_PUSH_PROTECTION
     reset_shot_clock()
     stats[i].rebounds += 1
     announce("REBOUND!", "catch", i)
     break

# plyr_d_seekcnt is #skt_t plus a quarter of that span, or 25 when the drone is 320 units from its hoop.
# seq_jump returns to seq_stand on a short release and the ball stays in hand.
# The shooter plants instead of carrying the gather down the floor.
func head_fake_release(i: int, shoot: bool, ordered_cpu: bool) -> bool:
 var p: Dictionary = players[i]
 if shoot or not p.shoot_held or p.charge <= 0.0:
  return false
 var windup = 9.0 / ARCADE_TSEC
 var released_finish = str(p.get("shot_finish", "jumper"))
 return released_finish == "jumper" and p.charge < windup and clock >= 4.0 and not ordered_cpu

func drone_defense_seek_ticks(skill_idx: int, hoop_dist_asm: float) -> int:
 if hoop_dist_asm >= 320.0:
  return 25
 var base = DRONE_SKT_T[clampi(skill_idx, 0, DRONE_SKT_T.size() - 1)]
 return base + rng.randi_range(0, base >> 2)

func drone_skill_index(i: int) -> int:
 var team = i / 2
 var opp_team = 1 - team
 var pts_down = score[opp_team] - score[team]
 var adj = (difficulty - 1) * 4
 # drone_getcurskillo is ptsdown + plyr_d_skill, clamped around 15. Heat is not added.
 return clampi(15 + pts_down + adj, 0, 30)

func ai(i: int) -> Dictionary:
 var p: Dictionary = players[i]
 var team = i / 2
 var opp_team = 1 - team
 var deficit = score[opp_team] - score[team]
 var skill_idx = drone_skill_index(i)
 var target: Vector2 = p.pos
 var shoot = false
 var pass_action = false
 var turbo = false
 var spin = false
 var shove = false
 if inbounding_team >= 0 and owner >= 0 and (players[owner].pos.x < COURT.position.x or players[owner].pos.x > COURT.end.x):
  var own_hoop = hoop_for(1 - inbounding_team)
  var left_side = own_hoop.x < 640
  if i == owner:
   return {"move": Vector2.ZERO, "shoot": false, "pass": p.cooldown <= 0, "turbo": false, "spin": false}
  elif i / 2 == inbounding_team:
   # Teammate waits in own zone for the inbound pass (DRONE.ASM:1690-1765, PLYR.ASM:11276-11295)
   var wait_spot = Vector2(own_hoop.x + (115.0 if left_side else -115.0), own_hoop.y + 15.0)
   var diff = wait_spot - p.pos
   var move = diff.normalized() if diff.length() > 15.0 else Vector2.ZERO
   p.face = -1 if left_side else 1
   return {"move": move, "shoot": false, "pass": false, "turbo": false, "spin": false}
  else:
   # Enemy defenders stay back near midcourt during inbound (DRONE.ASM:1690-1765, PLYR.ASM:11276-11295)
   var back_x = 640.0 + (-150.0 if left_side else 150.0)
   var slot_y = 405.0 if (i % 2 == 0) else 535.0
   var def_spot = Vector2(back_x, slot_y)
   var diff = def_spot - p.pos
   var move = diff.normalized() if diff.length() > 20.0 else Vector2.ZERO
   p.face = -1 if left_side else 1
   return {"move": move, "shoot": false, "pass": false, "turbo": false, "spin": false}
 if not flight.is_empty() and flight.kind == "pass" and flight.get("alley",false) and flight.target == i and p.receive_jump > 0:
  target = p.pos
 elif owner == i and (p.pos.x < COURT.position.x or p.pos.x > COURT.end.x):
  return {"move":Vector2.ZERO, "shoot":false, "pass":p.cooldown <= 0, "turbo":false, "spin":false}
 elif owner == i:
  var hoop = hoop_for(team)
  var mate = (team * 2) + (1 - (i % 2))
  var dist: float = p.pos.distance_to(hoop)
  var mate_dist: float = players[mate].pos.distance_to(hoop)
  var near_def = nearest_defender(i)
  # Breakaway check (DRONE.ASM:191-215): no defender closer to hoop than ball carrier
  var breakaway = true
  for j in range(4):
   if j / 2 != team and players[j].stun <= 0.0 and players[j].pos.distance_to(hoop) < dist + 20.0:
    breakaway = false
    break
  # Alley-oop pass priority if teammate is airborne for a lob (DRONE.ASM:220-260)
  if players[mate].receive_jump > 0.05 and players[mate].stun <= 0.0 and mate_dist < 220.0 and p.cooldown <= 0.0:
   return {"move":(hoop - p.pos).normalized(), "shoot":false, "pass":true, "turbo":true, "spin":false}
  target = hoop + Vector2(-90 if hoop.x > 640 else 90, 10 * sin(elapsed + i))
  if p.charge > 0 and dist < 165:
   target = hoop + Vector2(60 if hoop.x > 640 else -60, 0)
  turbo = breakaway or dist < 240 or (deficit > 0 and p.get("turbo", 1.0) > 0.25)
  # Clock management when leading by 6+ in Q4 (DRONE.ASM:259-277)
  if quarter >= 4 and deficit <= -6 and shot_clock > 6.0 and clock > 6.0 and not breakaway:
   shoot = false
   target = hoop + Vector2(-220 if hoop.x > 640 else 220, 25.0 * sin(elapsed + i))
  else:
   # 3-pointer urgency check (DRONE.ASM:710-768 drone_chk3ptr: max 290 ASM units -> 375px, defender 70 ASM units -> 91px)
   var min_3pt_deficit = 3 if clock <= 60.0 else 6
   var need_three = is_three_pointer(p.pos, hoop) and dist < 375.0 and (is_player_on_fire(i) or (not on_fire(opp_team) and deficit >= min_3pt_deficit and (clock < 40.0 or near_def >= 91.0 or rng.randf() < (1.0 / 9.0))))
   if dist < 125 or shot_clock < 3 or clock < 2.0 or need_three or (dist < 370 and fmod(elapsed + i, 5.0) < 0.7):
    shoot = p.charge < 0.56
   # Contested shot windup pump-fake or mid-air pass bailout (DRONE.ASM:536-645 #fake, #injmp: 70 ASM units -> 91px)
   if p.charge > 0.0 and near_def < 91.0 and clock >= 4.0 and shot_clock >= 4.0:
    var jumping_blocker = false
    for j in range(4):
     if j / 2 != team and players[j].pos.distance_to(p.pos) < 91.0 and players[j].get("jump", 0.0) > 0.10:
      jumping_blocker = true
      break
    if jumping_blocker and p.cooldown <= 0.0 and rng.randf() < 0.125:
     shoot = false
     pass_action = true
    elif p.charge < 0.16 and rng.randf() < 0.03125:
     shoot = false
  # Defender in the lane: pass if the teammate is the clearer look (DRONE2.ASM drone_pass).
  if p.cooldown <= 0 and near_def < 55.0:
   if (mate_dist < dist - 30.0 and nearest_defender(mate) > 65.0) or fmod(elapsed, 2.0) < 0.025:
    pass_action = true
 elif not flight.is_empty() and flight.get("kind", "") == "shot":
  var shooter: int = flight.shooter
  if shooter / 2 != team:
   target = flight_position()
   var reacts: bool = flight.time >= 0.18-0.04*clampi(difficulty,0,2) and flight.get("cpu_block_allowed",[true,true,true,true])[i]
   # drone_defence blocks an airborne ball inside 65 units. It does not refuse a descending shot.
   shoot = reacts and not flight.blocked and p.cooldown <= 0 and p.pos.distance_to(target) < 65.0 * PX_PER_ASM and ball_height() <= 4.6
  else:
   target = hoop_for(team)
 elif not flight.is_empty() and (flight.get("kind", "") == "rebound" or flight.get("kind", "") == "loose"):
  var intercept_t = clampf((flight.time + REBOUND_GLIDE_DURATION) / maxf(flight.duration, 0.01), 0.0, 1.0)
  var predicted_point = flight.start.lerp(flight.end, intercept_t)
  target = flight.start.lerp(flight.end, clampf((flight.time + 0.35) / maxf(flight.duration, 0.01), 0.0, 1.0))
  var dist_to_target = p.pos.distance_to(target)
  var mate = (team * 2) + (1 - (i % 2))
  var mate_dist_to_target = players[mate].pos.distance_to(target)
  var ball_h = ball_height()
  var dist_to_ball = p.pos.distance_to(ball)
  var dist_to_pred = p.pos.distance_to(predicted_point)
  # Fast-break outlet spacing (DRONE.ASM:1880-1892): when teammate is much closer to rebound/loose ball, sprint to offensive 3pt outlet
  if dist_to_target > mate_dist_to_target + 90.0 and dist_to_target > 140.0 and dist_to_ball > 120.0 and players[mate].stun <= 0.0:
   var hoop = hoop_for(team)
   target = hoop + Vector2(-260.0 if hoop.x > 640 else 260.0, -70.0 if (i % 2 == 0) else 70.0)
   turbo = p.get("turbo", 1.0) > 0.25
  else:
   turbo = p.get("turbo", 1.0) > 0.20 and dist_to_target > 60.0
   var reacts = flight.time >= 0.10 - 0.03 * clampi(difficulty, 0, 2)
   var in_range = dist_to_ball < 95.0 or dist_to_pred < 115.0
   if reacts and in_range and ball_h <= 4.2 and in_cylinder_timer <= 0.0 and p.cooldown <= 0 and p.stun <= 0 and p.jump <= 0:
    shoot = true
 elif owner >= 0 and owner / 2 == team:
  var hoop = hoop_for(team)
  # Off-ball On-Fire drone spaces to 3-point arc instead of crowding the rim (DRONE.ASM:981-984)
  if is_player_on_fire(i):
   target = hoop + Vector2(-315.0 if hoop.x > 640 else 315.0, -90.0 if (i % 2 == 0) else 90.0)
  else:
   target = hoop
  var guard_dist = 1000.0
  var guard_id = -1
  for j in range(4):
   if j / 2 != team:
    var d = p.pos.distance_to(players[j].pos)
    if d < guard_dist:
     guard_dist = d
     guard_id = j
  # drone_offwoball pushes a defender within 50 units and 16/128 of facing.
  # #p_t is a 0-99 roll, not a per-thousand rate, and TE has no alley-oop rate table.
  var facing = Vector2(p.face, 0.0)
  var to_guard: Vector2 = players[guard_id].pos - p.pos if guard_id >= 0 else Vector2.ZERO
  var guard_in_front = guard_id >= 0 and to_guard.length() <= 50.0 * PX_PER_ASM and to_guard.length() > 0.01 and facing.dot(to_guard.normalized()) > cos(16.0 / 128.0 * TAU)
  if guard_in_front and players[guard_id].stun <= 0.0 and not no_pushing and p.cooldown <= 0.0 and rng.randi() % 100 < DRONE_P_T[skill_idx]:
   turbo = true
   pass_action = true
   shove = true
   if guard_dist > 25.0:
    target = players[guard_id].pos
 elif owner >= 0:
  var partner = (i / 2) * 2 + (1 - i % 2)
  var own_hoop = hoop_for(1 - team)
  var owner_dist_to_hoop = players[owner].pos.distance_to(own_hoop)
  var partner_beaten = owner_dist_to_hoop < 340.0 and players[partner].pos.distance_to(players[owner].pos) > 95.0
  var help_defense = players[partner].stun > 0.0 or partner_beaten or shot_clock < 5.0 or clock < 8.0 or (quarter >= 4 and deficit > 0)
  var mark = owner if (i % 2 == owner % 2 or help_defense) else (1 - team) * 2 + (1 - (owner % 2))
  # Under 8 seconds, a shot clock under 5, or the last 30 seconds of a quarter
  # when not ahead by 3, drone_defence forces nasty. Otherwise #nast_t can start one second of it.
  var forced_nasty = clock < 8.0 or (shot_clock >= 0.0 and shot_clock < 5.0) or (quarter >= 4 and clock < 30.0 and deficit > -3)
  if p.get("nasty_timer", 0.0) <= 0.0 and not forced_nasty and rng.randi_range(0, 999) < DRONE_NAST_T[skill_idx]:
   p.nasty_timer = 53.0 / ARCADE_TSEC
  var nasty = forced_nasty or p.get("nasty_timer", 0.0) > 0.0
  # Authentic DRONE.ASM sag: guard between offensive player and basket with DRONE_DIST_T cushion (DRONE.ASM:1425-1435)
  var to_own_hoop = (own_hoop - players[mark].pos).normalized()
  var sag_cushion = minf(float(DRONE_DIST_T[skill_idx]) * 1.0, owner_dist_to_hoop * 0.65)
  if is_player_on_fire(i) and owner_dist_to_hoop < 420.0:
   target = players[mark].pos.lerp(own_hoop, 0.42)
  elif nasty:
   target = players[mark].pos
  else:
   target = players[mark].pos + to_own_hoop * sag_cushion
  var dist_to_mark = p.pos.distance_to(players[mark].pos)
  var dist_to_owner = p.pos.distance_to(players[owner].pos)

  # Turbo on defense: close out when beaten or trailing in Q4 (DRONE.ASM:1450)
  var has_turbo_fuel = p.get("turbo", 1.0) > 0.15 and p.get("turbo_burnout", 0.0) <= 0.0
  var should_turbo = has_turbo_fuel and ((quarter >= 4 and deficit > 0) or nasty or dist_to_mark > 110.0 or (dist_to_owner <= 85.0 and dist_to_owner > 25.0 and difficulty >= 1) or (owner_dist_to_hoop < 220.0 and dist_to_owner <= 65.0))
  if should_turbo:
   turbo = true

  # drone_defence only re-rolls push/steal when plyr_d_seekcnt expires
  # (#skt_t, about 15 ticks at an even score). Closing-out turbo is not a push.
  # #ps adds steal, then half of those also hold turbo (DRONE2.ASM:845-1005).
  var seek = int(p.get("drone_seek", 0)) - 1
  if seek > 0:
   p.drone_seek = seek
  else:
   p.drone_seek = drone_defense_seek_ticks(skill_idx, oct_dist_asm(p.pos, own_hoop))
   var can_shove = not no_pushing and (p.get("turbo", 1.0) >= (10.0 / TE_TURBO_UNITS) or is_player_on_fire(i) or infinite_turbo) and p.cooldown <= 0.0
   var face_px = 35.0 * PX_PER_ASM
   var steal_px = float(DRONE_DIST_T[skill_idx]) * PX_PER_ASM
   var contact = nasty and dist_to_owner <= face_px
   if not contact and dist_to_owner <= steal_px:
    contact = rng.randi_range(0, 999) < DRONE_PS_T[skill_idx]
   if contact and players[owner].stun <= 0.0 and players[owner].get("steal_immune", 0.0) <= 0.0 and p.cooldown <= 0.0:
    if can_shove and rng.randi() % 2 == 0:
     shove = true
    pass_action = true
    if dist_to_owner > 25.0:
     target = players[owner].pos
 else:
  target = ball
 return {"move":(target - p.pos).normalized() if p.pos.distance_to(target) > 9 else Vector2.ZERO, "shoot":shoot, "pass":pass_action, "turbo":turbo, "shove":shove, "spin":spin}

func nearest_defender(i: int) -> float:
 var distance = 1000.0
 for j in range(4):
  if j / 2 != i / 2:
   distance = minf(distance, players[j].pos.distance_to(players[i].pos))
 return distance

static func three_point_geometry(side: int) -> Dictionary:
 var hoop: Vector2 = HOOPS[side]
 var direction = 1.0 if side == 0 else -1.0
 var arc_angle = asin(THREE_POINT_CORNER_OFFSET / THREE_POINT_RADIUS)
 var arc_x_offset = sqrt(THREE_POINT_RADIUS * THREE_POINT_RADIUS - THREE_POINT_CORNER_OFFSET * THREE_POINT_CORNER_OFFSET)
 return {
  "hoop": hoop,
  "radius": THREE_POINT_RADIUS,
  "arc_start": -arc_angle if side == 0 else PI - arc_angle,
  "arc_end": arc_angle if side == 0 else PI + arc_angle,
  "arc_join_x": hoop.x + direction * arc_x_offset,
  "top_y": hoop.y - THREE_POINT_CORNER_OFFSET,
  "bottom_y": hoop.y + THREE_POINT_CORNER_OFFSET,
  "baseline_x": COURT.position.x if side == 0 else COURT.end.x,
 }

func is_three_pointer(point: Vector2, hoop: Vector2) -> bool:
 var dy = absf(point.y - hoop.y)
 if dy > THREE_POINT_CORNER_OFFSET:
  return true
 return point.distance_to(hoop) > THREE_POINT_RADIUS

func calculate_defensive_contest(shooter: int, hoop: Vector2) -> Dictionary:
 var shooter_pos: Vector2 = players[shooter].pos
 var shot_vec = hoop - shooter_pos
 var shot_dist = shot_vec.length()
 if shot_dist < 0.001:
  return {"level":0.0,"defenders":[]}
 var shot_dir = shot_vec / shot_dist
 var primary_contest = 0.0
 var secondary_contest = 0.0
 var contesting: Array = []
 for j in range(4):
  if j / 2 == shooter / 2:
   continue
  var p_def: Dictionary = players[j]
  if p_def.get("stun",0.0) > 0.0:
   continue
  var def_vec = p_def.pos - shooter_pos
  var def_dist = def_vec.length()
  if def_dist > 145.0 or def_dist < 0.001:
   continue
  var def_dir = def_vec / def_dist
  var alignment = def_dir.dot(shot_dir)
  # Omnidirectional tight-in contest within 50 ASM units (~58px) (PLYR.ASM:5947-5949)
  if alignment < -0.15 and def_dist > 58.0:
   continue
  var cone = 0.85 if (alignment < -0.15 and def_dist <= 58.0) else clampf((alignment + 0.15) / 1.15, 0.0, 1.0)
  var prox = clampf((145.0 - def_dist) / 145.0, 0.0, 1.0)
  var vertical_mult = 1.5 if p_def.get("jump",0.0) > 0.0 else (1.2 if p_def.get("swipe",0.0) > 0.0 else 0.85)
  var def_skill = 0.75 + rating(j, 3) * 0.035
  var contest_val = cone * prox * vertical_mult * def_skill
  contesting.append({"id":j,"val":contest_val})
 contesting.sort_custom(func(a, b): return a.val > b.val)
 if contesting.size() > 0:
  primary_contest = contesting[0].val
 if contesting.size() > 1:
  secondary_contest = contesting[1].val * 0.45
 var total_contest = clampf(primary_contest + secondary_contest, 0.0, 1.0)
 var defender_ids: Array = []
 for d in contesting:
  defender_ids.append(d.id)
 return {"level":total_contest,"defenders":defender_ids}

func asm_units(px: float) -> int:
 return int(px / PX_PER_ASM)

# plyr_shoot sets reduce_3ptr for a 3 that started >= 270 units out, or an arc 3
# more than 0x16 units behind the line. Corner 3s inside 270 and heaves >= 400 do not.
func te_reduce_3ptr(point: Vector2, hoop: Vector2, three: bool) -> bool:
 if not three:
  return false
 var dist_asm = asm_units(point.distance_to(hoop))
 if dist_asm >= 400:
  return false
 if dist_asm >= 270:
  return true
 if absf(point.y - hoop.y) > THREE_POINT_CORNER_OFFSET:
  return false
 return asm_units(point.distance_to(hoop) - THREE_POINT_RADIUS) >= 22

# PLYR.ASM plyr_shoot defender adjustment. Within 40 units is a flat -240.
# Within 75 units and 20/128 of the hoop direction, subtract 390 - dist*4,
# scaled up when the defender is above the shooter.
func te_shot_contest(shooter: int, hoop: Vector2) -> Dictionary:
 var shooter_pos: Vector2 = players[shooter].pos
 var shot_vec = hoop - shooter_pos
 var shot_dist = shot_vec.length()
 if shot_dist < 0.001:
  return {"penalty":0, "defenders":[]}
 var shot_dir = shot_vec / shot_dist
 var lane_dot = cos(20.0 / 128.0 * TAU)
 var shooter_elev = body_elevation(shooter)
 var penalty = 0
 var defenders: Array = []
 for j in range(4):
  if j / 2 == shooter / 2:
   continue
  var rel: Vector2 = players[j].pos - shooter_pos
  var dist = rel.length()
  if dist < 0.001:
   continue
  var dist_asm = asm_units(dist)
  if dist_asm > 75:
   continue
  var pen = 0
  if dist_asm <= 40:
   pen += 240
  if (rel / dist).dot(shot_dir) >= lane_dot:
   var angled = dist_asm * 4 - 390
   var elev_px = (body_elevation(j) - shooter_elev) * (120.0 / 1.8)
   if elev_px > 0.0:
    angled = roundi(float(angled) * (elev_px + 8.0) / 8.0)
   pen += -angled
  if pen > 0:
   penalty += pen
   defenders.append(j)
 return {"penalty":penalty, "defenders":defenders}

func calculate_shot_percentage(i: int, charge: float, dunk: bool, layup: bool, specialty: bool, alley: bool = false, hook: bool = false, fadeaway: bool = false, moving_shot: Variant = null, bailed_to_layup: bool = false) -> Dictionary:
 var hoop = hoop_for(i / 2)
 var distance: float = players[i].pos.distance_to(hoop)
 var three_pointer = not dunk and not layup and not hook and is_three_pointer(players[i].pos, hoop)
 var delta_time = charge - 0.58
 var timing = exp(-(delta_time * delta_time) / (2.0 * 0.18 * 0.18))
 var is_moving_shot = false
 if moving_shot != null:
  is_moving_shot = bool(moving_shot)
 elif fadeaway:
  is_moving_shot = true
 elif i >= 0 and i < players.size():
  var p_shoot: Dictionary = players[i]
  is_moving_shot = p_shoot.get("shot_is_moving", false) or p_shoot.get("still_time", 1.0) < 0.10 or p_shoot.get("vel", Vector2.ZERO).length() > 10.0
 var my_team = i / 2
 var opp_team = 1 - my_team
 # Tournament mode clears plyr_ptsdown (assistance_off). Positive means this team is losing.
 var pts_down = 0 if tournament_mode else (score[opp_team] - score[my_team])
 var rubber_band = float(pts_down) * 0.02
 var sht_stat = clampi(int(rating(i, 1)), 0, 10)
 var skill = SHT_PERMILLE[sht_stat]
 var base = float(skill) / 1000.0
 var a9 = skill
 # Weak 3-point shooters only: PAT_SHOTSKILL <= 1025 (SHT0-SHT3) loses 200.
 if three_pointer and skill <= 1025:
  a9 -= 200
 if te_reduce_3ptr(players[i].pos, hoop, three_pointer):
  a9 -= 15
 var dist_asm = asm_units(distance)
 if dist_asm <= 0x70:
  a9 += 250
 if dist_asm >= 0x130:
  a9 -= 990
 var contest = te_shot_contest(i, hoop)
 var contest_penalty = float(contest.penalty) / 1000.0
 a9 -= int(contest.penalty)
 var dist_penalty = float(dist_asm * 2) / 1000.0
 a9 -= dist_asm * 2
 if a9 < 50:
  a9 = 50
 var lock_timing = false
 # brick_count >= 3 forces 990 at any distance. Later rules can still change it.
 if i >= 0 and i < brick_count.size() and brick_count[i] >= 3:
  a9 = 990
  lock_timing = true
 a9 += pts_down * 20
 if a9 < 50:
  a9 = 50
 # 55/1000 when tied or winning replaces the percent with 150.
 if rng.randf() < 0.055 and pts_down <= 0:
  a9 = 150
  lock_timing = true
 # game_time <= 0x400 (4.00s). Floors are raises; a tied Q4/OT shot is forced to 50.
 if clock <= 4.0:
  var shot_pts = 3 if three_pointer else 2
  if pts_down == 0:
   if quarter >= 4:
    a9 = 50
    lock_timing = true
  elif pts_down < 0:
   if pts_down <= -5 and quarter >= 4:
    var win_floor = 300 if clock > 2.0 else 120
    if a9 < win_floor:
     a9 = win_floor
     lock_timing = true
  else:
   var lose_floor = 100
   if quarter >= 4:
    if pts_down >= 4:
     lose_floor = 300
    elif pts_down == shot_pts:
     lose_floor = 800
    else:
     lose_floor = 380
   elif pts_down > 5 or pts_down == shot_pts:
    lose_floor = 120
   if a9 < lose_floor:
    a9 = lose_floor
    lock_timing = true
 var fire_bonus = 0.0
 if is_player_on_fire(i):
  a9 += 750
  fire_bonus = 0.75
  if dist_asm >= 0x148:
   a9 = 100
   fire_bonus = 0.0
   lock_timing = true
 if dunk:
  a9 += 760
  lock_timing = true
 elif layup or bailed_to_layup:
  # lay_perc replaces the jumper percent. On-fire does not survive this.
  a9 = 870
  base = 0.87
  fire_bonus = 0.0
  lock_timing = true
  if pts_down <= 0 and rng.randf() < 0.10:
   a9 = 450
   base = 0.45
 elif hook:
  a9 = 600
  base = 0.60
  fire_bonus = 0.0
  lock_timing = true
  if rng.randf() < 0.12:
   a9 = 250
   base = 0.25
 var timing_contrib = 0.0
 if not lock_timing:
  var scaled = roundi(float(a9) * timing)
  timing_contrib = float(scaled - a9) / 1000.0
  a9 = maxi(50, scaled)
 var final_chance = clampf(float(a9) / 1000.0, 0.0, 1.0)
 var percentage = roundf(final_chance * 1000.0) / 10.0
 var quality = "PERFECT" if timing > 0.93 else ("GREAT" if timing > 0.75 else ("GOOD" if timing > 0.50 else ("EARLY" if charge < 0.58 else "LATE")))
 var contest_level = clampf(contest_penalty, 0.0, 1.0)
 return {
  "chance":final_chance,
  "percentage":percentage,
  "base":base,
  "timing":timing,
  "timing_contrib":timing_contrib,
  "dist_penalty":dist_penalty,
  "contest_penalty":contest_penalty,
  "contest_level":contest_level,
  "defenders":contest.defenders,
  "rubber_band":rubber_band,
  "fire_bonus":fire_bonus,
  "three_pointer":three_pointer,
  "dunk":dunk,
  "layup":layup or bailed_to_layup,
  "specialty":specialty,
  "hook":hook,
  "fadeaway":fadeaway,
  "moving_shot":is_moving_shot,
  "still_shot":not is_moving_shot,
  "moving_penalty":0.0,
  "still_bonus":0.0,
  "quality":quality
 }

func calculate_rim_ricochet(start_pos: Vector2, hoop: Vector2) -> Vector2:
 var left_hoop = hoop.x < 640
 var bounce_x = hoop.x + rng.randf_range(80.0, 240.0) if left_hoop else hoop.x - rng.randf_range(80.0, 240.0)
 var bounce_y = clampf(hoop.y + rng.randf_range(-85.0, 85.0), COURT.position.y + 35.0, COURT.end.y - 35.0)
 return Vector2(bounce_x, bounce_y)

func terminal_speed(i: int, turbo_on: bool, diagonal: bool) -> float:
 # Each tick drops XZ velocity by 1/4, then adds a14. Terminal velocity is 4*a14.
 # a14 starts as plyr_bvel<<4 (PLYR.ASM movement). Hoop span 640 maps onto our 950.
 var accel = BV_TABLE[clampi(int(rating(i, 0)), 0, 10)] << 4
 var mine = owner == i
 var teammate = owner >= 0 and owner / 2 == i / 2 and not mine
 if mine or teammate:
  accel -= 0xe80
 if mine:
  accel -= 0x1100
  var losing = score[1 - i / 2] > score[i / 2]
  # Shot clock has left the stuck [1,0] "10" value, carrier is past half court, and is not losing.
  if oct_dist_asm(players[i].pos, hoop_for(i / 2)) > float(0x174) and shot_clock >= 0.0 and shot_clock < 10.0 and not losing:
   accel -= 0x3000
 if clock < 50.0 and score[1 - i / 2] > score[i / 2]:
  accel += 0x1c00
 if turbo_on:
  accel += 0x3e00
 if diagonal:
  accel -= accel >> 3
 var px_per_tick = float(accel) * 4.0 / 65536.0
 var speed = px_per_tick * ARCADE_TSEC * PX_PER_ASM
 if diagonal:
  speed *= sqrt(2.0)
 return maxf(0.0, speed)

func oct_dist_asm(a: Vector2, b: Vector2) -> float:
 var delta = (a - b) / PX_PER_ASM
 var longer = maxf(absf(delta.x), absf(delta.y))
 var shorter = minf(absf(delta.x), absf(delta.y))
 return longer + shorter * 0.375

func seek_dir_128(src: Vector2, dest: Vector2) -> int:
 var a0 = int(round((src.x - dest.x) / PX_PER_ASM))
 var a1 = int(round((src.y - dest.y) / PX_PER_ASM))
 var a2 = 0
 var swap = 0
 if a0 > 0:
  a0 = absi(a0)
  if a1 >= 0:
   a2 = 16
  else:
   a2 = 24
   a1 = absi(a1)
   swap = a0
   a0 = a1
   a1 = swap
 else:
  a0 = absi(a0)
  if a1 >= 0:
   a2 = 0
  else:
   a2 = 8
   a1 = absi(a1)
   swap = a0
   a0 = a1
   a1 = swap
 a2 = a2 << 2
 var step = 0
 var acc = 0
 if a0 >= a1:
  a2 += 31
  step = a0 >> 4
  if step != 0:
   while acc < a1:
    a2 -= 1
    acc += step
 else:
  step = a1 >> 4
  if step != 0:
   while acc < a0:
    a2 += 1
    acc += step
 return a2 & 127

func dir_delta_128(a: int, b: int) -> int:
 var delta = absi(a - b)
 if delta > 64:
  delta = 128 - delta
 return delta

# seekdirdist_obxz128's 0-127 angle, rounded to the 8 sequence directions.
func dir_sector(src: Vector2, dest: Vector2) -> int:
 return ((seek_dir_128(src, dest) + 8) & 127) >> 4

func passer_seqdir(i: int) -> int:
 var p: Dictionary = players[i]
 var aim: Vector2 = p.vel
 if aim.length() <= 10.0:
  var face = float(p.face)
  aim = Vector2(face if absf(face) > 0.01 else 1.0, 0.0)
 return dir_sector(p.pos, p.pos + aim)

# plyr_startpass no-look buckets (PLYR.ASM:5449). A hit skips PASSBH.
func nolook_angles(seqdir: int, tm: int) -> bool:
 if seqdir < 3:
  if tm == 2 or tm == 7:
   return true
 elif seqdir >= 6:
  if tm == 6 or tm == 1:
   return true
 if seqdir < 2:
  return false
 if seqdir < 5:
  return tm == 5 or tm == 2
 if seqdir == 7:
  return false
 return tm == 6

# #bhcont direction buckets (PLYR.ASM:5595).
func bh_angles(seqdir: int, tm: int) -> bool:
 if seqdir < 2 or seqdir == 7:
  if seqdir == 7:
   return tm == 5 or tm == 6
  return tm == 2 or tm == 3
 if seqdir >= 5:
  return tm >= 6
 return tm == 1 or tm == 2

# PASSBH_SEQ: 35% once the spacing, skill, inbound, and angle gates pass.
func behind_back_pass(i: int, mate: int) -> bool:
 if players[i].jump > 0.0:
  return false
 var dist = oct_dist_asm(players[i].pos, players[mate].pos)
 var seqdir = passer_seqdir(i)
 var tm = dir_sector(players[i].pos, players[mate].pos)
 if inbounding_team < 0 and dist >= 70.0 and dist <= 320.0 and nolook_angles(seqdir, tm):
  if rng.randi_range(0, 7) == 0:
   return false
 if dist < 90.0 or dist > 360.0:
  return false
 if rating(i, 5) < 5.0:
  return false
 var opp = (1 - int(i / 2)) * 2
 if oct_dist_asm(players[i].pos, players[opp].pos) < float(0x78):
  return false
 if oct_dist_asm(players[i].pos, players[opp + 1].pos) < float(0x78):
  return false
 # Inbound BH only when ahead by 7 or more (ptsdown <= -7).
 if inbounding_team >= 0:
  var pts_down = score[1 - int(i / 2)] - score[int(i / 2)]
  if pts_down > -7:
   return false
 if rng.randi_range(0, 999) >= 350:
  return false
 return bh_angles(seqdir, tm)

func behind_hoop(i: int, pos: Vector2) -> bool:
 var hoop = hoop_for(i / 2)
 var sector = ((seek_dir_128(pos, hoop) + 8) & 127) >> 4
 if hoop.x > 640.0:
  return sector >= 5
 return sector >= 1 and sector <= 3

func hook_z_ok(y: float) -> bool:
 var z = 1000.0 + ((y - COURT.position.y) / COURT.size.y) * (1389.0 - 1000.0)
 return z >= float(0x430) and z <= float(0x4fa)

func lane_blocks_dunk(i: int, hoop: Vector2) -> bool:
 var p: Dictionary = players[i]
 var dist_asm = oct_dist_asm(p.pos, hoop)
 var hoop_dir = seek_dir_128(p.pos, hoop)
 for j in range(4):
  if j / 2 == i / 2 or players[j].get("stun", 0.0) > 0.0:
   continue
  var def_dist = oct_dist_asm(p.pos, players[j].pos)
  if dist_asm < def_dist:
   continue
  var def_idx = 11 if is_player_on_fire(j) else clampi(int(rating(j, 3)), 0, 10)
  if def_dist > float(DEF_DIST_T[def_idx]):
   continue
  var width = DEF_WIDTH_T[def_idx]
  if dir_delta_128(seek_dir_128(p.pos, players[j].pos), hoop_dir) < width:
   return true
 return false

func finish_kind(i: int, turbo: bool, alley: bool = false) -> String:
 if alley:
  return "alley_oop"
 var p: Dictionary = players[i]
 var hoop = hoop_for(i / 2)
 var dist_asm = oct_dist_asm(p.pos, hoop)
 var hoop_dir_vec = hoop - p.pos
 var vel_dir = p.vel.normalized() if p.vel.length() > 10.0 else Vector2(p.face, 0.0)
 var directness = vel_dir.dot(hoop_dir_vec.normalized()) if hoop_dir_vec.length() > 0.001 else 1.0
 # Hook is chosen before the dunk attempt when the carrier is sideways, 64-200 units out, in the mid Z band.
 if not turbo and dist_asm >= float(0x40) and dist_asm < 200.0 and directness < 0.65 and directness > -0.65 and p.vel.length() > 30.0 and hook_z_ok(p.pos.y):
  return "hook_shot"
 if behind_hoop(i, p.pos) or dist_asm >= 170.0:
  return "jumper"
 var axis_min = ARCADE_TSEC * PX_PER_ASM
 var moving = absf(p.vel.x) >= axis_min or absf(p.vel.y) >= axis_min
 var facing = false
 if p.vel.length() > 10.0:
  facing = dir_delta_128(seek_dir_128(p.pos, p.pos + p.vel), seek_dir_128(p.pos, hoop)) <= 24
 if dist_asm > 60.0 and (not moving or not facing):
  return "jumper"
 var pwr_stat = clampi(int(rating(i, 6)), 0, 10)
 var dunk_through = rng.randf() < DNKTHRU_T[pwr_stat]
 if not dunk_through and lane_blocks_dunk(i, hoop):
  # HCOUNT bit 0 sends half of these to a jumper. Layup distance is 35..138.
  if (rng.randi() & 1) == 0 and dist_asm > 35.0 and dist_asm < 138.0:
   return "layup"
  return "jumper"
 if dist_asm > 80.0 and not turbo:
  return "jumper"
 if turbo and dist_asm > 80.0:
  return "turbo_dunk"
 return "dunk"

func dunk_rim_ticks(dist_asm: float) -> float:
 if dist_asm <= 60.0:
  return 37.0
 if dist_asm <= 80.0:
  return 64.0
 return 74.0

# Feet follow seq_strtdunk: v = GRAV/2*ticks plus the 108px rise to the rim.
# Short dunks arrive at the top. Longer ones peak above the rim and slam down.
func dunk_body_lift(progress: float, ticks: float) -> float:
 var span = maxf(ticks, 1.0)
 var t = clampf(progress, 0.0, 1.0) * span
 var v0 = DUNK_GRAVITY * 0.5 * span + DUNK_SLAM_PX / span
 var px = v0 * t - 0.5 * DUNK_GRAVITY * t * t
 # The cabinet ani point arrives at the rim. Our body origin is the feet, so
 # drop the curve until the slam puts the raised hands on the rim.
 var above_slam = maxf(0.0, px) * DUNK_METERS_PER_PX - DUNK_SLAM_PX * DUNK_METERS_PER_PX
 return maxf(0.0, DUNK_SLAM_LIFT + above_slam)

func choose_dunk_style(i: int, dist_asm: float, turbo: bool, burning: bool) -> String:
 var sector = dir_sector(players[i].pos, hoop_for(i / 2))
 var facing = [0, 1, 2, 3, 4, 3, 2, 1][clampi(sector, 0, 7)]
 var pool: Array = DUNK_UNDER[facing]
 if dist_asm > 80.0 and turbo:
  pool = DUNK_FANCY[facing]
 elif dist_asm > 60.0:
  pool = DUNK_FANCY[facing] if burning else DUNK_SHORT[facing]
 elif burning:
  pool = DUNK_UNDER[facing]
 return str(pool[rng.randi() % pool.size()])

# plyr_shoot #calcshot. Octagonal ASM pixels, excess past 170 divided by 8,
# times 110/256. At the rim the floor is 50 ticks; a flat arc floors at 35
# after the 3/4 cut. Hooks then add 15. Every shot adds the final 2 ticks.
# Seconds are ticks / ARCADE_TSEC so a 50-tick release lasts 0.94s, matching
# the 53.2 Hz cabinet rather than a 60 Hz frame.
func shot_flight_ticks(dist_asm: float, flat: bool, hook: bool, rainbow: bool) -> float:
 var d = dist_asm
 if d > 170.0:
  d = 170.0 + (d - 170.0) / 8.0
 var ticks = d * 110.0 / 256.0
 if flat:
  ticks = maxf(35.0, ticks * 0.75)
 else:
  ticks = maxf(50.0, ticks)
 if hook:
  ticks += 15.0
 if rainbow:
  ticks += 20.0
 return ticks + 2.0

# lay_perc's second roll. A hit blocks every ball touch for TSEC*2 (PLYR.ASM:4716).
func roll_layup_touch_lock() -> void:
 if rng.randi_range(0, 999) < 700:
  ball_touch_lock = TE_LAYUP_TOUCH_LOCK

func shoot_ball(i: int, turbo: bool, alley: bool = false, release_height: float = 1.3) -> void:
 if shot_past_half_court(i / 2, players[i].pos):
  return
 teammate_shot_order = -1
 inbound_transition = {}
 inbounding_team = -1
 var p: Dictionary = players[i]
 p.fake = 0.0
 p.dribble_locked = false
 var hoop = hoop_for(i / 2)
 var distance: float = p.pos.distance_to(hoop)
 var locked_finish = str(p.get("shot_finish", ""))
 var finish = locked_finish if locked_finish != "" else finish_kind(i, turbo, alley)
 p.shot_finish = ""
 var dunk = finish in ["dunk","turbo_dunk","alley_oop"]
 var specialty = finish in ["turbo_dunk","alley_oop"]
 var layup = finish == "layup"
 var hook = finish == "hook_shot"
 var launch_height = receive_height(i) if alley else 0.0
 p.receive_jump = 0.0
 var hoop_vec = hoop - p.pos
 var any_on_fire = fire_player >= 0
 # plyr_shoot seeks (ohoopx, CZMID). abs((dir & 63) - 32) >= 24 is a bad glass angle.
 # Close (<=100) banks 1/5 from in front and 1/4 from the wing, and always uses the make.
 # Anyone on fire cancels that close bank. Long shots bank only from in front, on 1/4 of releases, and only when the percentage makes.
 var hoop_dir = seek_dir_128(p.pos, hoop)
 var bank_offset = absi((hoop_dir & 63) - 32)
 var bank_dist = oct_dist_asm(p.pos, hoop)
 var close_bank = false
 var long_bank = false
 if not dunk and not alley and bank_offset < 24:
  if bank_dist <= 100.0:
   if not any_on_fire:
    var faces = 4 if bank_offset < 16 else 3
    if rng.randi_range(0, faces) == 0:
     close_bank = true
  elif bank_offset < 16 and rng.randi_range(0, 3) == 0:
   long_bank = true
 var fadeaway = not dunk and not layup and not hook and not alley and p.vel.length() > 20.0 and p.vel.dot(hoop_vec.normalized()) < -15.0
 var moving_shot = p.get("shot_is_moving", false) if p.has("shot_is_moving") else (p.get("still_time", 1.0) < 0.10 or p.vel.length() > 10.0)
 if fadeaway:
  moving_shot = true
  p.vel = -(hoop_vec.normalized()) * 55.0
  p.jump = 0.52
 var breakdown = calculate_shot_percentage(i, p.charge, dunk, layup, specialty, alley, hook, fadeaway, moving_shot)
 # The release consumes the shot meter. Leaving it charged holds the shooter
 # in the jump-shot pose after the ball is gone, including a denied dunk.
 p.charge = 0.0
 var chance: float = breakdown.chance
 var points = 2 if dunk else (3 if breakdown.three_pointer else 2)
 var burning = is_player_on_fire(i)
 var dunk_style = "standard"
 if dunk:
  dunk_style = choose_dunk_style(i, oct_dist_asm(p.pos, hoop), turbo or specialty, burning)
 if dunk:
  points = 2
  p.jump = 0.95 if burning else (0.85 if specialty else 0.70)
 else:
  if not fadeaway:
   p.jump = 0.58 if hook else (0.55 if layup else 0.50)
   if not dunk and not layup and not hook:
    if moving_shot:
     if p.get("shot_drift_vel", Vector2.ZERO).length() > 0:
      p.vel = p.shot_drift_vel
     elif p.vel.length() > 10.0:
      p.shot_drift_vel = p.vel * 0.70
      p.vel = p.shot_drift_vel
    else:
     p.vel = Vector2.ZERO
     p.shot_drift_vel = Vector2.ZERO
 p.drive = 0.0
 stats[i].attempts += 1
 var will_make = rng.randf() < chance
 var clank = false
 var airball = false
 var my_team = i / 2
 var opp_team = 1 - my_team
 var pts_down = score[opp_team] - score[my_team]
 var any_fire = fire_player >= 0
 # Unblocked dunks always make except for 2.5% clank when leading/up by 1 and nobody is on fire (PLYR2.ASM:5357-5373)
 if dunk:
  will_make = true
  if pts_down < 2 and not any_fire and not specialty:
   if rng.randf() < 0.025:
    will_make = false
    clank = true
 elif close_bank:
  will_make = true
 elif not long_bank and not layup and not hook and not alley and pts_down < 2 and not any_fire and nearest_defender(i) <= 56.0:
  # Contested jump-shot airball roll when defender within 50*DIST_REDUCTION (56px), not trailing by 2+, and nobody is on fire (PLYR.ASM:6430-6488)
  var air_prob = 0.12 if (distance > 380.0 and chance < 0.06) else (1.0 / 128.0 if distance < 65.0 else 1.0 / 32.0)
  if rng.randf() < air_prob:
   will_make = false
   airball = true
 var bank_shot = close_bank or (long_bank and will_make)
 # A10 starts at the hoop. RNDPER(16) flattens any release. Layups roll another
 # RNDPER(100). A close bank always clears A10. Hooks stay on the 50-tick
 # floor and then add 15, so they are slower than a layup, not faster.
 var flat_arc = false
 var rainbow = false
 if not dunk:
  var arc_roll = rng.randf()
  flat_arc = arc_roll < 0.016 or close_bank
  if layup and not flat_arc and rng.randf() < 0.10:
   flat_arc = true
  rainbow = not flat_arc and arc_roll >= 0.016 and arc_roll < 0.026 and bank_dist < 260.0
 # seq_strtdunk tick count is the time to the rim (PLYRDSEQ). Fire uses getdunkseq's
 # skill-5 table, not a longer timer. Under 60 / under 80 / beyond are DUNKB2 (37),
 # DUNKLAY7 (64), and DUNKL/DUNKQ (74).
 var dunk_motion_ticks = float(DUNK_TICKS.get(dunk_style, dunk_rim_ticks(oct_dist_asm(p.pos, hoop))))
 var dunk_duration = dunk_motion_ticks / ARCADE_TSEC
 var dunk_arc = 4.5 if burning else (3.0 if specialty else 1.6)
 var jumper_arc = 3.3 if flat_arc else 4.6
 var shot_ticks = shot_flight_ticks(oct_dist_asm(ball, hoop), flat_arc, hook, rainbow)
 var shot_duration = shot_ticks / ARCADE_TSEC
 var shot_time = dunk_duration if dunk else shot_duration
 var in_hand_until = SHOT_HAND_TICKS / ARCADE_TSEC
 if dunk:
  in_hand_until = shot_time * DUNK_HAND_RELEASE
 flight = {"kind":"shot", "start":ball, "end":hoop, "time":0.0, "duration":shot_time, "shooter":i, "points":points, "made":will_make, "dunk":dunk, "layup":layup, "hook":hook, "fadeaway":fadeaway, "super_dunk":specialty or burning, "dunk_style":dunk_style, "dunk_ticks":dunk_motion_ticks if dunk else 0.0, "hang_ticks":float(DUNK_HANG_TICKS.get(dunk_style, 64)), "finish":finish, "arc_height":(3.6 if turbo else 2.5) if hook else (dunk_arc if dunk else (1.0 if layup else jumper_arc)), "blocked":false, "shot_breakdown":breakdown, "clank":clank, "airball":airball, "flat_arc":flat_arc, "bank_shot":bank_shot, "moving_shot":moving_shot, "shot_dist":oct_dist_asm(p.pos, hoop), "in_hand_until":in_hand_until}
 if dunk or layup or hook:
  flight.player_start = p.pos
  flight.player_end = hoop+Vector2(-1 if hoop.x > 640 else 1,0)*(28 if dunk else 50)
  flight.player_launch_height = launch_height
 flight.release_height = release_height
 flight.cpu_block_allowed = []
 for defender in range(4):
  var def_skill_idx = drone_skill_index(defender)
  var blk_prob = float(DRONE_BLK_T[def_skill_idx]) * 0.01
  if dunk:
   var def_blk_stat = clampi(int(rating(defender, 3)), 0, 10)
   blk_prob *= 0.5 * (float(TRYBLK_T[def_blk_stat]) / 25.0)
  if players[defender].get("nasty_timer", 0.0) > 0.0:
   blk_prob = minf(0.75, blk_prob * 2.0)
  flight.cpu_block_allowed.append(rng.randf() < blk_prob)
 owner = -1
 p.cooldown = 0.65
 last_shot_feedback = {
  "shooter": i,
  "percentage": breakdown.percentage,
  "quality": breakdown.quality,
  "contest_level": breakdown.contest_level,
  "time": elapsed,
  "points": points,
  "made": will_make,
  "dunk": dunk,
  "moving_shot": moving_shot,
  "still_shot": not moving_shot
 }
 var callout = "UP IT GOES"
 if dunk:
  match dunk_style:
   "helicopter": callout = "HELICOPTER SLAM!"
   "frontflip": callout = "SOMERSAULT JAM!"
   "backflip": callout = "BACKFLIP DUNK!"
   "spin_360": callout = "360 WINDMILL!"
   "between_legs": callout = "BETWEEN THE LEGS!"
   "behind_back", "behind_head": callout = "BEHIND THE HEAD!"
   "windmill": callout = "WINDMILL!"
   "tomahawk": callout = "TOMAHAWK JAM!"
   "cradle": callout = "CRADLE DUNK!"
   "switch": callout = "SWITCH HANDS!"
   "reverse": callout = "REVERSE JAM!"
   _: callout = "BOOMSHAKALAKA!" if burning or specialty else "SLAM DUNK!"
 elif fadeaway:
  callout = "FADEAWAY JUMPER!"
 elif hook:
  callout = "HOOK SHOT!"
 elif layup:
  callout = "LAY IT UP!"
 elif moving_shot:
  callout = "PERFECT RELEASE!" if breakdown.quality == "PERFECT" else "PULL-UP JUMPER!"
 else:
  callout = "PERFECT RELEASE!" if breakdown.quality == "PERFECT" else ("FROM DOWNTOWN!" if points == 3 else "UP IT GOES")
 if layup:
  roll_layup_touch_lock()
 # scored_speech plays the jam line once, when the dunk goes in. Saying it
 # again here repeats "slams it" on the way up.
 if not dunk:
  announce(callout, "shot")

# plyr_dirtime counts ticks the stick has held one sector. A release clears it.
func note_dir_time(p: Dictionary, move: Vector2, delta: float) -> void:
 if move.length() < 0.05:
  p.dir_time = 0.0
  return
 var sector = dir_sector(Vector2.ZERO, move.normalized() * 128.0)
 if sector != int(p.get("dir_sector", -1)):
  p.dir_sector = sector
  p.dir_time = 0.0
  return
 p.dir_time = float(p.get("dir_time", 0.0)) + delta * ARCADE_TSEC

# plyr_startpass leads after 8 ticks in one direction. Under that, a defender
# inside 25 or a teammate inside 30 keeps the pass on the receiver's feet.
# No-look passes wait until 10 ticks. A jump never leads. Stick release zeros
# velocity on the same frame, so the dirtime-0 coin flip has nothing to lead.
func pass_should_lead(passer: int, mate: int, behind_back: bool) -> bool:
 var mate_p: Dictionary = players[mate]
 if mate_p.jump > 0.0:
  return false
 var dir_time = float(mate_p.get("dir_time", 0.0))
 if behind_back and dir_time < 10.0:
  return false
 if dir_time > 8.0:
  return true
 if dir_time <= 0.0:
  return false
 var opp = (1 - int(mate / 2)) * 2
 var close = oct_dist_asm(mate_p.pos, players[opp].pos) < 25.0 or oct_dist_asm(mate_p.pos, players[opp + 1].pos) < 25.0
 if not close:
  return true
 if oct_dist_asm(players[passer].pos, mate_p.pos) < 30.0:
  return false
 return dir_time > 4.0

# plyr_pass #bndlp. One velocity step per flight tick, then stop on the glass.
func walked_pass_target(mate: int, ticks: int) -> Vector2:
 var mate_p: Dictionary = players[mate]
 var step: Vector2 = mate_p.vel / ARCADE_TSEC
 if step.length() < 0.01:
  return mate_p.pos
 var pos: Vector2 = mate_p.pos
 var min_x = asm_spot(-337.0, 0.0).x
 var max_x = asm_spot(328.0, 0.0).x
 var min_y = asm_spot(0.0, 1008.0 - 1170.0).y
 var max_y = asm_spot(0.0, 1383.0 - 1170.0).y
 for _step in range(maxi(0, ticks)):
  pos += step
  if pos.x <= min_x or pos.x >= max_x or pos.y <= min_y or pos.y >= max_y:
   break
 return pos

# A downed receiver cannot hold the ball. Keep the pass speed and carry it past them.
func release_uncatchable_pass(receiver: int) -> void:
 var travel: Vector2 = flight.end - flight.start
 var speed = travel.length() / maxf(float(flight.duration), 0.01)
 var dir = travel.normalized() if travel.length() > 1.0 else Vector2(players[receiver].face, 0.0)
 var extra = 0.40
 var dest = (flight.end + dir * speed * extra).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
 var was_alley = flight.get("alley", false) or flight.get("double_dunk", false)
 ball = flight.end
 owner = -1
 flight = {"kind":"loose", "start":ball, "end":dest, "time":0.0, "duration":extra, "arc_height":0.45, "shooter":-1}
 players[receiver].pickup_delay = maxf(players[receiver].get("pickup_delay", 0.0), players[receiver].stun)
 if was_alley:
  announce("LOB MISSED! LOOSE BALL", "miss")

func pass_ball(i: int, turbo: bool) -> void:
 teammate_shot_order = -1
 players[i].fake = 0.0
 players[i].dribble_locked = false
 var release_height = ball_height() if not flight.is_empty() and flight.get("kind","") == "shot" else 1.1
 var mate = (i / 2) * 2 + (1 - i % 2)
 var alley = turbo and players[mate].receive_jump > 0 and players[mate].stun <= 0 and players[mate].pos.distance_to(hoop_for(i / 2)) < 220
 var pass_stat = clampi(int(rating(i, 5)), 0, 10)
 # plyr_pass: octagonal distance, long table above 300, else short, minus turbo, floor 16 ticks.
 var arcade_dist = oct_dist_asm(ball, players[mate].pos)
 var factor = float(LONGPAS_T[pass_stat]) if arcade_dist > 300.0 else float(SHORTPAS_T[pass_stat])
 if turbo:
  factor -= float(TURBOPAS_T[pass_stat])
 var ticks = maxf(16.0, (arcade_dist * factor) / 1024.0)
 var duration = ticks / ARCADE_TSEC
 if fast_passing:
  duration *= 0.50
 var behind_back = false if alley else behind_back_pass(i, mate)
 # plyr_pass walks the receiver's velocity for the flight, stopping at the court edge.
 # Alley lobs stay on the jumper. A jump, a short run, or a close defender skips the lead.
 var end = players[mate].pos
 if not alley and pass_should_lead(i, mate, behind_back):
  end = walked_pass_target(mate, maxi(1, int(duration * ARCADE_TSEC + 0.001)))
 flight = {"kind":"pass", "start":ball, "end":end, "start_height":release_height, "end_height":3.8 if alley else 1.1, "time":0.0, "duration":0.38 if alley else duration, "target":mate, "passer":i, "alley":alley, "turbo":turbo, "behind_back":behind_back}
 owner = -1
 inbounding_team = -1
 # assist_plyr / assist_delay are stored when the pass starts, not when it is caught.
 last_passer = i
 assist_window = 210.0 / ARCADE_TSEC
 players[i].cooldown = 0.45
 announce("LOB IT UP!" if alley else ("BEHIND THE BACK PASS!" if behind_back else "NICE PASS"), "pass")

# BLOCKREB tightens Z by 6 and limits X to tbl4 past the hand. The 30-pixel glide
# is how far seq_block can still slide before that box is tested. tbl3's +15
# applies only at or below RUNDRIBTURB; a block image uses the raised hand, so
# the ball only has to be within 3px of that image top. This sim has no sprite
# origin, so the existing 4.6m cap remains the vertical gate.
func block_contact_box(defender: int, ball_high: bool) -> Vector2:
 var skill = clampi(int(rating(defender, 3)), 0, 10)
 var z_asm = float(TBL1_Z[skill] if ball_high else TBL2_Z[skill]) - 6.0
 var x_asm = float(BLK_REACH_T[skill])
 return Vector2((BLOCK_GLIDE_ASM + x_asm) * PX_PER_ASM, (BLOCK_GLIDE_ASM + z_asm) * PX_PER_ASM)

func defend(i: int, turbo: bool) -> void:
 players[i].vel = Vector2.ZERO
 players[i].jump = 0.70
 players[i].cooldown = 0.75
 if must_rebound_timer > 0.0 or (not flight.is_empty() and (flight.get("kind", "") == "rebound" or flight.get("kind", "") == "loose")):
  var shooter = flight.get("shooter", -1)
  var is_defense = (shooter < 0 or shooter / 2 != i / 2)
  # plyr_tryrebound skips the shooter and teammate only while game_time is under 0:05.
  if not is_defense and flight.get("kind", "") == "rebound" and clock < 5.0:
   players[i].jump = 0.75
   return
  players[i].jump = 0.75
  if not flight.is_empty():
   var intercept_t = clampf((flight.time + REBOUND_GLIDE_DURATION) / maxf(flight.duration, 0.01), 0.0, 1.0)
   var predicted_point = flight.start.lerp(flight.end, intercept_t)
   var delta_pos = predicted_point - players[i].pos
   if delta_pos.length() > 0.1:
    var rebound_vel = delta_pos / REBOUND_GLIDE_DURATION
    players[i].vel = rebound_vel.limit_length(260.0)
    players[i].rebound_glide = REBOUND_GLIDE_DURATION
  return
 if not flight.is_empty() and flight.get("kind", "") == "shot":
  players[i].blocking = true
  if ball_touch_lock > 0.0:
   return
  start_block_glide(i)
  try_shot_block(i)
  return
 elif owner >= 0 and owner / 2 != i / 2:
  steal(i, turbo)

# #chkbb. A ball that reaches the glass from behind reverses. The display arc
# is not the collision height: a shot aimed at the rim meets the board.
func glass_plane_x(hoop: Vector2) -> float:
 var away = 1.0 if hoop.x > 640.0 else -1.0
 return hoop.x + away * GLASS_BEHIND_ASM * PX_PER_ASM

func crossed_back_glass(prev: Vector2, nxt: Vector2, hoop: Vector2) -> bool:
 var plane = glass_plane_x(hoop)
 if hoop.x > 640.0:
  return prev.x >= plane and nxt.x < plane
 return prev.x <= plane and nxt.x > plane

func bounce_back_glass(delta: float) -> bool:
 if flight.get("kind", "") != "shot" or flight.get("glass_back", false):
  return false
 var hoop: Vector2 = flight.end
 var prev: Vector2 = flight_position()
 var next_t = clampf((flight.time + delta) / maxf(flight.duration, 0.01), 0.0, 1.0)
 var nxt: Vector2 = flight.start.lerp(flight.end, next_t)
 if not crossed_back_glass(prev, nxt, hoop):
  return false
 var plane = glass_plane_x(hoop)
 var denom = nxt.x - prev.x
 var along = 0.0 if absf(denom) < 0.001 else clampf((plane - prev.x) / denom, 0.0, 1.0)
 var hit = prev.lerp(nxt, along)
 if absf(hit.y - hoop.y) >= GLASS_Z_ASM * PX_PER_ASM:
  return false
 var shooter = int(flight.get("shooter", -1))
 var travel: Vector2 = flight.end - flight.start
 var speed = travel / maxf(float(flight.duration), 0.01)
 speed.x = -speed.x
 var remain = 0.45
 var dest = (hit + speed * remain).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
 if shooter >= 0:
  record_miss(shooter)
 ball = hit
 owner = -1
 flight = {"kind": "loose", "start": hit, "end": dest, "time": 0.0, "duration": remain, "arc_height": 0.55, "shooter": shooter, "glass_back": true}
 announce("OFF THE GLASS!", "miss")
 return true

# seq_block looks 30 ticks ahead and slides at most 30 pixels toward that spot.
func start_block_glide(i: int) -> void:
 if flight.is_empty() or flight.get("kind", "") != "shot":
  return
 var ahead = minf(flight.time + 30.0 / ARCADE_TSEC, flight.duration)
 var dest = flight.start.lerp(flight.end, clampf(ahead / maxf(flight.duration, 0.01), 0.0, 1.0))
 var delta_pos: Vector2 = dest - players[i].pos
 var cap = BLOCK_GLIDE_ASM * PX_PER_ASM
 delta_pos.x = clampf(delta_pos.x, -cap, cap)
 delta_pos.y = clampf(delta_pos.y, -cap, cap)
 var glide = 30.0 / ARCADE_TSEC
 players[i].vel = delta_pos / glide
 players[i].rebound_glide = glide

func try_shot_block(i: int) -> void:
 if flight.is_empty() or flight.get("kind", "") != "shot" or ball_touch_lock > 0.0:
  return
 var shooter: int = int(flight.get("shooter", -1))
 if shooter < 0 or shooter / 2 == i / 2 or flight.get("blocked", false):
  return
 var t = clampf(flight.time / flight.duration, 0, 1)
 var contact = flight_position()
 var arc: float = flight.get("arc_height", 1.7 if flight.dunk else 4.6)
 var v_vert = 3.05 - flight.get("release_height", 1.3) + PI * arc * cos(t * PI)
 var def_team = i / 2
 var off_team = shooter / 2
 var pts_down = 0 if tournament_mode else (score[off_team] - score[def_team])
 # ball_chkpcollide: downward speed under 2 (3 when the defender is down 5+)
 # is a block. Faster descents whiff unless rnd's mask of 6 is 0, which
 # goaltends. On fire and airballs that do connect are blocks (PLYR2.ASM:2376-2432).
 var desc_threshold = -1.5 if pts_down >= 5 else -1.0
 var descending = v_vert < desc_threshold
 var at_rim = contact.distance_to(flight.end) < 115
 var ball_high = ball_height() > (28.0 / 120.0) * 3.05 or absf(v_vert) / maxf(flight.duration, 0.01) > 1.02
 var box = block_contact_box(i, ball_high)
 var delta_xz = contact - players[i].pos
 var in_reach = absf(delta_xz.x) < box.x and absf(delta_xz.y) < box.y and ball_height() <= 4.6
 if descending and at_rim and in_reach:
  if flight.dunk and dunk_strip_resisted(i, shooter):
   return
  var legal_block = flight.dunk or is_player_on_fire(i)
  if not legal_block and rng.randi() % 4 != 0:
   return
  if not legal_block and not flight.get("airball", false):
   var points: int = flight.points
   stats[i].goaltends += 1
   award_basket(shooter, points, false, false)
   announce("GOALTENDING! %d POINTS" % points, "whistle")
   inbound(i / 2, true)
  else:
   flight.made = false
   flight.blocked = true
   abort_finish_glide(shooter)
   stats[i].blocks += 1
   record_miss(shooter)
   if flight.dunk:
    announce("DENIED AT THE RIM!", "block")
   elif is_player_on_fire(i):
    announce("FIRE BLOCK! NO GOALTENDING!", "block")
   else:
    announce("REJECTED!", "block")
 elif not descending and in_reach:
  if flight.dunk and dunk_strip_resisted(i, shooter):
   return
  flight.made = false
  flight.blocked = true
  flight.block_call = "REJECTED!"
  abort_finish_glide(shooter)
  stats[i].blocks += 1
  record_miss(shooter)

# A block replaces the dunk or layup sequence. The finisher stops riding the
# rim path and comes down instead of gliding the rest of the flight in the air.
func abort_finish_glide(shooter: int) -> void:
 if shooter < 0 or shooter >= players.size():
  return
 players[shooter].vel = Vector2.ZERO
 players[shooter].jump = 0.0
 players[shooter].rim_hang = 0.0
 players[shooter].charge = 0.0
 players[shooter].receive_jump = 0.0

# takedunk_t is the chance a collision fails to take the ball from a dunker.
# A stripper with power 3 or less never wins that check.
func dunk_strip_resisted(defender: int, shooter: int) -> bool:
 var def_pwr = 10 if (maximum_power or is_player_on_fire(defender)) else clampi(int(rating(defender, 6)), 0, 10)
 if def_pwr <= 3:
  return true
 var dnk_pwr = clampi(int(rating(shooter, 6)), 0, 10)
 var idx = clampi((dnk_pwr - def_pwr) + 10, 0, TAKEDUNK_T.size() - 1)
 var resist = TAKEDUNK_T[idx]
 if resist <= 0:
  return false
 return rng.randf() < float(resist) / 1000.0

func steal(i: int, shove: bool) -> void:
 if shove and no_pushing:
  announce("NO PUSHING!", "whistle")
  return
 if shove and not is_player_on_fire(i) and not infinite_turbo:
  if players[i].turbo < (10.0 / 47.0):
   return
  # TE removes eight units when the move begins and up to seven more when
  # seq_push actually connects.
  players[i].turbo = maxf(0.0, players[i].turbo - (8.0 / 47.0))
 var action_dir: Vector2 = players[i].vel
 if action_dir.length() < 10.0:
  action_dir = players[i].get("last_move_vel", Vector2.ZERO)
 if action_dir.length() < 0.1:
  action_dir = Vector2(players[i].face, 0.0)
 var shove_len = TE_SHOVE_DIAGONAL_DURATION if shove and shove_faces_diagonal(action_dir) else TE_SHOVE_DURATION
 var swipe_len = shove_len if shove else float(STEAL_REACH_TICKS[passer_seqdir(i)]) / ARCADE_TSEC
 players[i].cooldown = swipe_len
 players[i].swipe = swipe_len
 players[i].swipe_total = swipe_len
 players[i].swipe_resolved = false
 players[i].swipe_shove = shove
 players[i].swipe_dir = action_dir.normalized()
 players[i].vel = Vector2.ZERO
 if not shove and owner >= 0:
  var to_target = players[owner].pos - players[i].pos
  if absf(to_target.x) > 0.1:
   players[i].face = 1 if to_target.x >= 0 else -1
 elif not flight.is_empty():
  var to_target = flight_position() - players[i].pos
  if absf(to_target.x) > 0.1:
   players[i].face = 1 if to_target.x >= 0 else -1
 if ball_touch_lock <= 0.0 and not flight.is_empty() and flight.kind == "pass" and not flight.get("tip",false) and int(flight.target)/2 != i/2:
  if players[i].pos.distance_to(flight_position()) < (68 if shove else 56) and ball_height() <= 2.5:
   if pass_intercept_succeeds(i, int(flight.time * ARCADE_TSEC)):
    intercept_pass(i)
  return

# Odd push_t seqdirs are the diagonal sequences. They connect on frame 8, not frame 12.
func shove_faces_diagonal(dir: Vector2) -> bool:
 if dir.length() < 0.1:
  return false
 return (dir_sector(Vector2.ZERO, dir.normalized() * 128.0) & 1) == 1

func shove_target(i: int) -> int:
 var team = i / 2
 var first_opponent = (1 - team) * 2
 var facing: Vector2 = players[i].get("swipe_dir", Vector2.ZERO)
 if facing.length() < 0.1:
  facing = Vector2(players[i].face, 0.0)
 facing = facing.normalized()
 for victim in [first_opponent, first_opponent + 1]:
  var offset: Vector2 = players[victim].pos - players[i].pos
  # Opponents: distance <= 50 and wrapped dir delta < 32/128 (PLYR2.ASM:4822-4834).
  if offset.length() <= TE_SHOVE_RANGE and offset.length() > 0.01 and facing.dot(offset.normalized()) > 0.0:
   return victim
 # Humans only. Drones return before the teammate test (PLYR2.ASM:4854-4874).
 # The teammate cone is 16/128, half the opponent cone.
 if players[i].get("human", false):
  var mate = i ^ 1
  var mate_offset: Vector2 = players[mate].pos - players[i].pos
  if mate_offset.length() <= TE_SHOVE_RANGE and mate_offset.length() > 0.01 and facing.dot(mate_offset.normalized()) > cos(16.0 / 128.0 * TAU):
   return mate
 return -1

# Cabinet dunks climb to HOOPY and stay there until seq_slamball. Presentation
# eases the body back down; the shove gate follows the cabinet rise instead.
func body_elevation(i: int) -> float:
 var p: Dictionary = players[i]
 if p.get("rim_hang", 0.0) > 0.0:
  return 1.35
 if dunk_ball_held(i) or dunk_already_slammed(i):
  var progress = clampf(float(flight.time) / maxf(float(flight.duration), 0.001), 0.0, 1.0)
  return 1.8 * clampf(progress / DUNK_RELEASE_FRACTION, 0.0, 1.0)
 if p.receive_jump > 0.0:
  return receive_height(i)
 if p.charge > 0.0:
  return sin(clampf(p.charge / 1.16, 0.0, 1.0) * PI) * 1.35
 if p.jump > 0.0:
  var t = 1.0 - clampf(p.jump / 0.70, 0.0, 1.0)
  if t <= 0.20:
   return 0.0
  return sin((t - 0.20) / 0.80 * PI) * 2.85
 return 0.0

func dunk_ball_held(victim: int) -> bool:
 if flight.is_empty() or flight.get("kind", "") != "shot":
  return false
 if not flight.get("dunk", false) or flight.get("blocked", false):
  return false
 if int(flight.get("shooter", -1)) != victim:
  return false
 return float(flight.time) < float(flight.duration) * DUNK_RELEASE_FRACTION

func dunk_already_slammed(victim: int) -> bool:
 if flight.is_empty() or flight.get("kind", "") != "shot":
  return false
 if not flight.get("dunk", false) or flight.get("blocked", false):
  return false
 if int(flight.get("shooter", -1)) != victim:
  return false
 return float(flight.time) >= float(flight.duration) * DUNK_RELEASE_FRACTION

func victim_dunking(victim: int) -> bool:
 if flight.is_empty() or flight.get("kind", "") != "shot" or flight.get("blocked", false):
  return false
 return flight.get("dunk", false) and int(flight.get("shooter", -1)) == victim

# BB.ASM counts pushing_delay down once for the whole game. Whoever is holding
# the ball keeps it, including a teammate who was passed to after the gain.
func pushing_delay_active() -> bool:
 for p in players:
  if p.get("push_keep_ball", 0.0) > 0.0:
   return true
 return false

# Keep-ball uses #shortfly_t. A winner who is not shooting rolls 50/1000.
# Losing the ball uses #winshortfly_t while ahead and #shortfly_t while behind.
# Similar power never takes the short no-ball flyback.
func short_flyback(victim: int, kept: bool, shooting: bool, victim_power: float, pusher_power: float) -> bool:
 var close_power = absf(victim_power - pusher_power) <= 1.0
 var power_idx = clampi(int(victim_power), 0, 10)
 var winning = score[1 - victim / 2] - score[victim / 2] <= 0
 var chance = 0.0
 if kept:
  if shooting or not winning:
   chance = 0.250 if close_power else SHORTFLY_T[power_idx]
  else:
   chance = 0.050
 else:
  if close_power:
   return false
  chance = WINSHORTFLY_T[power_idx] if winning else SHORTFLY_T[power_idx]
 return rng.randf() < chance

func no_ball_flail(victim_power: float, pusher_power: float) -> bool:
 if absf(victim_power - pusher_power) <= 1.0:
  return false
 return rng.randf() < NOBLFLAIL_T[clampi(int(victim_power), 0, 10)]

func shove_loose_flight(from: Vector2, rear: bool) -> Dictionary:
 var vx = rng.randf_range(-1.0, 0.999)
 var vy = 2.0 if rear else rng.randf_range(-1.0, 0.999)
 var duration = 0.55
 var dest = (from + Vector2(vx, vy) * PX_PER_ASM * ARCADE_TSEC * duration).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
 return {"kind": "loose", "start": from, "end": dest, "time": 0.0, "duration": duration, "arc_height": 0.35}

func resolve_steal(i: int, shove: bool) -> void:
 var team = i / 2
 if shove:
  var victim = shove_target(i)
  if victim < 0:
   return
  players[i].swipe_resolved = true
  # PLYR2.ASM rejects a target more than 0x54 pixels above the pusher.
  if body_elevation(victim) - body_elevation(i) > TE_SHOVE_ABOVE:
   return
  if inbounding_team >= 0:
   return
  # A TE layup is pushable 30% of the time. Elbows and rebounds are pushable
  # 15% of the time; its shove routine has no separate spin immunity.
  if not flight.is_empty() and flight.get("kind", "") == "shot" and flight.get("shooter", -1) == victim and flight.get("layup", false) and rng.randf() >= 0.30:
   return
  if (players[victim].get("elbow", 0.0) > 0.0 or players[victim].get("rebound_glide", 0.0) > 0.0) and rng.randf() >= 0.15:
   return
  if not is_player_on_fire(i) and not infinite_turbo:
   var contact_cost = 7.0 / 47.0
   players[i].turbo = players[i].turbo - contact_cost if players[i].turbo >= (10.0 / 47.0) else 0.0

  var pusher_power = 9.0 if (maximum_power or is_player_on_fire(i)) else rating(i, 6)
  var victim_power = rating(victim, 6)
  var victim_advantage = victim_power - pusher_power
  # The cabinet drives knockback along the pusher's committed direction, not
  # radially away from the victim's exact position inside the forward cone.
  var push_dir: Vector2 = players[i].get("swipe_dir", Vector2.ZERO)
  if push_dir.length() < 0.1:
   push_dir = Vector2.RIGHT * players[i].face
  push_dir = push_dir.normalized()
  var face_dir = -signf(push_dir.x)
  if absf(face_dir) > 0.1:
   players[victim].face = face_dir

  # TE quarters the horizontal impulse at a six-point victim advantage. At a
  # seven-point advantage, 35% of contacts become the short, non-fall reaction.
  var reduced_impulse = victim_advantage >= 6.0
  var full_knockdown = victim_advantage < 7.0 or rng.randf() < 0.65
  var shooting = players[victim].charge > 0.0 or (not flight.is_empty() and flight.get("kind", "") == "shot" and int(flight.get("shooter", -1)) == victim and not flight.get("dunk", false) and not flight.get("layup", false))
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  var fly_speed = 95.0 if reduced_impulse else 380.0
  var fly_stun = 1.10
  if full_knockdown:
   stats[victim].injury += 1
   players[victim].shove_kind = "flyback"
   players[victim].pickup_delay = maxf(players[victim].get("pickup_delay", 0.0), 0.67)
  else:
   players[victim].shove_kind = "stumble"
   fly_speed = 95.0
   fly_stun = 0.30
   players[victim].shove_time = fly_stun
   players[victim].stun = fly_stun
   players[victim].pickup_delay = maxf(players[victim].get("pickup_delay", 0.0), 0.35)
   players[victim].vel = push_dir * fly_speed

  var turnover = false
  var kept_ball = false
  # seq_slamball scores only while the dunker still owns the ball (PLYR2.ASM:4576).
  # A flyback replaces the dunk sequence (PLYR.ASM:1316), so the slam never runs.
  # DUNK_B also skips the short flyback (PLYR.ASM:1137, 1218). The stagcnt-16
  # stagger does not change sequences, and the dunk continues.
  var dunk_held = dunk_ball_held(victim)
  var interrupts_dunk = dunk_held and full_knockdown
  if dunk_held and not full_knockdown:
   stats[i].steals += 1
  if victim == owner or interrupts_dunk:
   # TE credits a push-steal when the carrier is hit, even if the carrier wins
   # the subsequent keep-ball roll.
   stats[i].steals += 1
   var points_down = clampi(score[i / 2] - score[victim / 2], 0, 15)
   var keep_prob = 0.50 if players[victim].get("elbow", 0.0) > 0.0 else (0.20 if absf(victim_power - pusher_power) <= 1.0 else KPBALL_T[clampi(int(victim_power), 0, 10)])
   keep_prob = minf(1.0, keep_prob + FLYB_T[points_down])
   var rear = players[victim].pos.y <= asm_spot(0.0, 1040.0 - 1170.0).y
   var into_table = rear and push_dir.y < 0.0
   kept_ball = not rear and (pushing_delay_active() or rng.randf() < keep_prob)
   if not kept_ball:
    turnover = true
    stats[victim].turnovers = stats[victim].get("turnovers", 0) + 1
    owner = -1
    reset_shot_clock()
    loose_ball_timer = 0.20
    ball = players[victim].pos
    flight = shove_loose_flight(ball, rear)
   elif interrupts_dunk:
    # FLYBACKWB keeps possession, but the replaced dunk cannot score.
    owner = victim
    ball = players[victim].pos
    flight = {}
   if full_knockdown and not victim_dunking(victim) and not into_table and short_flyback(victim, kept_ball, shooting, victim_power, pusher_power):
    fly_speed *= 0.25
    fly_stun = TE_SHORT_FLY_TICKS / ARCADE_TSEC
  elif full_knockdown and not victim_dunking(victim) and no_ball_flail(victim_power, pusher_power):
   fly_speed *= 0.25
   fly_stun = TE_SHORT_FLY_TICKS / ARCADE_TSEC
  if full_knockdown:
   players[victim].shove_time = fly_stun
   players[victim].stun = fly_stun
   players[victim].vel = push_dir * fly_speed

  if turnover:
   announce("SHOVED! LOOSE BALL!" if full_knockdown else "STUMBLED! LOOSE BALL!", "steal")
  elif kept_ball:
   announce("SHOVED! KEEPS THE BALL!" if full_knockdown else "STUMBLED! KEEPS THE BALL!", "shove")
  else:
   announce("SHOVED! NO FOULS!" if full_knockdown else "STAGGERED!", "shove")
  return
 var victim = -1
 if owner >= 0 and owner / 2 != team:
  var ball_pos = players[owner].pos + Vector2(players[owner].face * 18.0, 0.0)
  var dist_to_ball = players[i].pos.distance_to(ball_pos)
  var dist_to_owner = players[i].pos.distance_to(players[owner].pos)
  if dist_to_ball <= 46.0 or dist_to_owner <= 46.0:
   victim = owner
 if victim < 0 or ball_touch_lock > 0.0:
  return
 if players[victim].get("steal_immune", 0.0) > 0.0:
  return
 players[i].swipe_resolved = true
 var stl_stat = clampi(int(rating(i, 4)), 0, 10)
 var steal_chance = STL1[stl_stat]
 if rng.randf() < steal_chance:
  var clean_steal = rng.randf() < STL2[stl_stat]
  stats[i].steals += 1
  stats[victim].turnovers = stats[victim].get("turnovers", 0) + 1
  players[i].cooldown = 0.75
  players[victim].charge = 0.0
  players[victim].fake = 0.0
  if clean_steal:
   acquire_possession(i, true)
   # steals_off 30, pass_off 25, pushing_delay 80 (PLYR2.ASM give-ball path).
   players[i].steal_immune = TE_STEAL_LOCKOUT
   players[i].pass_off = TE_PASS_OFF
   players[i].push_keep_ball = TE_PUSH_PROTECTION
   reset_shot_clock()
   announce("PICKED THEIR POCKET!", "steal")
  else:
   owner = -1
   reset_shot_clock()
   loose_ball_timer = 0.0
   players[i].pickup_delay = TE_POKE_DELAY
   players[victim].pickup_delay = TE_POKE_DELAY
   var loose_dir = (players[victim].pos - players[i].pos).normalized()
   if loose_dir.length() < 0.1:
    loose_dir = Vector2.RIGHT * players[i].face
   var loose_dest = (ball + loose_dir * rng.randf_range(60.0, 110.0) + Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-30.0, 30.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
   flight = {"kind":"loose", "start":ball, "end":loose_dest, "time":0.0, "duration":0.45, "arc_height":1.2}
   announce("LOOSE BALL!", "steal")

# #giveball: rndrng0(99) must be under abs(ballpasstime-3)/2 + #int_t + 1,
# then RNDPER(400) must hit. No steal-skill or alley term (PLYR2.ASM:2759-2796).
func pass_intercept_succeeds(defender: int, pass_ticks: int) -> bool:
 var off_team = int(flight.get("target", 0)) / 2
 var pts_down = 0
 if not tournament_mode:
  pts_down = clampi(score[off_team] - score[defender / 2], 0, 15)
 var threshold = (absi(pass_ticks - 3) >> 1) + INT_T[pts_down] + 1
 if rng.randi() % 100 >= threshold:
  return false
 return rng.randf() < 0.40

func intercept_pass(i: int) -> void:
 stats[i].steals += 1
 var passer = int(flight.get("passer", -1))
 if passer >= 0 and passer < stats.size():
  stats[passer].turnovers = stats[passer].get("turnovers", 0) + 1
 if rng.randf() < 0.04:
  owner = -1
  var tip_dest = (ball + Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(-40.0, 40.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
  flight = {"kind":"loose", "start":ball, "end":tip_dest, "time":0.0, "duration":0.65, "arc_height":4.8, "tip":true}
  loose_ball_timer = 0.60
  players[i].cooldown = 0.5
  players[i].swipe = 0.25
  players[i].pickup_delay = 0.40
  announce("TIPPED PASS! LOOSE BALL", "steal")
  return
 acquire_possession(i, true)
 flight = {}
 ball = players[i].pos
 reset_shot_clock()
 players[i].cooldown = 0.8
 players[i].swipe = 0.25
 players[i].push_keep_ball = TE_PUSH_PROTECTION
 announce("PASS PICKED OFF!", "steal")

func tick_flight(delta: float) -> void:
 if flight.is_empty():
  return
 if bounce_back_glass(delta):
  return
 flight.time += delta
 var t = clampf(flight.time / flight.duration, 0, 1)
 ball = flight.start.lerp(flight.end, t)
 if flight.kind == "pass" and not flight.get("tip",false) and ball_height() <= 2.5:
  var accum = float(flight.get("intercept_ticks", 0.0)) + delta * ARCADE_TSEC
  var rolls = mini(int(accum), 3)
  flight.intercept_ticks = accum - float(rolls)
  if rolls > 0 and ball_touch_lock <= 0.0:
   var pass_ticks = int(flight.time * ARCADE_TSEC)
   for i in range(4):
    if i / 2 == int(flight.target) / 2 or players[i].stun > 0:
     continue
    if players[i].pos.distance_to(ball) >= 42.0:
     continue
    for _roll in range(rolls):
     if pass_intercept_succeeds(i, pass_ticks):
      intercept_pass(i)
      return
 elif ball_touch_lock <= 0.0 and (flight.kind == "rebound" or flight.kind == "loose"):
  if flight.kind == "loose" and loose_ball_timer > 0.0:
   pass
  else:
   var candidates: Array = []
   for i in range(4):
    var p: Dictionary = players[i]
    if p.stun <= 0 and p.jump > 0 and p.get("pickup_delay", 0.0) <= 0.0:
     var p_h = 1.2 + sin(clampf((0.75 - p.jump) / 0.75, 0, 1) * PI) * 1.6
     var ball_h = ball_height()
     var d = p.pos.distance_to(ball)
     var shooter = flight.get("shooter", -1)
     var is_defense = (shooter < 0 or shooter / 2 != i / 2)
     var is_rebound = flight.kind == "rebound"
     # Defender reach bonus & priority in crowd (PLYR2.ASM:2480-2620, ATTRACT.ASM:2546-2552)
     var def_stat = rating(i, 3)
     var reach_limit = (62.0 + def_stat * 1.5) if (is_defense and is_rebound) else 48.0
     if d < reach_limit and absf(ball_h - p_h) < 1.4:
      var def_bonus = (-28.0 - def_stat * 2.0) if (is_defense and is_rebound) else 0.0
      candidates.append({"id": i, "score": d + absf(ball_h - p_h) * 15.0 + def_bonus})
   if candidates.size() > 0:
    candidates.sort_custom(func(a, b): return a.score < b.score)
    var winner = candidates[0].id
    var is_rebound = flight.kind == "rebound"
    var p_win: Dictionary = players[winner]
    acquire_possession(winner, true)
    flight = {}
    p_win.vel = Vector2.ZERO
    p_win.rebound_glide = 0.0
    p_win.push_keep_ball = TE_PUSH_PROTECTION
    reset_shot_clock()
    if is_rebound:
     stats[winner].rebounds += 1
     announce("REBOUND!", "catch", winner)
    else:
     announce("LOOSE BALL!", "catch")
    return
 if t < 1:
  return
 if flight.kind == "rebound":
  if flight.get("bounces", 0) == 0:
   flight.bounces = 1
   flight.start = flight.end
   flight.end = (flight.end + Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-35.0, 35.0))).clamp(COURT.position + Vector2(25.0, 25.0), COURT.end - Vector2(25.0, 25.0))
   flight.time = 0.0
   flight.duration = REBOUND_BOUNCE_DURATION
   flight.bounce_height = 0.75
  else:
   ball = flight.end
   flight = {}
   loose_ball_timer = 0.0
  return
 if flight.kind == "loose":
  ball = flight.end
  flight = {}
  return
 if flight.kind == "pass":
  var receiver: int = int(flight.get("target", -1))
  # stagger_t, fall_t, and flyback_t set NOBALL. The pass keeps its velocity
  # instead of being caught by the player on the floor.
  if receiver >= 0 and players[receiver].stun > 0.0:
   release_uncatchable_pass(receiver)
   return
  var alley: bool = flight.alley
  var double_dunk: bool = flight.get("double_dunk", false)
  var catch_height = ball_height()
  var catchable: bool = players[receiver].receive_jump > 0 and players[receiver].stun <= 0 and players[receiver].pos.distance_to(flight.end) < 70 and players[receiver].pos.distance_to(hoop_for(receiver/2)) < 220
  if (alley or double_dunk) and not catchable:
   owner = -1
   flight = {}
   loose_ball_timer = 0.45
   players[receiver].pickup_delay = 0.45
   announce("LOB MISSED! LOOSE BALL","miss")
   return
  acquire_possession(receiver)
  ball = players[owner].pos
  flight = {}
  if alley or double_dunk:
   players[owner].alley_cnt = players[owner].get("alley_cnt", 0) + 1
   players[owner].charge = 0.58
   shoot_ball(owner, true, true, catch_height)
   announce("DOUBLE DUNK!" if double_dunk else "ALLEY-OOP!","dunk")
  return
 var shooter: int = flight.shooter
 var team = shooter / 2
 # ball_bbcollision: shot_distance >= 0x158 uses lhoopl_t/lhoopr_t, which have
 # no score spots, unless RNDPER(200) hits. game_time <= 0x400 raises that to
 # RNDPER(350). One roll at the rim is the pass through that zone. Dunks score
 # in seq_slamball and do not take this hoop.
 if flight.made and not flight.blocked and not flight.get("dunk", false) and float(flight.get("shot_dist", 0.0)) >= float(0x158):
  var allow = 350 if clock <= 4.0 else 200
  if rng.randi_range(0, 999) >= allow:
   flight.made = false
   if int(last_shot_feedback.get("shooter", -1)) == shooter:
    last_shot_feedback.made = false
 if flight.made and not flight.blocked:
  if flight.dunk:
   var hang = float(flight.get("hang_ticks", 64.0)) / ARCADE_TSEC
   players[shooter].rim_hang = hang
   players[shooter].jump = maxf(players[shooter].jump, hang)
   players[shooter].pos = hoop_for(team) + Vector2(-15 if hoop_for(team).x > 640 else 15, 0)
  # seq_slamball's facial only plays facial_snd. It does not move or stun anyone.
  var was_on_fire = is_player_on_fire(shooter)
  var shattered = award_basket(shooter,flight.points,flight.dunk,true,flight.get("super_dunk",false))
  var ignited = is_player_on_fire(shooter) and not was_on_fire
  var name_text: String = Teams.DATA[teams[team]].players[shooter%2]
  var message = "OFF THE GLASS!" if flight.get("bank_shot", false) else ("HE'S ON FIRE! " + name_text if ignited else ("HE'S HEATING UP! " + name_text if player_streak[shooter] == 2 else "BOOMSHAKALAKA!" if flight.get("super_dunk",false) else "SLAM DUNK!" if flight.dunk else "FROM DOWNTOWN!" if flight.points == 3 else "NOTHING BUT NET!"))
  if shattered:
   players[shooter].rim_hang = 0.0
   players[shooter].jump = 0.0
   announce("BOOM! BACKBOARD SHATTERED!","shatter", shooter)
   flight = {}
   owner = -1
   ball = hoop_for(team)
   reset_shot_clock()
   pending_inbound = 1-team
   shatter_shooter = shooter
   freeze = 1.65
  else:
   announce(message,"fire" if ignited else ("dunk" if flight.dunk else "score"), shooter)
   inbound(1-team, true, true)
 else:
  record_miss(shooter)
  in_cylinder_timer = 0.20
  must_rebound_timer = 2.0
  loose_ball_timer = maxf(loose_ball_timer, 0.20)
  var was_blocked = flight.get("blocked", false)
  var was_bank_shot = flight.get("bank_shot", false)
  var was_clank = flight.get("clank", false)
  var was_airball = flight.get("airball", false)
  var ricochet = calculate_rim_ricochet(flight.start, flight.end)
  var arc_h = 2.8 if was_clank else (1.2 if was_airball else 2.2)
  if was_bank_shot:
   ricochet = hoop_for(team) + (ricochet - hoop_for(team)) * 0.65
   arc_h = 1.6
  var block_call = str(flight.get("block_call", ""))
  if delta >= 1.5:
   ball = ricochet
   flight = {}
   owner = -1
   reset_shot_clock()
   loose_ball_timer = 0.0
   in_cylinder_timer = 0.0
   if block_call != "":
    announce(block_call, "block")
   elif not was_blocked:
    announce("AIRBALL!" if was_airball else ("OFF THE GLASS!" if was_bank_shot else "OFF THE RIM!"), "miss")
  else:
   flight = {"kind":"rebound", "start":hoop_for(team), "end":ricochet, "time":0.0, "duration":REBOUND_FLIGHT_DURATION, "shooter":shooter, "arc_height":arc_h, "bounces":0}
   owner = -1
   reset_shot_clock()
   if block_call != "":
    announce(block_call, "block")
   elif not was_blocked:
    announce("AIRBALL!" if was_airball else ("OFF THE GLASS!" if was_bank_shot else ("OFF THE BACK IRON!" if was_clank else "OFF THE RIM!")), "miss")

func next_period(from_transition: bool = false) -> void:
 if not from_transition and quarter_scores.size() < quarter:
  record_quarter_score()
 if quarter >= 4:
  if score[0] != score[1]:
   phase = "finished"
   if not from_transition:
    announce("FINAL", "whistle")
   return
  overtime += 1
  clock = minf(60.0, period_length)
  if not from_transition:
   announce("OVERTIME" if overtime == 1 else ("DOUBLE OVERTIME" if overtime == 2 else "TRIPLE OVERTIME"), "whistle")
 else:
  quarter += 1
  clock = period_length
  if not from_transition:
   announce("HALFTIME • SWITCH ENDS" if quarter == 3 else "QUARTER %d" % quarter, "whistle")
 for p in players:
  p.turbo = 1.0
  p.turbo_burnout = 0.0
  p.turbo_flash = 0.0
  p.alley_cnt = 0
  p.shove_kind = ""
  p.shove_time = 0.0
 var gmqrtr = (3 + overtime) if overtime > 0 else (quarter - 1)
 inbound(gmqrtr & 1, false, false, true)

func snapshot() -> Dictionary:
 return {"tipoff":tipoff.duplicate(true), "board_breaks":board_breaks.duplicate(), "pending_inbound":pending_inbound, "shatter_shooter":shatter_shooter, "players":players.duplicate(true), "teams":teams.duplicate(), "score":score.duplicate(), "streak":streak.duplicate(), "player_streak":player_streak.duplicate(), "fire_player":fire_player, "fire_points":fire_points, "fire_shots":fire_shots, "last_passer":last_passer, "assist_window":assist_window, "brick_count":brick_count.duplicate(), "inbounding_team":inbounding_team, "teammate_shot_order":teammate_shot_order, "stats":stats.duplicate(true), "ball":ball, "owner":owner, "flight":flight.duplicate(true), "clock":clock, "shot_clock":shot_clock, "quarter":quarter, "overtime":overtime, "phase":phase, "freeze":freeze, "banner":banner, "banner_player":banner_player, "banner_time":banner_time, "event_id":event_id, "event_kind":event_kind, "elapsed":elapsed, "big_heads":big_heads, "infinite_turbo":infinite_turbo, "tournament_mode":tournament_mode, "no_pushing":no_pushing, "fast_passing":fast_passing, "maximum_power":maximum_power, "last_shot_feedback":last_shot_feedback.duplicate(true), "loose_ball_timer":loose_ball_timer, "ball_touch_lock":ball_touch_lock, "in_cylinder_timer":in_cylinder_timer, "must_rebound_timer":must_rebound_timer, "bullet_time_remaining":bullet_time_remaining, "inbound_transition":inbound_transition.duplicate(true), "quarter_transition":quarter_transition.duplicate(true), "quarter_scores":quarter_scores.duplicate(true), "clock_buzzer_sounded":clock_buzzer_sounded}

func apply_snapshot(data: Dictionary) -> void:
 for key in data:
  set(key, data[key])
