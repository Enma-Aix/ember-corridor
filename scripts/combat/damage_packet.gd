class_name DamagePacket
extends RefCounted

var source_instance_id: int:
	get:
		return _source_instance_id
var attack_id: StringName:
	get:
		return _attack_id
var base_attack: float:
	get:
		return _base_attack
var coefficient: float:
	get:
		return _coefficient
var flat_damage: float:
	get:
		return _flat_damage
var poise_damage: float:
	get:
		return _poise_damage
var hit_tags: PackedStringArray:
	get:
		return _hit_tags.duplicate()
var direction: Vector2:
	get:
		return _direction
var launch_profile: StringName:
	get:
		return _launch_profile
var crit_chance: float:
	get:
		return _crit_chance
var crit_damage_multiplier: float:
	get:
		return _crit_damage_multiplier
var critical_roll: float:
	get:
		return _critical_roll
var hit_stop_ticks: int:
	get:
		return _hit_stop_ticks
var feedback_strength: StringName:
	get:
		return _feedback_strength

var _source_instance_id: int
var _attack_id: StringName
var _base_attack: float
var _coefficient: float
var _flat_damage: float
var _poise_damage: float
var _hit_tags := PackedStringArray()
var _direction: Vector2
var _launch_profile: StringName
var _crit_chance: float
var _crit_damage_multiplier: float
var _critical_roll: float
var _hit_stop_ticks: int
var _feedback_strength: StringName


func _init(
	new_source_instance_id: int,
	new_attack_id: StringName,
	new_base_attack: float,
	new_coefficient: float,
	new_flat_damage: float,
	new_poise_damage: float,
	new_hit_tags: PackedStringArray,
	new_direction: Vector2,
	new_launch_profile: StringName,
	new_crit_chance: float,
	new_crit_damage_multiplier: float,
	new_critical_roll: float,
	new_hit_stop_ticks: int,
	new_feedback_strength: StringName
) -> void:
	_source_instance_id = new_source_instance_id
	_attack_id = new_attack_id
	_base_attack = new_base_attack
	_coefficient = new_coefficient
	_flat_damage = new_flat_damage
	_poise_damage = new_poise_damage
	_hit_tags = new_hit_tags.duplicate()
	_direction = new_direction
	_launch_profile = new_launch_profile
	_crit_chance = new_crit_chance
	_crit_damage_multiplier = new_crit_damage_multiplier
	_critical_roll = new_critical_roll
	_hit_stop_ticks = new_hit_stop_ticks
	_feedback_strength = new_feedback_strength


static func from_attack(
	new_source_instance_id: int,
	source_definition: AttackDefinition,
	new_base_attack: float,
	new_crit_chance: float,
	new_crit_damage_multiplier: float,
	new_critical_roll: float,
	new_direction: Vector2
) -> DamagePacket:
	if source_definition == null:
		return null
	var snapshot_tags := PackedStringArray()
	for tag: StringName in source_definition.hit_tags:
		snapshot_tags.append(String(tag))
	return DamagePacket.new(
		new_source_instance_id,
		source_definition.definition_id,
		new_base_attack,
		source_definition.damage_coefficient,
		source_definition.flat_damage,
		source_definition.poise_damage,
		snapshot_tags,
		new_direction,
		source_definition.launch_profile,
		new_crit_chance,
		new_crit_damage_multiplier,
		new_critical_roll,
		source_definition.hit_stop_ticks,
		StringName(source_definition.feedback_strength)
	)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if source_instance_id <= 0:
		errors.append("source_instance_id must be greater than 0")
	if attack_id == &"":
		errors.append("attack_id must not be empty")
	if not _is_finite_non_negative(base_attack):
		errors.append("base_attack must be finite and at least 0")
	if not _is_finite_non_negative(coefficient):
		errors.append("coefficient must be finite and at least 0")
	if not _is_finite_non_negative(flat_damage):
		errors.append("flat_damage must be finite and at least 0")
	if not _is_finite_non_negative(poise_damage):
		errors.append("poise_damage must be finite and at least 0")
	if not _is_finite_non_negative(crit_chance):
		errors.append("crit_chance must be finite and at least 0")
	if not _is_finite(crit_damage_multiplier) or crit_damage_multiplier < 1.0:
		errors.append("crit_damage_multiplier must be finite and at least 1")
	if not _is_finite(critical_roll) or critical_roll < 0.0 or critical_roll >= 1.0:
		errors.append("critical_roll must be finite and in [0, 1)")
	if not _is_finite(direction.x) or not _is_finite(direction.y):
		errors.append("direction components must be finite")
	elif direction.length_squared() > 1.000001:
		errors.append("direction length must not exceed 1")
	if launch_profile == &"":
		errors.append("launch_profile must not be empty")
	if hit_stop_ticks < 0:
		errors.append("hit_stop_ticks must be at least 0")
	if not _is_feedback_strength_supported(feedback_strength):
		errors.append("feedback_strength must be light, medium, heavy, or finisher")
	var seen_tags: Dictionary[String, bool] = {}
	for tag: String in hit_tags:
		if tag.is_empty():
			errors.append("hit_tags must not contain an empty value")
		elif seen_tags.has(tag):
			errors.append("duplicate hit tag: %s" % tag)
		else:
			seen_tags[tag] = true
	return errors


func _is_finite_non_negative(value: float) -> bool:
	return _is_finite(value) and value >= 0.0


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)


func _is_feedback_strength_supported(value: StringName) -> bool:
	return value in [&"light", &"medium", &"heavy", &"finisher"]
