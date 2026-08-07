class_name ElevationComponent
extends Node

signal jump_started
signal landed
signal elevation_changed(elevation: float)

const ElevationModelScript := preload("res://scripts/actors/elevation_model.gd")

@export_range(1.0, 2000.0, 1.0) var jump_speed := 720.0
@export_range(1.0, 5000.0, 1.0) var gravity := 1800.0
@export_range(0.0, 500.0, 1.0) var min_hit_height := 0.0
@export_range(0.0, 500.0, 1.0) var max_hit_height := 56.0
@export_node_path("Node2D") var visual_root_path := NodePath("../VisualRoot")

@onready var visual_root: Node2D = get_node(visual_root_path)

var _elevation_model: ElevationModel = ElevationModelScript.new()
var _base_visual_position := Vector2.ZERO


func _ready() -> void:
	_base_visual_position = visual_root.position
	var configuration_errors := _elevation_model.configure(
		jump_speed,
		gravity,
		min_hit_height,
		max_hit_height
	)
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			_report_configuration_error(message)
		set_physics_process(false)
		return
	_apply_visual_offset()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump"):
		request_jump()
	advance_physics(delta)


func request_jump() -> bool:
	if not _elevation_model.request_jump():
		return false
	jump_started.emit()
	return true


func advance_physics(delta: float) -> bool:
	var previous_elevation := _elevation_model.elevation
	var did_land := _elevation_model.advance(delta)
	_apply_visual_offset()
	if not is_equal_approx(previous_elevation, _elevation_model.elevation):
		elevation_changed.emit(_elevation_model.elevation)
	if did_land:
		landed.emit()
	return did_land


func elevation() -> float:
	return _elevation_model.elevation


func vertical_velocity() -> float:
	return _elevation_model.vertical_velocity


func is_grounded() -> bool:
	return _elevation_model.grounded


func hit_height_range() -> Vector2:
	return _elevation_model.hit_height_range()


func overlaps_height_range(query_min: float, query_max: float) -> bool:
	return _elevation_model.overlaps_height_range(query_min, query_max)


func _apply_visual_offset() -> void:
	visual_root.position = Vector2(
		_base_visual_position.x,
		_base_visual_position.y - _elevation_model.elevation
	)


func _report_configuration_error(message: String) -> void:
	var app := get_node_or_null("/root/App")
	if app != null and app.has_method("report_error"):
		app.call("report_error", &"MOV-002", message, true)
		return
	push_error("[MOV-002] %s" % message)
