extends SceneTree

const BaseDefinitionScript := preload("res://scripts/data/base_definition.gd")
const AttackDefinitionScript := preload("res://scripts/data/attack_definition.gd")
const AttackCancelWindowScript := preload(
	"res://scripts/data/attack_cancel_window.gd"
)
const DataRegistryScript := preload("res://scripts/core/data_registry.gd")
const SettingsServiceScript := preload("res://scripts/core/settings_service.gd")
const GroundMovementModelScript := preload(
	"res://scripts/actors/ground_movement_model.gd"
)
const ElevationModelScript := preload("res://scripts/actors/elevation_model.gd")
const DodgeModelScript := preload("res://scripts/actors/dodge_model.gd")
const StateMachineModelScript := preload(
	"res://scripts/combat/state_machine_model.gd"
)
const AttackTimelineModelScript := preload(
	"res://scripts/combat/attack_timeline_model.gd"
)
const HitContactScript := preload("res://scripts/combat/hit_contact.gd")
const HitResolverModelScript := preload(
	"res://scripts/combat/hit_resolver_model.gd"
)
const HitboxComponentScript := preload(
	"res://scripts/combat/hitbox_component.gd"
)
const HurtboxComponentScript := preload(
	"res://scripts/combat/hurtbox_component.gd"
)

var _case_results: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_record_case("version is pinned to Godot 4.7.1", _test_version_pin())
	_record_case("required input actions have keyboard and gamepad events", _test_input_actions())
	_record_case("input device switching reacts to keyboard, mouse, and gamepad events", _test_input_device_switching())
	_record_case("ground movement uses horizontal and depth speeds", _test_ground_movement_speeds())
	_record_case("ground movement normalizes boundary input", _test_ground_movement_boundaries())
	_record_case("ground movement rejects invalid configuration", _test_ground_movement_invalid_configuration())
	_record_case("ground movement facing ignores vertical input and stick jitter", _test_ground_movement_facing())
	_record_case("elevation jump starts once and blocks air jumps", _test_elevation_jump_gating())
	_record_case("elevation lands once and remains stable", _test_elevation_landing())
	_record_case("elevation rejects invalid configuration and delta", _test_elevation_invalid_configuration())
	_record_case("elevation height ranges support boundary queries", _test_elevation_height_ranges())
	_record_case("elevation component separates visuals from ground coordinates", _test_elevation_component_separation())
	_record_case("dodge lasts 24 ticks and travels configured distance", _test_dodge_duration_and_distance())
	_record_case("dodge invulnerability is active on ticks 4 through 13", _test_dodge_invulnerability_ticks())
	_record_case("dodge resolves eight directions and facing fallback", _test_dodge_direction_resolution())
	_record_case("dodge cooldown blocks exactly 45 ticks", _test_dodge_cooldown_boundary())
	var dodge_wall_errors: PackedStringArray = await _test_dodge_wall_collision()
	_record_case("dodge cannot cross WorldStatic walls", dodge_wall_errors)
	_record_case("state machine accepts a valid transition table", _test_state_machine_configuration())
	_record_case("state machine applies legal transitions and signals", _test_state_machine_legal_transitions())
	_record_case("state machine rejects illegal transitions with reasons", _test_state_machine_rejections())
	_record_case("state machine invalid configuration is transactional", _test_state_machine_invalid_configuration())
	_record_case("state machine reset and terminal state remain stable", _test_state_machine_reset_and_terminal_stability())
	_record_case("attack definition exposes exact phase boundaries", _test_attack_definition_phase_boundaries())
	_record_case("attack definition rejects invalid timeline data", _test_attack_definition_invalid_data())
	_record_case("attack cancel windows are inclusive and deterministic", _test_attack_cancel_windows())
	_record_case("attack timeline advances and completes exactly once", _test_attack_timeline_progression())
	_record_case("attack timeline start, pause, and reset boundaries", _test_attack_timeline_runtime_boundaries())
	_record_case("project attack Resource drives the debug visualization", _test_project_attack_visualization())
	_record_case("attack definition validates its hitbox profile", _test_attack_hitbox_profile())
	_record_case("hit resolver deduplicates and honors rehit boundaries", _test_hit_resolver_deduplication())
	_record_case("hit resolver filters faction, invulnerability, and height", _test_hit_resolver_filters())
	_record_case("hit resolver accepts multiple targets in stable order", _test_hit_resolver_multi_target_order())
	_record_case("hitbox mirrors geometry and uses named collision layers", _test_hitbox_mirroring_and_layers())
	var area_contact_errors: PackedStringArray = await _test_hitbox_hurtbox_area_contact()
	_record_case("Area2D contact forwards once across pause-like resume", area_contact_errors)
	var sandbox_hitbox_errors: PackedStringArray = await _test_project_hitbox_sandbox()
	_record_case("project sandbox wires debug hitboxes without damage", sandbox_hitbox_errors)
	_record_case("collision layers match architecture", _test_collision_layers())
	_record_case("valid Resource is indexed and returned", _test_valid_definition())
	_record_case("duplicate definition ID blocks indexing", _test_duplicate_definition())
	_record_case("invalid definition ID is rejected", _test_invalid_definition())
	_record_case("project placeholder Resource loads", _test_project_resource())
	_record_case("export remap paths resolve to source Resources", _test_export_remap_path())
	_record_case("release build guards the debug panel", _test_release_debug_guard())

	var failure_count := 0
	for result: Dictionary in _case_results:
		var errors: PackedStringArray = result["errors"]
		if errors.is_empty():
			print("PASS: %s" % result["name"])
		else:
			failure_count += 1
			print("FAIL: %s" % result["name"])
			for message: String in errors:
				print("  - %s" % message)
	_write_reports(failure_count)
	print(
		"PROJECT TEST SUMMARY: %d passed, %d failed"
		% [_case_results.size() - failure_count, failure_count]
	)
	quit(0 if failure_count == 0 else 1)


func _record_case(case_name: String, errors: PackedStringArray) -> void:
	_case_results.append({"name": case_name, "errors": errors})


func _test_version_pin() -> PackedStringArray:
	var errors := PackedStringArray()
	if VersionInfo.REQUIRED_GODOT_VERSION != "4.7.1":
		errors.append("VersionInfo does not pin 4.7.1")
	if not VersionInfo.is_expected_engine():
		errors.append(
			"running engine is %s, expected 4.7.1"
			% Engine.get_version_info().get("string", "unknown")
		)
	return errors


func _test_input_actions() -> PackedStringArray:
	var errors := PackedStringArray()
	var settings := SettingsServiceScript.new()
	settings.ensure_default_input_map()
	for action: StringName in SettingsServiceScript.REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			errors.append("missing Input action: %s" % String(action))
			continue
		var has_keyboard := false
		var has_gamepad := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_keyboard = true
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_gamepad = true
		if not has_keyboard:
			errors.append("%s has no keyboard binding" % String(action))
		if not has_gamepad:
			errors.append("%s has no gamepad binding" % String(action))
	settings.free()
	return errors


func _test_input_device_switching() -> PackedStringArray:
	var errors := PackedStringArray()
	var settings := SettingsServiceScript.new()

	var joy_button := InputEventJoypadButton.new()
	joy_button.button_index = JOY_BUTTON_A
	joy_button.pressed = true
	settings._input(joy_button)
	if settings.active_input_device != SettingsServiceScript.InputDevice.GAMEPAD:
		errors.append("pressed gamepad button did not select the gamepad")
	if settings.active_input_device_label() != "XInput gamepad":
		errors.append("gamepad label did not match the active device")

	var echo_key := InputEventKey.new()
	echo_key.physical_keycode = KEY_A
	echo_key.pressed = true
	echo_key.echo = true
	settings._input(echo_key)
	if settings.active_input_device != SettingsServiceScript.InputDevice.GAMEPAD:
		errors.append("echoed keyboard event incorrectly changed the active device")

	var key := InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	settings._input(key)
	if settings.active_input_device != SettingsServiceScript.InputDevice.KEYBOARD_MOUSE:
		errors.append("pressed keyboard key did not select keyboard/mouse")

	var weak_joy_motion := InputEventJoypadMotion.new()
	weak_joy_motion.axis = JOY_AXIS_LEFT_X
	weak_joy_motion.axis_value = 0.2
	settings._input(weak_joy_motion)
	if settings.active_input_device != SettingsServiceScript.InputDevice.KEYBOARD_MOUSE:
		errors.append("sub-deadzone stick motion incorrectly selected the gamepad")

	var strong_joy_motion := InputEventJoypadMotion.new()
	strong_joy_motion.axis = JOY_AXIS_LEFT_X
	strong_joy_motion.axis_value = 0.75
	settings._input(strong_joy_motion)
	if settings.active_input_device != SettingsServiceScript.InputDevice.GAMEPAD:
		errors.append("strong stick motion did not select the gamepad")

	var small_mouse_motion := InputEventMouseMotion.new()
	small_mouse_motion.relative = Vector2(1.0, 1.0)
	settings._input(small_mouse_motion)
	if settings.active_input_device != SettingsServiceScript.InputDevice.GAMEPAD:
		errors.append("tiny mouse motion incorrectly changed the active device")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(3.0, 0.0)
	settings._input(mouse_motion)
	if settings.active_input_device != SettingsServiceScript.InputDevice.KEYBOARD_MOUSE:
		errors.append("meaningful mouse motion did not select keyboard/mouse")
	if settings.active_input_device_label() != "Keyboard / mouse":
		errors.append("keyboard/mouse label did not match the active device")

	settings.free()
	return errors


