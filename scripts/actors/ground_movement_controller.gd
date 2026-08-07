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
	if Input.is_action_just_pressed(&"dodge"):
		try_start_dodge(input_vector)

	var was_dodging := _dodge_model.is_active()
	if was_dodging:
		var displacement := _dodge_model.advance_tick()
		velocity = displacement / maxf(delta, 0.000001)
		_sync_dodge_state(was_dodging)
	else:
		_dodge_model.advance_tick()
		velocity = _movement_model.velocity_for_input(input_vector)
		_movement_model.update_facing(input_vector.x)
	_apply_facing()
	move_and_slide()


func facing_sign() -> int:
	return _movement_model.facing_sign


func movement_velocity_for_input(input_vector: Vector2) -> Vector2:
	return _movement_model.velocity_for_input(input_vector)


func try_start_dodge(input_vector: Vector2) -> bool:
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
