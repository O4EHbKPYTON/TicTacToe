extends VBoxContainer
class_name BlochImageLoader

@onready var bloch_display: TextureRect = %BlochDisplay

func load_bloch_image(url: String) -> void:
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_bloch_image_loaded.bind(request))
	request.request(url)

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
			bloch_display.custom_minimum_size = Vector2(800, 800)
			bloch_display.size = Vector2(800, 800)
		else:
			print("Ошибка загрузки изображения: ", error)
	else:
		print("Ошибка HTTP-запроса: ", result)
		print("Код ответа: ", response_code)
