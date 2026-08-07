class_name CombatReactionProfile
extends BaseDefinition

const SUPPORTED_STRATEGIES := [&"normal", &"elite", &"boss"]

@export_category("Reaction Strategy")
@export_enum("normal", "elite", "boss") var strategy := "normal"
@export var react_on_health_hit := true
@export_range(0, 120, 1, "or_greater") var hit_reaction_ticks := 12
@export_range(1, 600, 1, "or_greater") var break_duration_ticks := 60
@export_range(0.0, 1000.0, 1.0, "or_greater") var hit_knockback := 16.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var break_knockback := 40.0
@export_range(0.0, 100.0, 0.01, "or_greater") var poise_recovery_per_tick := 1.0
@export_range(0.0, 1.0, 0.05) var post_break_poise_damage_multiplier := 0.5
@export var forced_break_tags: Array[StringName] = []


func definition_kind() -> StringName:
	return &"combat_reaction_profile"


func validation_errors() -> PackedStringArray:
	var errors := super.validation_errors()
	if StringName(strategy) not in SUPPORTED_STRATEGIES:
		errors.append("strategy must be normal, elite, or boss")
	if react_on_health_hit and hit_reaction_ticks < 1:
		errors.append("reactive strategies require at least one hit-reaction tick")
	if not react_on_health_hit and hit_reaction_ticks != 0:
		errors.append("non-reactive strategies must use zero hit-reaction ticks")
	if break_duration_ticks < 1:
		errors.append("break_duration_ticks must be at least 1")
	if not _is_finite_non_negative(hit_knockback):
		errors.append("hit_knockback must be finite and at least 0")
	if not _is_finite_non_negative(break_knockback):
		errors.append("break_knockback must be finite and at least 0")
	if not _is_finite_non_negative(poise_recovery_per_tick):
		errors.append("poise_recovery_per_tick must be finite and at least 0")
	if (
		not _is_finite(post_break_poise_damage_multiplier)
		or post_break_poise_damage_multiplier < 0.0
		or post_break_poise_damage_multiplier > 1.0
	):
		errors.append("post_break_poise_damage_multiplier must be in [0, 1]")
	var seen_tags: Dictionary[StringName, bool] = {}
	for forced_tag: StringName in forced_break_tags:
		if forced_tag == &"":
			errors.append("forced_break_tags must not contain an empty value")
		elif seen_tags.has(forced_tag):
			errors.append("duplicate forced-break tag: %s" % String(forced_tag))
		else:
			seen_tags[forced_tag] = true
	return errors


func has_forced_break_tag(hit_tags: PackedStringArray) -> bool:
	for forced_tag: StringName in forced_break_tags:
		if hit_tags.has(String(forced_tag)):
			return true
	return false


func _is_finite_non_negative(value: float) -> bool:
	return _is_finite(value) and value >= 0.0


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