func _test_ground_movement_speeds() -> PackedStringArray:
	var errors := PackedStringArray()
	var movement: GroundMovementModel = GroundMovementModelScript.new()
	errors.append_array(movement.configure(320.0, 0.9))
	var horizontal := movement.velocity_for_input(Vector2.RIGHT)
	var depth := movement.velocity_for_input(Vector2.DOWN)
	var stopped := movement.velocity_for_input(Vector2.ZERO)
	if not is_equal_approx(horizontal.x, 320.0) or not is_zero_approx(horizontal.y):
		errors.append("horizontal movement did not use 320 px/s")
	if not is_zero_approx(depth.x) or not is_equal_approx(depth.y, 288.0):
		errors.append("depth movement did not use the 0.9 speed ratio")
	if not stopped.is_zero_approx():
		errors.append("zero input produced movement")
	return errors


func _test_ground_movement_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var movement: GroundMovementModel = GroundMovementModelScript.new()
	var diagonal := movement.velocity_for_input(Vector2(1.0, 1.0))
	var expected_x := 320.0 / sqrt(2.0)
	var expected_y := 288.0 / sqrt(2.0)
	if not is_equal_approx(diagonal.x, expected_x):
		errors.append("diagonal horizontal component was not normalized")
	if not is_equal_approx(diagonal.y, expected_y):
		errors.append("diagonal depth component was not normalized")
	var saturated := movement.velocity_for_input(Vector2(4.0, 0.0))
	if not is_equal_approx(saturated.x, 320.0):
		errors.append("out-of-range input was not clamped to unit length")
	return errors


func _test_ground_movement_invalid_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	var movement: GroundMovementModel = GroundMovementModelScript.new()
	var invalid_speed := movement.configure(0.0, 0.9)
	if invalid_speed.is_empty():
		errors.append("zero horizontal speed was accepted")
	var invalid_low_ratio := movement.configure(320.0, 0.0)
	if invalid_low_ratio.is_empty():
		errors.append("zero depth speed ratio was accepted")
	var invalid_high_ratio := movement.configure(320.0, 1.1)
	if invalid_high_ratio.is_empty():
		errors.append("depth speed ratio above one was accepted")
	if not is_equal_approx(movement.horizontal_speed, 320.0):
		errors.append("invalid configuration changed horizontal speed")
	if not is_equal_approx(movement.depth_speed_ratio, 0.9):
		errors.append("invalid configuration changed depth speed ratio")
	return errors


func _test_ground_movement_facing() -> PackedStringArray:
	var errors := PackedStringArray()
	var movement: GroundMovementModel = GroundMovementModelScript.new()
	if movement.update_facing(0.0) != GroundMovementModel.FACING_RIGHT:
		errors.append("zero horizontal input changed the initial facing")
	if movement.update_facing(-1.0) != GroundMovementModel.FACING_LEFT:
		errors.append("left input did not face left")
	if movement.update_facing(0.0) != GroundMovementModel.FACING_LEFT:
		errors.append("vertical-only input did not preserve left facing")
	if movement.update_facing(0.005) != GroundMovementModel.FACING_LEFT:
		errors.append("sub-threshold stick jitter changed facing")
	if movement.update_facing(1.0) != GroundMovementModel.FACING_RIGHT:
		errors.append("right input did not face right")
	return errors


func _test_elevation_jump_gating() -> PackedStringArray:
	var errors := PackedStringArray()
	var elevation: ElevationModel = ElevationModelScript.new()
	errors.append_array(elevation.configure(720.0, 1800.0, 0.0, 56.0))
	if not elevation.grounded:
		errors.append("new elevation model did not start grounded")
	if not elevation.request_jump():
		errors.append("grounded jump request was rejected")
	if elevation.grounded:
		errors.append("jump request did not leave the grounded state")
	if not is_equal_approx(elevation.vertical_velocity, 720.0):
		errors.append("jump request did not apply configured vertical velocity")
	if elevation.request_jump():
		errors.append("second jump request was accepted while airborne")
	return errors


func _test_elevation_landing() -> PackedStringArray:
	var errors := PackedStringArray()
	var elevation: ElevationModel = ElevationModelScript.new()
	elevation.request_jump()
	var landing_count := 0
	var peak_elevation := 0.0
	for _tick: int in range(180):
		if elevation.advance(1.0 / 60.0):
			landing_count += 1
		peak_elevation = maxf(peak_elevation, elevation.elevation)
	if peak_elevation <= 0.0:
		errors.append("jump never produced positive elevation")
	if landing_count != 1:
		errors.append("jump emitted %d landings instead of one" % landing_count)
	if not elevation.grounded:
		errors.append("elevation did not return to grounded")
	if not is_zero_approx(elevation.elevation):
		errors.append("landing did not clamp elevation to zero")
	if not is_zero_approx(elevation.vertical_velocity):
		errors.append("landing did not clear vertical velocity")
	for _tick: int in range(60):
		if elevation.advance(1.0 / 60.0):
			errors.append("grounded stability step reported another landing")
			break
	if not is_zero_approx(elevation.elevation):
		errors.append("grounded stability steps drifted below or above zero")
	return errors


func _test_elevation_invalid_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	var elevation: ElevationModel = ElevationModelScript.new()
	if elevation.configure(0.0, 1800.0, 0.0, 56.0).is_empty():
		errors.append("zero jump speed was accepted")
	if elevation.configure(720.0, 0.0, 0.0, 56.0).is_empty():
		errors.append("zero gravity was accepted")
	if elevation.configure(720.0, 1800.0, -1.0, 56.0).is_empty():
		errors.append("negative minimum hit height was accepted")
	if elevation.configure(720.0, 1800.0, 40.0, 20.0).is_empty():
		errors.append("maximum hit height below minimum was accepted")
	if not is_equal_approx(elevation.jump_speed, 720.0):
		errors.append("invalid configuration changed jump speed")
	if not is_equal_approx(elevation.gravity, 1800.0):
		errors.append("invalid configuration changed gravity")

	elevation.request_jump()
	var before_elevation := elevation.elevation
	var before_velocity := elevation.vertical_velocity
	elevation.advance(0.0)
	elevation.advance(-1.0)
	if not is_equal_approx(elevation.elevation, before_elevation):
		errors.append("invalid delta changed elevation")
	if not is_equal_approx(elevation.vertical_velocity, before_velocity):
		errors.append("invalid delta changed vertical velocity")
	if elevation.overlaps_height_range(24.0, 12.0):
		errors.append("reversed height query was accepted")
	return errors


func _test_elevation_height_ranges() -> PackedStringArray:
	var errors := PackedStringArray()
	var elevation: ElevationModel = ElevationModelScript.new()
	if not elevation.overlaps_height_range(0.0, 24.0):
		errors.append("grounded actor did not overlap a low height range")
	elevation.request_jump()
	for _tick: int in range(12):
		elevation.advance(1.0 / 60.0)
	var elevated_range := elevation.hit_height_range()
	if elevated_range.x <= 24.0:
		errors.append("test jump did not clear the low probe height")
	if elevation.overlaps_height_range(0.0, 24.0):
		errors.append("airborne actor still overlapped the cleared low probe")
	if not elevation.overlaps_height_range(elevated_range.y, elevated_range.y + 8.0):
		errors.append("inclusive hit-height boundary did not overlap")
	if elevation.overlaps_height_range(elevated_range.y + 8.0, elevated_range.y + 16.0):
		errors.append("separated hit-height ranges incorrectly overlapped")
	return errors


