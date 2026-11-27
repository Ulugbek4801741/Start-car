extends CharacterBody3D

var current_speed: float = 0.0
var steering_input: float = 0.0
var controls := {"left": false, "right": false, "gas": false, "brake": false}
const MAX_SPEED := 38.0
const REVERSE_SPEED := 10.0
const ACCEL := 18.0
const BRAKE_POWER := 28.0
const DRAG := 5.5
const STEER_RATE := 2.0

func set_controls(value: Dictionary) -> void:
	controls = value

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	if controls.get("gas", false):
		throttle = 1.0
	if controls.get("brake", false):
		throttle = -0.65 if current_speed > 1.0 else -0.35
	if throttle > 0.0:
		current_speed = move_toward(current_speed, MAX_SPEED, ACCEL * delta)
	elif throttle < 0.0:
		current_speed = move_toward(current_speed, -REVERSE_SPEED, BRAKE_POWER * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, DRAG * delta)

	steering_input = float(controls.get("right", false)) - float(controls.get("left", false))
	var steering_scale := clamp(abs(current_speed) / 6.0, 0.0, 1.0)
	rotation.y -= steering_input * STEER_RATE * steering_scale * delta * sign(current_speed if abs(current_speed) > 0.1 else 1.0)

	var forward := -global_transform.basis.z
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed
	velocity.y -= 18.0 * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
