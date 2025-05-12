extends Node

@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)

func send_quantum_request(symbol: String, power: float, cell_index: int) -> void:
	var request_data := {
		"qubit_name": symbol,
		"power": power,
		"cell_index": cell_index
	}
	var json := JSON.new()
	var json_string := json.stringify(request_data)
	var headers := ["Content-Type: application/json"]
	http_request.request(global.SERVER_URL, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var response_data: Dictionary = json.get_data()
			var symbol: String = response_data.get("result", "")
			var cell_index: int = response_data.get("cell_index", -1)
			global.quantum_response.emit(symbol, cell_index)
		else:
			print("quantum_error", "Ошибка разбора ответа сервера.")
	else:
		print("quantum_error", "Ошибка запроса: код ответа " + str(response_code))