func _test_elevation_component_separation() -> PackedStringArray:
	var errors := PackedStringArray()
	var player_scene := ResourceLoader.load("res://scenes/actors/player.tscn") as PackedScene
	if player_scene == null:
		errors.append("player scene could not be loaded for elevation integration")
		return errors
	var player := player_scene.instantiate() as CharacterBody2D
	if player == null:
		errors.append("player scene root is not CharacterBody2D")
		return errors
	root.add_child(player)
	player.set_physics_process(false)
	var component := player.get_node_or_null("Elevation") as ElevationComponent
	var visual_root := player.get_node_or_null("VisualRoot") as Node2D
	var shadow := player.get_node_or_null("Shadow") as Node2D
	if component == null or visual_root == null or shadow == null:
		errors.append("player scene is missing elevation integration nodes")
		player.free()
		return errors
	component.set_physics_process(false)
	var ground_before := player.global_position
	var visual_before := visual_root.position
	var shadow_before := shadow.position
	if not component.request_jump():
		errors.append("player elevation component rejected a grounded jump")
	component.advance_physics(1.0 / 60.0)
	if not player.global_position.is_equal_approx(ground_before):
		errors.append("visual elevation changed the CharacterBody2D ground position")
	if visual_root.position.y >= visual_before.y:
		errors.append("visual root did not move upward after jump")
	if not is_equal_approx(
		visual_root.position.y,
		visual_before.y - component.elevation()
	):
		errors.append("visual root offset does not match elevation")
	if not shadow.position.is_equal_approx(shadow_before):
		errors.append("ground shadow moved with the elevated visual root")
	player.free()
	return errors


func _test_dodge_duration_and_distance() -> PackedStringArray:
	var errors := PackedStringArray()
	var dodge: DodgeModel = DodgeModelScript.new()
	if not dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT):
		errors.append("valid dodge start was rejected")
		return errors
	var traveled_distance := 0.0
	var moving_ticks := 0
	for tick: int in range(1, DodgeModel.TOTAL_TICKS + 1):
		var displacement := dodge.advance_tick()
		traveled_distance += displacement.length()
		if not displacement.is_zero_approx():
			moving_ticks += 1
		if tick < DodgeModel.TOTAL_TICKS and not dodge.is_active():
			errors.append("dodge ended before tick 24")
			break
	if dodge.is_active():
		errors.append("dodge remained active after tick 24")
	if dodge.action_tick != DodgeModel.TOTAL_TICKS:
		errors.append("dodge action tick did not stop at 24")
	if moving_ticks != DodgeModel.TRAVEL_TICKS:
		errors.append("dodge traveled for %d ticks instead of %d" % [moving_ticks, DodgeModel.TRAVEL_TICKS])
	if not is_equal_approx(traveled_distance, DodgeModel.DODGE_DISTANCE):
		errors.append(
			"dodge traveled %.3f px instead of %.3f px"
			% [traveled_distance, DodgeModel.DODGE_DISTANCE]
		)
	return errors


func _test_dodge_invulnerability_ticks() -> PackedStringArray:
	var errors := PackedStringArray()
	var dodge: DodgeModel = DodgeModelScript.new()
	dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT)
	var invulnerable_ticks: Array[int] = []
	for tick: int in range(1, DodgeModel.TOTAL_TICKS + 1):
		dodge.advance_tick()
		if dodge.is_invulnerable():
			invulnerable_ticks.append(tick)
	var expected_ticks: Array[int] = []
	for tick: int in range(
		DodgeModel.INVULNERABLE_START_TICK,
		DodgeModel.INVULNERABLE_END_TICK + 1
	):
		expected_ticks.append(tick)
	if invulnerable_ticks != expected_ticks:
		errors.append(
			"invulnerability ticks were %s, expected %s"
			% [str(invulnerable_ticks), str(expected_ticks)]
		)
	return errors


func _test_dodge_direction_resolution() -> PackedStringArray:
	var errors := PackedStringArray()
	var diagonal: DodgeModel = DodgeModelScript.new()
	if not diagonal.try_start(Vector2(1.0, -1.0), GroundMovementModel.FACING_LEFT):
		errors.append("diagonal dodge was rejected")
	elif not diagonal.direction.is_equal_approx(Vector2(1.0, -1.0).normalized()):
		errors.append("diagonal dodge direction was not normalized")

	var saturated: DodgeModel = DodgeModelScript.new()
	if not saturated.try_start(Vector2(4.0, 0.0), GroundMovementModel.FACING_LEFT):
		errors.append("out-of-range dodge input was rejected instead of clamped")
	elif not saturated.direction.is_equal_approx(Vector2.RIGHT):
		errors.append("out-of-range dodge input was not clamped to a unit direction")

	var fallback: DodgeModel = DodgeModelScript.new()
	if not fallback.try_start(Vector2.ZERO, GroundMovementModel.FACING_LEFT):
		errors.append("zero-input dodge did not use current facing")
	elif not fallback.direction.is_equal_approx(Vector2.LEFT):
		errors.append("zero-input dodge did not fall back to left facing")

	var vertical: DodgeModel = DodgeModelScript.new()
	if not vertical.try_start(Vector2.UP, GroundMovementModel.FACING_RIGHT):
		errors.append("vertical dodge was rejected")
	elif not vertical.direction.is_equal_approx(Vector2.UP):
		errors.append("vertical dodge direction changed")

	var invalid: DodgeModel = DodgeModelScript.new()
	if invalid.try_start(Vector2.ZERO, 0):
		errors.append("zero-input dodge accepted an invalid facing sign")
	return errors


func _test_dodge_cooldown_boundary() -> PackedStringArray:
	var errors := PackedStringArray()
	var dodge: DodgeModel = DodgeModelScript.new()
	dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT)
	for _tick: int in range(DodgeModel.TOTAL_TICKS):
		dodge.advance_tick()
	if dodge.cooldown_ticks_remaining != DodgeModel.COOLDOWN_TICKS:
		errors.append("dodge cooldown did not begin at 45 ticks")
	if dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT):
		errors.append("dodge restarted at the beginning of cooldown")
	for _tick: int in range(DodgeModel.COOLDOWN_TICKS - 1):
		dodge.advance_tick()
	if dodge.cooldown_ticks_remaining != 1:
		errors.append("cooldown boundary did not reach one remaining tick")
	if dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT):
		errors.append("dodge restarted with one cooldown tick remaining")
	dodge.advance_tick()
	if dodge.cooldown_ticks_remaining != 0:
		errors.append("cooldown did not end after exactly 45 ticks")
	if not dodge.try_start(Vector2.RIGHT, GroundMovementModel.FACING_RIGHT):
		errors.append("dodge could not restart after cooldown ended")
	return errors


func _test_dodge_wall_collision() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not be loaded for wall test")
		return errors
	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	await physics_frame
	var player := sandbox.get_node("Actors/PlayerRoot") as PlayerGroundMovementController
	if player == null:
		errors.append("movement sandbox is missing the player controller")
		sandbox.free()
		return errors
	player.global_position = Vector2(1160.0, 430.0)
	await physics_frame
	var start_x := player.global_position.x
	if not player.try_start_dodge(Vector2.RIGHT):
		errors.append("wall integration dodge could not start")
		sandbox.free()
		return errors
	var maximum_x := player.global_position.x
	var saw_invulnerability := false
	for _tick: int in range(DodgeModel.TOTAL_TICKS + 6):
		await physics_frame
		maximum_x = maxf(maximum_x, player.global_position.x)
		saw_invulnerability = saw_invulnerability or player.is_dodge_invulnerable()
	if maximum_x <= start_x:
		errors.append("wall integration dodge produced no movement")
	if maximum_x > 1188.5:
		errors.append("dodge crossed the WorldStatic wall boundary")
	if player.is_dodging():
		errors.append("wall collision left dodge active beyond 24 ticks")
	if not saw_invulnerability:
		errors.append("wall integration dodge never entered invulnerability")
	sandbox.free()
	return errors


func _state_machine_fixture_table() -> Dictionary:
	return {
		&"Idle": PackedStringArray(["Move", "Dodge"]),
		&"Move": PackedStringArray(["Idle", "Dodge", "Defeated"]),
		&"Dodge": PackedStringArray(["Idle"]),
		&"Defeated": PackedStringArray(),
	}


