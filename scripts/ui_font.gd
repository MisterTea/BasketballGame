class_name UiFont
extends RefCounted

static var font: Font

static func get_font() -> Font:
	if font != null:
		return font
	var base := load("res://fonts/NotoSans-UI.ttf") as FontFile
	var arrows := load("res://fonts/NotoSansSymbols-Arrows.ttf") as Font
	var symbols := load("res://fonts/NotoSansSymbols2-UI.ttf") as Font
	var fire := load("res://fonts/NotoEmoji-Fire.ttf") as Font
	base = base.duplicate() as FontFile
	base.fallbacks = [arrows, symbols, fire]
	font = base
	return font
