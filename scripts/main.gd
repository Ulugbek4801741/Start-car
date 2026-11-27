extends Node3D

const CarController = preload("res://scripts/car_controller.gd")
const EngineAudio = preload("res://scripts/engine_audio.gd")

var car: CharacterBody3D
var camera: Camera3D
var speed_label: Label
var status_label: Label
var touch_values := {"left": false, "right": false, "gas": false, "brake": false}
var engine_audio: Node

func _ready() -> void:
	_build_world()
	_build_track()
	_build_car()
	_build_camera()
	_build_ui()
	engine_audio = EngineAudio.new()
	add_child(engine_audio)
	status_label.text = "READY  •  3D OFFLINE RACING"

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.36, 0.65)
	sky_mat.sky_horizon_color = Color(0.65, 0.78, 0.9)
	sky_mat.ground_bottom_color = Color(0.12, 0.14, 0.15)
	sky_mat.ground_horizon_color = Color(0.5, 0.58, 0.62)
	environment.sky.sky_material = sky_mat
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.65
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.2
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.32, 0.16)
	ground_mat.roughness = 1.0
	ground.material_override = ground_mat
	ground.position.y = -0.12
	add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(180, 0.3, 180)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.27
	ground_body.add_child(ground_collision)
	add_child(ground_body)

func _build_track() -> void:
	# A broad circular asphalt ring, created locally at runtime.
	var track := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer_radius := 42.0
	var inner_radius := 25.0
	var road_y := 0.02
	var steps := 128
	for i in range(steps):
		var a0 := TAU * float(i) / steps
		var a1 := TAU * float(i + 1) / steps
		var o0 := Vector3(cos(a0) * outer_radius, road_y, sin(a0) * outer_radius)
		var o1 := Vector3(cos(a1) * outer_radius, road_y, sin(a1) * outer_radius)
		var i0 := Vector3(cos(a0) * inner_radius, road_y, sin(a0) * inner_radius)
		var i1 := Vector3(cos(a1) * inner_radius, road_y, sin(a1) * inner_radius)
		st.add_vertex(o0); st.add_vertex(i0); st.add_vertex(o1)
		st.add_vertex(o1); st.add_vertex(i0); st.add_vertex(i1)
	track.mesh = st.commit()
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.18, 0.19, 0.2)
	asphalt.roughness = 0.95
	track.material_override = asphalt
	add_child(track)

	# Simple outer/inner curb markers and dotted centerline.
	for i in range(48):
		var angle := TAU * float(i) / 48.0
		_add_marker(Vector3(cos(angle) * 43.2, 0.15, sin(angle) * 43.2), Color(0.9, 0.16, 0.1))
		_add_marker(Vector3(cos(angle) * 24.0, 0.15, sin(angle) * 24.0), Color(0.92, 0.92, 0.92))
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		_add_marker(Vector3(cos(angle) * 33.5, 0.04, sin(angle) * 33.5), Color(0.95, 0.82, 0.16), 0.7)

	# Starting line across the track.
	for i in range(12):
		var piece := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 0.035, 1.25)
		piece.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE if i % 2 == 0 else Color.BLACK
		piece.material_override = mat
		piece.position = Vector3(-5.5 + i * 1.1, 0.07, 33.5)
		add_child(piece)

func _add_marker(pos: Vector3, color: Color, size: float = 0.5) -> void:
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, 0.3, size)
	marker.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	marker.material_override = material
	marker.position = pos
	add_child(marker)

func _build_car() -> void:
	car = CharacterBody3D.new()
	car.set_script(CarController)
	car.position = Vector3(0, 0.35, 33.5)
	car.rotation.y = -PI / 2.0
	var car_collision := CollisionShape3D.new()
	var car_shape := BoxShape3D.new()
	car_shape.size = Vector3(1.5, 0.7, 3.2)
	car_collision.shape = car_shape
	car.add_child(car_collision)
	add_child(car)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.85, 0.55, 3.7)
	body.mesh = body_mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.85, 0.08, 0.06)
	paint.metallic = 0.45
	paint.roughness = 0.28
	body.material_override = paint
	body.position.y = 0.48
	car.add_child(body)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.35, 0.58, 1.55)
	cabin.mesh = cabin_mesh
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.08, 0.2, 0.28, 0.8)
	glass.metallic = 0.3
	glass.roughness = 0.18
	cabin.material_override = glass
	cabin.position = Vector3(0, 0.98, -0.25)
	car.add_child(cabin)

	# Four low-poly wheels for the visual prototype.
	for x in [-1.0, 1.0]:
		for z in [-1.15, 1.15]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.42
			wheel_mesh.bottom_radius = 0.42
			wheel_mesh.height = 0.28
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI / 2
			var wheel_mat := StandardMaterial3D.new()
			wheel_mat.albedo_color = Color(0.035, 0.035, 0.04)
			wheel.material_override = wheel_mat
			wheel.position = Vector3(x, 0.05, z)
			car.add_child(wheel)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 72
	add_child(camera)
	camera.position = Vector3(0, 5.2, 8.5)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := ColorRect.new()
	panel.color = Color(0.03, 0.05, 0.07, 0.55)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(250, 72)
	ui.add_child(panel)

	speed_label = Label.new()
	speed_label.position = Vector2(32, 22)
	speed_label.add_theme_font_size_override("font_size", 30)
	speed_label.text = "000 km/h"
	panel.add_child(speed_label)
	status_label = Label.new()
	status_label.position = Vector2(32, 55)
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.text = "START-CAR • OFFLINE"
	panel.add_child(status_label)

	_add_touch_button(ui, "◀", Vector2(35, -155), "left")
	_add_touch_button(ui, "▶", Vector2(145, -155), "right")
	_add_touch_button(ui, "▲ GAS", Vector2(-185, -170), "gas")
	_add_touch_button(ui, "▼ BRAKE", Vector2(-185, -75), "brake")

func _add_touch_button(parent: Variant, caption: String, offset: Vector2, action: String) -> void:
	var holder: CanvasLayer = parent if parent is CanvasLayer else get_node("UI")
	var button := Button.new()
	button.text = caption
	button.size = Vector2(92, 74)
	button.add_theme_font_size_override("font_size", 24)
	button.anchor_left = 0 if offset.x >= 0 else 1
	button.anchor_right = button.anchor_left
	button.anchor_top = 1
	button.anchor_bottom = 1
	button.position = offset
	button.modulate = Color(1, 1, 1, 0.78)
	button.button_down.connect(func(): touch_values[action] = true)
	button.button_up.connect(func(): touch_values[action] = false)
	holder.add_child(button)

func _process(delta: float) -> void:
	if not is_instance_valid(car):
		return
	var input := {
		"left": touch_values["left"] or Input.is_action_pressed("ui_left"),
		"right": touch_values["right"] or Input.is_action_pressed("ui_right"),
		"gas": touch_values["gas"] or Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_accept"),
		"brake": touch_values["brake"] or Input.is_action_pressed("ui_down")
	}
	car.set_controls(input)
	var kmh: float = abs(car.current_speed) * 3.6
	speed_label.text = "%03d km/h" % int(kmh)
	engine_audio.set_engine_speed(kmh)
	var target := car.global_position + car.global_transform.basis.z * 7.5 + Vector3.UP * 4.2
	camera.global_position = camera.global_position.lerp(target, min(1.0, delta * 4.0))
	camera.look_at(car.global_position + Vector3.UP * 0.7, Vector3.UP)