func _test_state_machine_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	var machine: StateMachineModel = StateMachineModelScript.new()
	errors.append_array(machine.configure(&"Idle", _state_machine_fixture_table()))
	if not machine.is_configured():
		errors.append("valid transition table did not configure the state machine")
	if machine.current_state != &"Idle" or machine.previous_state != &"":
		errors.append("configured state machine did not start in Idle")
	if machine.transition_count != 0:
		errors.append("configuration incorrectly counted an initial transition")
	var known_states := machine.known_states()
	var expected_states := PackedStringArray(["Defeated", "Dodge", "Idle", "Move"])
	if known_states != expected_states:
		errors.append(
			"known states were not returned in deterministic order: %s"
			% str(known_states)
		)
	if not machine.can_transition_to(&"Move") or not machine.can_transition_to(&"Dodge"):
		errors.append("Idle did not expose both configured branch targets")
	var exposed_targets := machine.allowed_targets_from(&"Idle")
	exposed_targets.clear()
	if machine.allowed_targets_from(&"Idle").size() != 2:
		errors.append("caller mutation changed the internal transition table")
	return errors


func _test_state_machine_legal_transitions() -> PackedStringArray:
	var errors := PackedStringArray()
	var machine: StateMachineModel = StateMachineModelScript.new()
	machine.configure(&"Idle", _state_machine_fixture_table())
	var events: Array[Dictionary] = []
	machine.state_changed.connect(
		func(
			previous_state: StringName,
			current_state: StringName,
			transition_index: int
		) -> void:
			events.append(
				{
					"previous": previous_state,
					"current": current_state,
					"index": transition_index,
				}
			)
	)
	if not machine.request_transition(&"Move"):
		errors.append("legal Idle -> Move transition was rejected")
	if not machine.request_transition(&"Dodge"):
		errors.append("legal Move -> Dodge transition was rejected")
	if machine.previous_state != &"Move" or machine.current_state != &"Dodge":
		errors.append("legal transitions did not update previous/current state")
	if machine.transition_count != 2 or events.size() != 2:
		errors.append("legal transitions did not increment and signal exactly twice")
	elif (
		events[0]["previous"] != &"Idle"
		or events[0]["current"] != &"Move"
		or events[0]["index"] != 1
		or events[1]["previous"] != &"Move"
		or events[1]["current"] != &"Dodge"
		or events[1]["index"] != 2
	):
		errors.append("state_changed signal payload did not match transitions")
	if machine.last_rejection_code != &"" or not machine.last_rejection_message.is_empty():
		errors.append("successful transition retained a stale rejection reason")
	return errors


func _test_state_machine_rejections() -> PackedStringArray:
	var errors := PackedStringArray()
	var unconfigured: StateMachineModel = StateMachineModelScript.new()
	if unconfigured.request_transition(&"Idle"):
		errors.append("unconfigured state machine accepted a transition")
	if unconfigured.last_rejection_code != StateMachineModel.REJECTION_NOT_CONFIGURED:
		errors.append("unconfigured rejection did not use its stable reason code")

	var machine: StateMachineModel = StateMachineModelScript.new()
	machine.configure(&"Idle", _state_machine_fixture_table())
	var rejection_events: Array[Dictionary] = []
	machine.transition_rejected.connect(
		func(
			current_state: StringName,
			target_state: StringName,
			reason_code: StringName,
			message: String
		) -> void:
			rejection_events.append(
				{
					"current": current_state,
					"target": target_state,
					"reason": reason_code,
					"message": message,
				}
			)
	)
	if machine.request_transition(&""):
		errors.append("empty target transition was accepted")
	if machine.last_rejection_code != StateMachineModel.REJECTION_EMPTY_TARGET:
		errors.append("empty target did not use its stable rejection code")
	if machine.request_transition(&"Airborne"):
		errors.append("unknown target transition was accepted")
	if machine.last_rejection_code != StateMachineModel.REJECTION_UNKNOWN_TARGET:
		errors.append("unknown target did not use its stable rejection code")
	if machine.request_transition(&"Defeated"):
		errors.append("table-forbidden Idle -> Defeated transition was accepted")
	if machine.last_rejection_code != StateMachineModel.REJECTION_NOT_ALLOWED:
		errors.append("forbidden transition did not use its stable rejection code")
	if machine.current_state != &"Idle" or machine.transition_count != 0:
		errors.append("rejected transitions mutated state or transition count")
	if rejection_events.size() != 3:
		errors.append("rejected transitions did not emit exactly three events")
	else:
		for event: Dictionary in rejection_events:
			if event["current"] != &"Idle" or String(event["message"]).is_empty():
				errors.append("transition_rejected signal omitted context")
				break
	return errors


func _test_state_machine_invalid_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	var machine: StateMachineModel = StateMachineModelScript.new()
	if machine.configure(&"Idle", {}).is_empty():
		errors.append("empty transition table was accepted")
	if machine.configure(&"Ghost", _state_machine_fixture_table()).is_empty():
		errors.append("undeclared initial state was accepted")
	if machine.configure(
		&"Idle",
		{&"Idle": PackedStringArray(["Ghost"])}
	).is_empty():
		errors.append("undeclared transition target was accepted")
	if machine.configure(
		&"Idle",
		{&"Idle": PackedStringArray(["Idle", "Idle"])}
	).is_empty():
		errors.append("duplicate transition target was accepted")
	if machine.configure(&"Idle", {&"Idle": 42}).is_empty():
		errors.append("non-array transition target collection was accepted")
	if machine.configure(&"Idle", {&" Idle": PackedStringArray()}).is_empty():
		errors.append("whitespace-padded state ID was accepted")

	errors.append_array(machine.configure(&"Idle", _state_machine_fixture_table()))
	machine.request_transition(&"Move")
	var before_states := machine.known_states()
	var invalid_reconfigure := machine.configure(
		&"Idle",
		{&"Idle": PackedStringArray(["Missing"])}
	)
	if invalid_reconfigure.is_empty():
		errors.append("invalid reconfiguration unexpectedly succeeded")
	if machine.current_state != &"Move" or machine.transition_count != 1:
		errors.append("invalid reconfiguration changed runtime state")
	if machine.known_states() != before_states:
		errors.append("invalid reconfiguration replaced the valid transition table")
	return errors


func _test_state_machine_reset_and_terminal_stability() -> PackedStringArray:
	var errors := PackedStringArray()
	var machine: StateMachineModel = StateMachineModelScript.new()
	machine.configure(&"Idle", _state_machine_fixture_table())
	machine.request_transition(&"Move")
	machine.request_transition(&"Defeated")
	if machine.current_state != &"Defeated":
		errors.append("legal transition did not enter terminal Defeated state")
	if not machine.allowed_targets_from(&"Defeated").is_empty():
		errors.append("terminal state unexpectedly exposed outgoing targets")
	for _tick: int in range(120):
		var simulated_delta := 1.0 / 30.0 if _tick % 2 == 0 else 1.0 / 144.0
		if simulated_delta <= 0.0:
			errors.append("invalid simulated delta in state stability test")
	if machine.current_state != &"Defeated" or machine.transition_count != 2:
		errors.append("terminal state changed without an explicit transition request")
	if machine.request_transition(&"Idle"):
		errors.append("terminal state accepted a forbidden outgoing transition")
	if not machine.reset():
		errors.append("configured state machine reset was rejected")
	if (
		machine.current_state != &"Idle"
		or machine.previous_state != &""
		or machine.transition_count != 0
	):
		errors.append("reset did not restore the initial runtime state")
	var weak_machine: WeakRef = weakref(machine)
	machine = null
	if weak_machine.get_ref() != null:
		errors.append("state machine retained itself after its owner released it")
	return errors


func _make_test_attack() -> AttackDefinition:
	var attack: AttackDefinition = AttackDefinitionScript.new()
	attack.definition_id = &"attack.test.a1"
	attack.display_name_key = &"attack.test.a1.name"
	attack.startup_ticks = 6
	attack.active_ticks = 3
	attack.recovery_ticks = 11
	attack.hit_stop_ticks = 3
	attack.hitbox_size = Vector2(88.0, 44.0)
	attack.hitbox_offset = Vector2(48.0, -22.0)
	attack.min_hit_height = 0.0
	attack.max_hit_height = 56.0
	attack.rehit_interval_ticks = 0
	var dodge_window: AttackCancelWindow = AttackCancelWindowScript.new()
	dodge_window.start_tick = 15
	dodge_window.end_tick = 20
	dodge_window.target_tags = [&"action.dodge"]
	attack.cancel_windows.append(dodge_window)
	return attack


