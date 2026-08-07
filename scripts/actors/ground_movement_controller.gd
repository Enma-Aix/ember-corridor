class_name PlayerGroundMovementController
extends CharacterBody2D

signal facing_changed(facing_sign: int)

const GroundMovementModelScript := preload(
	"res://scripts/actors/ground_movement_model.gd"
)

@export_range(1.0, 1000.0, 1.0) var horizontal_speed := 320.0
@export_range(0.1, 1.0, 0.01) var depth_speed_ratio := 0.9

@onready var visual_root: Node2D = %VisualRoot

var _movement_model: GroundMovementModel = GroundMovementModelScript.new()
var _base_visual_scale_x := 1.0
var _displayed_facing := GroundMovementModel.FACING_RIGHT


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var configuration_errors := _movement_model.configure(
		horizontal_speed,
		depth_speed_ratio
	)
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			App.report_error(&"MOV-001", message, true)
		set_physics_process(false)
		return
	_base_visual_scale_x = absf(visual_root.scale.x)
	_apply_facing()


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	)
	velocity = _movement_model.velocity_for_input(input_vector)
	_movement_model.update_facing(input_vector.x)
	_apply_facing()
	move_and_slide()


func facing_sign() -> int:
	return _movement_model.facing_sign


func movement_velocity_for_input(input_vector: Vector2) -> Vector2:
	return _movement_model.velocity_for_input(input_vector)


func _apply_facing() -> void:
	var target_scale_x := _base_visual_scale_x * float(_movement_model.facing_sign)
	if is_equal_approx(visual_root.scale.x, target_scale_x):
		return
	visual_root.scale.x = target_scale_x
	_displayed_facing = _movement_model.facing_sign
	facing_changed.emit(_displayed_facing)
