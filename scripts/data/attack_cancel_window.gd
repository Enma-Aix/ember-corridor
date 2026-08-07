class_name AttackCancelWindow
extends Resource

const TARGET_TAG_PATTERN := "^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)+$"

@export_range(1, 600, 1, "or_greater") var start_tick := 1
@export_range(1, 600, 1, "or_greater") var end_tick := 1
@export var target_tags: Array[StringName] = []


func validation_errors(total_ticks: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if start_tick < 1:
		errors.append("start_tick must be at least 1")
	if end_tick < start_tick:
		errors.append("end_tick must be greater than or equal to start_tick")
	if total_ticks < 1:
		errors.append("total_ticks must be at least 1")
	elif end_tick > total_ticks:
		errors.append("end_tick must not exceed the attack total tick count")
	if target_tags.is_empty():
		errors.append("target_tags must declare at least one cancel target")

	var tag_pattern := RegEx.new()
	if tag_pattern.compile(TARGET_TAG_PATTERN) != OK:
		errors.append("cancel target tag validator could not be compiled")
		return errors
	var seen_tags: Dictionary[StringName, bool] = {}
	for target_tag: StringName in target_tags:
		var tag_text := String(target_tag)
		if tag_text.is_empty() or tag_pattern.search(tag_text) == null:
			errors.append(
				"target tag must use dotted lowercase form: %s" % tag_text
			)
		elif seen_tags.has(target_tag):
			errors.append("duplicate cancel target tag: %s" % tag_text)
		else:
			seen_tags[target_tag] = true
	return errors


func contains_tick(action_tick: int) -> bool:
	return action_tick >= start_tick and action_tick <= end_tick
