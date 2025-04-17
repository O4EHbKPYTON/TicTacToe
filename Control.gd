extends Control

const BOARD_SIZE := 3
const SERVER_URL := "http://127.0.0.1:8000/run-cirq"

@onready var info_label: Label = $MainVBox/InfoLabel
@onready var start_button: Button = $MainVBox/ControlPanel/ButtonPanel/StartButton
@onready var reset_button: Button = $MainVBox/ControlPanel/ButtonPanel/ResetButton
@onready var x_slider: HSlider = $MainVBox/ControlPanel/QuantumPanel/XSlider
@onready var o_slider: HSlider = $MainVBox/ControlPanel/QuantumPanel/OSlider
@onready var grid_container: GridContainer = $MainVBox/GameGrid
@onready var http_request: HTTPRequest = $MainVBox/QuantumRequest

var cells: Array[Button] = []
var moves: Array[String] = []
var game_started: bool = false
var current_player: String = "×"
var quantum_params: Dictionary = {"q×": 0.0, "qo": 0.0}

func _ready() -> void:
	for child in $MainVBox/GameGrid.get_children():
		child.queue_free()
	cells.clear()
	
	self.anchor_right = 1.0
	self.anchor_bottom = 1.0
	
	$MainVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$MainVBox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$MainVBox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	$MainVBox/ControlPanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$MainVBox/ControlPanel.alignment = BoxContainer.ALIGNMENT_CENTER
	
	$MainVBox/GameGrid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$MainVBox/GameGrid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	for i in range(BOARD_SIZE * BOARD_SIZE):
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(100, 100)
		button.pressed.connect(_on_cell_pressed.bind(button))
		$MainVBox/GameGrid.add_child(button)
		cells.append(button)
	
	await get_tree().process_frame
	
	$MainVBox/ControlPanel.position.y = 0
	
	start_button.pressed.connect(_on_start_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	x_slider.value_changed.connect(_on_x_slider_changed)
	o_slider.value_changed.connect(_on_o_slider_changed)
	http_request.request_completed.connect(_on_http_request_completed)
	
	update_info_label("Выберите квантовую неопределенность для × и o")

func _on_start_button_pressed() -> void:
	if not game_started:
		game_started = true
		current_player = "×"
		update_info_label("Ход ×")

func _on_reset_button_pressed() -> void:
	game_started = false
	moves.clear()
	current_player = "×"
	quantum_params["q×"] = 0.0
	quantum_params["qo"] = 0.0
	x_slider.value = 0.0
	o_slider.value = 0.0
	
	for button in cells:
		button.text = ""
		button.disabled = false
	
	update_info_label("Выберите квантовую неопределенность для × и o")

func _on_x_slider_changed(value: float) -> void:
	quantum_params["q×"] = value
	update_info_label("Квантовая неопределенность в × = %.1f" % value)

func _on_o_slider_changed(value: float) -> void:
	quantum_params["qo"] = value
	update_info_label("Квантовая неопределенность в o = %.1f" % value)

func _on_cell_pressed(button: Button) -> void:
	if not game_started or button.text != "":
		return
	
	var current_pressed_button = button
	
	var power :float = 1.0 + quantum_params["q×"] if current_player == "×" else quantum_params["qo"]
	
	var request_data := {
		"qubit_name": current_player,
		"power": power,
		"cell_index": cells.find(button) 
	}
	
	var json := JSON.new()
	var json_string := json.stringify(request_data)
	
	for cell in cells:
		cell.disabled = true
	
	var headers := ["Content-Type: application/json"]
	http_request.request(SERVER_URL, headers, HTTPClient.METHOD_POST, json_string)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# Повторное включение кнопки
	for cell in cells:
		cell.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		update_info_label("Ошибка подключения к run_quantum.py")
		return
	
	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		update_info_label("Ошибка при анализе квантового результата")
		return
	
	var response_data: Dictionary = json.get_data()
	var symbol: String = response_data.get("result", "")
	var cell_index: int = response_data.get("cell_index", -1)  # Получаем индекс
	
	if symbol.is_empty() or cell_index == -1:
		print(cell_index)
		print(symbol.is_empty())
		update_info_label("Неверный квантовый результат")
		return
	
	# Находим кнопку по индексу
	if cell_index >= 0 and cell_index < cells.size():
		cells[cell_index].text = symbol
		moves.append(symbol)
		
		if check_win():
			update_info_label("%s выиграл игру!" % symbol)
			game_started = false
		elif moves.size() == BOARD_SIZE * BOARD_SIZE:
			update_info_label("Ничья!")
			game_started = false
		else:
			current_player = "o" if current_player == "×" else "×"
			update_info_label("%s's move" % current_player)
	else:
		update_info_label("Неверный индекс ячейки")
		
func check_win() -> bool:
	for row in range(BOARD_SIZE):
		var first := cells[row * BOARD_SIZE].text
		if first == "":
			continue
		
		var win := true
		for col in range(1, BOARD_SIZE):
			if cells[row * BOARD_SIZE + col].text != first:
				win = false
				break
		
		if win:
			highlight_winning_cells(range(row * BOARD_SIZE, (row + 1) * BOARD_SIZE))
			return true
	
	for col in range(BOARD_SIZE):
		var first := cells[col].text
		if first == "":
			continue
		
		var win := true
		for row in range(1, BOARD_SIZE):
			if cells[row * BOARD_SIZE + col].text != first:
				win = false
				break
		
		if win:
			highlight_winning_cells(range(col, BOARD_SIZE * BOARD_SIZE, BOARD_SIZE))
			return true
	
	var first_diag := cells[0].text
	if first_diag != "":
		var win := true
		for i in range(1, BOARD_SIZE):
			if cells[i * BOARD_SIZE + i].text != first_diag:
				win = false
				break
		
		if win:
			highlight_winning_cells(range(0, BOARD_SIZE * BOARD_SIZE, BOARD_SIZE + 1))
			return true
	
	var second_diag := cells[BOARD_SIZE - 1].text
	if second_diag != "":
		var win := true
		for i in range(1, BOARD_SIZE):
			if cells[i * BOARD_SIZE + (BOARD_SIZE - 1 - i)].text != second_diag:
				win = false
				break
		
		if win:
			highlight_winning_cells(range(BOARD_SIZE - 1, BOARD_SIZE * BOARD_SIZE - 1, BOARD_SIZE - 1))
			return true
	
	return false

func highlight_winning_cells(indices: Array) -> void:
	for index in indices:
		if index < cells.size():
			cells[index].add_theme_color_override("font_color", Color.RED)

func update_info_label(text: String) -> void:
	info_label.text = text