func _test_attack_definition_phase_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	errors.append_array(attack.validation_errors())
	if attack.total_ticks() != 20:
		errors.append("6/3/11 attack did not total 20 ticks")
	if attack.phase_at_tick(0) != AttackDefinition.TimelinePhase.BEFORE_START:
		errors.append("tick 0 was not before_start")
	if (
		attack.phase_at_tick(1) != AttackDefinition.TimelinePhase.STARTUP
		or attack.phase_at_tick(6) != AttackDefinition.TimelinePhase.STARTUP
	):
		errors.append("startup phase did not include ticks 1 through 6")
	if (
		attack.phase_at_tick(7) != AttackDefinition.TimelinePhase.ACTIVE
		or attack.phase_at_tick(9) != AttackDefinition.TimelinePhase.ACTIVE
	):
		errors.append("active phase did not include ticks 7 through 9")
	if (
		attack.phase_at_tick(10) != AttackDefinition.TimelinePhase.RECOVERY
		or attack.phase_at_tick(20) != AttackDefinition.TimelinePhase.RECOVERY
	):
		errors.append("recovery phase did not include ticks 10 through 20")
	if attack.phase_at_tick(21) != AttackDefinition.TimelinePhase.COMPLETE:
		errors.append("tick after total duration was not complete")
	if attack.phase_tick_range(AttackDefinition.TimelinePhase.STARTUP) != Vector2i(1, 6):
		errors.append("startup tick range was incorrect")
	if attack.phase_tick_range(AttackDefinition.TimelinePhase.ACTIVE) != Vector2i(7, 9):
		errors.append("active tick range was incorrect")
	if attack.phase_tick_range(AttackDefinition.TimelinePhase.RECOVERY) != Vector2i(10, 20):
		errors.append("recovery tick range was incorrect")
	var active_tick_count := 0
	for tick: int in range(1, attack.total_ticks() + 1):
		if attack.is_active_tick(tick):
			active_tick_count += 1
	if active_tick_count != 3:
		errors.append("hitbox-active query did not return exactly three ticks")

	var instant := _make_test_attack()
	instant.startup_ticks = 0
	instant.active_ticks = 2
	instant.recovery_ticks = 0
	instant.cancel_windows.clear()
	if not instant.validation_errors().is_empty():
		errors.append("zero-startup and zero-recovery boundary was rejected")
	if (
		instant.phase_at_tick(1) != AttackDefinition.TimelinePhase.ACTIVE
		or instant.phase_at_tick(2) != AttackDefinition.TimelinePhase.ACTIVE
		or instant.phase_at_tick(3) != AttackDefinition.TimelinePhase.COMPLETE
	):
		errors.append("zero-length phase boundaries were incorrect")
	return errors


func _test_attack_definition_invalid_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	attack.startup_ticks = -1
	if attack.validation_errors().is_empty():
		errors.append("negative startup duration was accepted")
	attack.startup_ticks = 6
	attack.active_ticks = 0
	if attack.validation_errors().is_empty():
		errors.append("zero active duration was accepted")
	attack.active_ticks = 3
	attack.recovery_ticks = -1
	if attack.validation_errors().is_empty():
		errors.append("negative recovery duration was accepted")
	attack.recovery_ticks = 11
	attack.hit_stop_ticks = -1
	if attack.validation_errors().is_empty():
		errors.append("negative hit stop was accepted")
	attack.hit_stop_ticks = 3

	var window: AttackCancelWindow = attack.cancel_windows[0]
	window.start_tick = 0
	if attack.validation_errors().is_empty():
		errors.append("cancel window starting before tick 1 was accepted")
	window.start_tick = 15
	window.end_tick = 14
	if attack.validation_errors().is_empty():
		errors.append("reversed cancel window was accepted")
	window.end_tick = 21
	if attack.validation_errors().is_empty():
		errors.append("cancel window beyond total duration was accepted")
	window.end_tick = 20
	window.target_tags = []
	if attack.validation_errors().is_empty():
		errors.append("cancel window without target tags was accepted")
	window.target_tags = [&"Dodge"]
	if attack.validation_errors().is_empty():
		errors.append("cancel target without dotted lowercase form was accepted")
	window.target_tags = [&"action.dodge", &"action.dodge"]
	if attack.validation_errors().is_empty():
		errors.append("duplicate cancel target tag was accepted")
	return errors


func _test_attack_cancel_windows() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	var skill_window: AttackCancelWindow = AttackCancelWindowScript.new()
	skill_window.start_tick = 18
	skill_window.end_tick = 19
	skill_window.target_tags = [&"skill.any", &"action.dodge"]
	attack.cancel_windows.append(skill_window)
	errors.append_array(attack.validation_errors())
	if not attack.cancel_targets_at_tick(14).is_empty():
		errors.append("cancel targets appeared before the first window")
	if attack.cancel_targets_at_tick(15) != PackedStringArray(["action.dodge"]):
		errors.append("cancel window did not include its start tick")
	if (
		attack.cancel_targets_at_tick(18)
		!= PackedStringArray(["action.dodge", "skill.any"])
	):
		errors.append("overlapping cancel targets were not deduplicated and sorted")
	if attack.cancel_targets_at_tick(20) != PackedStringArray(["action.dodge"]):
		errors.append("cancel window did not include its end tick")
	if not attack.cancel_targets_at_tick(21).is_empty():
		errors.append("cancel targets remained after all windows")
	return errors


func _test_attack_timeline_progression() -> PackedStringArray:
	var errors := PackedStringArray()
	var source_attack := _make_test_attack()
	var timeline: AttackTimelineModel = AttackTimelineModelScript.new()
	var phase_events: Array[Dictionary] = []
	var completion_events: Array[Dictionary] = []
	timeline.phase_changed.connect(
		func(
			_previous_phase: AttackDefinition.TimelinePhase,
			current_phase: AttackDefinition.TimelinePhase,
			action_tick: int
		) -> void:
			phase_events.append({"phase": current_phase, "tick": action_tick})
	)
	timeline.timeline_completed.connect(
		func(attack_id: StringName, total_ticks: int) -> void:
			completion_events.append({"attack_id": attack_id, "ticks": total_ticks})
	)
	errors.append_array(timeline.start(source_attack))
	source_attack.startup_ticks = 60
	var active_ticks := 0
	var cancel_ticks := 0
	for _tick: int in range(20):
		if not timeline.advance_tick():
			errors.append("timeline stopped before 20 ticks")
			break
		if timeline.is_hitbox_active():
			active_ticks += 1
		if timeline.available_cancel_targets().has("action.dodge"):
			cancel_ticks += 1
	if timeline.is_running:
		errors.append("timeline remained running after its total duration")
	if timeline.action_tick != 20 or timeline.total_ticks() != 20:
		errors.append("runtime snapshot changed after source Resource mutation")
	if active_ticks != 3:
		errors.append("runtime reported %d active ticks instead of 3" % active_ticks)
	if cancel_ticks != 6:
		errors.append("runtime reported %d cancel ticks instead of 6" % cancel_ticks)
	if timeline.advance_tick():
		errors.append("completed timeline advanced past its total duration")
	if phase_events.size() != 3:
		errors.append("timeline did not emit exactly three phase changes")
	elif (
		phase_events[0]["tick"] != 1
		or phase_events[0]["phase"] != AttackDefinition.TimelinePhase.STARTUP
		or phase_events[1]["tick"] != 7
		or phase_events[1]["phase"] != AttackDefinition.TimelinePhase.ACTIVE
		or phase_events[2]["tick"] != 10
		or phase_events[2]["phase"] != AttackDefinition.TimelinePhase.RECOVERY
	):
		errors.append("phase change signal boundaries were incorrect")
	if (
		completion_events.size() != 1
		or completion_events[0]["attack_id"] != &"attack.test.a1"
		or completion_events[0]["ticks"] != 20
	):
		errors.append("timeline completion signal was missing or incorrect")
	return errors


