extends Control

@onready var quantum_network: Node = %QuantumNetwork
@onready var info_label: Label = %InfoLabel

@onready var start_button: Button = %StartButton
@onready var reset_button: Button = %ResetButton
@onready var x_slider: HSlider = %XSlider
@onready var o_slider: HSlider = %OSlider
@onready var game_grid: GridContainer = %GameGrid

const BOARD_SIZE := 3
var cells: Array[Button] = []
var moves: Array[String] = []
var game_started: bool = false
var current_player: String = "×"
var quantum_params: Dictionary = {"q×": 0.0, "qo": 0.0}

func _ready() -> void:
	start_ttt()

func start_ttt() -> void:
	game_grid.columns = BOARD_SIZE
	cells.clear()
	for child in game_grid.get_children():
		child.queue_free()
	for i in range(BOARD_SIZE * BOARD_SIZE):
		var button := Button.new()
		button.name = "Cell_%d" % i
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(200, 200)
		button.pressed.connect(_on_cell_pressed.bind(button))
		game_grid.add_child(button)
		cells.append(button)

	start_button.pressed.connect(_on_start_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	x_slider.value_changed.connect(_on_x_slider_changed)
	o_slider.value_changed.connect(_on_o_slider_changed)

	# Подключение сигнала от quantum_network
	if not quantum_network.is_connected("quantum_response", Callable(self, "_on_quantum_response")):
		quantum_network.connect("quantum_response", Callable(self, "_on_quantum_response"))

	update_info_label("Выберите квантовую неопределенность для × и o")

func update_info_label(text: String) -> void:
	info_label.text = text

func _on_quantum_response(player: String, cell_index: int) -> void:
	for cell in cells:
		cell.disabled = false
	
	if cell_index >= 0 and cell_index < cells.size():
		cells[cell_index].text = player
		moves.append(player)

		if check_win():
			update_info_label("%s выиграл игру!" % player)
			game_started = false
		elif moves.size() == BOARD_SIZE * BOARD_SIZE:
			update_info_label("Ничья!")
			game_started = false
		else:
			current_player = "o" if current_player == "×" else "×"
			update_info_label("Ход %s" % current_player)
	else:
		update_info_label("Неверный индекс ячейки")

func _on_quantum_error(message: String) -> void:
	for cell in cells:
		cell.disabled = false
	update_info_label(message)

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
	var power: float = 1.0 + quantum_params["q×"] if current_player == "×" else quantum_params["qo"]
	var cell_index := cells.find(button)
	for cell in cells:
		cell.disabled = true
	print("Отправка запроса:", current_player, power, cell_index)
	quantum_network.send_quantum_request(current_player, power, cell_index)

func check_win() -> bool:
	for i in range(BOARD_SIZE):
		var row := []
		for j in range(BOARD_SIZE):
			row.append(cells[i * BOARD_SIZE + j])
		if row.all(func(cell): return cell.text == row[0].text and cell.text != ""):
			highlight_winning_cells(row)
			return true

		var col := []
		for j in range(BOARD_SIZE):
			col.append(cells[j * BOARD_SIZE + i])
		if col.all(func(cell): return cell.text == col[0].text and cell.text != ""):
			highlight_winning_cells(col)
			return true

	var diag1 := []
	var diag2 := []
	for i in range(BOARD_SIZE):
		diag1.append(cells[i * BOARD_SIZE + i])
		diag2.append(cells[i * BOARD_SIZE + (BOARD_SIZE - i - 1)])
	if diag1.all(func(cell): return cell.text == diag1[0].text and cell.text != ""):
		highlight_winning_cells(diag1)
		return true
	if diag2.all(func(cell): return cell.text == diag2[0].text and cell.text != ""):
		highlight_winning_cells(diag2)
		return true

	return false


func highlight_winning_cells(winning_cells: Array) -> void:
	for cell in winning_cells:
		cell.add_theme_color_override("font_color", Color.RED)
