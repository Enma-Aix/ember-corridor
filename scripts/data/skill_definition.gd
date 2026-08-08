class_name SkillDefinition
extends BaseDefinition

@export_category("Presentation")
@export var description_key: StringName = &""
@export_file("*.png", "*.svg", "*.webp") var icon_path := ""
@export var animation_name: StringName = &""
@export_file("*.tscn") var vfx_scene_path := ""
@export var sfx_event: StringName = &""

@export_category("Gameplay")
@export_range(0.0, 600.0, 0.01, "or_greater") var cooldown_seconds := 0.0
@export var attack_sequence: Array[AttackDefinition] = []
@export var movement_profile: SkillMovementProfile
@export var cancel_rules: Array[AttackCancelWindow] = []
@export var ai_value_tags: Array[StringName] = []

@export_category("Progression")
@export_range(1, 100, 1, "or_greater") var unlock_level := 1
@export var upgrade_nodes: Array[StringName] = []


func definition_kind() -> StringName:
	return &"skill"


func validation_errors() -> PackedStringArray:
	var errors := super.validation_errors()
	if description_key == &"":
		errors.append("description_key is required")
	if animation_name == &"":
		errors.append("animation_name is required")
	if not _is_finite_positive(cooldown_seconds):
		errors.append("cooldown_seconds must be finite and greater than 0")
	if unlock_level < 1:
		errors.append("unlock_level must be at least 1")
	if attack_sequence.is_empty():
		errors.append("attack_sequence must contain at least one attack")

	var total_action_ticks := 0
	var seen_attack_ids: Dictionary[StringName, bool] = {}
	for index: int in attack_sequence.size():
		var attack: AttackDefinition = attack_sequence[index]
		if attack == null:
			errors.append("attack_sequence[%d] must not be null" % index)
			continue
		for message: String in attack.validation_errors():
			errors.append("attack_sequence[%d]: %s" % [index, message])
		if seen_attack_ids.has(attack.definition_id):
			errors.append("duplicate attack_sequence ID: %s" % String(attack.definition_id))
		else:
			seen_attack_ids[attack.definition_id] = true
		total_action_ticks += attack.total_ticks()

	if movement_profile == null:
		errors.append("movement_profile is required")
	else:
		errors.append_array(movement_profile.validation_errors(total_action_ticks))

	if cancel_rules.is_empty():
		errors.append("cancel_rules must contain at least one rule")
	for index: int in cancel_rules.size():
		var rule: AttackCancelWindow = cancel_rules[index]
		if rule == null:
			errors.append("cancel_rules[%d] must not be null" % index)
			continue
		for message: String in rule.validation_errors(total_action_ticks):
			errors.append("cancel_rules[%d]: %s" % [index, message])
		if not _attack_sequence_declares_rule(rule):
			errors.append(
				"cancel_rules[%d] must also be declared by an AttackDefinition" % index
			)

	_validate_unique_names(ai_value_tags, "ai_value_tags", errors)
	_validate_unique_names(upgrade_nodes, "upgrade_nodes", errors)
	return errors


func primary_attack() -> AttackDefinition:
	return attack_sequence[0] if not attack_sequence.is_empty() else null


func total_ticks() -> int:
	var result := 0
	for attack: AttackDefinition in attack_sequence:
		if attack != null:
			result += attack.total_ticks()
	return result


func _attack_sequence_declares_rule(rule: AttackCancelWindow) -> bool:
	for attack: AttackDefinition in attack_sequence:
		if attack == null:
			continue
		for attack_rule: AttackCancelWindow in attack.cancel_windows:
			if attack_rule == null:
				continue
			if (
				attack_rule.start_tick == rule.start_tick
				and attack_rule.end_tick == rule.end_tick
				and attack_rule.target_tags == rule.target_tags
			):
				return true
	return false


func _validate_unique_names(
	values: Array[StringName],
	field_name: String,
	errors: PackedStringArray
) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for value: StringName in values:
		if value == &"":
			errors.append("%s must not contain an empty value" % field_name)
		elif seen.has(value):
			errors.append("%s contains duplicate value: %s" % [field_name, String(value)])
		else:
			seen[value] = true


func _is_finite_positive(value: float) -> bool:
	return not is_nan(value) and not is_inf(value) and value > 0.0
