class_name UiFont
extends RefCounted

static var font: Font

static func get_font() -> Font:
	if font != null:
		return font
	font = load("res://fonts/UiFont.ttf")
	return font
