extends SceneTree

var failures = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var ui_font = UiFont.get_font()
	for mark in ["★", "🔥", "⚠", "←", "→", "•", "—", "…", "⌖", "A"]:
		check(ui_font.has_char(mark.unicode_at(0)), "font draws %s" % mark)
	print("UI FONT TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func _initialize() -> void:
	call_deferred("run")