func _test_attack_timeline_runtime_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var timeline: AttackTimelineModel = AttackTimelineModelScript.new()
	if timeline.start(null).is_empty():
		errors.append("timeline accepted a null AttackDefinition")
	var invalid_attack := _make_test_attack()
	invalid_attack.active_ticks = 0
	if timeline.start(invalid_attack).is_empty():
		errors.append("timeline accepted invalid attack data")
	var attack := _make_test_attack()
	errors.append_array(timeline.start(attack))
	if timeline.start(attack).is_empty():
		errors.append("running timeline accepted a restart")
	for _paused_frame: int in range(120):
		var ignored_delta := 1.0 / 30.0 if _paused_frame % 2 == 0 else 1.0 / 144.0
		if ignored_delta <= 0.0:
			errors.append("invalid simulated pause delta")
	if timeline.action_tick != 0 or not timeline.is_running:
		errors.append("timeline advanced without an explicit tick during simulated pause")
	timeline.advance_tick()
	timeline.reset()
	if (
		timeline.action_tick != 0
		or timeline.total_ticks() != 0
		or timeline.is_running
		or timeline.attack_id != &""
	):
		errors.append("timeline reset did not clear its runtime snapshot")
	if not timeline.start(attack).is_empty():
		errors.append("timeline could not restart after reset")
	return errors


func _test_project_attack_visualization() -> PackedStringArray:
	var errors := PackedStringArray()
	var loaded := ResourceLoader.load("res://data/attacks/dev_a1.tres")
	var attack := loaded as AttackDefinition
	if attack == null:
		errors.append("project attack Resource did not load as AttackDefinition")
		return errors
	errors.append_array(attack.validation_errors())
	if (
		attack.startup_ticks != 6
		or attack.active_ticks != 3
		or attack.recovery_ticks != 11
		or attack.hit_stop_ticks != 3
	):
		errors.append("project attack Resource did not keep the 6/3/11/3 baseline")
	var registry: DataRegistryService = DataRegistryScript.new()
	var registry_errors := registry.reload_definitions("res://data")
	errors.append_array(registry_errors)
	if registry.definition_count() != 2:
		errors.append("DataRegistry did not index character and attack Resources")
	if registry.get_definition(&"attack.dev.a1_placeholder") != attack:
		errors.append("DataRegistry did not return the project attack Resource")
	registry.free()

	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for timeline visualization")
		return errors
	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	var panel := sandbox.get_node_or_null("Hud/AttackTimelinePanel") as PanelContainer
	var startup := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/TimelineBar/StartupSegment"
	) as PanelContainer
	var active := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/TimelineBar/ActiveSegment"
	) as PanelContainer
	var recovery := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/TimelineBar/RecoverySegment"
	) as PanelContainer
	var cancel_label := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/CancelWindowsLabel"
	) as Label
	if panel == null or startup == null or active == null or recovery == null:
		errors.append("timeline visualization is missing required segment nodes")
	elif (
		not is_equal_approx(startup.custom_minimum_size.x, 108.0)
		or not is_equal_approx(active.custom_minimum_size.x, 54.0)
		or not is_equal_approx(recovery.custom_minimum_size.x, 198.0)
	):
		errors.append("timeline segment widths do not match the 6/3/11 ratio")
	if panel != null and panel.visible != OS.is_debug_build():
		errors.append("timeline visualization visibility is not guarded by Debug build")
	if cancel_label == null or not cancel_label.text.contains("tick 15-20"):
		errors.append("timeline visualization does not show the cancel window")
	sandbox.free()
	return errors


func _make_hit_contact(
	target_instance_id: int,
	new_action_tick: int = 7,
	new_hit_id: StringName = &"hit.test.1",
	new_source_faction: StringName = &"player",
	new_target_faction: StringName = &"enemy",
	new_target_invulnerable: bool = false,
	source_height_range: Vector2 = Vector2(0.0, 56.0),
	target_height_range: Vector2 = Vector2(0.0, 56.0),
	new_rehit_interval_ticks: int = 0,
	new_source_instance_id: int = 1001
) -> HitContact:
	return HitContactScript.new(
		new_source_instance_id,
		target_instance_id,
		new_source_faction,
		new_target_faction,
		&"attack.test.a1",
		new_hit_id,
		new_action_tick,
		new_rehit_interval_ticks,
		source_height_range.x,
		source_height_range.y,
		target_height_range.x,
		target_height_range.y,
		new_target_invulnerable
	)


func _test_attack_hitbox_profile() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	errors.append_array(attack.validation_errors())
	if attack.hitbox_size != Vector2(88.0, 44.0):
		errors.append("test attack hitbox size does not match the A1 baseline")
	if attack.hitbox_offset != Vector2(48.0, -22.0):
		errors.append("test attack hitbox offset does not match the A1 baseline")
	if attack.min_hit_height != 0.0 or attack.max_hit_height != 56.0:
		errors.append("test attack hit-height range does not match the A1 baseline")
	if attack.rehit_interval_ticks != 0:
		errors.append("A1 must use once-per-hit-id contact semantics")

	attack.hitbox_size = Vector2(0.0, 44.0)
	if attack.validation_errors().is_empty():
		errors.append("zero-width hitbox profile was accepted")
	attack.hitbox_size = Vector2(88.0, 44.0)
	attack.min_hit_height = -1.0
	if attack.validation_errors().is_empty():
		errors.append("negative attack hit height was accepted")
	attack.min_hit_height = 24.0
	attack.max_hit_height = 23.0
	if attack.validation_errors().is_empty():
		errors.append("reversed attack hit-height range was accepted")
	attack.min_hit_height = 0.0
	attack.max_hit_height = 56.0
	attack.rehit_interval_ticks = -1
	if attack.validation_errors().is_empty():
		errors.append("negative rehit interval was accepted")
	return errors


func _test_hit_resolver_deduplication() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: HitResolverModel = HitResolverModelScript.new()
	var first_contact := _make_hit_contact(2001)
	if not resolver.try_accept(first_contact):
		errors.append("first valid contact was rejected")
	var duplicate_contact := _make_hit_contact(2001, 8)
	if resolver.try_accept(duplicate_contact):
		errors.append("same hit_id was accepted twice for one target")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_DUPLICATE_HIT:
		errors.append("duplicate contact did not return the stable rejection code")
	var next_attack_contact := _make_hit_contact(2001, 8, &"hit.test.2")
	if not resolver.try_accept(next_attack_contact):
		errors.append("new hit_id did not allow the same target to be hit again")

	var rehit_resolver: HitResolverModel = HitResolverModelScript.new()
	if not rehit_resolver.try_accept(
		_make_hit_contact(2002, 7, &"hit.test.rehit", &"player", &"enemy", false, Vector2(0.0, 56.0), Vector2(0.0, 56.0), 3)
	):
		errors.append("first periodic contact was rejected")
	if rehit_resolver.try_accept(
		_make_hit_contact(2002, 9, &"hit.test.rehit", &"player", &"enemy", false, Vector2(0.0, 56.0), Vector2(0.0, 56.0), 3)
	):
		errors.append("periodic contact was accepted before its 3-tick interval")
	if not rehit_resolver.try_accept(
		_make_hit_contact(2002, 10, &"hit.test.rehit", &"player", &"enemy", false, Vector2(0.0, 56.0), Vector2(0.0, 56.0), 3)
	):
		errors.append("periodic contact was not accepted at the exact interval boundary")

	var paused_resolver: HitResolverModel = HitResolverModelScript.new()
	paused_resolver.try_accept(_make_hit_contact(2003, 7, &"hit.test.pause"))
	for paused_frame: int in range(120):
		var simulated_delta := 1.0 / 30.0 if paused_frame % 2 == 0 else 1.0 / 144.0
		if simulated_delta <= 0.0:
			errors.append("pause simulation produced an invalid delta")
	if paused_resolver.try_accept(_make_hit_contact(2003, 7, &"hit.test.pause")):
		errors.append("pause-like frames without action-tick progress caused a rehit")
	return errors


func _test_hit_resolver_filters() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: HitResolverModel = HitResolverModelScript.new()
	if resolver.try_accept(
		_make_hit_contact(2101, 7, &"hit.invalid", &"player", &"enemy", false, Vector2(0.0, 56.0), Vector2(0.0, 56.0), 0, 0)
	):
		errors.append("invalid runtime instance ID was accepted")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_INVALID_CONTACT:
		errors.append("invalid contact did not use its stable rejection code")
	if resolver.try_accept(
		_make_hit_contact(2102, 7, &"hit.friendly", &"player", &"player")
	):
		errors.append("same-faction contact was accepted")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_FRIENDLY_FACTION:
		errors.append("same-faction contact returned the wrong rejection code")
	if resolver.try_accept(
		_make_hit_contact(2103, 7, &"hit.invulnerable", &"player", &"enemy", true)
	):
		errors.append("invulnerable target contact was accepted")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_INVULNERABLE:
		errors.append("invulnerable target returned the wrong rejection code")
	if resolver.try_accept(
		_make_hit_contact(2104, 7, &"hit.height_miss", &"player", &"enemy", false, Vector2(0.0, 23.0), Vector2(24.0, 56.0))
	):
		errors.append("separated elevation ranges were accepted")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_HEIGHT_MISS:
		errors.append("height miss returned the wrong rejection code")
	if not resolver.try_accept(
		_make_hit_contact(2105, 7, &"hit.height_edge", &"player", &"enemy", false, Vector2(0.0, 24.0), Vector2(24.0, 56.0))
	):
		errors.append("inclusive elevation boundary contact was rejected")
	return errors


