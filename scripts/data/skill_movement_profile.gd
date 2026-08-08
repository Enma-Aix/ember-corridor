class_name SkillMovementProfile
extends Resource

const DIRECTION_FACING_HORIZONTAL := "facing_horizontal"

@export_category("Travel")
@export_range(1, 600, 1, "or_greater") var travel_start_tick := 1
@export_range(1, 600, 1, "or_greater") var travel_end_tick := 1
@export_range(0.0, 10000.0, 0.1, "or_greater") var distance_pixels := 1.0
@export_enum("facing_horizontal") var direction_mode := DIRECTION_FACING_HORIZONTAL

@export_category("Collision")
@export_flags_2d_physics var blocking_collision_mask := 1
@export_flags_2d_physics var pass_through_collision_mask := 4
@export var pass_through_target_tags: Array[StringName] = []


func validation_errors(total_action_ticks: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if total_action_ticks < 1:
		errors.append("total_action_ticks must be at least 1")
	if travel_start_tick < 1:
		errors.append("travel_start_tick must be at least 1")
	if travel_end_tick < travel_start_tick:
		errors.append("travel_end_tick must be greater than or equal to travel_start_tick")
	elif total_action_ticks > 0 and travel_end_tick > total_action_ticks:
		errors.append("travel_end_tick must not exceed the action timeline")
	if not _is_finite_positive(distance_pixels):
		errors.append("distance_pixels must be finite and greater than 0")
	if direction_mode != DIRECTION_FACING_HORIZONTAL:
		errors.append("direction_mode must be facing_horizontal")
	if blocking_collision_mask <= 0:
		errors.append("blocking_collision_mask must declare at least one layer")
	if pass_through_collision_mask <= 0:
		errors.append("pass_through_collision_mask must declare at least one layer")
	if (blocking_collision_mask & pass_through_collision_mask) != 0:
		errors.append("blocking and pass-through collision masks must not overlap")
	if pass_through_target_tags.is_empty():
		errors.append("pass_through_target_tags must declare at least one target tag")
	var seen_tags: Dictionary[StringName, bool] = {}
	for target_tag: StringName in pass_through_target_tags:
		if target_tag == &"":
			errors.append("pass_through_target_tags must not contain an empty value")
		elif seen_tags.has(target_tag):
			errors.append("duplicate pass-through target tag: %s" % String(target_tag))
		else:
			seen_tags[target_tag] = true
	return errors


func travel_tick_count() -> int:
	return maxi(0, travel_end_tick - travel_start_tick + 1)


func displacement_at_tick(action_tick: int, facing_sign: int) -> Vector2:
	if (
		facing_sign not in [-1, 1]
		or action_tick < travel_start_tick
		or action_tick > travel_end_tick
	):
		return Vector2.ZERO
	var per_tick_distance := distance_pixels / float(travel_tick_count())
	return Vector2(per_tick_distance * float(facing_sign), 0.0)


func passes_target_tag(target_tag: StringName) -> bool:
	return pass_through_target_tags.has(target_tag)


func _is_finite_positive(value: float) -> bool:
	return not is_nan(value) and not is_inf(value) and value > 0.0
