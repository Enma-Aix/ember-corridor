class_name HitFeedbackProfile
extends BaseDefinition

const SUPPORTED_STRENGTHS := [&"light", &"medium", &"heavy", &"finisher"]
const HIT_STOP_BUDGETS := {
	&"light": Vector2i(2, 3),
	&"medium": Vector2i(4, 5),
	&"heavy": Vector2i(6, 8),
	&"finisher": Vector2i(1, 10),
}

@export_category("Strength")
@export_enum("light", "medium", "heavy", "finisher") var strength := "light"
@export_range(0, 10, 1) var minimum_hit_stop_ticks := 2
@export_range(0, 10, 1) var maximum_hit_stop_ticks := 3

@export_category("Camera")
@export_range(0.0, 24.0, 0.1) var camera_shake_pixels := 0.5
@export_range(0, 30, 1) var camera_duration_ticks := 2
@export_range(0, 3, 1) var camera_extension_ticks := 1
@export_range(0.0, 0.03, 0.001) var camera_zoom_pulse := 0.0

@export_category("VFX")
@export var vfx_style: StringName = &"vfx.hit.light"
@export_range(0.1, 4.0, 0.05) var vfx_scale := 0.8
@export_range(1, 60, 1) var vfx_lifetime_ticks := 8

@export_category("SFX")
@export var sfx_cue: StringName = &"sfx.hit.light"
@export_range(1, 3, 1) var sfx_layer_count := 1


func definition_kind() -> StringName:
	return &"hit_feedback_profile"


func strength_key() -> StringName:
	return StringName(strength)


func resolve_hit_stop_ticks(requested_ticks: int) -> int:
	if requested_ticks <= 0:
		return 0
	return clampi(
		requested_ticks,
		minimum_hit_stop_ticks,
		maximum_hit_stop_ticks
	)


func validation_errors() -> PackedStringArray:
	var errors := super.validation_errors()
	var key := strength_key()
	if key not in SUPPORTED_STRENGTHS:
		errors.append("strength must be light, medium, heavy, or finisher")
		return errors

	var budget: Vector2i = HIT_STOP_BUDGETS[key]
	if (
		minimum_hit_stop_ticks < budget.x
		or minimum_hit_stop_ticks > budget.y
	):
		errors.append(
			"minimum_hit_stop_ticks must stay inside the %s budget [%d, %d]"
			% [strength, budget.x, budget.y]
		)
	if (
		maximum_hit_stop_ticks < minimum_hit_stop_ticks
		or maximum_hit_stop_ticks > budget.y
	):
		errors.append(
			"maximum_hit_stop_ticks must be at least the minimum and at most %d"
			% budget.y
		)
	if camera_shake_pixels < 0.0 or not _is_finite(camera_shake_pixels):
		errors.append("camera_shake_pixels must be finite and at least 0")
	if camera_duration_ticks < 0 or camera_duration_ticks > 30:
		errors.append("camera_duration_ticks must be in [0, 30]")
	if camera_extension_ticks < 0 or camera_extension_ticks > 3:
		errors.append("camera_extension_ticks must be in [0, 3]")
	if (
		camera_zoom_pulse < 0.0
		or camera_zoom_pulse > 0.03
		or not _is_finite(camera_zoom_pulse)
	):
		errors.append("camera_zoom_pulse must be finite and in [0, 0.03]")
	if vfx_style == &"":
		errors.append("vfx_style must not be empty")
	if vfx_scale <= 0.0 or not _is_finite(vfx_scale):
		errors.append("vfx_scale must be finite and greater than 0")
	if vfx_lifetime_ticks < 1:
		errors.append("vfx_lifetime_ticks must be at least 1")
	if sfx_cue == &"":
		errors.append("sfx_cue must not be empty")
	if not _sfx_layers_match_budget(key, sfx_layer_count):
		errors.append("sfx_layer_count does not match the %s feedback budget" % strength)
	return errors


func _sfx_layers_match_budget(key: StringName, layer_count: int) -> bool:
	match key:
		&"light":
			return layer_count == 1
		&"medium":
			return layer_count == 2
		&"heavy":
			return layer_count in [2, 3]
		&"finisher":
			return layer_count == 3
	return false


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
