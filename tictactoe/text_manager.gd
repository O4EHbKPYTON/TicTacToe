extends Node

var tutorial_steps = []
var current_step := 0

@onready var text: RichTextLabel = %Text
@onready var formula: RichTextLabel = %Formula
@onready var button_left: Button = %ButtonLeft
@onready var button_right: Button = %ButtonRight
@onready var http_request: HTTPRequest = $HTTPRequest

var file = FileAccess.open("res://data/text/ttt.json", FileAccess.READ)

func _ready() -> void:
	load_tutorial_data()
	update_tutorial()
	_connect_signals()

func _connect_signals() -> void:
	button_left.pressed.connect(_on_left_pressed)
	button_right.pressed.connect(_on_right_pressed)
	http_request.request_completed.connect(_on_request_completed)

func load_tutorial_data():
	if file:
		var content = file.get_as_text()
		tutorial_steps = JSON.parse_string(content)
	else:
		print("ошибка текста!!!")

func _on_left_pressed():
	if current_step > 0:
		current_step -= 1
		update_tutorial()

func _on_right_pressed():
	if current_step < tutorial_steps.size() - 1:
		current_step += 1
		update_tutorial()

func update_tutorial():
	if tutorial_steps.is_empty():
		return
	var step = tutorial_steps[current_step]
	text.text = step["text"]
	formula.text = "Загрузка формулы..."
	var url = global.FORMULA_URL + str(step["slide"])
	http_request.request(url)
	button_left.disabled = current_step == 0
	button_right.disabled = current_step >= tutorial_steps.size() - 1

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		formula.text = json.get("formula", "Формула не найдена")
	else:
		formula.text = "Ошибка при загрузке формулы"
