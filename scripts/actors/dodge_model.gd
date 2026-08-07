class_name DodgeModel
extends RefCounted

const TOTAL_TICKS := 24
const TRAVEL_TICKS := 10
const INVULNERABLE_START_TICK := 4
const INVULNERABLE_END_TICK := 13
const COOLDOWN_TICKS := 45
const DODGE_DISTANCE := 70.4
const INPUT_EPSILON_SQUARED := 0.0001
const FACING_LEFT := -1
const FACING_RIGHT := 1

var direction := Vector2.RIGHT
var action_tick := 0
var cooldown_ticks_remaining := 0
var _active := false


func try_start(raw_input: Vector2, facing_sign: int) -> bool:
	if _active or cooldown_ticks_remaining > 0:
		return false
	if not is_finite(raw_input.x) or not is_finite(raw_input.y):
		return false

	var requested_direction := raw_input.limit_length(1.0)
	if requested_direction.length_squared() <= INPUT_EPSILON_SQUARED:
		if facing_sign != FACING_LEFT and facing_sign != FACING_RIGHT:
			return false
		requested_direction = Vector2(float(facing_sign), 0.0)
	else:
		requested_direction = requested_direction.normalized()

	direction = requested_direction
	action_tick = 0
	_active = true
	return true


func advance_tick() -> Vector2:
	if not _active:
		cooldown_ticks_remaining = maxi(0, cooldown_ticks_remaining - 1)
		return Vector2.ZERO

	action_tick += 1
	var displacement := Vector2.ZERO
	if action_tick <= TRAVEL_TICKS:
		displacement = direction * (DODGE_DISTANCE / float(TRAVEL_TICKS))
	if action_tick >= TOTAL_TICKS:
		_active = false
		cooldown_ticks_remaining = COOLDOWN_TICKS
	return displacement


func is_active() -> bool:
	return _active


func is_invulnerable() -> bool:
	return (
		_active
		and action_tick >= INVULNERABLE_START_TICK
		and action_tick <= INVULNERABLE_END_TICK
	)


func is_traveling() -> bool:
	return _active and action_tick > 0 and action_tick <= TRAVEL_TICKS