func _test_hit_resolver_multi_target_order() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: HitResolverModel = HitResolverModelScript.new()
	var signaled_target_ids: Array[int] = []
	resolver.hit_accepted.connect(
		func(contact: HitContact) -> void:
			signaled_target_ids.append(contact.target_instance_id)
	)
	var contacts: Array[HitContact] = [
		_make_hit_contact(2203, 7, &"hit.test.multi"),
		_make_hit_contact(2201, 7, &"hit.test.multi"),
		_make_hit_contact(2202, 7, &"hit.test.multi"),
	]
	var accepted_contacts := resolver.accept_batch(contacts)
	if accepted_contacts.size() != 3:
		errors.append("one hitbox did not accept all three distinct targets")
	elif (
		accepted_contacts[0].target_instance_id != 2201
		or accepted_contacts[1].target_instance_id != 2202
		or accepted_contacts[2].target_instance_id != 2203
	):
		errors.append("multi-target results were not ordered by runtime target ID")
	if signaled_target_ids != [2201, 2202, 2203]:
		errors.append("multi-target accepted signals were not deterministic")
	if not resolver.accept_batch(contacts).is_empty():
		errors.append("replaying a multi-target batch bypassed hit_id deduplication")
	if resolver.tracked_contact_count() != 3:
		errors.append("resolver did not track one dedupe key per target")
	return errors


func _test_hitbox_mirroring_and_layers() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	var hitbox: HitboxComponent = HitboxComponentScript.new()
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	hitbox.add_child(collision_shape)
	errors.append_array(
		hitbox.activate(attack, &"hit.test.mirror", 2301, &"player", 1, 12.0)
	)
	if hitbox.activate(attack, &"hit.test.restart", 2301, &"player", 1).is_empty():
		errors.append("active hitbox accepted a new hit_id before state exit")
	if hitbox.position != Vector2(48.0, -22.0):
		errors.append("right-facing hitbox did not use the configured offset")
	if hitbox.collision_layer != 8 or hitbox.collision_mask != 64:
		errors.append("player hitbox does not use PlayerHitbox -> EnemyHurtbox layers")
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null or rectangle.size != Vector2(88.0, 44.0):
		errors.append("hitbox CollisionShape2D did not use Resource geometry")
	if not hitbox.set_facing_sign(-1):
		errors.append("valid left-facing sign was rejected")
	if hitbox.position != Vector2(-48.0, -22.0):
		errors.append("left-facing hitbox was not an exact horizontal mirror")
	if hitbox.set_facing_sign(0):
		errors.append("invalid zero facing sign was accepted")
	hitbox.set_action_tick(6)
	if hitbox.set_contact_enabled(true) or hitbox.contact_enabled:
		errors.append("hitbox activated during startup")
	hitbox.set_action_tick(7)
	if not hitbox.set_contact_enabled(true) or not hitbox.contact_enabled:
		errors.append("hitbox did not activate on the first active tick")
	var contact := hitbox.build_contact(2302, &"enemy", false, 24.0, 80.0)
	if contact == null:
		errors.append("active hitbox did not create a contact snapshot")
	elif (
		not is_equal_approx(contact.source_min_hit_height, 12.0)
		or not is_equal_approx(contact.source_max_hit_height, 68.0)
	):
		errors.append("source elevation was not included in the hit-height snapshot")
	hitbox.deactivate()

	var enemy_hitbox: HitboxComponent = HitboxComponentScript.new()
	var enemy_shape := CollisionShape2D.new()
	enemy_shape.name = "CollisionShape2D"
	enemy_hitbox.add_child(enemy_shape)
	errors.append_array(
		enemy_hitbox.activate(attack, &"hit.test.enemy", 2303, &"enemy", 1)
	)
	if enemy_hitbox.collision_layer != 16 or enemy_hitbox.collision_mask != 32:
		errors.append("enemy hitbox does not use EnemyHitbox -> PlayerHurtbox layers")
	hitbox.free()
	enemy_hitbox.free()
	return errors


func _test_hitbox_hurtbox_area_contact() -> PackedStringArray:
	var errors := PackedStringArray()
	var world := Node2D.new()
	root.add_child(world)
	var resolver: HitResolverModel = HitResolverModelScript.new()
	var hitbox: HitboxComponent = HitboxComponentScript.new()
	hitbox.name = "Hitbox"
	var hitbox_shape := CollisionShape2D.new()
	hitbox_shape.name = "CollisionShape2D"
	hitbox.add_child(hitbox_shape)
	world.add_child(hitbox)

	var hurtbox: HurtboxComponent = HurtboxComponentScript.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(48.0, 0.0)
	var hurtbox_shape := CollisionShape2D.new()
	hurtbox_shape.name = "CollisionShape2D"
	hurtbox_shape.position = Vector2(0.0, -22.0)
	var hurtbox_rectangle := RectangleShape2D.new()
	hurtbox_rectangle.size = Vector2(22.0, 48.0)
	hurtbox_shape.shape = hurtbox_rectangle
	hurtbox.add_child(hurtbox_shape)
	errors.append_array(hurtbox.configure(2402, &"enemy", 0.0, 56.0))
	hurtbox.bind_resolver(resolver)
	world.add_child(hurtbox)

	var forwarded_contacts: Array[HitContact] = []
	hurtbox.contact_forwarded.connect(
		func(contact: HitContact) -> void:
			forwarded_contacts.append(contact)
	)
	var attack := _make_test_attack()
	errors.append_array(
		hitbox.activate(attack, &"hit.test.area", 2401, &"player", 1)
	)
	hitbox.set_action_tick(7)
	hitbox.set_contact_enabled(true)
	await physics_frame
	await physics_frame
	if resolver.accepted_count != 1 or forwarded_contacts.size() != 1:
		errors.append(
			"Area2D overlap produced %d accepted / %d forwarded contacts"
			% [resolver.accepted_count, forwarded_contacts.size()]
		)

	hitbox.set_contact_enabled(false)
	await physics_frame
	await physics_frame
	hitbox.set_contact_enabled(true)
	await physics_frame
	await physics_frame
	if resolver.accepted_count != 1:
		errors.append("reenabling the same paused hit_id accepted duplicate contact")
	if resolver.last_rejection_code != HitResolverModel.REJECTION_DUPLICATE_HIT:
		errors.append("reenabled overlap did not pass through resolver deduplication")

	hitbox.set_contact_enabled(false)
	await physics_frame
	await physics_frame
	hitbox.deactivate()
	hurtbox.position = Vector2(48.0, 45.0)
	errors.append_array(
		hitbox.activate(attack, &"hit.test.depth_inside", 2401, &"player", 1)
	)
	hitbox.set_action_tick(7)
	hitbox.set_contact_enabled(true)
	await physics_frame
	await physics_frame
	if resolver.accepted_count != 2:
		errors.append("one-pixel depth-edge overlap did not produce a contact")

	hitbox.set_contact_enabled(false)
	await physics_frame
	await physics_frame
	hitbox.deactivate()
	hurtbox.position = Vector2(48.0, 47.0)
	errors.append_array(
		hitbox.activate(attack, &"hit.test.depth_outside", 2401, &"player", 1)
	)
	hitbox.set_action_tick(7)
	hitbox.set_contact_enabled(true)
	await physics_frame
	await physics_frame
	if resolver.accepted_count != 2:
		errors.append("separated depth-edge shapes produced a false contact")

	var weak_hitbox: WeakRef = weakref(hitbox)
	var weak_hurtbox: WeakRef = weakref(hurtbox)
	world.free()
	hitbox = null
	hurtbox = null
	if weak_hitbox.get_ref() != null or weak_hurtbox.get_ref() != null:
		errors.append("released Area2D combat components remained alive")
	return errors


