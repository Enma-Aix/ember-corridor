class_name AttackDefinition
extends BaseDefinition

const HIT_STOP_BUDGETS := {
	"light": Vector2i(2, 3),
	"medium": Vector2i(4, 5),
	"heavy": Vector2i(6, 8),
	"finisher": Vector2i(1, 10),
}

enum TimelinePhase {
	BEFORE_START,
	STARTUP,
	ACTIVE,
	RECOVERY,
	COMPLETE,
}

@export_category("Timeline")
@export_range(0, 600, 1, "or_greater") var startup_ticks := 1
@export_range(1, 600, 1, "or_greater") var active_ticks := 1
@export_range(0, 600, 1, "or_greater") var recovery_ticks := 1
@export var cancel_windows: Array[AttackCancelWindow] = []

@export_category("Feedback")
@export_range(0, 120, 1, "or_greater") var hit_stop_ticks := 0
@export_enum("light", "medium", "heavy", "finisher") var feedback_strength := "light"

@export_category("Damage")
@export_range(0.0, 100.0, 0.01, "or_greater") var damage_coefficient := 1.0
@export_range(0.0, 100000.0, 1.0, "or_greater") var flat_damage := 0.0
@export_range(0.0, 100000.0, 1.0, "or_greater") var poise_damage := 0.0
@export var hit_tags: Array[StringName] = []
@export var launch_profile: StringName = &"none"

@export_category("Hitbox")
@export var hitbox_size := Vector2(88.0, 44.0)
@export var hitbox_offset := Vector2(48.0, -22.0)
@export_range(0.0, 1000.0, 1.0, "or_greater") var min_hit_height := 0.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var max_hit_height := 56.0
@export_range(0, 600, 1, "or_greater") var rehit_interval_ticks := 0


func definition_kind() -> StringName:
	return &"attack"


func validation_errors() -> PackedStringArray:
	var errors := super.validation_errors()
	if startup_ticks < 0:
		errors.append("startup_ticks must be at least 0")
	if active_ticks < 1:
		errors.append("active_ticks must be at least 1")
	if recovery_ticks < 0:
		errors.append("recovery_ticks must be at least 0")
	if hit_stop_ticks < 0:
		errors.append("hit_stop_ticks must be at least 0")
	if feedback_strength not in ["light", "medium", "heavy", "finisher"]:
		errors.append("feedback_strength must be light, medium, heavy, or finisher")
	elif hit_stop_ticks > 0:
		var hit_stop_budget: Vector2i = HIT_STOP_BUDGETS[feedback_strength]
		if (
			hit_stop_ticks < hit_stop_budget.x
			or hit_stop_ticks > hit_stop_budget.y
		):
			errors.append(
				"hit_stop_ticks must stay inside the %s budget [%d, %d]"
				% [feedback_strength, hit_stop_budget.x, hit_stop_budget.y]
			)
	if not _is_finite_non_negative(damage_coefficient):
		errors.append("damage_coefficient must be finite and at least 0")
	if not _is_finite_non_negative(flat_damage):
		errors.append("flat_damage must be finite and at least 0")
	if not _is_finite_non_negative(poise_damage):
		errors.append("poise_damage must be finite and at least 0")
	if launch_profile == &"":
		errors.append("launch_profile must not be empty")
	var seen_hit_tags: Dictionary[StringName, bool] = {}
	for hit_tag: StringName in hit_tags:
		if hit_tag == &"":
			errors.append("hit_tags must not contain an empty value")
		elif seen_hit_tags.has(hit_tag):
			errors.append("duplicate hit_tag: %s" % String(hit_tag))
		else:
			seen_hit_tags[hit_tag] = true
	if hitbox_size.x <= 0.0 or hitbox_size.y <= 0.0:
		errors.append("hitbox_size components must be greater than 0")
	if min_hit_height < 0.0:
		errors.append("min_hit_height must be at least 0")
	if max_hit_height < min_hit_height:
		errors.append("max_hit_height must be greater than or equal to min_hit_height")
	if rehit_interval_ticks < 0:
		errors.append("rehit_interval_ticks must be at least 0")
	var duration := total_ticks()
	for index: int in cancel_windows.size():
		var cancel_window: AttackCancelWindow = cancel_windows[index]
		if cancel_window == null:
			errors.append("cancel_windows[%d] must not be null" % index)
			continue
		for message: String in cancel_window.validation_errors(duration):
			errors.append("cancel_windows[%d]: %s" % [index, message])
	return errors


func _is_finite_non_negative(value: float) -> bool:
	return not is_nan(value) and not is_inf(value) and value >= 0.0


func total_ticks() -> int:
	return startup_ticks + active_ticks + recovery_ticks


func phase_at_tick(action_tick: int) -> TimelinePhase:
	if action_tick < 1:
		return TimelinePhase.BEFORE_START
	if action_tick <= startup_ticks:
		return TimelinePhase.STARTUP
	if action_tick <= startup_ticks + active_ticks:
		return TimelinePhase.ACTIVE
	if action_tick <= total_ticks():
		return TimelinePhase.RECOVERY
	return TimelinePhase.COMPLETE


func phase_name_at_tick(action_tick: int) -> StringName:
	match phase_at_tick(action_tick):
		TimelinePhase.BEFORE_START:
			return &"before_start"
		TimelinePhase.STARTUP:
			return &"startup"
		TimelinePhase.ACTIVE:
			return &"active"
		TimelinePhase.RECOVERY:
			return &"recovery"
		TimelinePhase.COMPLETE:
			return &"complete"
	return &"unknown"


func is_active_tick(action_tick: int) -> bool:
	return phase_at_tick(action_tick) == TimelinePhase.ACTIVE


func cancel_targets_at_tick(action_tick: int) -> PackedStringArray:
	var targets := PackedStringArray()
	var seen_targets: Dictionary[StringName, bool] = {}
	for cancel_window: AttackCancelWindow in cancel_windows:
		if cancel_window == null or not cancel_window.contains_tick(action_tick):
			continue
		for target_tag: StringName in cancel_window.target_tags:
			if seen_targets.has(target_tag):
				continue
			seen_targets[target_tag] = true
			targets.append(String(target_tag))
	targets.sort()
	return targets


func phase_tick_range(phase: TimelinePhase) -> Vector2i:
	match phase:
		TimelinePhase.STARTUP:
			if startup_ticks == 0:
				return Vector2i.ZERO
			return Vector2i(1, startup_ticks)
		TimelinePhase.ACTIVE:
			return Vector2i(startup_ticks + 1, startup_ticks + active_ticks)
		TimelinePhase.RECOVERY:
			if recovery_ticks == 0:
				return Vector2i.ZERO
			return Vector2i(startup_ticks + active_ticks + 1, total_ticks())
	return Vector2i.ZERO
