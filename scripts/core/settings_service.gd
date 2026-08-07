extends Node

signal input_device_changed(device: int)

enum InputDevice {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

const REQUIRED_ACTIONS := [
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

var active_input_device := InputDevice.KEYBOARD_MOUSE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_default_input_map()
	GameLog.info(&"SettingsService", "Default keyboard and XInput actions are available")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed:
			_set_active_input_device(InputDevice.GAMEPAD)
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) >= 0.35:
			_set_active_input_device(InputDevice.GAMEPAD)
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_set_active_input_device(InputDevice.KEYBOARD_MOUSE)
	elif event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.pressed:
			_set_active_input_device(InputDevice.KEYBOARD_MOUSE)
	elif event is InputEventMouseMotion:
		var mouse_motion_event := event as InputEventMouseMotion
		if mouse_motion_event.relative.length_squared() >= 4.0:
			_set_active_input_device(InputDevice.KEYBOARD_MOUSE)


func ensure_default_input_map() -> void:
	for action: StringName in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		if InputMap.action_get_events(action).is_empty():
			_install_default_events(action)


func active_input_device_label() -> String:
	match active_input_device:
		InputDevice.GAMEPAD:
			return "XInput gamepad"
		_:
			return "Keyboard / mouse"


func _set_active_input_device(device: int) -> void:
	if active_input_device == device:
		return
	active_input_device = device
	GameLog.debug(&"SettingsService", "Input device changed to %s" % active_input_device_label())
	input_device_changed.emit(device)


func _install_default_events(action: StringName) -> void:
	match action:
		&"move_left":
			_add_key(action, KEY_A)
			_add_joy_axis(action, JOY_AXIS_LEFT_X, -1.0)
			_add_joy_button(action, JOY_BUTTON_DPAD_LEFT)
		&"move_right":
			_add_key(action, KEY_D)
			_add_joy_axis(action, JOY_AXIS_LEFT_X, 1.0)
			_add_joy_button(action, JOY_BUTTON_DPAD_RIGHT)
		&"move_up":
			_add_key(action, KEY_W)
			_add_joy_axis(action, JOY_AXIS_LEFT_Y, -1.0)
			_add_joy_button(action, JOY_BUTTON_DPAD_UP)
		&"move_down":
			_add_key(action, KEY_S)
			_add_joy_axis(action, JOY_AXIS_LEFT_Y, 1.0)
			_add_joy_button(action, JOY_BUTTON_DPAD_DOWN)
		&"attack":
			_add_key(action, KEY_J)
			_add_joy_button(action, JOY_BUTTON_X)
		&"jump":
			_add_key(action, KEY_K)
			_add_joy_button(action, JOY_BUTTON_A)
		&"dodge":
			_add_key(action, KEY_L)
			_add_joy_button(action, JOY_BUTTON_B)
		&"skill_1":
			_add_key(action, KEY_U)
			_add_joy_button(action, JOY_BUTTON_Y)
		&"skill_2":
			_add_key(action, KEY_I)
			_add_joy_button(action, JOY_BUTTON_LEFT_SHOULDER)
		&"skill_3":
			_add_key(action, KEY_O)
			_add_joy_button(action, JOY_BUTTON_LEFT_STICK)
		&"skill_4":
			_add_key(action, KEY_P)
			_add_joy_button(action, JOY_BUTTON_RIGHT_STICK)
		&"ultimate":
			_add_key(action, KEY_H)
			_add_joy_button(action, JOY_BUTTON_RIGHT_SHOULDER)
		&"interact":
			_add_key(action, KEY_SPACE)
			_add_joy_button(action, JOY_BUTTON_BACK)
		&"pause":
			_add_key(action, KEY_ESCAPE)
			_add_joy_button(action, JOY_BUTTON_START)


func _add_key(action: StringName, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_joy_button(action: StringName, button_index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, axis: int, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
