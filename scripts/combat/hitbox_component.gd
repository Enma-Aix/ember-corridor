class_name HitboxComponent
extends Area2D

const HitContactScript := preload("res://scripts/combat/hit_contact.gd")

var is_active: bool:
	get:
		return _is_active
var contact_enabled: bool:
	get:
		return _contact_enabled
var hit_id: StringName:
	get:
		return _hit_id
var action_tick: int:
	get:
		return _action_tick
var facing_sign: int:
	get:
		return _facing_sign

var _definition: AttackDefinition
var _source_instance_id := 0
var _source_faction: StringName = &""
var _hit_id: StringName = &""
var _action_tick := 0
var _source_elevation := 0.0
var _facing_sign := 1
var _is_active := false
var _contact_enabled := false


func _ready() -> void:
	monitoring = false
	_set_contact_nodes_enabled(false)


func activate(
	source_definition: AttackDefinition,
	new_hit_id: StringName,
	new_source_instance_id: int,
	new_source_faction: StringName,
	new_facing_sign: int,
	new_source_elevation := 0.0
) -> PackedStringArray:
	var errors := PackedStringArray()
	if _is_active:
		errors.append("cannot activate a new hit_id while this hitbox is active")
	if source_definition == null:
		errors.append("attack definition must not be null")
	else:
		errors.append_array(source_definition.validation_errors())
	if new_hit_id == &"":
		errors.append("hit_id must not be empty")
	if new_source_instance_id <= 0:
		errors.append("source instance ID must be greater than 0")
	if not _is_supported_faction(new_source_faction):
		errors.append("source faction must be player or enemy")
	if new_facing_sign != -1 and new_facing_sign != 1:
		errors.append("facing sign must be -1 or 1")
	if new_source_elevation < 0.0:
		errors.append("source elevation must be at least 0")
	if _collision_shape() == null:
		errors.append("HitboxComponent requires a CollisionShape2D child")
	if not errors.is_empty():
		return errors

	var definition_snapshot := source_definition.duplicate(true) as AttackDefinition
	if definition_snapshot == null:
		errors.append("attack definition could not be snapshotted")
		return errors
	_definition = definition_snapshot
	_hit_id = new_hit_id
	_source_instance_id = new_source_instance_id
	_source_faction = new_source_faction
	_source_elevation = new_source_elevation
	_action_tick = 0
	_is_active = true
	_apply_collision_profile()
	set_facing_sign(new_facing_sign)
	set_contact_enabled(false)
	return errors


func deactivate() -> void:
	set_contact_enabled(false)
	_definition = null
	_source_instance_id = 0
	_source_faction = &""
	_hit_id = &""
	_action_tick = 0
	_source_elevation = 0.0
	_is_active = false


func set_action_tick(new_action_tick: int) -> bool:
	if not _is_active or _definition == null:
		return false
	if new_action_tick < 0 or new_action_tick > _definition.total_ticks():
		return false
	_action_tick = new_action_tick
	return true


func set_contact_enabled(enabled: bool) -> bool:
	var should_enable := (
		enabled
		and _is_active
		and _definition != null
		and _definition.is_active_tick(_action_tick)
	)
	_contact_enabled = should_enable
	_set_contact_nodes_enabled(should_enable)
	return should_enable == enabled


func set_facing_sign(new_facing_sign: int) -> bool:
	if new_facing_sign != -1 and new_facing_sign != 1:
		return false
	_facing_sign = new_facing_sign
	if _definition != null:
		position = Vector2(
			absf(_definition.hitbox_offset.x) * float(_facing_sign),
			_definition.hitbox_offset.y
		)
	return true


func build_contact(
	target_instance_id: int,
	target_faction: StringName,
	target_invulnerable: bool,
	target_min_hit_height: float,
	target_max_hit_height: float
) -> HitContact:
	if not _contact_enabled or _definition == null:
		return null
	return HitContactScript.new(
		_source_instance_id,
		target_instance_id,
		_source_faction,
		target_faction,
		_definition.definition_id,
		_hit_id,
		_action_tick,
		_definition.rehit_interval_ticks,
		_source_elevation + _definition.min_hit_height,
		_source_elevation + _definition.max_hit_height,
		target_min_hit_height,
		target_max_hit_height,
		target_invulnerable
	)


func _apply_collision_profile() -> void:
	if _source_faction == &"player":
		collision_layer = 1 << 3
		collision_mask = 1 << 6
	else:
		collision_layer = 1 << 4
		collision_mask = 1 << 5
	var collision_shape := _collision_shape()
	if collision_shape == null:
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = _definition.hitbox_size
	collision_shape.shape = rectangle
	var debug_shape := get_node_or_null("DebugShape") as Polygon2D
	if debug_shape != null:
		var half_size := _definition.hitbox_size * 0.5
		debug_shape.polygon = PackedVector2Array(
			[
				Vector2(-half_size.x, -half_size.y),
				Vector2(half_size.x, -half_size.y),
				Vector2(half_size.x, half_size.y),
				Vector2(-half_size.x, half_size.y),
			]
		)


func _set_contact_nodes_enabled(enabled: bool) -> void:
	monitorable = enabled
	var collision_shape := _collision_shape()
	if collision_shape != null:
		collision_shape.disabled = not enabled
	var debug_shape := get_node_or_null("DebugShape") as Polygon2D
	if debug_shape != null:
		debug_shape.visible = enabled and OS.is_debug_build()


func _collision_shape() -> CollisionShape2D:
	return get_node_or_null("CollisionShape2D") as CollisionShape2D


func _is_supported_faction(faction: StringName) -> bool:
	return faction == &"player" or faction == &"enemy"
