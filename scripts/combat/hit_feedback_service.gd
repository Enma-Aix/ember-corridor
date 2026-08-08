class_name HitFeedbackService
extends Node

signal feedback_accepted(request: HitFeedbackRequest, profile: HitFeedbackProfile)
signal feedback_rejected(errors: PackedStringArray)
signal hit_stop_requested(requested_ticks: int, active_ticks: int)
signal hit_stop_tick(remaining_ticks: int)
signal hit_stop_finished
signal camera_feedback_requested(
	world_position: Vector2,
	shake_pixels: float,
	duration_ticks: int,
	zoom_pulse: float
)
signal camera_state_changed(offset: Vector2, zoom_scale: float)
signal vfx_feedback_requested(
	world_position: Vector2,
	direction: Vector2,
	style: StringName,
	scale: float,
	lifetime_ticks: int,
	critical: bool
)
signal sfx_feedback_requested(
	world_position: Vector2,
	cue: StringName,
	layer_count: int,
	critical: bool
)

const MAX_CAMERA_FEEDBACK_TICKS := 30
const SHAKE_PATTERN := [
	Vector2(1.0, 0.0),
	Vector2(-0.65, 0.75),
	Vector2(0.35, -1.0),
	Vector2(-1.0, -0.3),
	Vector2(0.75, 0.55),
	Vector2(-0.25, -0.7),
]

@export var auto_pause_tree := true

var hit_stop_ticks_remaining: int:
	get:
		return _hit_stop_ticks_remaining
var camera_ticks_remaining: int:
	get:
		return _camera_ticks_remaining
var camera_shake_pixels: float:
	get:
		return _camera_shake_pixels
var camera_zoom_pulse: float:
	get:
		return _camera_zoom_pulse
var request_count: int:
	get:
		return _request_count

var _profiles: Dictionary[StringName, HitFeedbackProfile] = {}
var _configured := false
var _hit_stop_ticks_remaining := 0
var _camera_ticks_remaining := 0
var _camera_peak_ticks := 0
var _camera_shake_pixels := 0.0
var _camera_zoom_pulse := 0.0
var _camera_step := 0
var _request_count := 0
var _owns_tree_pause := false
var _last_request_physics_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -100


func _physics_process(_delta: float) -> void:
	if not _configured:
		return
	if _hit_stop_ticks_remaining > 0 and not _can_advance_hit_stop():
		return
	var consume_hit_stop := Engine.get_physics_frames() != _last_request_physics_frame
	advance_feedback_tick(consume_hit_stop)
	if _hit_stop_ticks_remaining <= 0:
		_release_tree_pause()


func _exit_tree() -> void:
	_release_tree_pause()


func configure(source_profiles: Array[HitFeedbackProfile]) -> PackedStringArray:
	var errors := PackedStringArray()
	var snapshots: Dictionary[StringName, HitFeedbackProfile] = {}
	for index: int in source_profiles.size():
		var source_profile: HitFeedbackProfile = source_profiles[index]
		if source_profile == null:
			errors.append("feedback profile[%d] must not be null" % index)
			continue
		for message: String in source_profile.validation_errors():
			errors.append("feedback profile[%d]: %s" % [index, message])
		var key := source_profile.strength_key()
		if snapshots.has(key):
			errors.append("duplicate feedback strength: %s" % String(key))
			continue
		var snapshot := source_profile.duplicate(true) as HitFeedbackProfile
		if snapshot == null:
			errors.append("feedback profile[%d] could not be snapshotted" % index)
		else:
			snapshots[key] = snapshot
	for required_strength: StringName in HitFeedbackProfile.SUPPORTED_STRENGTHS:
		if not snapshots.has(required_strength):
			errors.append("missing feedback strength: %s" % String(required_strength))
	if not errors.is_empty():
		return errors

	_release_tree_pause()
	_profiles = snapshots
	_configured = true
	reset_runtime()
	return errors


func is_configured() -> bool:
	return _configured


func has_profile(strength: StringName) -> bool:
	return _profiles.has(strength)


func profile_for(strength: StringName) -> HitFeedbackProfile:
	return _profiles.get(strength) as HitFeedbackProfile


