extends Control

const DISPLAY_ACTIONS := [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"attack",
	&"jump",
	&"dodge",
	&"skill_1",
	&"skill_2",
	&"skill_3",
	&"skill_4",
	&"ultimate",
	&"interact",
	&"pause",
]

@onready var subtitle_label: Label = %SubtitleLabel
@onready var version_label: Label = %VersionLabel
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var status_label: Label = %StatusLabel
@onready var device_label: Label = %DeviceLabel
@onready var actions_label: Label = %ActionsLabel
@onready var movement_label: Label = %MovementLabel


func _ready() -> void:
	version_label.text = App.version_label()
	debug_panel.visible = OS.is_debug_build()
	if not OS.is_debug_build():
		subtitle_label.text = "Foundation build"
		return
	if not App.startup_completed.is_connected(_on_startup_completed):
		App.startup_completed.connect(_on_startup_completed)
	if not SettingsService.input_device_changed.is_connected(_on_input_device_changed):
		SettingsService.input_device_changed.connect(_on_input_device_changed)
	_on_input_device_changed(SettingsService.active_input_device)
	_refresh_startup_status()


func _process(_delta: float) -> void:
	if not debug_panel.visible:
		return
	var active_actions := PackedStringArray()
	for action: StringName in DISPLAY_ACTIONS:
		if Input.is_action_pressed(action):
			active_actions.append(String(action))
	actions_label.text = "Active actions: %s" % (
		", ".join(active_actions) if not active_actions.is_empty() else "none"
	)
	var movement := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	)
	movement_label.text = "Movement vector: (%.2f, %.2f)" % [movement.x, movement.y]


func _on_startup_completed() -> void:
	_refresh_startup_status()


func _on_input_device_changed(_device: int) -> void:
	device_label.text = "Device: %s" % SettingsService.active_input_device_label()


func _refresh_startup_status() -> void:
	if App.is_ready_for_gameplay:
		status_label.text = "Foundation status: READY · Data definitions: %d" % (
			DataRegistry.definition_count()
		)
		status_label.modulate = Color(0.55, 0.95, 0.68)
	elif App.startup_errors.is_empty():
		status_label.text = "Foundation status: INITIALIZING"
		status_label.modulate = Color(0.95, 0.82, 0.45)
	else:
		status_label.text = "Foundation status: BLOCKED · Check error log"
		status_label.modulate = Color(1.0, 0.48, 0.48)

