class_name CombatLaunchProfile
extends BaseDefinition

@export_category("Airborne Control")
@export_range(0.0, 5000.0, 1.0, "or_greater") var upward_velocity := 0.0
@export var can_hit_downed := false


func definition_kind() -> StringName:
	return &"combat_launch_profile"


func validation_errors() -> PackedStringArray:
	var errors := super.validation_errors()
	if not _is_finite_non_negative(upward_velocity):
		errors.append("upward_velocity must be finite and at least 0")
	if is_zero_approx(upward_velocity) and not can_hit_downed:
		errors.append("launch profile must launch or explicitly hit downed targets")
	return errors


func _is_finite_non_negative(value: float) -> bool:
	return not is_nan(value) and not is_inf(value) and value >= 0.0
