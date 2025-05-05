extends Node

signal quantum_response(success: bool, player: String, cell_index: int)

const SERVER_URL := "http://127.0.0.1:8000/run-cirq"

@onready var quantum_request: HTTPRequest = HTTPRequest.new()
@onready var debug_label: Label = %DEBUGLabel

func _ready() -> void:
	add_child(quantum_request)
	quantum_request.request_completed.connect(_on_http_request_completed)

func send_quantum_request(player: String, power: float, cell_index: int) -> void:
	var request_data := {
		"qubit_name": player,
		"power": power,
		"cell_index": cell_index
	}
	var json_string := JSON.stringify(request_data)
	var headers := ["Content-Type: application/json"]
	quantum_request.request(SERVER_URL, headers, HTTPClient.METHOD_POST, json_string)
	emit_signal("quantum_response", player, cell_index)

func _on_http_request_completed(result, response_code, headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("quantum_error", "Ошибка подключения к run_quantum.py")
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		emit_signal("quantum_error", "Ошибка при анализе квантового результата")
		return

	var response_data: Dictionary = json.get_data()
	var player: String = response_data.get("result", "")
	var cell_index: int = response_data.get("cell_index", -1)

	if player.is_empty() or cell_index == -1:
		debug_label.text = "error"
	else:
		debug_label.text = "response"
