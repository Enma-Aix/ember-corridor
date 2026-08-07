class_name ElevationModel
extends RefCounted

const LANDING_EPSILON := 0.001

var elevation := 0.0
var vertical_velocity := 0.0
var gravity := 1800.0
var jump_speed := 720.0
var grounded := true
var min_hit_height := 0.0
var max_hit_height := 56.0


func configure(
	new_jump_speed: float,
	new_gravity: float,
	new_min_hit_height: float,
	new_max_hit_height: float
) -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(new_jump_speed) or new_jump_speed <= 0.0:
		errors.append("jump_speed must be finite and greater than zero")
	if not is_finite(new_gravity) or new_gravity <= 0.0:
		errors.append("gravity must be finite and greater than zero")
	if not is_finite(new_min_hit_height) or new_min_hit_height < 0.0:
		errors.append("min_hit_height must be finite and at least zero")
	if not is_finite(new_max_hit_height) or new_max_hit_height < new_min_hit_height:
		errors.append("max_hit_height must be finite and at least min_hit_height")
	if errors.is_empty():
		jump_speed = new_jump_speed
		gravity = new_gravity
		min_hit_height = new_min_hit_height
		max_hit_height = new_max_hit_height
	return errors


func request_jump() -> bool:
	if not grounded:
		return false
	grounded = false
	vertical_velocity = jump_speed
	return true


func advance(delta: float) -> bool:
	if not is_finite(delta) or delta <= 0.0:
		return false
	if grounded:
		_snap_to_ground()
		return false

	vertical_velocity -= gravity * delta
	elevation += vertical_velocity * delta
	if elevation <= LANDING_EPSILON and vertical_velocity <= 0.0:
		_snap_to_ground()
		return true
	return false


func hit_height_range() -> Vector2:
	return Vector2(
		elevation + min_hit_height,
		elevation + max_hit_height
	)


func overlaps_height_range(query_min: float, query_max: float) -> bool:
	if not is_finite(query_min) or not is_finite(query_max):
		return false
	if query_min > query_max:
		return false
	var actor_range := hit_height_range()
	return (
		query_max + LANDING_EPSILON >= actor_range.x
		and query_min - LANDING_EPSILON <= actor_range.y
	)


func _snap_to_ground() -> void:
	elevation = 0.0
	vertical_velocity = 0.0
	grounded = true
