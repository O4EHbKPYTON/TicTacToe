extends Node3D

@onready var bloch_sphere: Node3D = %BlochSphere
@onready var state_vector: Node3D = %StateVector
@onready var camera: Camera3D = %Camera3D
@onready var tween: Tween

# Добавим константы для позиционирования
const SPHERE_RADIUS := 2.0
const AXIS_LENGTH := 3.0
const ARROW_LENGTH := 1.5

var current_theta: float = 0.0
var is_dragging: bool = false
var last_mouse_pos: Vector2

func _ready():
	setup_sphere()
	setup_axes()
	setup_state_vector()
	update_bloch_sphere(Vector3(0, 0, 1))

func setup_sphere():
	# Центрируем сферу
	%SphereMesh.position = Vector3.ZERO
	%SphereMesh.mesh.radius = SPHERE_RADIUS
	%SphereMesh.mesh.height = SPHERE_RADIUS * 2

func setup_axes():
	var axis_length = SPHERE_RADIUS * 1.5
	var axis_radius = 0.03
	var arrow_tip_length = 0.2

	# Передаем явные смещения для подписей
	_create_axis(%XAxis, Color.RED, 
		Vector3(axis_length/2, 0, 0),
		Vector3(0, 0, deg_to_rad(-90)),
		Vector3(axis_length/2 + 0.5, 0, 0),  # X смещение
		"X")  # Явно передаем текст

	_create_axis(%YAxis, Color.GREEN,
		Vector3(0, 0, axis_length/2),
		Vector3(deg_to_rad(90), 0, 0),
		Vector3(0, 0, axis_length/2 + 0.5),  # Y смещение
		"Y")

	_create_axis(%ZAxis, Color.BLUE,
		Vector3(0, axis_length/2, 0),
		Vector3.ZERO,
		Vector3(0, axis_length/2 + 0.5, 0),  # Z смещение
		"Z")

func _create_axis(
	axis_node: MeshInstance3D, 
	color: Color, 
	position: Vector3, 
	rotation: Vector3, 
	label_pos: Vector3,
	label_text: String  # Новый параметр для текста
):
	var axis_length = SPHERE_RADIUS * 1.5
	var axis_radius = 0.03
	var arrow_tip_length = 0.2
	
	# Основная ось (остается без изменений)
	axis_node.mesh = CylinderMesh.new()
	axis_node.mesh.height = axis_length
	axis_node.mesh.top_radius = axis_radius
	axis_node.mesh.bottom_radius = axis_radius
	axis_node.position = position
	axis_node.rotation = rotation
	
	# Наконечник стрелки (остается без изменений)
	var arrow_tip = MeshInstance3D.new()
	arrow_tip.mesh = CylinderMesh.new()
	arrow_tip.mesh.height = arrow_tip_length
	arrow_tip.mesh.top_radius = 0.01
	arrow_tip.mesh.bottom_radius = axis_radius * 2
	arrow_tip.position = Vector3(0, axis_length/2 + arrow_tip_length/2, 0)
	axis_node.add_child(arrow_tip)
	
	# Подпись оси (исправленная часть)
	var label = Label3D.new()
	label.text = label_text  # Используем явно переданный текст
	label.font_size = 40
	label.position = Vector3(0, axis_length/2 + arrow_tip_length/2 + 0.3, 0)
	label.billboard = true  # Делаем текст всегда обращенным к камере
	axis_node.add_child(label)
	
	# Материал (без изменений)
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = color
	axis_node.material_override = mat
	arrow_tip.material_override = mat

func setup_state_vector():
	var arrow_length = SPHERE_RADIUS * 0.75
	
	# Основной стержень
	%ArrowCylinder.mesh = CylinderMesh.new()
	%ArrowCylinder.mesh.height = arrow_length
	%ArrowCylinder.mesh.top_radius = 0.02
	%ArrowCylinder.mesh.bottom_radius = 0.05
	%ArrowCylinder.position = Vector3(0, 0,  -SPHERE_RADIUS*0.62)
	%ArrowCylinder.rotation.x = deg_to_rad(90)
	
	# Наконечник
	%ArrowCone.mesh = CylinderMesh.new()
	%ArrowCone.mesh.height = 0.15
	%ArrowCone.mesh.top_radius = 0.01
	%ArrowCone.mesh.bottom_radius = 0.07
	%ArrowCone.position = Vector3(0, 0, -SPHERE_RADIUS*0.5)
	%ArrowCone.rotation.x = deg_to_rad(90)
	
	# Материал
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.ORANGE
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color.ORANGE * 0.8
	
	%ArrowCylinder.material_override = arrow_mat
	%ArrowCone.material_override = arrow_mat
	

func update_bloch_sphere(state: Vector3):
	var normalized_state = state.normalized()
	current_theta = acos(normalized_state.z)
	var current_phi = atan2(normalized_state.y, normalized_state.x)
	
	# Плавное обновление позиции и вращения
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(state_vector, "position", normalized_state * SPHERE_RADIUS, 0.8)
	tween.parallel().tween_property(state_vector, "rotation", 
		Vector3(current_theta, current_phi, 0), 0.8)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_pos = event.position
			
	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position - last_mouse_pos
		# Вращаем саму сферу Блоха
		bloch_sphere.rotate_y(delta.x * 0.01)
		bloch_sphere.rotate_x(delta.y * 0.01)
		bloch_sphere.rotation.x = clamp(bloch_sphere.rotation.x, -PI/2, PI/2)
		last_mouse_pos = event.position

func apply_x_gate(power: float):
	var new_theta = current_theta + PI * power
	var new_state = Vector3(
		sin(new_theta) * cos(0),
		sin(new_theta) * sin(0),
		cos(new_theta)
	)
	update_bloch_sphere(new_state)

func collapse_state():
	var collapse_to = Vector3(0, 0, 1) if randf() < 0.5 else Vector3(0, 0, -1)
	update_bloch_sphere(collapse_to)

func _on_TutorialStep_changed(step: Dictionary):
	match step["bloch_state"]:
		"superposition":
			update_bloch_sphere(Vector3(1, 0, 0))
		"x":
			apply_x_gate(1.0)
		"measurement":
			collapse_state()
		"o":
			update_bloch_sphere(Vector3(0, 0, -1))
