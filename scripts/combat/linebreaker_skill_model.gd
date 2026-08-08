class_name LinebreakerSkillModel
extends RefCounted

signal skill_started(skill_id: StringName, attack: AttackDefinition)
signal skill_finished(
	skill_id: StringName,
	reason: StringName,
	cancel_target: StringName
)
signal skill_start_rejected(errors: PackedStringArray)

const FINISH_COMPLETE := &"complete"
const FINISH_CANCELED := &"canceled"
const ACTION_TAG_PREFIX := "action."

var timeline: AttackTimelineModel:
	get:
		return _timeline
var current_attack: AttackDefinition:
	get:
		return _definition.primary_attack() if _definition != null else null
var movement_profile: SkillMovementProfile:
	get:
		return _definition.movement_profile if _definition != null else null
var last_finish_reason: StringName:
	get:
		return _last_finish_reason
var last_cancel_target: StringName:
	get:
		return _last_cancel_target

var _definition: SkillDefinition
var _timeline := AttackTimelineModel.new()
var _configured := false
var _active := false
var _facing_sign := 1
var _last_finish_reason: StringName = &""
var _last_cancel_target: StringName = &""


func configure(source_definition: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if source_definition == null:
		errors.append("linebreaker SkillDefinition must not be null")
		return errors
	errors.append_array(source_definition.validation_errors())
	if source_definition.attack_sequence.size() != 1:
		errors.append("linebreaker must declare exactly one AttackDefinition")
	if not errors.is_empty():
		return errors

	var snapshot := source_definition.duplicate(true) as SkillDefinition
	if snapshot == null:
		errors.append("linebreaker SkillDefinition could not be snapshotted")
		return errors
	_definition = snapshot
	_configured = true
	reset()
	return errors


func is_configured() -> bool:
	return _configured


func is_active() -> bool:
	return _active


func skill_id() -> StringName:
	return _definition.definition_id if _definition != null else &""


func try_start(facing_sign: int) -> bool:
	if not _configured or _active or facing_sign not in [-1, 1]:
		return false
	var attack := _definition.primary_attack()
	var start_errors := _timeline.start(attack)
	if not start_errors.is_empty():
		skill_start_rejected.emit(start_errors)
		return false
	_facing_sign = facing_sign
	_active = true
	_last_finish_reason = &""
	_last_cancel_target = &""
	skill_started.emit(_definition.definition_id, attack)
	return true


func advance_tick(input_buffer: InputBufferModel = null) -> Vector2:
	if not _active:
		return Vector2.ZERO
	if not _timeline.advance_tick():
		_finish(FINISH_COMPLETE, &"")
		return Vector2.ZERO

	var current_tick := _timeline.action_tick
	var displacement := movement_profile.displacement_at_tick(
		current_tick,
		_facing_sign
	)
	var cancel_target := _consume_buffered_cancel(input_buffer)
	if cancel_target != &"":
		_finish(FINISH_CANCELED, cancel_target)
	elif not _timeline.is_running:
		_finish(FINISH_COMPLETE, &"")
	return displacement


func reset() -> void:
	_timeline.reset()
	_active = false
	_facing_sign = 1
	_last_finish_reason = &""
	_last_cancel_target = &""


func _consume_buffered_cancel(input_buffer: InputBufferModel) -> StringName:
	if input_buffer == null:
		return &""
	for target_text: String in _timeline.available_cancel_targets():
		if not target_text.begins_with(ACTION_TAG_PREFIX):
			continue
		var input_action := StringName(target_text.trim_prefix(ACTION_TAG_PREFIX))
		if not input_buffer.has_buffered_press(input_action):
			continue
		if input_buffer.consume(input_action):
			return StringName(target_text)
	return &""


func _finish(reason: StringName, cancel_target: StringName) -> void:
	var finished_skill_id := skill_id()
	_last_finish_reason = reason
	_last_cancel_target = cancel_target
	_timeline.reset()
	_active = false
	skill_finished.emit(finished_skill_id, reason, cancel_target)
