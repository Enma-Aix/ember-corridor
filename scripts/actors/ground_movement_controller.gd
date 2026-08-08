class_name PlayerGroundMovementController
extends CharacterBody2D

signal facing_changed(facing_sign: int)
signal dodge_started(direction: Vector2)
signal dodge_finished
signal dodge_invulnerability_changed(is_invulnerable: bool)

const GroundMovementModelScript := preload(
	"res://scripts/actors/ground_movement_model.gd"
)
const DodgeModelScript := preload("res://scripts/actors/dodge_model.gd")

@export_range(1.0, 1000.0, 1.0) var horizontal_speed := 320.0
@export_range(0.1, 1.0, 0.01) var depth_speed_ratio := 0.9

@onready var visual_root: Node2D = %VisualRoot

var _movement_model: GroundMovementModel = GroundMovementModelScript.new()
var _dodge_model: DodgeModel = DodgeModelScript.new()
var _base_visual_scale_x := 1.0
var _displayed_facing := GroundMovementModel.FACING_RIGHT
var _displayed_dodge_invulnerability := false
var _facing_locked := false
var _action_motion_active := false
var _action_motion_pending := false
var _queued_action_displacement := Vector2.ZERO
var _collision_mask_before_action := 0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var configuration_errors := _movement_model.configure(
		horizontal_speed,
		depth_speed_ratio
	)
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			_report_configuration_error(message)
		set_physics_process(false)
		return
	_base_visual_scale_x = absf(visual_root.scale.x)
	_apply_facing()


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	)
	if not _action_motion_active and Input.is_action_just_pressed(&"dodge"):
		try_start_dodge(input_vector)

	var was_dodging := _dodge_model.is_active()
	if _action_motion_pending:
		_action_motion_pending = false
		velocity = _queued_action_displacement / maxf(delta, 0.000001)
		_queued_action_displacement = Vector2.ZERO
		if not was_dodging:
			_dodge_model.advance_tick()
	elif _action_motion_active:
		velocity = Vector2.ZERO
		if not was_dodging:
			_dodge_model.advance_tick()
	elif was_dodging:
		var displacement := _dodge_model.advance_tick()
		velocity = displacement / maxf(delta, 0.000001)
		_sync_dodge_state(was_dodging)
	else:
		_dodge_model.advance_tick()
		velocity = _movement_model.velocity_for_input(input_vector)
		if not _facing_locked:
			_movement_model.update_facing(input_vector.x)
	_apply_facing()
	move_and_slide()


func facing_sign() -> int:
	return _movement_model.facing_sign


func movement_velocity_for_input(input_vector: Vector2) -> Vector2:
	return _movement_model.velocity_for_input(input_vector)


func try_start_dodge(input_vector: Vector2) -> bool:
	if _action_motion_active:
		return false
	if not _dodge_model.try_start(input_vector, _movement_model.facing_sign):
		return false
	_movement_model.update_facing(_dodge_model.direction.x)
	_apply_facing()
	dodge_started.emit(_dodge_model.direction)
	return true


func is_dodging() -> bool:
	return _dodge_model.is_active()


func is_dodge_invulnerable() -> bool:
	return _dodge_model.is_invulnerable()


func dodge_tick() -> int:
	return _dodge_model.action_tick


func dodge_cooldown_ticks() -> int:
	return _dodge_model.cooldown_ticks_remaining


func dodge_direction() -> Vector2:
	return _dodge_model.direction


func set_facing_locked(locked: bool) -> void:
	_facing_locked = locked


func begin_action_motion(blocking_collision_mask: int) -> bool:
	if _action_motion_active or blocking_collision_mask <= 0 or is_dodging():
		return false
	_collision_mask_before_action = collision_mask
	collision_mask = blocking_collision_mask
	_action_motion_active = true
	return true


func queue_action_displacement(displacement: Vector2) -> bool:
	if (
		not is_finite(displacement.x)
		or not is_finite(displacement.y)
	):
		return false
	_queued_action_displacement = displacement
	_action_motion_pending = true
	return true


func end_action_motion() -> void:
	if not _action_motion_active:
		return
	collision_mask = _collision_mask_before_action
	_collision_mask_before_action = 0
	_action_motion_active = false


func is_action_motion_active() -> bool:
	return _action_motion_active


func _apply_facing() -> void:
	var target_scale_x := _base_visual_scale_x * float(_movement_model.facing_sign)
	if is_equal_approx(visual_root.scale.x, target_scale_x):
		return
	visual_root.scale.x = target_scale_x
	_displayed_facing = _movement_model.facing_sign
	facing_changed.emit(_displayed_facing)


func _sync_dodge_state(was_dodging: bool) -> void:
	var current_invulnerability := _dodge_model.is_invulnerable()
	if current_invulnerability != _displayed_dodge_invulnerability:
		_displayed_dodge_invulnerability = current_invulnerability
		dodge_invulnerability_changed.emit(current_invulnerability)
	if was_dodging and not _dodge_model.is_active():
		dodge_finished.emit()


func _report_configuration_error(message: String) -> void:
	var app := get_node_or_null("/root/App")
	if app != null and app.has_method("report_error"):
		app.call("report_error", &"MOV-001", message, true)
		return
	push_error("[MOV-001] %s" % message)
