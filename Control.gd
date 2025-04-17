extends Control

# Game constants
const BOARD_SIZE := 3
const SERVER_URL := "http://127.0.0.1:8000/run-cirq"

# UI elements
@onready var info_label: Label = $MainVBox/InfoLabel
@onready var start_button: Button = $MainVBox/ControlPanel/ButtonPanel/StartButton
@onready var reset_button: Button = $MainVBox/ControlPanel/ButtonPanel/ResetButton
@onready var x_slider: HSlider = $MainVBox/ControlPanel/QuantumPanel/XSlider
@onready var o_slider: HSlider = $MainVBox/ControlPanel/QuantumPanel/OSlider
@onready var grid_container: GridContainer = $MainVBox/GameGrid
@onready var http_request: HTTPRequest = $MainVBox/QuantumRequest

# Game state
var cells: Array[Button] = []
var moves: Array[String] = []
var game_started: bool = false
var current_player: String = "X"
var quantum_params: Dictionary = {"qX": 0.0, "qO": 0.0}

func _ready() -> void:
	for child in $MainVBox/GameGrid.get_children():
		child.queue_free()
	cells.clear()
	
	# Настройка якорных точек для корневого элемента
	self.anchor_right = 1.0
	self.anchor_bottom = 1.0
	
	# Настройка MainVBox
	$MainVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$MainVBox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$MainVBox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Настройка ControlPanel
	$MainVBox/ControlPanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$MainVBox/ControlPanel.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Настройка GameGrid
	$MainVBox/GameGrid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$MainVBox/GameGrid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Создаем кнопки игрового поля
	for i in range(BOARD_SIZE * BOARD_SIZE):
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(100, 100)
		button.pressed.connect(_on_cell_pressed.bind(button))
		$MainVBox/GameGrid.add_child(button)
		cells.append(button)
	
	# Ждем один кадр перед финальной настройкой
	await get_tree().process_frame
	
	# Принудительно устанавливаем позицию ControlPanel
	$MainVBox/ControlPanel.position.y = 0
	
	# Инициализация UI соединений
	start_button.pressed.connect(_on_start_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	x_slider.value_changed.connect(_on_x_slider_changed)
	o_slider.value_changed.connect(_on_o_slider_changed)
	http_request.request_completed.connect(_on_http_request_completed)
	
	update_info_label("Choose quantum uncertainty in X and O")

func _on_start_button_pressed() -> void:
	if not game_started:
		game_started = true
		current_player = "X"
		update_info_label("X's move")

func _on_reset_button_pressed() -> void:
	game_started = false
	moves.clear()
	current_player = "X"
	quantum_params["qX"] = 0.0
	quantum_params["qO"] = 0.0
	x_slider.value = 0.0
	o_slider.value = 0.0
	
	for button in cells:
		button.text = ""
		button.disabled = false
	
	update_info_label("Choose quantum uncertainty in X and O")

func _on_x_slider_changed(value: float) -> void:
	quantum_params["qX"] = value
	update_info_label("Quantum uncertainty in X = %.1f" % value)

func _on_o_slider_changed(value: float) -> void:
	quantum_params["qO"] = value
	update_info_label("Quantum uncertainty in O = %.1f" % value)

func _on_cell_pressed(button: Button) -> void:
	if not game_started or button.text != "":
		return
	
	# Determine which quantum parameter to use based on current player
	var power :float = 1.0 + quantum_params["qX"] if current_player == "X" else quantum_params["qO"]
	
	# Prepare the quantum computation request
	var request_data := {
		"qubit_name": current_player,
		"power": power
	}
	
	var json := JSON.new()
	var json_string := json.stringify(request_data)
	
	# Disable all buttons while waiting for quantum result
	for cell in cells:
		cell.disabled = true
	
	# Send request to quantum server
	var headers := ["Content-Type: application/json"]
	http_request.request(SERVER_URL, headers, HTTPClient.METHOD_POST, json_string)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# Re-enable all buttons
	for cell in cells:
		cell.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		update_info_label("Error connecting to quantum server")
		return
	
	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		update_info_label("Error parsing quantum result")
		return
	
	var response_data: Dictionary = json.get_data()
	var symbol: String = response_data.get("result", "")
	
	if symbol.is_empty():
		update_info_label("Invalid quantum result")
		return
	
	# Find which button was pressed (since we can't pass it directly through HTTP)
	var pressed_button: Button
	for button in cells:
		if button.text == "" and button.is_pressed():
			pressed_button = button
			break
	
	if not pressed_button:
		update_info_label("Couldn't determine pressed cell")
		return
	
	# Update the game state
	pressed_button.text = symbol
	moves.append(symbol)
	
	if check_win():
		update_info_label("%s won the game!" % symbol)
		game_started = false
	elif moves.size() == BOARD_SIZE * BOARD_SIZE:
		update_info_label("Draw!")
		game_started = false
	else:
		current_player = "O" if current_player == "X" else "X"
		update_info_label("%s's move" % current_player)

func check_win() -> bool:
	# Check rows
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
	
	# Check columns
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
	
	# Check diagonals
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
