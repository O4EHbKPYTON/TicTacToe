extends HBoxContainer
class_name BlochImageLoader

@onready var bloch_display: TextureRect = %BlochDisplay

# Отображаемые состояния и соответствующие пути к изображениям
var bloch_images := {
	"superposition": "res://data/bloch_sphere/superposition_state.png",
	"x": "res://data/bloch_sphere/state_plus.png",
	"o": "res://data/bloch_sphere/state_minus.png",
	"measurement_0": "res://data/bloch_sphere/measurement_collapse_0.png",
	"measurement_1": "res://data/bloch_sphere/measurement_collapse_1.png"
}

func set_state(state: String) -> void:
	if state in bloch_images:
		global.current_state = state
		load_bloch_image(bloch_images[state])
	else:
		print("Invalid state: ", state)

func load_bloch_image(path: String) -> void:
	var texture = load(path)
	if texture is Texture2D:
		bloch_display.texture = texture
		bloch_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bloch_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bloch_display.custom_minimum_size = Vector2(640, 640)
		bloch_display.size = Vector2(640, 640)
	else:
		print("Не удалось загрузить изображение: ", path)
