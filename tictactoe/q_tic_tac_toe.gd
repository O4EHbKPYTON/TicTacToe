extends Control

@onready var quantum_network: Node = %QuantumNetwork
@onready var info_label: Label = %InfoLabel

@onready var start_button: Button = %StartButton
@onready var reset_button: Button = %ResetButton
@onready var x_slider: HSlider = %XSlider
@onready var o_slider: HSlider = %OSlider
@onready var game_grid: GridContainer = %GameGrid

@onready var bloch_sphere: BlochImageLoader = %BlochSphere
@onready var bloch_display: TextureRect = %BlochDisplay

const BOARD_SIZE := 3
var cells: Array[Button] = []
var moves: Array[String] = []
var game_started: bool = false
var current_symbol: String = "x"
var quantum_params: Dictionary = {"qx": 0.0, "qo": 0.0}

func _ready() -> void:
	start_ttt()
	_connect_signals()
	bloch_sphere.load_bloch_image(bloch_sphere.get_bloch_sphere_url(global.current_state))

func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	x_slider.value_changed.connect(_on_x_slider_changed)
	o_slider.value_changed.connect(_on_o_slider_changed)
	global.quantum_response.connect(_on_quantum_response)

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
	update_info_label("Выберите квантовую неопределенность для x и o")

func update_info_label(text: String) -> void:
	info_label.text = text

func _on_quantum_response(symbol: String, cell_index: int) -> void:
	for cell in cells:
		cell.disabled = false
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
			current_symbol = "o" if current_symbol == "x" else "x"
			update_info_label("Ход %s" % current_symbol)
	else:
		update_info_label("Неверный индекс ячейки")

func _on_quantum_error(message: String) -> void:
	for cell in cells:
		cell.disabled = false
	update_info_label(message)

func _on_start_button_pressed() -> void:
	if not game_started:
		game_started = true
		current_symbol = "x"
		update_info_label("Ход x")

func _on_reset_button_pressed() -> void:
	game_started = false
	moves.clear()
	current_symbol = "x"
	quantum_params["qx"] = 0.0
	quantum_params["qo"] = 0.0
	x_slider.value = 0.0
	o_slider.value = 0.0
	for button in cells:
		button.text = ""
		button.disabled = false
	update_info_label("Выберите квантовую неопределенность для x и o")

func _on_x_slider_changed(value: float) -> void:
	quantum_params["qx"] = value
	update_info_label("Квантовая неопределенность для x = %.1f" % value)

func _on_o_slider_changed(value: float) -> void:
	quantum_params["qo"] = value
	update_info_label("Квантовая неопределенность для o = %.1f" % value)

func _on_cell_pressed(button: Button) -> void:
	if not game_started or button.text != "":
		return
	var power: float = 1.0 + quantum_params["qx"] if current_symbol == "x" else quantum_params["qo"]
	var cell_index := cells.find(button)
	for cell in cells:
		cell.disabled = true
	var theta : float = PI * (quantum_params["qx"] if current_symbol == "x" else quantum_params["qo"])
	quantum_network.send_quantum_request(current_symbol, theta, cell_index)

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
