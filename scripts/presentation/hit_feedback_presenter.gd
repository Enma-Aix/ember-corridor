class_name HitFeedbackPresenter
extends Node2D

signal vfx_presented(style: StringName)
signal sfx_presented(cue: StringName, layer_count: int)

@export var camera_path: NodePath

var vfx_request_count: int:
	get:
		return _vfx_request_count
var sfx_request_count: int:
	get:
		return _sfx_request_count
var active_vfx_count: int:
	get:
		return _active_vfx.size()
var last_sfx_cue: StringName:
	get:
		return _last_sfx_cue
var last_sfx_layer_count: int:
	get:
		return _last_sfx_layer_count

var _service: HitFeedbackService
var _camera: Camera2D
var _active_vfx: Array[Dictionary] = []
var _vfx_request_count := 0
var _sfx_request_count := 0
var _last_sfx_cue: StringName = &""
var _last_sfx_layer_count := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = get_node_or_null(camera_path) as Camera2D


func _physics_process(_delta: float) -> void:
	if _active_vfx.is_empty():
		return
	var survivors: Array[Dictionary] = []
	for effect: Dictionary in _active_vfx:
		var ticks_remaining := int(effect["ticks_remaining"]) - 1
		if ticks_remaining <= 0:
			continue
		effect["ticks_remaining"] = ticks_remaining
		survivors.append(effect)
	_active_vfx = survivors
	queue_redraw()


func _draw() -> void:
	for effect: Dictionary in _active_vfx:
		var position: Vector2 = effect["position"]
		var direction: Vector2 = effect["direction"]
		var color: Color = effect["color"]
		var lifetime := maxi(int(effect["lifetime"]), 1)
		var ticks_remaining := int(effect["ticks_remaining"])
		var progress := 1.0 - float(ticks_remaining) / float(lifetime)
		var radius := lerpf(7.0, 30.0, progress) * float(effect["scale"])
		var alpha := 1.0 - progress
		color.a *= alpha
		draw_arc(position, radius, 0.0, TAU, 24, color, 3.0)
		var ray_direction := direction.normalized()
		if ray_direction.is_zero_approx():
			ray_direction = Vector2.RIGHT
		draw_line(
			position - ray_direction * radius * 0.35,
			position + ray_direction * radius,
			color,
			4.0
		)


func bind_service(service: HitFeedbackService) -> PackedStringArray:
	var errors := PackedStringArray()
	if service == null:
		errors.append("HitFeedbackPresenter requires a service")
		return errors
	_unbind_service()
	_service = service
	_service.camera_state_changed.connect(_on_camera_state_changed)
	_service.vfx_feedback_requested.connect(_on_vfx_feedback_requested)
	_service.sfx_feedback_requested.connect(_on_sfx_feedback_requested)
	return errors


func _exit_tree() -> void:
	_unbind_service()
	_reset_camera()


func _on_camera_state_changed(offset: Vector2, zoom_scale: float) -> void:
	if _camera == null:
		return
	_camera.offset = offset
	_camera.zoom = Vector2.ONE * zoom_scale


func _on_vfx_feedback_requested(
	world_position: Vector2,
	direction: Vector2,
	style: StringName,
	scale: float,
	lifetime_ticks: int,
	critical: bool
) -> void:
	var color := _color_for_style(style)
	if critical:
		color = color.lightened(0.28)
	_active_vfx.append(
		{
			"position": world_position,
			"direction": direction,
			"color": color,
			"scale": scale * (1.2 if critical else 1.0),
			"lifetime": lifetime_ticks,
			"ticks_remaining": lifetime_ticks,
		}
	)
	_vfx_request_count += 1
	queue_redraw()
	vfx_presented.emit(style)


func _on_sfx_feedback_requested(
	_world_position: Vector2,
	cue: StringName,
	layer_count: int,
	_critical: bool
) -> void:
	_sfx_request_count += 1
	_last_sfx_cue = cue
	_last_sfx_layer_count = layer_count
	sfx_presented.emit(cue, layer_count)


func _unbind_service() -> void:
	if _service == null:
		return
	if _service.camera_state_changed.is_connected(_on_camera_state_changed):
		_service.camera_state_changed.disconnect(_on_camera_state_changed)
	if _service.vfx_feedback_requested.is_connected(_on_vfx_feedback_requested):
		_service.vfx_feedback_requested.disconnect(_on_vfx_feedback_requested)
	if _service.sfx_feedback_requested.is_connected(_on_sfx_feedback_requested):
		_service.sfx_feedback_requested.disconnect(_on_sfx_feedback_requested)
	_service = null


func _reset_camera() -> void:
	if _camera == null:
		return
	_camera.offset = Vector2.ZERO
	_camera.zoom = Vector2.ONE


func _color_for_style(style: StringName) -> Color:
	match style:
		&"vfx.hit.medium":
			return Color(0.2, 0.86, 1.0, 0.92)
		&"vfx.hit.heavy":
			return Color(1.0, 0.72, 0.18, 0.95)
		&"vfx.hit.finisher":
			return Color(1.0, 0.94, 0.62, 1.0)
	return Color(1.0, 0.42, 0.12, 0.86)
