class_name GroundMovementModel
extends RefCounted

const FACING_LEFT := -1
const FACING_RIGHT := 1
const FACING_INPUT_THRESHOLD := 0.01

var horizontal_speed := 320.0
var depth_speed_ratio := 0.9
var facing_sign := FACING_RIGHT


func configure(new_horizontal_speed: float, new_depth_speed_ratio: float) -> PackedStringArray:
	var errors := PackedStringArray()
	if new_horizontal_speed <= 0.0:
		errors.append("horizontal_speed must be greater than zero")
	if new_depth_speed_ratio <= 0.0 or new_depth_speed_ratio > 1.0:
		errors.append("depth_speed_ratio must be greater than zero and at most one")
	if errors.is_empty():
		horizontal_speed = new_horizontal_speed
		depth_speed_ratio = new_depth_speed_ratio
	return errors


func velocity_for_input(raw_input: Vector2) -> Vector2:
	var direction := raw_input.limit_length(1.0)
	return Vector2(
		direction.x * horizontal_speed,
		direction.y * horizontal_speed * depth_speed_ratio
	)


func update_facing(horizontal_input: float) -> int:
	if horizontal_input < -FACING_INPUT_THRESHOLD:
		facing_sign = FACING_LEFT
	elif horizontal_input > FACING_INPUT_THRESHOLD:
		facing_sign = FACING_RIGHT
	return facing_sign
