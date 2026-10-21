extends SceneTree

const DunkCallouts = {
	"standard": "SLAM DUNK!",
	"backflip": "BACKFLIP DUNK!",
	"frontflip": "SOMERSAULT JAM!",
	"helicopter": "HELICOPTER SLAM!",
	"spin_360": "360 WINDMILL!",
	"between_legs": "BETWEEN THE LEGS!",
	"behind_back": "BEHIND THE BACK SLAM!"
}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var dunk_style = "backflip"
	var args = OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--dunk-style" and i + 1 < args.size():
			dunk_style = args[i + 1]
	
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	
	await process_frame
	await process_frame
	
	main_scene.begin_match({"teams": [0, 1], "seconds": 180.0, "level": 1})
	main_scene.is_bot = true
	
	await process_frame
	await process_frame
	
	# Hide all players except player 0
	for i in range(1, 4):
		if i < main_scene.arena.athletes.size():
			var actor = main_scene.arena.athletes[i]
			actor.root.visible = false
			actor.marker.visible = false
			actor.control.visible = false
			actor.label.visible = false
			if actor.has("fire"):
				for f in actor.fire:
					f.visible = false
	
	var p0 = main_scene.game.players[0]
	# Start inside dunk range (< 180px from hoop at 1115)
	p0.pos = Vector2(945, 465)
	p0.vel = Vector2(260, 0)
	p0.face = 1
	p0.turbo = 1.0
	p0.drive = 0.5
	main_scene.game.owner = 0
	main_scene.game.ball = p0.pos
	main_scene.game.freeze = 0.0
	main_scene.game.tipoff.active = false
	main_scene.game.phase = "playing"
	main_scene.game.banner_time = 0.0
	main_scene.arena.reset_camera()
	
	# Short approach run (6 frames)
	for f in range(6):
		p0.vel = Vector2(260, 0)
		p0.drive = 0.5
		await process_frame
	
	# Launch dunk
	main_scene.game.shoot_ball(0, true)
	if not main_scene.game.flight.get("dunk", false):
		push_error("Failed to trigger dunk! Flight: " + str(main_scene.game.flight))
		quit(1)
		return
	
	main_scene.game.flight.dunk_style = dunk_style
	main_scene.game.banner = DunkCallouts.get(dunk_style, "SLAM DUNK!")
	main_scene.game.banner_time = 2.0
	if dunk_style != "standard":
		main_scene.game.flight.super_dunk = true
		main_scene.game.flight.duration = 1.45
		main_scene.game.flight.arc_height = 3.0
	
	# Record through flight, rim impact, and landing
	for f in range(120):
		await process_frame
	
	print("RECORDED DUNK: ", dunk_style)
	quit(0)
