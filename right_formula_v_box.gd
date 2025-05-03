extends VBoxContainer
class_name TutorialLoader
const BLOCH_SPHERE_URL := "http://127.0.0.1:8000/bloch_sphere/"
const FORMULA_URL := "http://127.0.0.1:8000/formula/"

@onready var tutorial_text: RichTextLabel = %TutorialText
@onready var next_step_button: Button = %NextStepButton
@onready var quantum_request: HTTPRequest = %QuantumRequest
@onready var formula_placeholder: TextureRect = %FormulaPlaceholder
@onready var bloch_image_loader: BlochImageLoader = %BlochImageLoader


var tutorial_steps: Array[Dictionary] = [
	{
		"title": "Квантовые крестики-нолики",
		"content": "Добро пожаловать в квантовую версию классической игры! Здесь клетки могут находиться в суперпозиции состояний X и O одновременно, пока не будет произведено измерение.",
		"bloch_state": "superposition",
		"formula_type": "intro"
	},
	{
		"title": "Базисные состояния",
		"content": "Классические состояния X и O представляются как ортогональные векторы:\nX = [1, 0]\nO = [0, 1]",
		"bloch_state": "x",
		"formula_type": "basis_states"
	},
	{
		"title": "X-Gate (Ворота Паули-X)",
		"content": "X-Gate - основной квантовый ворот, выполняющий инверсию состояний:\nX|X⟩ = |O⟩\nX|O⟩ = |X⟩\nМатрица: [[0, 1], [1, 0]]",
		"bloch_state": "x",
		"formula_type": "x_gate"
	},
	{
		"title": "Квантовая стратегия",
		"content": "Управление состоянием кубита:\n|ψ⟩ = RX(θ)|X⟩\nθ = π⋅(power)\nГде power - значение слайдера",
		"bloch_state": "superposition",
		"formula_type": "strategy"
	},
	{
		"title": "Суперпозиция",
		"content": "Квантовая клетка может находиться в состоянии X и O одновременно! Это называется суперпозицией и описывается вектором состояния |ψ⟩ = α|X⟩ + β|O⟩.",
		"bloch_state": "superposition",
		"formula_type": "superposition"
	},
	{
		"title": "Вероятности",
		"content": "Квадраты коэффициентов α и β определяют вероятности получить X или O при измерении: P(X) = |α|², P(O) = |β|².",
		"bloch_state": "superposition",
		"formula_type": "probability"
	},
	{
		"title": "Квантовые ворота X",
		"content": "Слайдеры применяют X-Gate с разной мощностью, вращая состояние кубита вокруг оси X на сфере Блоха.",
		"bloch_state": "x",
		"formula_type": "x_gate"
	},
	{
		"title": "Измерение",
		"content": "При нажатии на клетку происходит измерение - суперпозиция коллапсирует в одно из базисных состояний (X или O) согласно вероятностям.",
		"bloch_state": "measurement",
		"formula_type": "measurement"
	},
	{
		"title": "Квантовая стратегия",
		"content": "Используйте слайдеры для управления вероятностями. Установите высокую мощность для X, чтобы увеличить шансы получить крестик, и наоборот для нолика.",
		"bloch_state": "superposition",
		"formula_type": "strategy"
	}
]

		
func _ready() -> void:
	advance_tutorial()
	next_step_button.pressed.connect(advance_tutorial)
	

func _on_formula_image_loaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest):
	request.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		var image = Image.new()
		if image.load_png_from_buffer(body) == OK:
			var texture = ImageTexture.create_from_image(image)
			formula_placeholder.texture = texture
			formula_placeholder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			formula_placeholder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func advance_tutorial() -> void:
	if global.tutorial_index < tutorial_steps.size():
		var step = tutorial_steps[global.tutorial_index]
		tutorial_text.text = "[b]%s[/b]\n\n%s" % [step["title"], step["content"]]
		# Передаем оба аргумента: bloch_state и formula_type
		update_tutorial_display(step["bloch_state"], step["formula_type"])
		global.tutorial_index += 1
	else:
		tutorial_text.text = "Ты готов! Нажми 'Start' и попробуй сделать квантовый ход."
		next_step_button.disabled = true
		
	

func update_tutorial_display(bloch_state: String, formula_type: String) -> void:
	bloch_image_loader.load_bloch_image(BLOCH_SPHERE_URL + bloch_state)
	
	var formula_request = HTTPRequest.new()
	add_child(formula_request)
	formula_request.request_completed.connect(_on_formula_image_loaded.bind(formula_request))
	formula_request.request(FORMULA_URL + formula_type)