func request_feedback(request: HitFeedbackRequest) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _configured:
		errors.append("hit feedback service is not configured")
	elif request == null:
		errors.append("hit feedback request must not be null")
	else:
		errors.append_array(request.validation_errors())
		if not _profiles.has(request.feedback_strength):
			errors.append(
				"no profile for feedback strength: %s"
				% String(request.feedback_strength)
			)
	if not errors.is_empty():
		feedback_rejected.emit(errors)
		return errors

	var profile: HitFeedbackProfile = _profiles[request.feedback_strength]
	var resolved_hit_stop := profile.resolve_hit_stop_ticks(request.hit_stop_ticks)
	_hit_stop_ticks_remaining = maxi(
		_hit_stop_ticks_remaining,
		resolved_hit_stop
	)
	_merge_camera_feedback(profile)
	_request_count += 1
	_last_request_physics_frame = Engine.get_physics_frames()

	if resolved_hit_stop > 0:
		hit_stop_requested.emit(resolved_hit_stop, _hit_stop_ticks_remaining)
		_try_acquire_tree_pause()
	camera_feedback_requested.emit(
		request.world_position,
		profile.camera_shake_pixels,
		profile.camera_duration_ticks,
		profile.camera_zoom_pulse
	)
	vfx_feedback_requested.emit(
		request.world_position,
		request.direction,
		profile.vfx_style,
		profile.vfx_scale,
		profile.vfx_lifetime_ticks,
		request.critical
	)
	sfx_feedback_requested.emit(
		request.world_position,
		profile.sfx_cue,
		profile.sfx_layer_count,
		request.critical
	)
	feedback_accepted.emit(request, profile)
	return errors


func advance_feedback_tick(consume_hit_stop := true) -> bool:
	var was_hit_stopped := _hit_stop_ticks_remaining > 0
	if was_hit_stopped and consume_hit_stop:
		_hit_stop_ticks_remaining -= 1
		hit_stop_tick.emit(_hit_stop_ticks_remaining)
		if _hit_stop_ticks_remaining == 0:
			hit_stop_finished.emit()
	_advance_camera_tick()
	return was_hit_stopped


func reset_runtime() -> void:
	_release_tree_pause()
	_hit_stop_ticks_remaining = 0
	_camera_ticks_remaining = 0
	_camera_peak_ticks = 0
	_camera_shake_pixels = 0.0
	_camera_zoom_pulse = 0.0
	_camera_step = 0
	_request_count = 0
	_last_request_physics_frame = -1
	camera_state_changed.emit(Vector2.ZERO, 1.0)


func _merge_camera_feedback(profile: HitFeedbackProfile) -> void:
	var extension := 0
	if _camera_ticks_remaining > 0:
		extension = profile.camera_extension_ticks
	_camera_ticks_remaining = mini(
		maxi(_camera_ticks_remaining, profile.camera_duration_ticks) + extension,
		MAX_CAMERA_FEEDBACK_TICKS
	)
	_camera_peak_ticks = maxi(_camera_peak_ticks, _camera_ticks_remaining)
	_camera_shake_pixels = maxf(
		_camera_shake_pixels,
		profile.camera_shake_pixels
	)
	_camera_zoom_pulse = maxf(
		_camera_zoom_pulse,
		profile.camera_zoom_pulse
	)


func _advance_camera_tick() -> void:
	if _camera_ticks_remaining <= 0:
		return
	_camera_ticks_remaining -= 1
	_camera_step += 1
	if _camera_ticks_remaining == 0:
		_camera_peak_ticks = 0
		_camera_shake_pixels = 0.0
		_camera_zoom_pulse = 0.0
		camera_state_changed.emit(Vector2.ZERO, 1.0)
		return
	var envelope := (
		float(_camera_ticks_remaining)
		/ maxf(float(_camera_peak_ticks), 1.0)
	)
	var pattern: Vector2 = SHAKE_PATTERN[_camera_step % SHAKE_PATTERN.size()]
	var offset := pattern.normalized() * _camera_shake_pixels * envelope
	var zoom_scale := 1.0 + _camera_zoom_pulse * envelope
	camera_state_changed.emit(offset, zoom_scale)


func _can_advance_hit_stop() -> bool:
	if not auto_pause_tree or not is_inside_tree():
		return true
	var tree := get_tree()
	if tree == null:
		return true
	if _owns_tree_pause:
		return true
	if tree.paused:
		return false
	_try_acquire_tree_pause()
	return _owns_tree_pause


func _try_acquire_tree_pause() -> void:
	if (
		not auto_pause_tree
		or not is_inside_tree()
		or _hit_stop_ticks_remaining <= 0
		or _owns_tree_pause
	):
		return
	var tree := get_tree()
	if tree == null or tree.paused:
		return
	tree.paused = true
	_owns_tree_pause = true


func _release_tree_pause() -> void:
	if not _owns_tree_pause:
		return
	var tree := get_tree()
	if tree != null:
		tree.paused = false
	_owns_tree_pause = false
