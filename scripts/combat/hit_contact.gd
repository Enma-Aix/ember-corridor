class_name HitContact
extends RefCounted

var source_instance_id: int:
	get:
		return _source_instance_id
var target_instance_id: int:
	get:
		return _target_instance_id
var source_faction: StringName:
	get:
		return _source_faction
var target_faction: StringName:
	get:
		return _target_faction
var attack_id: StringName:
	get:
		return _attack_id
var hit_id: StringName:
	get:
		return _hit_id
var action_tick: int:
	get:
		return _action_tick
var rehit_interval_ticks: int:
	get:
		return _rehit_interval_ticks
var source_min_hit_height: float:
	get:
		return _source_min_hit_height
var source_max_hit_height: float:
	get:
		return _source_max_hit_height
var target_min_hit_height: float:
	get:
		return _target_min_hit_height
var target_max_hit_height: float:
	get:
		return _target_max_hit_height
var target_invulnerable: bool:
	get:
		return _target_invulnerable

var _source_instance_id: int
var _target_instance_id: int
var _source_faction: StringName
var _target_faction: StringName
var _attack_id: StringName
var _hit_id: StringName
var _action_tick: int
var _rehit_interval_ticks: int
var _source_min_hit_height: float
var _source_max_hit_height: float
var _target_min_hit_height: float
var _target_max_hit_height: float
var _target_invulnerable: bool


func _init(
	new_source_instance_id: int,
	new_target_instance_id: int,
	new_source_faction: StringName,
	new_target_faction: StringName,
	new_attack_id: StringName,
	new_hit_id: StringName,
	new_action_tick: int,
	new_rehit_interval_ticks: int,
	new_source_min_hit_height: float,
	new_source_max_hit_height: float,
	new_target_min_hit_height: float,
	new_target_max_hit_height: float,
	new_target_invulnerable: bool
) -> void:
	_source_instance_id = new_source_instance_id
	_target_instance_id = new_target_instance_id
	_source_faction = new_source_faction
	_target_faction = new_target_faction
	_attack_id = new_attack_id
	_hit_id = new_hit_id
	_action_tick = new_action_tick
	_rehit_interval_ticks = new_rehit_interval_ticks
	_source_min_hit_height = new_source_min_hit_height
	_source_max_hit_height = new_source_max_hit_height
	_target_min_hit_height = new_target_min_hit_height
	_target_max_hit_height = new_target_max_hit_height
	_target_invulnerable = new_target_invulnerable


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if source_instance_id <= 0:
		errors.append("source_instance_id must be greater than 0")
	if target_instance_id <= 0:
		errors.append("target_instance_id must be greater than 0")
	if source_faction == &"" or target_faction == &"":
		errors.append("source and target factions must not be empty")
	if attack_id == &"":
		errors.append("attack_id must not be empty")
	if hit_id == &"":
		errors.append("hit_id must not be empty")
	if action_tick < 1:
		errors.append("action_tick must be at least 1")
	if rehit_interval_ticks < 0:
		errors.append("rehit_interval_ticks must be at least 0")
	if source_min_hit_height < 0.0 or source_max_hit_height < source_min_hit_height:
		errors.append("source hit-height range is invalid")
	if target_min_hit_height < 0.0 or target_max_hit_height < target_min_hit_height:
		errors.append("target hit-height range is invalid")
	return errors


func height_ranges_overlap() -> bool:
	return (
		source_max_hit_height >= target_min_hit_height
		and target_max_hit_height >= source_min_hit_height
	)


func dedupe_key() -> String:
	return "%d|%s|%d" % [source_instance_id, String(hit_id), target_instance_id]