func _test_project_hitbox_sandbox() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for CMB-003 integration")
		return errors
	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	var player := sandbox.get_node_or_null("Actors/PlayerRoot") as CharacterBody2D
	var hitbox := sandbox.get_node_or_null(
		"Actors/PlayerRoot/HitboxContainer/DevA1Hitbox"
	) as HitboxComponent
	var hurtbox := sandbox.get_node_or_null(
		"Actors/PlayerRoot/Hurtbox"
	) as HurtboxComponent
	var dummy_a := sandbox.get_node_or_null(
		"Actors/Targets/DummyA/DummyAHurtbox"
	) as HurtboxComponent
	var dummy_b := sandbox.get_node_or_null(
		"Actors/Targets/DummyB/DummyBHurtbox"
	) as HurtboxComponent
	var contact_label := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/HitContactLabel"
	) as Label
	if player == null or hitbox == null or hurtbox == null:
		errors.append("player scene is missing HitboxContainer or Hurtbox")
	elif (
		hitbox.collision_layer != 8
		or hitbox.collision_mask != 64
		or hurtbox.collision_layer != 32
		or hurtbox.collision_mask != 16
	):
		errors.append("player hitbox/hurtbox collision layers do not match architecture")
	if dummy_a == null or dummy_b == null:
		errors.append("sandbox is missing its two multi-target hurtboxes")
	elif (
		dummy_a.combatant_instance_id == dummy_b.combatant_instance_id
		or dummy_a.faction_id != &"enemy"
		or dummy_b.faction_id != &"enemy"
	):
		errors.append("sandbox targets do not have independent enemy runtime identities")
	if contact_label == null or not contact_label.text.contains("Contacts: 0 accepted"):
		errors.append("CMB-003 debug contact counter is missing")
	if hitbox != null and hitbox.contact_enabled:
		errors.append("project hitbox started enabled outside the active attack phase")
	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	for _tick: int in range(12):
		await physics_frame
	if contact_label == null or not contact_label.text.contains("Contacts: 2 accepted"):
		errors.append("A1 sandbox attack did not contact both distinct training targets once")
	if hitbox != null and hitbox.contact_enabled:
		errors.append("project hitbox remained enabled after the active phase")
	sandbox.free()
	return errors


func _test_collision_layers() -> PackedStringArray:
	var errors := PackedStringArray()
	var expected := [
		"WorldStatic",
		"PlayerBody",
		"EnemyBody",
		"PlayerHitbox",
		"EnemyHitbox",
		"PlayerHurtbox",
		"EnemyHurtbox",
		"Interactable",
		"Hazard",
		"Sensor",
	]
	for index: int in range(expected.size()):
		var setting_name := "layer_names/2d_physics/layer_%d" % (index + 1)
		var actual := String(ProjectSettings.get_setting(setting_name, ""))
		if actual != expected[index]:
			errors.append(
				"layer %d is '%s', expected '%s'" % [index + 1, actual, expected[index]]
			)
	return errors


func _test_valid_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	var definition: BaseDefinition = BaseDefinitionScript.new()
	definition.definition_id = &"test.valid"
	definition.display_name_key = &"test.valid.name"
	var definitions: Array[BaseDefinition] = []
	definitions.append(definition)
	var registry: DataRegistryService = DataRegistryScript.new()
	var validation_errors := registry.index_definitions(definitions)
	if not validation_errors.is_empty():
		errors.append_array(validation_errors)
	if registry.definition_count() != 1:
		errors.append("registry did not index exactly one definition")
	if registry.get_definition(&"test.valid") != definition:
		errors.append("registry lookup did not return the indexed Resource")
	registry.free()
	return errors


func _test_duplicate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	var first: BaseDefinition = BaseDefinitionScript.new()
	first.definition_id = &"test.duplicate"
	first.display_name_key = &"test.first.name"
	var second: BaseDefinition = BaseDefinitionScript.new()
	second.definition_id = &"test.duplicate"
	second.display_name_key = &"test.second.name"
	var definitions: Array[BaseDefinition] = []
	definitions.append(first)
	definitions.append(second)
	var registry: DataRegistryService = DataRegistryScript.new()
	var validation_errors := registry.index_definitions(definitions)
	var duplicate_found := false
	for message: String in validation_errors:
		if message.contains("duplicate definition_id"):
			duplicate_found = true
	if not duplicate_found:
		errors.append("duplicate definition_id was not reported")
	if registry.definition_count() != 0:
		errors.append("registry retained definitions after duplicate validation failure")
	registry.free()
	return errors


func _test_invalid_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	var definition: BaseDefinition = BaseDefinitionScript.new()
	definition.definition_id = &"Invalid ID"
	definition.display_name_key = &"test.invalid.name"
	var validation_errors := definition.validation_errors()
	if validation_errors.is_empty():
		errors.append("invalid definition_id passed validation")
	return errors


func _test_project_resource() -> PackedStringArray:
	var errors := PackedStringArray()
	var resource := ResourceLoader.load("res://data/characters/dev_character.tres")
	if resource == null:
		errors.append("dev_character.tres could not be loaded")
	elif not resource is CharacterDefinition:
		errors.append("dev_character.tres is not a CharacterDefinition")
	else:
		var definition := resource as CharacterDefinition
		if definition.definition_id != &"character.dev_placeholder":
			errors.append("dev_character.tres has an unexpected definition_id")
	return errors


func _test_export_remap_path() -> PackedStringArray:
	var errors := PackedStringArray()
	var registry: DataRegistryService = DataRegistryScript.new()
	var remapped_path := registry._definition_path_from_entry(
		"res://data/characters/dev_character.tres.remap"
	)
	if remapped_path != "res://data/characters/dev_character.tres":
		errors.append("exported .tres.remap path was not canonicalized")
	var source_path := registry._definition_path_from_entry(
		"res://data/characters/dev_character.tres"
	)
	if source_path != "res://data/characters/dev_character.tres":
		errors.append("source .tres path changed during canonicalization")
	if not registry._definition_path_from_entry("res://data/readme.txt").is_empty():
		errors.append("non-Resource file was accepted as a definition")
	registry.free()
	return errors


func _test_release_debug_guard() -> PackedStringArray:
	var errors := PackedStringArray()
	var source_file := FileAccess.open("res://scenes/boot/boot.gd", FileAccess.READ)
	if source_file == null:
		errors.append("boot.gd could not be read")
		return errors
	var source := source_file.get_as_text()
	if not source.contains("OS.is_debug_build()"):
		errors.append("boot debug panel is not guarded by OS.is_debug_build()")
	return errors


func _write_reports(failure_count: int) -> void:
	var output_directory := ProjectSettings.globalize_path("res://build/test-results")
	DirAccess.make_dir_recursive_absolute(output_directory)
	_write_junit_report(failure_count)
	_write_json_report(failure_count)


func _write_junit_report(failure_count: int) -> void:
	var lines := PackedStringArray()
	lines.append('<?xml version="1.0" encoding="UTF-8"?>')
	lines.append(
		'<testsuite name="ember-corridor-regression" tests="%d" failures="%d">'
		% [_case_results.size(), failure_count]
	)
	for result: Dictionary in _case_results:
		var case_name := _xml_escape(String(result["name"]))
		var errors: PackedStringArray = result["errors"]
		if errors.is_empty():
			lines.append('  <testcase name="%s"/>' % case_name)
		else:
			var details := _xml_escape("\n".join(errors))
			lines.append('  <testcase name="%s">' % case_name)
			lines.append('    <failure message="M0 assertion failed">%s</failure>' % details)
			lines.append("  </testcase>")
	lines.append("</testsuite>")
	var report := FileAccess.open(
		"res://build/test-results/m0-results.xml",
		FileAccess.WRITE
	)
	if report == null:
		push_warning("Could not write JUnit report")
		return
	report.store_string("\n".join(lines) + "\n")


func _write_json_report(failure_count: int) -> void:
	var cases: Array[Dictionary] = []
	for result: Dictionary in _case_results:
		var errors: PackedStringArray = result["errors"]
		cases.append(
			{
				"name": result["name"],
				"status": "passed" if errors.is_empty() else "failed",
				"errors": Array(errors),
			}
		)
	var report_data := {
		"suite": "ember-corridor-regression",
		"tests": _case_results.size(),
		"failures": failure_count,
		"cases": cases,
	}
	var report := FileAccess.open(
		"res://build/test-results/m0-results.json",
		FileAccess.WRITE
	)
	if report == null:
		push_warning("Could not write JSON report")
		return
	report.store_string(JSON.stringify(report_data, "\t") + "\n")


func _xml_escape(value: String) -> String:
	return (
		value.replace("&", "&amp;")
		.replace("<", "&lt;")
		.replace(">", "&gt;")
		.replace('"', "&quot;")
		.replace("'", "&apos;")
	)
