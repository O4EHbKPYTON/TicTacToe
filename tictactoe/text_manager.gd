extends Node

@onready var text: RichTextLabel = %TextPart1
@onready var formula_image: TextureRect = %FormulaImage
@onready var button_left: Button = %ButtonLeft
@onready var button_right: Button = %ButtonRight
@onready var bloch_sphere: BlochImageLoader = %BlochSphere

var file = FileAccess.open("res://data/text/ttt.json", FileAccess.READ)

func _ready() -> void:
	load_font() 
	load_tutorial_data()
	update_tutorial()
	_connect_signals()

func load_font() -> void:
	var dynamic_font = FontFile.new()
	var font_path = "res://fonts/Commissioner.ttf"
	if FileAccess.file_exists(font_path):
		dynamic_font.load_dynamic_font(font_path)
		dynamic_font.size = 100  
		text.add_theme_color_override("font_selected_color", Color.WHITE)
		text.add_theme_color_override("default_color", Color.WHITE)
		text.add_theme_color_override("font_color", Color.WHITE)
		text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		text.add_theme_font_override("normal_font", dynamic_font)
		text.add_theme_font_size_override("normal_font_size", 100)
	else:
		printerr("Файл шрифта не найден:", font_path)

func _connect_signals() -> void:
	button_left.pressed.connect(_on_left_pressed)
	button_right.pressed.connect(_on_right_pressed)

func load_tutorial_data():
	if file:
		var content = file.get_as_text()
		global.tutorial_steps = JSON.parse_string(content)
	else:
		print("ошибка текста!!!")

func _on_left_pressed():
	if global.current_step > 0:
		global.current_step -= 1
		update_tutorial()

func _on_right_pressed():
	if global.current_step < global.tutorial_steps.size() - 1:
		global.current_step += 1
		update_tutorial()

func update_tutorial():
	if global.tutorial_steps.is_empty():
		return
	var step = global.tutorial_steps[global.current_step]
	text.text = "[color=white]" + step["text"] + "[/color]"

	match step["formula"]:
		"intro", "superposition":
			bloch_sphere.set_state("superposition")
		"basis_states", "x_gate":
			bloch_sphere.set_state("x")  
		"measurement":
			bloch_sphere.set_state("measurement")

	# Загрузка локального изображения
	var image_path = "res://data/formulas/" + step["formula"] + ".png"
	if ResourceLoader.exists(image_path):
		var tex = load(image_path)
		formula_image.texture = tex
	else:
		formula_image.texture = null
		text.text += "\n[Формула не найдена локально]"

	button_left.disabled = global.current_step == 0
	button_right.disabled = global.current_step >= global.tutorial_steps.size() - 1
