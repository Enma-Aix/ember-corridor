class_name HitFeedbackRequest
extends RefCounted

var source_instance_id: int:
	get:
		return _source_instance_id
var target_instance_id: int:
	get:
		return _target_instance_id
var attack_id: StringName:
	get:
		return _attack_id
var hit_id: StringName:
	get:
		return _hit_id
var world_position: Vector2:
	get:
		return _world_position
var direction: Vector2:
	get:
		return _direction
var final_damage: int:
	get:
		return _final_damage
var critical: bool:
	get:
		return _critical
var hit_stop_ticks: int:
	get:
		return _hit_stop_ticks
var feedback_strength: StringName:
	get:
		return _feedback_strength

var _source_instance_id: int
var _target_instance_id: int
var _attack_id: StringName
var _hit_id: StringName
var _world_position: Vector2
var _direction: Vector2
var _final_damage: int
var _critical: bool
var _hit_stop_ticks: int
var _feedback_strength: StringName


func _init(
	new_source_instance_id: int,
	new_target_instance_id: int,
	new_attack_id: StringName,
	new_hit_id: StringName,
	new_world_position: Vector2,
	new_direction: Vector2,
	new_final_damage: int,
	new_critical: bool,
	new_hit_stop_ticks: int,
	new_feedback_strength: StringName
) -> void:
	_source_instance_id = new_source_instance_id
	_target_instance_id = new_target_instance_id
	_attack_id = new_attack_id
	_hit_id = new_hit_id
	_world_position = new_world_position
	_direction = new_direction
	_final_damage = new_final_damage
	_critical = new_critical
	_hit_stop_ticks = new_hit_stop_ticks
	_feedback_strength = new_feedback_strength


static func from_outcome(
	contact: HitContact,
	result: HitResult,
	new_world_position: Vector2,
	new_direction: Vector2
) -> HitFeedbackRequest:
	if contact == null or result == null or not result.accepted:
		return null
	return HitFeedbackRequest.new(
		contact.source_instance_id,
		contact.target_instance_id,
		contact.attack_id,
		contact.hit_id,
		new_world_position,
		new_direction,
		result.final_damage,
		result.critical,
		result.hit_stop_ticks,
		result.feedback_strength
	)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if source_instance_id <= 0:
		errors.append("source_instance_id must be greater than 0")
	if target_instance_id <= 0:
		errors.append("target_instance_id must be greater than 0")
	if attack_id == &"":
		errors.append("attack_id must not be empty")
	if hit_id == &"":
		errors.append("hit_id must not be empty")
	if not _vector_is_finite(world_position):
		errors.append("world_position components must be finite")
	if not _vector_is_finite(direction):
		errors.append("direction components must be finite")
	elif direction.length_squared() > 1.000001:
		errors.append("direction length must not exceed 1")
	if final_damage < 1:
		errors.append("final_damage must be at least 1")
	if hit_stop_ticks < 0:
		errors.append("hit_stop_ticks must be at least 0")
	if feedback_strength not in HitFeedbackProfile.SUPPORTED_STRENGTHS:
		errors.append("feedback_strength is not supported")
	return errors


func _vector_is_finite(value: Vector2) -> bool:
	return (
		not is_nan(value.x)
		and not is_inf(value.x)
		and not is_nan(value.y)
		and not is_inf(value.y)
	)
