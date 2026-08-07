extends SceneTree

const BaseDefinitionScript := preload("res://scripts/data/base_definition.gd")
const DataRegistryScript := preload("res://scripts/core/data_registry.gd")
const SettingsServiceScript := preload("res://scripts/core/settings_service.gd")
const GroundMovementModelScript := preload(
	"res://scripts/actors/ground_movement_model.gd"
)
const ElevationModelScript := preload("res://scripts/actors/elevation_model.gd")
const DodgeModelScript := preload("res://scripts/actors/dodge_model.gd")

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
