extends VBoxContainer
class_name BlochImageLoader

@onready var bloch_display: TextureRect = %BlochDisplay

func get_bloch_sphere_url(state: String) -> String:
	return global.BLOCH_SPHERE_URL + state

func set_state(state: String) -> void:
	if state in ["superposition", "x", "o", "measurement"]:
		global.current_state = state
		load_bloch_image(get_bloch_sphere_url(global.current_state))
	else:
		print("Invalid state: ", state)

func load_bloch_image(BLOCH_SPHERE_URL: String) -> void:
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_bloch_image_loaded.bind(request))
	request.request(BLOCH_SPHERE_URL)

func _on_bloch_image_loaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		var image = Image.new()
		var error = image.load_png_from_buffer(body)
		if error == OK:
			var texture = ImageTexture.create_from_image(image)
			bloch_display.texture = texture
			bloch_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bloch_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			bloch_display.custom_minimum_size = Vector2(640, 1036)
			bloch_display.size = Vector2(640, 1036)
		else:
			print("Ошибка загрузки изображения: ", error)
	else:
		print("Ошибка HTTP-запроса: ", result)
		print("Код ответа: ", response_code)
