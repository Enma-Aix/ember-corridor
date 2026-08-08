extends SceneTree

const BaseDefinitionScript := preload("res://scripts/data/base_definition.gd")
const AttackDefinitionScript := preload("res://scripts/data/attack_definition.gd")
const AttackCancelWindowScript := preload(
	"res://scripts/data/attack_cancel_window.gd"
)
const SkillMovementProfileScript := preload(
	"res://scripts/data/skill_movement_profile.gd"
)
const SkillDefinitionScript := preload("res://scripts/data/skill_definition.gd")
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
const InputBufferModelScript := preload(
	"res://scripts/combat/input_buffer_model.gd"
)
const NormalAttackComboModelScript := preload(
	"res://scripts/combat/normal_attack_combo_model.gd"
)
const LinebreakerSkillModelScript := preload(
	"res://scripts/combat/linebreaker_skill_model.gd"
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
const DamagePacketScript := preload("res://scripts/combat/damage_packet.gd")
const HitResultScript := preload("res://scripts/combat/hit_result.gd")
const DamageResolverModelScript := preload(
	"res://scripts/combat/damage_resolver_model.gd"
)
const HitFeedbackRequestScript := preload(
	"res://scripts/combat/hit_feedback_request.gd"
)
const HitFeedbackServiceScript := preload(
	"res://scripts/combat/hit_feedback_service.gd"
)
const CombatReactionProfileScript := preload(
	"res://scripts/data/combat_reaction_profile.gd"
)
const CombatLaunchProfileScript := preload(
	"res://scripts/data/combat_launch_profile.gd"
)
const JuggleModelScript := preload("res://scripts/combat/juggle_model.gd")
const CombatantModelScript := preload("res://scripts/combat/combatant_model.gd")
const VerticalSliceScene := preload("res://scenes/game/vertical_slice.tscn")

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
	_record_case("elevation accepts combat launches and forced landing", _test_elevation_combat_launch())
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
	_record_case("input buffer expires after exactly eight fixed ticks", _test_input_buffer_expiration_boundary())
	_record_case("input buffer records release and consumes once", _test_input_buffer_release_and_consumption())
	_record_case("input buffer isolates actions pause and clear", _test_input_buffer_isolation_pause_and_clear())
	_record_case("project normal combo resources preserve A1 A2 A3 data", _test_normal_combo_resource_contract())
	_record_case("normal combo consumes early and in-window attack input", _test_normal_combo_buffered_chain())
	_record_case("normal combo honors end and after-window boundaries", _test_normal_combo_cancel_boundaries())
	_record_case("normal combo miss recovery reset and invalid data are stable", _test_normal_combo_recovery_and_validation())
	_record_case("all normal attacks mirror their hitboxes left and right", _test_normal_combo_hitbox_mirroring())
	_record_case("linebreaker Resource preserves its complete data contract", _test_linebreaker_resource_contract())
	_record_case("linebreaker movement profile has exact mirrored tick boundaries", _test_linebreaker_movement_boundaries())
	_record_case("linebreaker progression is deterministic and snapshot-based", _test_linebreaker_progression())
	_record_case("linebreaker buffered cancels honor inclusive boundaries", _test_linebreaker_cancel_boundaries())
	_record_case("normal attacks expose only declared skill cancel windows", _test_normal_to_skill_cancel_rules())
	_record_case("project attack Resource drives the debug visualization", _test_project_attack_visualization())
	_record_case("attack definition validates its hitbox profile", _test_attack_hitbox_profile())
	_record_case("hit resolver deduplicates and honors rehit boundaries", _test_hit_resolver_deduplication())
	_record_case("hit resolver filters faction, invulnerability, and height", _test_hit_resolver_filters())
	_record_case("hit resolver accepts multiple targets in stable order", _test_hit_resolver_multi_target_order())
	_record_case("hitbox mirrors geometry and uses named collision layers", _test_hitbox_mirroring_and_layers())
	var area_contact_errors: PackedStringArray = await _test_hitbox_hurtbox_area_contact()
	_record_case("Area2D contact forwards once across pause-like resume", area_contact_errors)
	var sandbox_hitbox_errors: PackedStringArray = await _test_project_hitbox_sandbox()
	_record_case("project sandbox applies damage to two combatant strategies once", sandbox_hitbox_errors)
	var sandbox_combo_errors: PackedStringArray = await _test_project_normal_combo_sandbox()
	_record_case("project sandbox chains A1 A2 A3 and launches only on A3", sandbox_combo_errors)
	var linebreaker_collision_errors: PackedStringArray = await _test_linebreaker_collision_sandbox()
	_record_case("linebreaker crosses EnemyBody targets but stops at WorldStatic", linebreaker_collision_errors)
	var linebreaker_cancel_errors: PackedStringArray = await _test_linebreaker_cancel_sandbox()
	_record_case("sandbox hit-confirm and buffered linebreaker cancels integrate", linebreaker_cancel_errors)
	_record_case("attack definition validates its damage profile", _test_attack_damage_profile())
	_record_case("damage packet is an immutable validated snapshot", _test_damage_packet_snapshot())
	_record_case("damage formula handles baseline, rounding, and minimum", _test_damage_formula_baseline())
	_record_case("damage formula clamps negative defense and handles boundaries", _test_damage_defense_boundaries())
	_record_case("critical chance uses exact boundaries and a 60 percent cap", _test_damage_critical_boundaries())
	_record_case("damage modifiers and rejected results are explicit", _test_damage_modifiers_and_rejections())
	_record_case("damage resolution is deterministic, stateless, and releasable", _test_damage_determinism_and_lifecycle())
	_record_case("feedback profiles preserve all four design budgets", _test_hit_feedback_profiles())
	_record_case("feedback requests snapshot accepted hit outcomes", _test_hit_feedback_request_snapshot())
	_record_case("feedback service routes hit stop camera VFX and SFX independently", _test_hit_feedback_channel_routing())
	_record_case("hit stop overlap takes the maximum with exact tick boundaries", _test_hit_feedback_hit_stop_boundaries())
	_record_case("camera feedback takes maximum strength with bounded extension", _test_hit_feedback_camera_merging())
	_record_case("feedback progression is deterministic and releasable", _test_hit_feedback_determinism_and_lifecycle())
	var feedback_sandbox_errors: PackedStringArray = await _test_hit_feedback_sandbox()
	_record_case("sandbox hit feedback pauses and restores the scene safely", feedback_sandbox_errors)
	_record_case("normal elite and boss reaction profiles are registered and valid", _test_combat_reaction_profiles())
	_record_case("launch and ground-pursuit profiles are registered and valid", _test_combat_launch_profiles())
	_record_case("normal combatants react while applying health and poise", _test_normal_combatant_reaction())
	_record_case("elite combatants preserve action until poise breaks", _test_elite_combatant_reaction())
	_record_case("boss combatants break only from a tag or zero poise", _test_boss_combatant_reaction())
	_record_case("break recovery and protection honor exact tick boundaries", _test_break_recovery_and_protection())
	_record_case("poise regeneration starts after exactly 180 ticks", _test_poise_recovery_boundary())
	_record_case("defeat and healing clamp state and emit once", _test_combatant_defeat_and_healing())
	_record_case("combatant application is transactional deterministic and releasable", _test_combatant_determinism_and_lifecycle())
	_record_case("normal targets launch and gain juggle resistance", _test_normal_juggle_progression())
	_record_case("continuous airborne control forces landing at tick 210", _test_forced_landing_boundary())
	_record_case("knockdown allows one pursuit within exactly 30 ticks", _test_knockdown_ground_pursuit())
	_record_case("elite boss break and defeat preserve control immunity", _test_juggle_immunity_and_interrupts())
	_record_case("juggle state is fixed-tick deterministic and releasable", _test_juggle_determinism_and_lifecycle())
	_record_case("collision layers match architecture", _test_collision_layers())
	_record_case("valid Resource is indexed and returned", _test_valid_definition())
	_record_case("duplicate definition ID blocks indexing", _test_duplicate_definition())
	_record_case("invalid definition ID is rejected", _test_invalid_definition())
	_record_case("project placeholder Resource loads", _test_project_resource())
	_record_case("export remap paths resolve to source Resources", _test_export_remap_path())
	_record_case("release build guards the debug panel", _test_release_debug_guard())
	var vertical_slice_errors: PackedStringArray = await _test_vertical_slice_runtime()
	_record_case("visual vertical slice starts, fights, and reaches an end state", vertical_slice_errors)

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


func _test_vertical_slice_runtime() -> PackedStringArray:
	var errors := PackedStringArray()
	var slice := VerticalSliceScene.instantiate()
	root.add_child(slice)
	await process_frame

	if not slice.title_root.visible or slice.hud_root.visible:
		errors.append("vertical slice did not open on the title screen")
	if slice._player_sprite == null or slice._player_sprite.texture == null:
		errors.append("runtime player art was not attached")
	if slice._enemy_sprites.size() != 2 or slice._enemy_models.size() != 2:
		errors.append("runtime enemy art or combat models were not attached")
	if slice.title_root.theme == null or slice.title_root.theme.default_font == null:
		errors.append("runtime Chinese font theme was not attached")

	slice._start_run()
	await process_frame
	if slice.title_root.visible or not slice.hud_root.visible:
		errors.append("starting the run did not switch from title to HUD")
	if slice.combat_core.process_mode != Node.PROCESS_MODE_INHERIT:
		errors.append("starting the run did not enable the combat core")

	var spider: CharacterBody2D = slice.spider_target
	spider.position = slice.player.position + Vector2(40.0, 0.0)
	var state: Dictionary = slice._enemy_states[spider]
	state["cooldown"] = 0.0
	slice._enemy_states[spider] = state
	for _tick: int in 40:
		slice._physics_process(1.0 / 60.0)
	if slice._player_health >= slice.PLAYER_MAX_HEALTH:
		errors.append("nearby enemy never completed its attack or damaged the player")

	slice._player_health = 0
	slice._check_outcome()
	if not slice._run_completed or not slice.end_root.visible:
		errors.append("zero player health did not reach the defeat state")
	if slice.combat_core.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("end state did not stop the combat core")

	slice.queue_free()
	await process_frame
	return errors


func _test_version_pin() -> PackedStringArray:
	var errors := PackedStringArray()
	if VersionInfo.GAME_VERSION != "0.1.2-visual-slice":
		errors.append("VersionInfo does not match release/VERSION")
	if VersionInfo.BUILD_CHANNEL != "legacy visual slice":
		errors.append("VersionInfo does not identify the legacy visual slice")
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


func _test_elevation_combat_launch() -> PackedStringArray:
	var errors := PackedStringArray()
	var elevation: ElevationModel = ElevationModelScript.new()
	errors.append_array(elevation.configure(720.0, 1800.0, 0.0, 56.0))
	if not elevation.launch(600.0) or elevation.grounded:
		errors.append("valid combat launch did not leave the ground")
	if not is_equal_approx(elevation.vertical_velocity, 600.0):
		errors.append("combat launch did not apply its exact upward velocity")
	elevation.advance(1.0 / 60.0, 2.0)
	if (
		not is_equal_approx(elevation.vertical_velocity, 540.0)
		or not is_equal_approx(elevation.elevation, 9.0)
	):
		errors.append("gravity multiplier did not produce deterministic elevation")
	var before_elevation := elevation.elevation
	var before_velocity := elevation.vertical_velocity
	elevation.advance(1.0 / 60.0, 0.0)
	if (
		not is_equal_approx(elevation.elevation, before_elevation)
		or not is_equal_approx(elevation.vertical_velocity, before_velocity)
	):
		errors.append("invalid gravity multiplier partially changed elevation")
	if elevation.launch(NAN):
		errors.append("non-finite combat launch was accepted")
	if not elevation.force_land():
		errors.append("forced landing did not report an airborne transition")
	if (
		not elevation.grounded
		or not is_zero_approx(elevation.elevation)
		or not is_zero_approx(elevation.vertical_velocity)
		or elevation.force_land()
	):
		errors.append("forced landing did not clamp or remain idempotent")
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
	attack.feedback_strength = "light"
	attack.damage_coefficient = 1.0
	attack.flat_damage = 10.0
	attack.poise_damage = 12.0
	attack.hit_tags = [&"damage.physical", &"attack.normal"]
	attack.launch_profile = &"none"
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


func _test_input_buffer_expiration_boundary() -> PackedStringArray:
	var errors := PackedStringArray()
	var buffer: InputBufferModel = InputBufferModelScript.new()
	errors.append_array(buffer.configure(InputBufferModel.DEFAULT_BUFFER_TICKS))
	if not buffer.record_pressed(&"attack"):
		errors.append("input buffer rejected a valid attack press")
	for _tick: int in range(7):
		buffer.advance_tick()
	if not buffer.has_buffered_press(&"attack"):
		errors.append("attack press expired before the eighth buffered tick")
	if buffer.input_age_ticks(&"attack") != 7:
		errors.append("attack press did not report age 7 at its final valid tick")
	buffer.advance_tick()
	if buffer.has_buffered_press(&"attack"):
		errors.append("attack press remained valid at age 8")
	if not buffer.pending_actions().is_empty():
		errors.append("expired attack press remained in pending actions")
	return errors


func _test_input_buffer_release_and_consumption() -> PackedStringArray:
	var errors := PackedStringArray()
	var buffer: InputBufferModel = InputBufferModelScript.new()
	errors.append_array(buffer.configure())
	buffer.record_pressed(&"attack")
	buffer.advance_tick()
	buffer.advance_tick()
	if not buffer.record_released(&"attack"):
		errors.append("input buffer did not record release for a pending press")
	var pending := buffer.buffered_entry(&"attack")
	if (
		pending.get("pressed_tick", -1) != 0
		or pending.get("released_tick", -1) != 2
	):
		errors.append("pending input did not preserve pressed/released ticks")
	var consumed := buffer.consume(&"attack")
	if (
		consumed.get("pressed_tick", -1) != 0
		or consumed.get("released_tick", -1) != 2
		or consumed.get("consumed_tick", -1) != 2
	):
		errors.append("consumed input snapshot has incorrect tick metadata")
	if not buffer.consume(&"attack").is_empty():
		errors.append("the same buffered press was consumed more than once")

	buffer.reset()
	buffer.record_pressed(&"attack")
	buffer.consume(&"attack")
	for _tick: int in range(3):
		buffer.advance_tick()
	if not buffer.record_released(&"attack"):
		errors.append("release after consumption was not attached to input history")
	var history := buffer.last_event(&"attack")
	if history.get("released_tick", -1) != 3:
		errors.append("consumed input history did not preserve its release tick")
	return errors


func _test_input_buffer_isolation_pause_and_clear() -> PackedStringArray:
	var errors := PackedStringArray()
	var buffer: InputBufferModel = InputBufferModelScript.new()
	errors.append_array(buffer.configure())
	buffer.record_pressed(&"attack")
	buffer.record_pressed(&"dodge")
	for _paused_frame: int in range(240):
		var ignored_delta := 1.0 / 30.0 if _paused_frame % 2 == 0 else 1.0 / 144.0
		if ignored_delta <= 0.0:
			errors.append("simulated pause delta was invalid")
	if (
		buffer.current_tick != 0
		or not buffer.has_buffered_press(&"attack")
		or not buffer.has_buffered_press(&"dodge")
	):
		errors.append("render frames advanced or lost fixed-tick buffered input")
	buffer.consume(&"attack")
	if not buffer.has_buffered_press(&"dodge"):
		errors.append("consuming attack also removed the dodge action")
	buffer.clear()
	if not buffer.pending_actions().is_empty():
		errors.append("clear did not remove pending actions")
	var previous_capacity := buffer.buffer_ticks
	if buffer.configure(0).is_empty():
		errors.append("input buffer accepted zero capacity")
	if buffer.buffer_ticks != previous_capacity:
		errors.append("invalid buffer configuration mutated prior capacity")
	if buffer.record_pressed(&"") or buffer.record_released(&""):
		errors.append("input buffer accepted an empty action ID")
	return errors


func _load_project_normal_attack_sequence() -> Array[AttackDefinition]:
	var result: Array[AttackDefinition] = []
	for path: String in [
		"res://data/attacks/dev_a1.tres",
		"res://data/attacks/dev_a2.tres",
		"res://data/attacks/dev_a3.tres",
	]:
		var attack := ResourceLoader.load(path) as AttackDefinition
		if attack != null:
			result.append(attack)
	return result


func _test_normal_combo_resource_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("project did not load all three normal attack Resources")
		return errors
	for attack: AttackDefinition in sequence:
		errors.append_array(attack.validation_errors())
	if (
		Vector3i(
			sequence[0].startup_ticks,
			sequence[0].active_ticks,
			sequence[0].recovery_ticks
		) != Vector3i(6, 3, 11)
		or Vector3i(
			sequence[1].startup_ticks,
			sequence[1].active_ticks,
			sequence[1].recovery_ticks
		) != Vector3i(7, 3, 13)
		or Vector3i(
			sequence[2].startup_ticks,
			sequence[2].active_ticks,
			sequence[2].recovery_ticks
		) != Vector3i(9, 4, 18)
	):
		errors.append("A1/A2/A3 timelines do not match the 6/3/11 7/3/13 9/4/18 baseline")
	if (
		sequence[0].cancel_targets_at_tick(8).has("action.attack")
		or not sequence[0].cancel_targets_at_tick(9).has("action.attack")
		or not sequence[0].cancel_targets_at_tick(20).has("action.attack")
		or sequence[0].cancel_targets_at_tick(21).has("action.attack")
	):
		errors.append("A1 attack-chain cancel boundaries are not exactly 9 through 20")
	if (
		sequence[1].hitbox_size.y <= sequence[0].hitbox_size.y
		or not sequence[1].cancel_targets_at_tick(10).has("action.attack")
		or not sequence[1].cancel_targets_at_tick(23).has("action.attack")
	):
		errors.append("A2 does not preserve its wider depth and 10 through 23 chain window")
	if (
		sequence[2].cancel_targets_at_tick(22).has("action.attack")
		or sequence[2].launch_profile != &"combat.launch.dev_launcher"
		or sequence[2].hit_stop_ticks != 5
	):
		errors.append("A3 must finish the chain with launcher data and no A4 cancel")
	var registry: DataRegistryService = DataRegistryScript.new()
	errors.append_array(registry.reload_definitions("res://data"))
	if registry.definition_count() != 15:
		errors.append("DataRegistry did not index all fifteen project definitions")
	for attack: AttackDefinition in sequence:
		if registry.get_definition(attack.definition_id) == null:
			errors.append("DataRegistry is missing %s" % String(attack.definition_id))
	registry.free()
	return errors


func _test_normal_combo_buffered_chain() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("normal combo sequence could not be loaded")
		return errors
	var buffer: InputBufferModel = InputBufferModelScript.new()
	var combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
	errors.append_array(buffer.configure())
	errors.append_array(combo.configure(sequence))
	var started_ids: Array[StringName] = []
	var finish_reasons: Array[StringName] = []
	combo.attack_started.connect(
		func(attack: AttackDefinition, _index: int) -> void:
			started_ids.append(attack.definition_id)
	)
	combo.attack_finished.connect(
		func(_attack_id: StringName, _index: int, reason: StringName) -> void:
			finish_reasons.append(reason)
	)

	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	if combo.combo_index != 0 or combo.timeline.action_tick != 1:
		errors.append("initial attack press did not start A1 on tick 1")
	buffer.advance_tick()
	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	var safety := 32
	while combo.combo_index == 0 and safety > 0:
		buffer.advance_tick()
		combo.advance_tick(buffer)
		safety -= 1
	if combo.combo_index != 1 or combo.timeline.action_tick != 1:
		errors.append("early buffered press did not chain A1 into A2 at tick 9")
	if buffer.last_event(&"attack").get("consumed_tick", -1) - buffer.last_event(&"attack").get("pressed_tick", -1) != 7:
		errors.append("A1 early input was not consumed on the final valid buffer age")

	buffer.advance_tick()
	combo.advance_tick(buffer)
	buffer.advance_tick()
	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	safety = 36
	while combo.combo_index == 1 and safety > 0:
		buffer.advance_tick()
		combo.advance_tick(buffer)
		safety -= 1
	if combo.combo_index != 2 or combo.timeline.action_tick != 1:
		errors.append("buffered press did not chain A2 into A3 at tick 10")
	safety = 48
	while combo.timeline.is_running and safety > 0:
		buffer.advance_tick()
		combo.advance_tick(buffer)
		safety -= 1
	if combo.combo_index != -1 or combo.last_finish_reason != &"complete":
		errors.append("A3 did not recover to idle after its complete timeline")
	if started_ids.size() != 3 or finish_reasons != [&"chained", &"chained", &"complete"]:
		errors.append("combo start/finish signals did not preserve A1 A2 A3 order")
	return errors


func _test_normal_combo_cancel_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("normal combo sequence could not be loaded")
		return errors

	var end_buffer: InputBufferModel = InputBufferModelScript.new()
	var end_combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
	end_buffer.configure()
	end_combo.configure(sequence)
	end_buffer.record_pressed(&"attack")
	end_combo.advance_tick(end_buffer)
	while end_combo.timeline.action_tick < 19:
		end_buffer.advance_tick()
		end_combo.advance_tick(end_buffer)
	end_buffer.advance_tick()
	end_buffer.record_pressed(&"attack")
	end_combo.advance_tick(end_buffer)
	if end_combo.combo_index != 1 or end_combo.timeline.action_tick != 1:
		errors.append("attack press on A1 cancel end tick 20 did not start A2")

	var after_buffer: InputBufferModel = InputBufferModelScript.new()
	var after_combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
	after_buffer.configure()
	after_combo.configure(sequence)
	after_buffer.record_pressed(&"attack")
	after_combo.advance_tick(after_buffer)
	while after_combo.timeline.is_running:
		after_buffer.advance_tick()
		after_combo.advance_tick(after_buffer)
	after_buffer.advance_tick()
	after_buffer.record_pressed(&"attack")
	after_combo.advance_tick(after_buffer)
	if after_combo.combo_index != 0 or after_combo.timeline.action_tick != 1:
		errors.append("post-window attack did not begin a fresh A1 chain")
	return errors


func _test_normal_combo_recovery_and_validation() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("normal combo sequence could not be loaded")
		return errors
	var combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
	errors.append_array(combo.configure(sequence))
	var invalid_sequence: Array[AttackDefinition] = [sequence[2], sequence[1]]
	if combo.configure(invalid_sequence).is_empty():
		errors.append("combo accepted an intermediate attack without action.attack cancel")
	if not combo.is_configured() or combo.sequence_size() != 3:
		errors.append("invalid reconfiguration damaged the prior valid combo")

	var buffer: InputBufferModel = InputBufferModelScript.new()
	buffer.configure()
	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	while combo.timeline.is_running:
		buffer.advance_tick()
		combo.advance_tick(buffer)
	if combo.combo_index != -1:
		errors.append("an unchained miss did not recover to idle")
	buffer.advance_tick()
	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	if combo.combo_index != 0:
		errors.append("fresh input after miss recovery did not restart at A1")
	combo.reset()
	if combo.combo_index != -1 or combo.timeline.is_running:
		errors.append("combo reset did not clear its active timeline")
	return errors


func _test_normal_combo_hitbox_mirroring() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("normal combo sequence could not be loaded")
		return errors
	for index: int in sequence.size():
		var attack := sequence[index]
		var hitbox: HitboxComponent = HitboxComponentScript.new()
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		hitbox.add_child(collision_shape)
		root.add_child(hitbox)
		errors.append_array(
			hitbox.activate(attack, StringName("combo.right.%d" % index), 8100 + index, &"player", 1)
		)
		if not is_equal_approx(hitbox.position.x, absf(attack.hitbox_offset.x)):
			errors.append("A%d right-facing hitbox offset is incorrect" % (index + 1))
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle == null or rectangle.size != attack.hitbox_size:
			errors.append("A%d hitbox size did not come from its Resource" % (index + 1))
		hitbox.deactivate()
		errors.append_array(
			hitbox.activate(attack, StringName("combo.left.%d" % index), 8200 + index, &"player", -1)
		)
		if not is_equal_approx(hitbox.position.x, -absf(attack.hitbox_offset.x)):
			errors.append("A%d left-facing hitbox was not mirrored" % (index + 1))
		hitbox.free()
	return errors


func _load_linebreaker_skill() -> SkillDefinition:
	return ResourceLoader.load(
		"res://data/skills/bladebound_linebreaker.tres"
	) as SkillDefinition


func _test_linebreaker_resource_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var skill := _load_linebreaker_skill()
	if skill == null:
		errors.append("linebreaker SkillDefinition did not load")
		return errors
	errors.append_array(skill.validation_errors())
	var attack := skill.primary_attack()
	var movement := skill.movement_profile
	if (
		skill.definition_kind() != &"skill"
		or skill.definition_id != &"skill.bladebound.linebreaker"
		or not is_equal_approx(skill.cooldown_seconds, 5.0)
		or skill.animation_name != &"skill_linebreaker"
		or skill.attack_sequence.size() != 1
	):
		errors.append("linebreaker identity, cooldown, animation, or sequence is incorrect")
	if (
		attack == null
		or attack.definition_id != &"attack.bladebound.linebreaker"
		or Vector3i(
			attack.startup_ticks,
			attack.active_ticks,
			attack.recovery_ticks
		) != Vector3i(2, 8, 10)
		or attack.hitbox_size != Vector2(120.0, 60.0)
	):
		errors.append("linebreaker nested AttackDefinition baseline is incorrect")
	if (
		movement == null
		or not is_equal_approx(movement.distance_pixels, 176.0)
		or movement.travel_start_tick != 1
		or movement.travel_end_tick != 10
		or movement.blocking_collision_mask != 1
		or movement.pass_through_collision_mask != 4
		or not movement.passes_target_tag(&"enemy.size.small")
	):
		errors.append("linebreaker movement or collision contract is incorrect")
	if (
		attack == null
		or attack.cancel_targets_at_tick(9).has("action.attack")
		or not attack.cancel_targets_at_tick(10).has("action.attack")
		or not attack.cancel_targets_at_tick(20).has("action.attack")
		or attack.cancel_targets_at_tick(21).has("action.attack")
		or attack.cancel_targets_at_tick(11).has("action.dodge")
		or not attack.cancel_targets_at_tick(12).has("action.dodge")
	):
		errors.append("linebreaker cancel rules do not preserve their exact boundaries")

	var registry: DataRegistryService = DataRegistryScript.new()
	errors.append_array(registry.reload_definitions("res://data"))
	if registry.definition_count() != 15:
		errors.append("DataRegistry did not index all fifteen project definitions")
	if registry.get_definition(skill.definition_id) == null:
		errors.append("DataRegistry is missing the linebreaker SkillDefinition")
	registry.free()
	return errors


func _test_linebreaker_movement_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var source := _load_linebreaker_skill()
	if source == null or source.movement_profile == null:
		errors.append("linebreaker movement profile did not load")
		return errors
	var movement := source.movement_profile
	errors.append_array(movement.validation_errors(source.total_ticks()))
	var right_total := Vector2.ZERO
	var left_total := Vector2.ZERO
	for action_tick: int in range(0, 22):
		var right := movement.displacement_at_tick(action_tick, 1)
		var left := movement.displacement_at_tick(action_tick, -1)
		if not left.is_equal_approx(-right):
			errors.append("linebreaker displacement did not mirror at tick %d" % action_tick)
		right_total += right
		left_total += left
	if not right_total.is_equal_approx(Vector2(176.0, 0.0)):
		errors.append("right-facing linebreaker did not travel exactly 176 px")
	if not left_total.is_equal_approx(Vector2(-176.0, 0.0)):
		errors.append("left-facing linebreaker did not travel exactly -176 px")
	if movement.displacement_at_tick(1, 0) != Vector2.ZERO:
		errors.append("linebreaker accepted an invalid zero facing sign")

	var invalid := movement.duplicate(true) as SkillMovementProfile
	invalid.travel_start_tick = 11
	invalid.travel_end_tick = 10
	invalid.distance_pixels = NAN
	invalid.blocking_collision_mask = 4
	invalid.pass_through_collision_mask = 4
	invalid.pass_through_target_tags = []
	if invalid.validation_errors(source.total_ticks()).size() < 4:
		errors.append("movement profile did not reject its invalid boundaries")
	return errors


func _test_linebreaker_progression() -> PackedStringArray:
	var errors := PackedStringArray()
	var project_skill := _load_linebreaker_skill()
	if project_skill == null:
		errors.append("linebreaker SkillDefinition did not load")
		return errors
	var source := project_skill.duplicate(true) as SkillDefinition
	var model: LinebreakerSkillModel = LinebreakerSkillModelScript.new()
	errors.append_array(model.configure(source))
	source.movement_profile.distance_pixels = 999.0
	if not is_equal_approx(model.movement_profile.distance_pixels, 176.0):
		errors.append("source mutation changed the configured linebreaker snapshot")
	if model.try_start(0):
		errors.append("linebreaker accepted an invalid facing sign")
	if not model.try_start(1):
		errors.append("configured linebreaker could not start")
	if model.try_start(1):
		errors.append("active linebreaker restarted over its own timeline")
	var total_displacement := Vector2.ZERO
	var moving_ticks := 0
	for _tick: int in range(20):
		var displacement := model.advance_tick()
		total_displacement += displacement
		if not displacement.is_zero_approx():
			moving_ticks += 1
	if moving_ticks != 10 or not total_displacement.is_equal_approx(Vector2(176.0, 0.0)):
		errors.append("linebreaker fixed-tick progression changed its 10-tick travel")
	if model.is_active() or model.last_finish_reason != &"complete":
		errors.append("linebreaker did not finish after exactly 20 action ticks")
	if model.configure(null).is_empty() or not model.is_configured():
		errors.append("invalid reconfiguration damaged the prior valid snapshot")
	var weak_model: WeakRef = weakref(model)
	model = null
	if weak_model.get_ref() != null:
		errors.append("released linebreaker model remained alive")
	return errors


func _test_linebreaker_cancel_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var source := _load_linebreaker_skill()
	if source == null:
		errors.append("linebreaker SkillDefinition did not load")
		return errors

	var early_buffer: InputBufferModel = InputBufferModelScript.new()
	var early_model: LinebreakerSkillModel = LinebreakerSkillModelScript.new()
	early_buffer.configure()
	early_model.configure(source)
	early_model.try_start(1)
	for _tick: int in range(3):
		early_buffer.advance_tick()
		early_model.advance_tick(early_buffer)
	early_buffer.record_pressed(&"attack")
	while early_model.is_active() and early_model.timeline.action_tick < 10:
		early_buffer.advance_tick()
		early_model.advance_tick(early_buffer)
	if (
		early_model.last_finish_reason != &"canceled"
		or early_model.last_cancel_target != &"action.attack"
	):
		errors.append("early attack input did not cancel linebreaker at tick 10")
	elif (
		early_buffer.last_event(&"attack").get("consumed_tick", -1)
		- early_buffer.last_event(&"attack").get("pressed_tick", -1)
		!= 7
	):
		errors.append("early linebreaker cancel was not consumed at buffer age 7")

	var end_buffer: InputBufferModel = InputBufferModelScript.new()
	var end_model: LinebreakerSkillModel = LinebreakerSkillModelScript.new()
	end_buffer.configure()
	end_model.configure(source)
	end_model.try_start(1)
	while end_model.timeline.action_tick < 19:
		end_buffer.advance_tick()
		end_model.advance_tick(end_buffer)
	end_buffer.record_pressed(&"attack")
	end_buffer.advance_tick()
	end_model.advance_tick(end_buffer)
	if end_model.last_cancel_target != &"action.attack":
		errors.append("attack input on cancel end tick 20 was not accepted")

	var after_buffer: InputBufferModel = InputBufferModelScript.new()
	var after_model: LinebreakerSkillModel = LinebreakerSkillModelScript.new()
	after_buffer.configure()
	after_model.configure(source)
	after_model.try_start(1)
	for _tick: int in range(20):
		after_buffer.advance_tick()
		after_model.advance_tick(after_buffer)
	after_buffer.record_pressed(&"attack")
	if (
		after_model.advance_tick(after_buffer) != Vector2.ZERO
		or after_model.last_finish_reason != &"complete"
	):
		errors.append("post-window input changed a completed linebreaker")
	return errors


func _test_normal_to_skill_cancel_rules() -> PackedStringArray:
	var errors := PackedStringArray()
	var sequence := _load_project_normal_attack_sequence()
	if sequence.size() != 3:
		errors.append("normal attack sequence did not load")
		return errors
	var expected_ranges := [Vector2i(9, 18), Vector2i(10, 21), Vector2i(13, 27)]
	for index: int in sequence.size():
		var expected: Vector2i = expected_ranges[index]
		var attack := sequence[index]
		if (
			attack.cancel_targets_at_tick(expected.x - 1).has("action.skill_1")
			or not attack.cancel_targets_at_tick(expected.x).has("action.skill_1")
			or not attack.cancel_targets_at_tick(expected.y).has("action.skill_1")
			or attack.cancel_targets_at_tick(expected.y + 1).has("action.skill_1")
		):
			errors.append("A%d skill cancel boundaries are incorrect" % (index + 1))

	var buffer: InputBufferModel = InputBufferModelScript.new()
	var combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
	buffer.configure()
	combo.configure(sequence)
	buffer.record_pressed(&"attack")
	combo.advance_tick(buffer)
	while combo.timeline.action_tick < 8:
		buffer.advance_tick()
		combo.advance_tick(buffer)
	if combo.can_cancel_to(&"action.skill_1") or combo.cancel_to(&"action.skill_1"):
		errors.append("A1 canceled into skill before its declared window")
	buffer.advance_tick()
	combo.advance_tick(buffer)
	if not combo.can_cancel_to(&"action.skill_1"):
		errors.append("A1 did not expose its skill cancel on tick 9")
	elif not combo.cancel_to(&"action.skill_1"):
		errors.append("A1 rejected its declared skill cancel")
	if combo.last_finish_reason != &"canceled" or combo.timeline.is_running:
		errors.append("normal combo did not return to idle after skill cancellation")
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
	if registry.definition_count() != 15:
		errors.append("DataRegistry did not index all fifteen project definitions")
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
	var dummy_a_body := sandbox.get_node_or_null(
		"Actors/Targets/DummyA/Body"
	) as Node2D
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
	for _tick: int in range(16):
		await physics_frame
	if contact_label == null or not contact_label.text.contains("Contacts: 2 accepted"):
		errors.append("A1 sandbox attack did not contact both distinct training targets once")
	elif (
		not contact_label.text.contains("Damage: 2 resolved")
		or not contact_label.text.contains("total 143")
		or not contact_label.text.contains("range 55-88")
		or not contact_label.text.contains("crit 0")
		or not contact_label.text.contains("Normal HP 212/300")
		or not contact_label.text.contains("Poise 12.0/24.0 · hit_stun")
		or not contact_label.text.contains("Elite HP 245/300")
		or not contact_label.text.contains("Poise 0.0/12.0 · poise_break")
	):
		errors.append(
			"sandbox did not resolve and apply the 88 + 55 multi-strategy hit: %s"
			% contact_label.text.replace("\n", " | ")
		)
	if (
		dummy_a == null
		or dummy_a_body == null
		or not is_equal_approx(dummy_a.min_hit_height, 0.0)
		or not is_equal_approx(dummy_a_body.position.y, 0.0)
	):
		errors.append("A1 incorrectly launched its normal target")
	if hitbox != null and hitbox.contact_enabled:
		errors.append("project hitbox remained enabled after the active phase")
	for _finish_tick: int in range(10):
		await physics_frame
	for _attack_index: int in range(5):
		Input.action_press(&"attack")
		await physics_frame
		Input.action_release(&"attack")
		for _attack_tick: int in range(24):
			await physics_frame
	if (
		contact_label == null
		or not contact_label.text.contains("Contacts: 10 accepted")
		or not contact_label.text.contains("Damage: 10 resolved")
		or not contact_label.text.contains("Normal HP 0/300")
		or not contact_label.text.contains("Elite HP 0/300")
		or not contact_label.text.contains("defeated")
	):
		errors.append("repeated sandbox attacks did not reach stable terminal states")
	if (
		dummy_a != null
		and dummy_b != null
		and (dummy_a.is_accepting_hits or dummy_b.is_accepting_hits)
	):
		errors.append("defeated sandbox targets kept accepting hurtbox contacts")
	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	for _attack_tick: int in range(24):
		await physics_frame
	if (
		contact_label != null
		and (
			not contact_label.text.contains("Contacts: 10 accepted")
			or not contact_label.text.contains("Damage: 10 resolved")
		)
	):
		errors.append("defeated targets received another accepted or applied hit")
	sandbox.free()
	return errors


func _test_project_normal_combo_sandbox() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for CMB-008 integration")
		return errors
	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	var combo := sandbox.get("normal_attack_combo") as NormalAttackComboModel
	var dummy_a := sandbox.get_node_or_null(
		"Actors/Targets/DummyA/DummyAHurtbox"
	) as HurtboxComponent
	var dummy_a_body := sandbox.get_node_or_null(
		"Actors/Targets/DummyA/Body"
	) as Node2D
	var contact_label := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/HitContactLabel"
	) as Label
	var attack_trail := sandbox.get_node_or_null(
		"Actors/PlayerRoot/VisualRoot/AttackTrail"
	) as Polygon2D
	if combo == null or dummy_a == null or dummy_a_body == null:
		errors.append("sandbox is missing combo model or normal target presentation")
		sandbox.free()
		return errors

	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	await physics_frame
	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	await physics_frame
	var safety := 40
	while combo.combo_index == 0 and safety > 0:
		await physics_frame
		safety -= 1
	if combo.combo_index != 1:
		errors.append("sandbox did not consume early input to enter A2")
	else:
		await physics_frame
		Input.action_press(&"attack")
		await physics_frame
		Input.action_release(&"attack")
		await physics_frame

	safety = 48
	while combo.combo_index != 2 and safety > 0:
		await physics_frame
		safety -= 1
	if combo.combo_index != 2:
		errors.append("sandbox did not consume buffered input to enter A3")
	else:
		safety = 24
		while combo.timeline.action_tick < 12 and safety > 0:
			await physics_frame
			safety -= 1
		if attack_trail == null or not attack_trail.visible:
			errors.append("A3 active ticks did not show the attack trail")
		if (
			dummy_a.min_hit_height <= 0.0
			or dummy_a_body.position.y >= 0.0
		):
			errors.append("A3 did not launch the normal target above ground")
		if contact_label == null or not contact_label.text.contains("Contacts: 6 accepted"):
			errors.append("full A1/A2/A3 chain did not hit both targets exactly once per attack")

	Input.action_release(&"attack")
	safety = 48
	while combo.timeline.is_running and safety > 0:
		await physics_frame
		safety -= 1
	if combo.timeline.is_running or combo.combo_index != -1:
		errors.append("sandbox combo did not return to idle after A3 recovery")
	sandbox.free()
	return errors


func _test_linebreaker_collision_sandbox() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for CMB-009 collision test")
		return errors

	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	await physics_frame
	var player := sandbox.get_node_or_null(
		"Actors/PlayerRoot"
	) as PlayerGroundMovementController
	var dummy_a := sandbox.get_node_or_null(
		"Actors/Targets/DummyA"
	) as CharacterBody2D
	var dummy_b := sandbox.get_node_or_null(
		"Actors/Targets/DummyB"
	) as CharacterBody2D
	var skill := sandbox.get("linebreaker_skill") as LinebreakerSkillModel
	var attack_trail := sandbox.get_node_or_null(
		"Actors/PlayerRoot/VisualRoot/AttackTrail"
	) as Polygon2D
	var contact_label := sandbox.get_node_or_null(
		"Hud/AttackTimelinePanel/TimelineMargin/TimelineVBox/HitContactLabel"
	) as Label
	if player == null or dummy_a == null or dummy_b == null or skill == null:
		errors.append("sandbox is missing CMB-009 player, EnemyBody, or skill model")
		sandbox.free()
		return errors
	if (
		dummy_a.collision_layer != 4
		or dummy_b.collision_layer != 4
		or (player.collision_mask & 4) != 0
	):
		errors.append("EnemyBody pass-through layers do not match the movement profile")

	var start_x := player.global_position.x
	Input.action_press(&"skill_1")
	await physics_frame
	Input.action_release(&"skill_1")
	var saw_active_trail := false
	var maximum_x := player.global_position.x
	for _tick: int in range(30):
		await physics_frame
		maximum_x = maxf(maximum_x, player.global_position.x)
		saw_active_trail = saw_active_trail or (
			attack_trail != null and attack_trail.visible
		)
	if not is_equal_approx(player.global_position.x, start_x + 176.0):
		errors.append(
			"linebreaker ended at %.2f instead of %.2f"
			% [player.global_position.x, start_x + 176.0]
		)
	if maximum_x <= dummy_b.global_position.x + 20.0:
		errors.append("linebreaker did not pass through both EnemyBody targets")
	if not saw_active_trail:
		errors.append("linebreaker active ticks did not show its distinct trail")
	if (
		contact_label == null
		or not contact_label.text.contains("Contacts: 2 accepted")
		or not contact_label.text.contains("Damage: 2 resolved")
	):
		errors.append("linebreaker did not hit both crossed targets exactly once")
	if skill.is_active() or player.is_action_motion_active() or player.collision_mask != 1:
		errors.append("linebreaker did not restore player movement collision state")
	sandbox.free()
	await physics_frame

	var wall_sandbox := sandbox_scene.instantiate()
	root.add_child(wall_sandbox)
	await physics_frame
	var wall_player := wall_sandbox.get_node_or_null(
		"Actors/PlayerRoot"
	) as PlayerGroundMovementController
	var wall_skill := wall_sandbox.get("linebreaker_skill") as LinebreakerSkillModel
	if wall_player == null or wall_skill == null:
		errors.append("wall sandbox is missing its player or linebreaker model")
		wall_sandbox.free()
		return errors
	wall_player.global_position = Vector2(1160.0, 430.0)
	await physics_frame
	Input.action_press(&"skill_1")
	await physics_frame
	Input.action_release(&"skill_1")
	var wall_maximum_x := wall_player.global_position.x
	for _tick: int in range(30):
		await physics_frame
		wall_maximum_x = maxf(wall_maximum_x, wall_player.global_position.x)
	if wall_maximum_x <= 1160.0:
		errors.append("wall-bound linebreaker produced no forward motion")
	if wall_maximum_x > 1188.5:
		errors.append("linebreaker crossed the WorldStatic wall boundary")
	if wall_skill.is_active() or wall_player.is_action_motion_active():
		errors.append("wall collision left linebreaker motion active")
	wall_sandbox.free()
	return errors


func _test_linebreaker_cancel_sandbox() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for CMB-009 cancel test")
		return errors

	var skill_to_attack := sandbox_scene.instantiate()
	root.add_child(skill_to_attack)
	await physics_frame
	Input.action_release(&"attack")
	Input.action_release(&"skill_1")
	await physics_frame
	var first_skill := skill_to_attack.get(
		"linebreaker_skill"
	) as LinebreakerSkillModel
	var first_combo := skill_to_attack.get(
		"normal_attack_combo"
	) as NormalAttackComboModel
	var first_buffer := skill_to_attack.get("input_buffer") as InputBufferModel
	if first_buffer == null or not first_buffer.record_pressed(&"skill_1"):
		errors.append("sandbox input buffer rejected the linebreaker start fixture")
	await physics_frame
	var safety := 12
	while (
		first_skill != null
		and first_skill.is_active()
		and first_skill.timeline.action_tick < 3
		and safety > 0
	):
		await physics_frame
		safety -= 1
	if first_buffer == null or not first_buffer.record_pressed(&"attack"):
		errors.append("sandbox input buffer rejected the attack cancel fixture")
	safety = 20
	while first_skill != null and first_skill.is_active() and safety > 0:
		await physics_frame
		safety -= 1
	if (
		first_skill == null
		or first_skill.last_finish_reason != &"canceled"
		or first_skill.last_cancel_target != &"action.attack"
	):
		errors.append(
			"buffered attack did not cancel linebreaker: reason=%s target=%s active=%s tick=%d"
			% [
				String(first_skill.last_finish_reason) if first_skill != null else "null",
				String(first_skill.last_cancel_target) if first_skill != null else "null",
				str(first_skill.is_active()) if first_skill != null else "null",
				first_skill.timeline.action_tick if first_skill != null else -1,
			]
		)
	if (
		first_combo == null
		or first_combo.combo_index != 0
		or not first_combo.timeline.is_running
	):
		errors.append(
			"linebreaker attack cancel did not enter A1: index=%d running=%s tick=%d"
			% [
				first_combo.combo_index if first_combo != null else -99,
				str(first_combo.timeline.is_running) if first_combo != null else "null",
				first_combo.timeline.action_tick if first_combo != null else -1,
			]
		)
	skill_to_attack.free()
	await physics_frame

	var normal_to_skill := sandbox_scene.instantiate()
	root.add_child(normal_to_skill)
	await physics_frame
	Input.action_release(&"attack")
	Input.action_release(&"skill_1")
	await physics_frame
	var second_skill := normal_to_skill.get(
		"linebreaker_skill"
	) as LinebreakerSkillModel
	var second_combo := normal_to_skill.get(
		"normal_attack_combo"
	) as NormalAttackComboModel
	var second_buffer := normal_to_skill.get("input_buffer") as InputBufferModel
	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	safety = 20
	while (
		second_combo != null
		and second_combo.timeline.action_tick < 8
		and safety > 0
	):
		await physics_frame
		safety -= 1
	if not bool(normal_to_skill.get("_current_normal_attack_hit")):
		errors.append("A1 did not register the hit confirmation used by skill cancel")
	if second_buffer == null or not second_buffer.record_pressed(&"skill_1"):
		errors.append("sandbox input buffer rejected the skill cancel fixture")
	await physics_frame
	if second_skill == null or not second_skill.is_active():
		errors.append(
			"hit-confirmed A1 did not cancel into linebreaker: combo_index=%d combo_tick=%d hit=%s"
			% [
				second_combo.combo_index if second_combo != null else -99,
				second_combo.timeline.action_tick if second_combo != null else -1,
				str(normal_to_skill.get("_current_normal_attack_hit")),
			]
		)
	if second_combo == null or second_combo.last_finish_reason != &"canceled":
		errors.append("normal combo did not report its skill cancellation")
	normal_to_skill.free()
	return errors


func _load_hit_feedback_profiles() -> Array[HitFeedbackProfile]:
	var profiles: Array[HitFeedbackProfile] = []
	for path: String in [
		"res://data/combat/feedback_profiles/light.tres",
		"res://data/combat/feedback_profiles/medium.tres",
		"res://data/combat/feedback_profiles/heavy.tres",
		"res://data/combat/feedback_profiles/finisher.tres",
	]:
		var source := ResourceLoader.load(path) as HitFeedbackProfile
		if source == null:
			continue
		var snapshot := source.duplicate(true) as HitFeedbackProfile
		if snapshot != null:
			profiles.append(snapshot)
	return profiles


func _make_feedback_request(
	strength: StringName = &"light",
	hit_stop_ticks: int = 3,
	hit_id: StringName = &"hit.feedback.test",
	critical := false
) -> HitFeedbackRequest:
	return HitFeedbackRequestScript.new(
		1001,
		2001,
		&"attack.test.a1",
		hit_id,
		Vector2(320.0, 240.0),
		Vector2.RIGHT,
		88,
		critical,
		hit_stop_ticks,
		strength
	)


func _test_hit_feedback_profiles() -> PackedStringArray:
	var errors := PackedStringArray()
	var profiles := _load_hit_feedback_profiles()
	if profiles.size() != 4:
		errors.append("project did not load all four feedback profiles")
		return errors
	var expected := {
		&"light": Vector3i(2, 3, 1),
		&"medium": Vector3i(4, 5, 2),
		&"heavy": Vector3i(6, 8, 3),
		&"finisher": Vector3i(8, 10, 3),
	}
	for profile: HitFeedbackProfile in profiles:
		errors.append_array(profile.validation_errors())
		var key := profile.strength_key()
		if not expected.has(key):
			errors.append("unexpected feedback strength: %s" % String(key))
			continue
		var contract: Vector3i = expected[key]
		if (
			profile.minimum_hit_stop_ticks != contract.x
			or profile.maximum_hit_stop_ticks != contract.y
			or profile.sfx_layer_count != contract.z
		):
			errors.append("%s feedback budget changed" % String(key))
		if profile.camera_zoom_pulse > 0.03:
			errors.append("%s camera zoom exceeds the three-percent budget" % String(key))

	var attack := _make_test_attack()
	attack.hit_stop_ticks = 4
	if attack.validation_errors().is_empty():
		errors.append("light attack accepted hit stop above its three-tick budget")
	attack.feedback_strength = "medium"
	if not attack.validation_errors().is_empty():
		errors.append("medium attack rejected its four-tick lower boundary")
	attack.feedback_strength = "heavy"
	attack.hit_stop_ticks = 9
	if attack.validation_errors().is_empty():
		errors.append("heavy attack accepted hit stop above eight ticks")
	attack.feedback_strength = "finisher"
	attack.hit_stop_ticks = 10
	if not attack.validation_errors().is_empty():
		errors.append("finisher attack rejected its ten-tick upper boundary")

	var registry: DataRegistryService = DataRegistryScript.new()
	errors.append_array(registry.reload_definitions("res://data"))
	for profile: HitFeedbackProfile in profiles:
		if registry.get_definition(profile.definition_id) == null:
			errors.append("DataRegistry is missing %s" % String(profile.definition_id))
	registry.free()
	return errors


func _test_hit_feedback_request_snapshot() -> PackedStringArray:
	var errors := PackedStringArray()
	var contact := _make_hit_contact(2001, 7, &"hit.feedback.snapshot")
	var result := DamageResolverModelScript.new().resolve(_make_damage_packet(), 25.0)
	var request: HitFeedbackRequest = HitFeedbackRequestScript.from_outcome(
		contact,
		result,
		Vector2(480.0, 260.0),
		Vector2.LEFT
	)
	if request == null:
		errors.append("accepted HitResult did not create feedback request")
		return errors
	contact = null
	result = null
	if (
		request.source_instance_id != 1001
		or request.target_instance_id != 2001
		or request.attack_id != &"attack.test.a1"
		or request.hit_id != &"hit.feedback.snapshot"
		or request.world_position != Vector2(480.0, 260.0)
		or request.direction != Vector2.LEFT
		or request.final_damage != 88
		or request.hit_stop_ticks != 3
		or request.feedback_strength != &"light"
	):
		errors.append("feedback request did not preserve its immutable hit snapshot")
	errors.append_array(request.validation_errors())
	if HitFeedbackRequestScript.from_outcome(
		_make_hit_contact(2001),
		HitResultScript.rejected(&"test_rejection"),
		Vector2.ZERO,
		Vector2.RIGHT
	) != null:
		errors.append("rejected HitResult created a feedback request")
	var invalid: HitFeedbackRequest = HitFeedbackRequestScript.new(
		0,
		0,
		&"",
		&"",
		Vector2(NAN, INF),
		Vector2(2.0, 0.0),
		0,
		false,
		-1,
		&"unsupported"
	)
	if invalid.validation_errors().size() < 8:
		errors.append("feedback request did not reject its invalid boundaries")
	return errors


func _test_hit_feedback_channel_routing() -> PackedStringArray:
	var errors := PackedStringArray()
	var profiles := _load_hit_feedback_profiles()
	var service: HitFeedbackService = HitFeedbackServiceScript.new()
	service.auto_pause_tree = false
	errors.append_array(service.configure(profiles))
	var channels := {
		"hit_stop": 0,
		"camera": 0,
		"vfx": 0,
		"sfx": 0,
		"accepted": 0,
	}
	service.hit_stop_requested.connect(
		func(_requested_ticks: int, _active_ticks: int) -> void:
			channels["hit_stop"] = int(channels["hit_stop"]) + 1
	)
	service.camera_feedback_requested.connect(
		func(
			_world_position: Vector2,
			_shake_pixels: float,
			_duration_ticks: int,
			_zoom_pulse: float
		) -> void:
			channels["camera"] = int(channels["camera"]) + 1
	)
	service.vfx_feedback_requested.connect(
		func(
			_world_position: Vector2,
			_direction: Vector2,
			_style: StringName,
			_scale: float,
			_lifetime_ticks: int,
			_critical: bool
		) -> void:
			channels["vfx"] = int(channels["vfx"]) + 1
	)
	service.sfx_feedback_requested.connect(
		func(
			_world_position: Vector2,
			_cue: StringName,
			_layer_count: int,
			_critical: bool
		) -> void:
			channels["sfx"] = int(channels["sfx"]) + 1
	)
	service.feedback_accepted.connect(
		func(_request: HitFeedbackRequest, _profile: HitFeedbackProfile) -> void:
			channels["accepted"] = int(channels["accepted"]) + 1
	)
	errors.append_array(
		service.request_feedback(
			_make_feedback_request(&"medium", 4, &"hit.feedback.routing")
		)
	)
	for channel_name: String in channels:
		if int(channels[channel_name]) != 1:
			errors.append("%s feedback channel did not emit exactly once" % channel_name)
	if service.request_count != 1:
		errors.append("valid feedback request count was not recorded")

	var invalid_profiles: Array[HitFeedbackProfile] = [
		profiles[0],
		profiles[0],
		profiles[2],
		profiles[3],
	]
	if service.configure(invalid_profiles).is_empty():
		errors.append("duplicate and incomplete feedback configuration was accepted")
	if not service.has_profile(&"medium") or not service.is_configured():
		errors.append("invalid reconfiguration replaced the valid profile table")
	if service.request_feedback(null).is_empty() or service.request_count != 1:
		errors.append("null feedback request was accepted or changed runtime state")
	service.free()
	return errors


func _test_hit_feedback_hit_stop_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var service: HitFeedbackService = HitFeedbackServiceScript.new()
	service.auto_pause_tree = false
	errors.append_array(service.configure(_load_hit_feedback_profiles()))
	var finish_count := [0]
	service.hit_stop_finished.connect(
		func() -> void: finish_count[0] = int(finish_count[0]) + 1
	)
	service.request_feedback(_make_feedback_request(&"light", 3, &"hit.stop.light"))
	if service.hit_stop_ticks_remaining != 3:
		errors.append("light hit stop did not start at three ticks")
	if not service.advance_feedback_tick() or service.hit_stop_ticks_remaining != 2:
		errors.append("first light hit-stop tick did not advance to two")
	service.request_feedback(_make_feedback_request(&"medium", 4, &"hit.stop.medium"))
	service.request_feedback(_make_feedback_request(&"light", 3, &"hit.stop.overlap"))
	if service.hit_stop_ticks_remaining != 4:
		errors.append("overlapping hit stops were summed or failed to take the maximum")
	for expected_remaining: int in [3, 2, 1, 0]:
		if not service.advance_feedback_tick():
			errors.append("active hit stop ended before its exact boundary")
			break
		if service.hit_stop_ticks_remaining != expected_remaining:
			errors.append("hit stop remaining tick boundary was incorrect")
			break
	if service.advance_feedback_tick():
		errors.append("hit stop remained active after reaching zero")
	if int(finish_count[0]) != 1:
		errors.append("hit stop completion did not emit exactly once")
	service.free()
	return errors


func _test_hit_feedback_camera_merging() -> PackedStringArray:
	var errors := PackedStringArray()
	var service: HitFeedbackService = HitFeedbackServiceScript.new()
	service.auto_pause_tree = false
	errors.append_array(service.configure(_load_hit_feedback_profiles()))
	service.request_feedback(_make_feedback_request(&"light", 3, &"camera.light"))
	if (
		not is_equal_approx(service.camera_shake_pixels, 0.6)
		or service.camera_ticks_remaining != 2
	):
		errors.append("light camera feedback did not use its profile")
	service.request_feedback(_make_feedback_request(&"medium", 4, &"camera.medium"))
	if (
		not is_equal_approx(service.camera_shake_pixels, 2.2)
		or service.camera_ticks_remaining != 6
	):
		errors.append("medium camera feedback did not take max strength plus one extension")
	service.request_feedback(_make_feedback_request(&"light", 3, &"camera.weaker"))
	if (
		not is_equal_approx(service.camera_shake_pixels, 2.2)
		or service.camera_ticks_remaining != 7
	):
		errors.append("weaker overlap summed strength or failed bounded extension")
	service.request_feedback(_make_feedback_request(&"heavy", 8, &"camera.heavy"))
	if (
		not is_equal_approx(service.camera_shake_pixels, 4.0)
		or service.camera_ticks_remaining != 10
	):
		errors.append("heavy overlap did not replace amplitude without summing")
	for index: int in range(20):
		service.request_feedback(
			_make_feedback_request(
				&"finisher",
				10,
				StringName("camera.finisher.%d" % index)
			)
		)
	if (
		service.camera_ticks_remaining != HitFeedbackService.MAX_CAMERA_FEEDBACK_TICKS
		or not is_equal_approx(service.camera_shake_pixels, 5.0)
		or not is_equal_approx(service.camera_zoom_pulse, 0.03)
	):
		errors.append("camera overlap exceeded its duration, amplitude, or zoom cap")
	for _tick: int in range(HitFeedbackService.MAX_CAMERA_FEEDBACK_TICKS):
		service.advance_feedback_tick()
	if (
		service.camera_ticks_remaining != 0
		or not is_zero_approx(service.camera_shake_pixels)
		or not is_zero_approx(service.camera_zoom_pulse)
	):
		errors.append("camera feedback did not return to a neutral state")
	service.free()
	return errors


func _test_hit_feedback_determinism_and_lifecycle() -> PackedStringArray:
	var errors := PackedStringArray()
	var profiles := _load_hit_feedback_profiles()
	var first: HitFeedbackService = HitFeedbackServiceScript.new()
	var second: HitFeedbackService = HitFeedbackServiceScript.new()
	first.auto_pause_tree = false
	second.auto_pause_tree = false
	errors.append_array(first.configure(profiles))
	errors.append_array(second.configure(profiles))
	var first_samples: Array[Vector3] = []
	var second_samples: Array[Vector3] = []
	first.camera_state_changed.connect(
		func(offset: Vector2, zoom_scale: float) -> void:
			first_samples.append(Vector3(offset.x, offset.y, zoom_scale))
	)
	second.camera_state_changed.connect(
		func(offset: Vector2, zoom_scale: float) -> void:
			second_samples.append(Vector3(offset.x, offset.y, zoom_scale))
	)
	var request := _make_feedback_request(&"heavy", 8, &"feedback.deterministic")
	first.request_feedback(request)
	second.request_feedback(request)
	for _tick: int in range(12):
		first.advance_feedback_tick()
		second.advance_feedback_tick()
	if first_samples != second_samples:
		errors.append("identical fixed-tick feedback inputs produced different camera samples")
	profiles[0].camera_shake_pixels = 20.0
	if (
		not is_equal_approx(first.profile_for(&"light").camera_shake_pixels, 0.6)
		or not is_equal_approx(second.profile_for(&"light").camera_shake_pixels, 0.6)
	):
		errors.append("configured services retained mutable source profiles")
	var weak_first: WeakRef = weakref(first)
	var weak_second: WeakRef = weakref(second)
	first.free()
	second.free()
	first = null
	second = null
	if weak_first.get_ref() != null or weak_second.get_ref() != null:
		errors.append("released feedback services remained alive")
	return errors


func _test_hit_feedback_sandbox() -> PackedStringArray:
	var errors := PackedStringArray()
	var sandbox_scene := ResourceLoader.load(
		"res://scenes/tests/movement_sandbox.tscn"
	) as PackedScene
	if sandbox_scene == null:
		errors.append("movement sandbox could not load for CMB-010 integration")
		return errors
	var sandbox := sandbox_scene.instantiate()
	root.add_child(sandbox)
	await physics_frame
	var service := sandbox.get_node_or_null("HitFeedbackService") as HitFeedbackService
	var presenter := sandbox.get_node_or_null(
		"HitFeedbackPresenter"
	) as HitFeedbackPresenter
	var camera := sandbox.get_node_or_null("CombatCamera") as Camera2D
	if service == null or presenter == null or camera == null:
		errors.append("sandbox is missing feedback service, presenter, or camera")
		sandbox.free()
		paused = false
		return errors
	Input.action_release(&"attack")
	await physics_frame
	Input.action_press(&"attack")
	await physics_frame
	Input.action_release(&"attack")
	var safety := 60
	var saw_hit_stop_pause := paused
	while service.request_count < 2 and safety > 0:
		await physics_frame
		saw_hit_stop_pause = saw_hit_stop_pause or paused
		safety -= 1
	if service.request_count != 2:
		errors.append("A1 multi-target hit did not emit two feedback requests")
	while service.hit_stop_ticks_remaining > 0 and safety > 0:
		await physics_frame
		saw_hit_stop_pause = saw_hit_stop_pause or paused
		safety -= 1
	await physics_frame
	if not saw_hit_stop_pause:
		errors.append("sandbox hit stop never paused the scene tree")
	if paused:
		errors.append("sandbox hit stop did not restore the running scene")
	if presenter.vfx_request_count != 2 or presenter.sfx_request_count != 2:
		errors.append("presenter did not receive independent VFX and SFX requests")
	while service.camera_ticks_remaining > 0 and safety > 0:
		await physics_frame
		safety -= 1
	if camera.offset != Vector2.ZERO or camera.zoom != Vector2.ONE:
		errors.append("combat camera did not return to its neutral transform")

	service.request_feedback(
		_make_feedback_request(&"light", 3, &"feedback.release.active")
	)
	if not paused:
		errors.append("direct active hit stop did not acquire the tree pause")
	sandbox.free()
	if paused:
		errors.append("freeing the room left its hit-stop pause active")
		paused = false
	return errors


func _make_damage_packet(
	attack: AttackDefinition = null,
	new_base_attack: float = 100.0,
	new_crit_chance: float = 0.05,
	new_crit_damage_multiplier: float = 1.5,
	new_critical_roll: float = 0.5,
	new_direction: Vector2 = Vector2.RIGHT,
	new_source_instance_id: int = 3001
) -> DamagePacket:
	var source_attack := attack if attack != null else _make_test_attack()
	return DamagePacketScript.from_attack(
		new_source_instance_id,
		source_attack,
		new_base_attack,
		new_crit_chance,
		new_crit_damage_multiplier,
		new_critical_roll,
		new_direction
	)


func _test_attack_damage_profile() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	errors.append_array(attack.validation_errors())
	if (
		not is_equal_approx(attack.damage_coefficient, 1.0)
		or not is_equal_approx(attack.flat_damage, 10.0)
		or not is_equal_approx(attack.poise_damage, 12.0)
	):
		errors.append("test attack damage numbers do not match the A1 baseline")
	if attack.hit_tags != [&"damage.physical", &"attack.normal"]:
		errors.append("test attack hit tags do not match the A1 baseline")
	if attack.launch_profile != &"none" or attack.feedback_strength != "light":
		errors.append("test attack launch or feedback profile is invalid")

	attack.damage_coefficient = -0.01
	if attack.validation_errors().is_empty():
		errors.append("negative damage coefficient was accepted")
	attack.damage_coefficient = 1.0
	attack.flat_damage = -1.0
	if attack.validation_errors().is_empty():
		errors.append("negative flat damage was accepted")
	attack.flat_damage = 10.0
	attack.poise_damage = -1.0
	if attack.validation_errors().is_empty():
		errors.append("negative poise damage was accepted")
	attack.poise_damage = 12.0
	attack.hit_tags = [&"damage.physical", &"damage.physical"]
	if attack.validation_errors().is_empty():
		errors.append("duplicate hit tags were accepted")
	attack.hit_tags = [&"damage.physical"]
	attack.launch_profile = &""
	if attack.validation_errors().is_empty():
		errors.append("empty launch profile was accepted")
	attack.launch_profile = &"none"
	attack.feedback_strength = "invalid"
	if attack.validation_errors().is_empty():
		errors.append("unsupported feedback strength was accepted")
	return errors


func _test_damage_packet_snapshot() -> PackedStringArray:
	var errors := PackedStringArray()
	var attack := _make_test_attack()
	var packet := _make_damage_packet(attack)
	if packet == null:
		errors.append("valid AttackDefinition did not create a DamagePacket")
		return errors
	errors.append_array(packet.validation_errors())
	attack.damage_coefficient = 9.0
	attack.flat_damage = 999.0
	attack.poise_damage = 999.0
	attack.hit_tags.append(&"mutated.after_snapshot")
	attack.feedback_strength = "heavy"
	var exposed_tags := packet.hit_tags
	exposed_tags.append("mutated.from_getter")
	if (
		not is_equal_approx(packet.coefficient, 1.0)
		or not is_equal_approx(packet.flat_damage, 10.0)
		or not is_equal_approx(packet.poise_damage, 12.0)
		or packet.feedback_strength != &"light"
		or packet.hit_tags != PackedStringArray(["damage.physical", "attack.normal"])
	):
		errors.append("DamagePacket changed after its source or returned tags were mutated")
	if packet.direction != Vector2.RIGHT or packet.launch_profile != &"none":
		errors.append("DamagePacket did not snapshot direction or launch profile")

	var invalid_packet: DamagePacket = DamagePacketScript.new(
		0,
		&"",
		-1.0,
		-1.0,
		-1.0,
		-1.0,
		PackedStringArray(["", ""]),
		Vector2(2.0, 0.0),
		&"",
		-1.0,
		0.5,
		1.0,
		-1,
		&"invalid"
	)
	if invalid_packet.validation_errors().size() < 10:
		errors.append("DamagePacket did not reject its invalid field boundaries")
	if DamagePacketScript.from_attack(3001, null, 100.0, 0.05, 1.5, 0.5, Vector2.RIGHT) != null:
		errors.append("null AttackDefinition created a DamagePacket")
	return errors


func _test_damage_formula_baseline() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var packet := _make_damage_packet()
	var result := resolver.resolve(packet, 25.0)
	if not result.accepted:
		errors.append("valid baseline damage was rejected")
	elif (
		not is_equal_approx(result.raw_damage, 110.0)
		or not is_equal_approx(result.defense_multiplier, 0.8)
		or result.final_damage != 88
		or result.critical
	):
		errors.append("100 attack + 10 flat against 25 defense did not resolve to 88")
	errors.append_array(result.validation_errors())

	var rounding_attack := _make_test_attack()
	rounding_attack.damage_coefficient = 0.0
	rounding_attack.flat_damage = 10.49
	var rounded_down := resolver.resolve(_make_damage_packet(rounding_attack), 0.0)
	if rounded_down.final_damage != 10:
		errors.append("10.49 damage did not round down to 10")
	rounding_attack.flat_damage = 10.51
	var rounded_up := resolver.resolve(_make_damage_packet(rounding_attack), 0.0)
	if rounded_up.final_damage != 11:
		errors.append("10.51 damage did not round up to 11")

	var minimum_attack := _make_test_attack()
	minimum_attack.damage_coefficient = 0.0
	minimum_attack.flat_damage = 0.0
	var minimum_result := resolver.resolve(
		_make_damage_packet(minimum_attack, 0.0),
		1000000000.0,
		PackedFloat64Array([0.0])
	)
	if minimum_result.final_damage != 1:
		errors.append("formula did not enforce the one-damage minimum")
	return errors


func _test_damage_defense_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var packet := _make_damage_packet()
	var negative_defense := resolver.resolve(packet, -250.0)
	var zero_defense := resolver.resolve(packet, 0.0)
	var equal_defense := resolver.resolve(packet, 100.0)
	var huge_defense := resolver.resolve(packet, 1000000000.0)
	if negative_defense.final_damage != 110 or zero_defense.final_damage != 110:
		errors.append("negative defense was not clamped to the zero-defense result")
	if equal_defense.final_damage != 55:
		errors.append("100 defense did not produce the expected 0.5 multiplier")
	if huge_defense.final_damage != 1:
		errors.append("very large defense bypassed the one-damage minimum")
	for invalid_defense: float in [NAN, INF, -INF]:
		var rejected := resolver.resolve(packet, invalid_defense)
		if (
			rejected.accepted
			or rejected.rejection_code != DamageResolverModel.REJECTION_INVALID_DEFENSE
		):
			errors.append("non-finite defense did not return invalid_defense")
	return errors


func _test_damage_critical_boundaries() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	if (
		not is_equal_approx(DamageResolverModel.DEFAULT_CRIT_CHANCE, 0.05)
		or not is_equal_approx(DamageResolverModel.MAX_CRIT_CHANCE, 0.60)
		or not is_equal_approx(DamageResolverModel.DEFAULT_CRIT_DAMAGE_MULTIPLIER, 1.5)
	):
		errors.append("documented default critical constants changed")
	var inside_default := resolver.resolve(
		_make_damage_packet(null, 100.0, 0.05, 1.5, 0.049999),
		0.0
	)
	var at_default_end := resolver.resolve(
		_make_damage_packet(null, 100.0, 0.05, 1.5, 0.05),
		0.0
	)
	if not inside_default.critical or inside_default.final_damage != 165:
		errors.append("critical roll inside the default 5 percent window did not crit")
	if at_default_end.critical or at_default_end.final_damage != 110:
		errors.append("critical roll at the exclusive 5 percent boundary crit")
	var inside_cap := resolver.resolve(
		_make_damage_packet(null, 100.0, 0.95, 1.5, 0.599999),
		0.0
	)
	var at_cap_end := resolver.resolve(
		_make_damage_packet(null, 100.0, 0.95, 1.5, 0.60),
		0.0
	)
	if not inside_cap.critical or not is_equal_approx(inside_cap.effective_crit_chance, 0.60):
		errors.append("critical chance above 60 percent did not clamp to the cap")
	if at_cap_end.critical or not is_equal_approx(at_cap_end.effective_crit_chance, 0.60):
		errors.append("critical roll at the exclusive 60 percent cap boundary crit")
	return errors


func _test_damage_modifiers_and_rejections() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var packet := _make_damage_packet()
	var combined := resolver.resolve(
		packet,
		0.0,
		PackedFloat64Array([1.25, 0.8])
	)
	if combined.final_damage != 110 or not is_equal_approx(combined.damage_modifier, 1.0):
		errors.append("ordered damage modifiers did not combine multiplicatively")
	if (
		not is_equal_approx(combined.poise_damage, 12.0)
		or combined.broke_poise
		or combined.reaction_type != &"none"
		or combined.knockback != Vector2.ZERO
		or combined.hit_stop_ticks != 3
		or combined.feedback_strength != &"light"
	):
		errors.append("HitResult did not carry deferred CMB-005/010 outcome fields")
	errors.append_array(combined.validation_errors())
	var zero_modifier := resolver.resolve(packet, 0.0, PackedFloat64Array([0.0]))
	if zero_modifier.final_damage != 1:
		errors.append("zero damage modifier bypassed the documented minimum")
	for invalid_modifier: float in [-0.01, NAN, INF]:
		var rejected := resolver.resolve(
			packet,
			0.0,
			PackedFloat64Array([invalid_modifier])
		)
		if (
			rejected.accepted
			or rejected.rejection_code != DamageResolverModel.REJECTION_INVALID_MODIFIER
			or not rejected.validation_errors().is_empty()
		):
			errors.append("invalid modifier did not produce a valid rejected HitResult")
	var null_result := resolver.resolve(null, 0.0)
	if (
		null_result.accepted
		or null_result.rejection_code != DamageResolverModel.REJECTION_INVALID_PACKET
	):
		errors.append("null packet did not return invalid_packet")
	return errors


func _test_damage_determinism_and_lifecycle() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var packet := _make_damage_packet(null, 100.0, 0.60, 1.5, 0.25)
	var first_result := resolver.resolve(packet, 25.0, PackedFloat64Array([0.9]))
	for simulated_frame: int in range(240):
		var ignored_delta := 1.0 / 30.0 if simulated_frame % 2 == 0 else 1.0 / 144.0
		if ignored_delta <= 0.0:
			errors.append("invalid simulated frame delta")
		var repeated := resolver.resolve(packet, 25.0, PackedFloat64Array([0.9]))
		if (
			repeated.final_damage != first_result.final_damage
			or repeated.critical != first_result.critical
		):
			errors.append("same immutable inputs produced different damage across frames")
			break
	var defense_order_a := PackedFloat64Array([100.0, 25.0])
	var defense_order_b := PackedFloat64Array([25.0, 100.0])
	var results_a := PackedInt32Array()
	var results_b := PackedInt32Array()
	for defense: float in defense_order_a:
		results_a.append(resolver.resolve(packet, defense).final_damage)
	for defense: float in defense_order_b:
		results_b.append(resolver.resolve(packet, defense).final_damage)
	if results_a != PackedInt32Array([83, 132]) or results_b != PackedInt32Array([132, 83]):
		errors.append("multi-target formulas depended on resolution order")

	var weak_resolver: WeakRef = weakref(resolver)
	var weak_packet: WeakRef = weakref(packet)
	var weak_result: WeakRef = weakref(first_result)
	resolver = null
	packet = null
	first_result = null
	if (
		weak_resolver.get_ref() != null
		or weak_packet.get_ref() != null
		or weak_result.get_ref() != null
	):
		errors.append("released damage formula objects remained alive")
	return errors


func _load_reaction_profile(strategy: StringName) -> CombatReactionProfile:
	var path := ""
	match strategy:
		&"normal":
			path = "res://data/combat/reaction_profiles/normal.tres"
		&"elite":
			path = "res://data/combat/reaction_profiles/elite.tres"
		&"boss":
			path = "res://data/combat/reaction_profiles/boss.tres"
	if path.is_empty():
		return null
	return ResourceLoader.load(path) as CombatReactionProfile


func _load_launch_profile(profile_name: StringName) -> CombatLaunchProfile:
	var path := ""
	match profile_name:
		&"launcher":
			path = "res://data/combat/launch_profiles/dev_launcher.tres"
		&"ground_pursuit":
			path = "res://data/combat/launch_profiles/dev_ground_pursuit.tres"
	if path.is_empty():
		return null
	return ResourceLoader.load(path) as CombatLaunchProfile


func _make_control_attack(
	launch_profile_id: StringName,
	new_poise_damage: float = 0.0,
	new_flat_damage: float = 0.0
) -> AttackDefinition:
	var attack := _make_test_attack()
	attack.definition_id = &"attack.test.control"
	attack.display_name_key = &"attack.test.control.name"
	attack.damage_coefficient = 0.0
	attack.flat_damage = new_flat_damage
	attack.poise_damage = new_poise_damage
	attack.hit_tags = [&"damage.physical", &"control.test"]
	attack.launch_profile = launch_profile_id
	return attack


func _make_control_packet(
	launch_profile_id: StringName,
	new_poise_damage: float = 0.0,
	new_flat_damage: float = 0.0
) -> DamagePacket:
	return _make_damage_packet(
		_make_control_attack(launch_profile_id, new_poise_damage, new_flat_damage)
	)


func _make_combatant(
	profile: CombatReactionProfile,
	new_instance_id: int,
	new_maximum_health: int = 500,
	new_maximum_poise: float = 24.0,
	new_defense: float = 25.0
) -> CombatantModel:
	var combatant: CombatantModel = CombatantModelScript.new()
	combatant.configure(
		new_instance_id,
		&"enemy",
		new_maximum_health,
		new_maximum_poise,
		new_defense,
		profile
	)
	return combatant


func _test_combat_reaction_profiles() -> PackedStringArray:
	var errors := PackedStringArray()
	var expected := {
		&"normal": &"combat.reaction.normal",
		&"elite": &"combat.reaction.elite",
		&"boss": &"combat.reaction.boss",
	}
	for strategy: StringName in expected:
		var profile := _load_reaction_profile(strategy)
		if profile == null:
			errors.append("%s reaction profile did not load" % String(strategy))
			continue
		errors.append_array(profile.validation_errors())
		if (
			profile.definition_kind() != &"combat_reaction_profile"
			or profile.definition_id != expected[strategy]
			or StringName(profile.strategy) != strategy
		):
			errors.append("%s reaction profile identity is incorrect" % String(strategy))
	var boss := _load_reaction_profile(&"boss")
	if boss == null or not boss.forced_break_tags.has(&"reaction.boss_break"):
		errors.append("boss profile does not declare its explicit break tag")

	var invalid := _load_reaction_profile(&"normal").duplicate(true) as CombatReactionProfile
	invalid.strategy = "unsupported"
	invalid.hit_reaction_ticks = 0
	invalid.break_duration_ticks = 0
	invalid.post_break_poise_damage_multiplier = 1.1
	invalid.forced_break_tags = [&"", &"reaction.repeat", &"reaction.repeat"]
	if invalid.validation_errors().size() < 5:
		errors.append("reaction profile did not reject its invalid boundaries")

	var registry: DataRegistryService = DataRegistryScript.new()
	errors.append_array(registry.reload_definitions("res://data"))
	if registry.definition_count() != 15:
		errors.append("DataRegistry did not index all fifteen project definitions")
	for definition_id: StringName in expected.values():
		if not registry.has_definition(definition_id):
			errors.append("DataRegistry is missing %s" % String(definition_id))
	registry.free()
	return errors


func _test_combat_launch_profiles() -> PackedStringArray:
	var errors := PackedStringArray()
	var launcher := _load_launch_profile(&"launcher")
	var pursuit := _load_launch_profile(&"ground_pursuit")
	if launcher == null or pursuit == null:
		errors.append("project launch profiles did not load")
		return errors
	errors.append_array(launcher.validation_errors())
	errors.append_array(pursuit.validation_errors())
	if (
		launcher.definition_kind() != &"combat_launch_profile"
		or launcher.definition_id != &"combat.launch.dev_launcher"
		or not is_equal_approx(launcher.upward_velocity, 720.0)
		or launcher.can_hit_downed
	):
		errors.append("launcher profile identity or baseline is incorrect")
	if (
		pursuit.definition_id != &"combat.launch.dev_ground_pursuit"
		or not is_zero_approx(pursuit.upward_velocity)
		or not pursuit.can_hit_downed
	):
		errors.append("ground-pursuit profile identity or baseline is incorrect")

	var invalid: CombatLaunchProfile = CombatLaunchProfileScript.new()
	invalid.definition_id = &"combat.launch.invalid"
	invalid.display_name_key = &"combat.launch.invalid.name"
	invalid.upward_velocity = NAN
	invalid.can_hit_downed = false
	if invalid.validation_errors().is_empty():
		errors.append("launch profile accepted a non-finite velocity")
	invalid.upward_velocity = 0.0
	if invalid.validation_errors().is_empty():
		errors.append("launch profile accepted an inert configuration")

	var registry: DataRegistryService = DataRegistryScript.new()
	errors.append_array(registry.reload_definitions("res://data"))
	for definition_id: StringName in [
		&"combat.launch.dev_launcher",
		&"combat.launch.dev_ground_pursuit",
		&"attack.dev.launcher_placeholder",
	]:
		if not registry.has_definition(definition_id):
			errors.append("DataRegistry is missing %s" % String(definition_id))
	registry.free()
	return errors


func _test_normal_combatant_reaction() -> PackedStringArray:
	var errors := PackedStringArray()
	var normal := _make_combatant(_load_reaction_profile(&"normal"), 4001, 300, 24.0, 25.0)
	errors.append_array(normal.validation_errors())
	var health_events: Array[Vector2i] = []
	normal.health_changed.connect(
		func(previous_health: int, current_health: int) -> void:
			health_events.append(Vector2i(previous_health, current_health))
	)
	var packet := _make_damage_packet()
	var resolved := DamageResolverModelScript.new().resolve(packet, normal.defense)
	var applied := normal.apply_damage(packet, resolved)
	if (
		not applied.accepted
		or normal.current_health != 212
		or not is_equal_approx(normal.current_poise, 12.0)
		or applied.reaction_type != CombatantModel.REACTION_HIT_STUN
		or applied.broke_poise
		or applied.knockback != Vector2(16.0, 0.0)
	):
		errors.append("normal strategy did not apply an immediate hit reaction")
	if health_events != [Vector2i(300, 212)]:
		errors.append("normal health change signal did not contain the exact transition")
	if normal.poise_recovery_delay_ticks_remaining != 180:
		errors.append("poise damage did not start the documented 180-tick delay")
	for _tick: int in range(11):
		normal.advance_tick()
	if normal.reaction_type != CombatantModel.REACTION_HIT_STUN or normal.reaction_ticks_remaining != 1:
		errors.append("normal hit reaction ended before its configured boundary")
	normal.advance_tick()
	if normal.reaction_type != CombatantModel.REACTION_NONE or normal.reaction_ticks_remaining != 0:
		errors.append("normal hit reaction did not end on its configured tick")
	errors.append_array(applied.validation_errors())
	return errors


func _test_elite_combatant_reaction() -> PackedStringArray:
	var errors := PackedStringArray()
	var elite := _make_combatant(_load_reaction_profile(&"elite"), 4002, 400, 24.0, 25.0)
	var packet := _make_damage_packet()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var first := elite.apply_damage(packet, resolver.resolve(packet, elite.defense))
	if (
		elite.current_health != 312
		or not is_equal_approx(elite.current_poise, 12.0)
		or first.reaction_type != CombatantModel.REACTION_NONE
		or first.knockback != Vector2.ZERO
		or first.broke_poise
	):
		errors.append("elite reacted before its poise was depleted")
	var break_events: Array[int] = []
	elite.poise_broken.connect(
		func(duration_ticks: int) -> void:
			break_events.append(duration_ticks)
	)
	var second := elite.apply_damage(packet, resolver.resolve(packet, elite.defense))
	if (
		elite.current_health != 224
		or not elite.is_broken
		or not is_zero_approx(elite.current_poise)
		or not second.broke_poise
		or second.reaction_type != CombatantModel.REACTION_POISE_BREAK
		or second.knockback != Vector2(32.0, 0.0)
		or elite.reaction_ticks_remaining != 90
	):
		errors.append("elite did not enter its configured break after zero poise")
	if break_events != [90]:
		errors.append("elite break signal was not emitted exactly once with 90 ticks")
	return errors


func _test_boss_combatant_reaction() -> PackedStringArray:
	var errors := PackedStringArray()
	var boss := _make_combatant(_load_reaction_profile(&"boss"), 4003, 600, 36.0, 0.0)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var ordinary_packet := _make_damage_packet()
	var ordinary := boss.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, boss.defense)
	)
	if (
		ordinary.reaction_type != CombatantModel.REACTION_NONE
		or ordinary.broke_poise
		or not is_equal_approx(boss.current_poise, 24.0)
	):
		errors.append("ordinary hit interrupted a boss before a break condition")

	var special_attack := _make_test_attack()
	special_attack.hit_tags.append(&"reaction.boss_break")
	var special_packet := _make_damage_packet(special_attack)
	var special := boss.apply_damage(
		special_packet,
		resolver.resolve(special_packet, boss.defense)
	)
	if (
		not special.broke_poise
		or special.reaction_type != CombatantModel.REACTION_POISE_BREAK
		or not boss.is_broken
		or boss.reaction_ticks_remaining != 60
		or not is_zero_approx(boss.current_poise)
	):
		errors.append("declared boss-break tag did not force the configured short break")

	var depleted_boss := _make_combatant(
		_load_reaction_profile(&"boss"), 4004, 600, 24.0, 0.0
	)
	depleted_boss.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, depleted_boss.defense)
	)
	var depletion_break := depleted_boss.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, depleted_boss.defense)
	)
	if not depletion_break.broke_poise or not depleted_boss.is_broken:
		errors.append("zero poise did not break a boss without the special tag")
	return errors


func _test_break_recovery_and_protection() -> PackedStringArray:
	var errors := PackedStringArray()
	var elite := _make_combatant(_load_reaction_profile(&"elite"), 4005, 1000, 12.0, 0.0)
	var packet := _make_damage_packet()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var broken := elite.apply_damage(packet, resolver.resolve(packet, elite.defense))
	if not broken.broke_poise or elite.reaction_ticks_remaining != 90:
		errors.append("break fixture did not start at 90 ticks")
	for _tick: int in range(89):
		elite.advance_tick()
	if not elite.is_broken or elite.reaction_ticks_remaining != 1:
		errors.append("break ended before the last configured tick")
	elite.advance_tick()
	if (
		elite.is_broken
		or elite.reaction_type != CombatantModel.REACTION_NONE
		or not is_equal_approx(elite.current_poise, 12.0)
		or elite.post_break_protection_ticks_remaining != 60
	):
		errors.append("break did not refill poise and start 60 protection ticks")

	var protected_hit := elite.apply_damage(packet, resolver.resolve(packet, elite.defense))
	if (
		not is_equal_approx(protected_hit.poise_damage, 6.0)
		or not is_equal_approx(elite.current_poise, 6.0)
		or protected_hit.broke_poise
	):
		errors.append("post-break protection did not halve elite poise damage")
	for _tick: int in range(59):
		elite.advance_tick()
	if elite.post_break_protection_ticks_remaining != 1:
		errors.append("post-break protection ended one tick early")
	elite.advance_tick()
	if elite.post_break_protection_ticks_remaining != 0:
		errors.append("post-break protection did not end on tick 60")
	errors.append_array(protected_hit.validation_errors())
	return errors


func _test_poise_recovery_boundary() -> PackedStringArray:
	var errors := PackedStringArray()
	var normal := _make_combatant(_load_reaction_profile(&"normal"), 4006, 1000, 36.0, 0.0)
	var packet := _make_damage_packet()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	normal.apply_damage(packet, resolver.resolve(packet, normal.defense))
	for _paused_frame: int in range(240):
		var ignored_delta := 1.0 / 30.0 if _paused_frame % 2 == 0 else 1.0 / 144.0
		if ignored_delta <= 0.0:
			errors.append("pause fixture produced an invalid delta")
	if (
		normal.poise_recovery_delay_ticks_remaining != 180
		or not is_equal_approx(normal.current_poise, 24.0)
	):
		errors.append("poise changed without an explicit fixed-tick advance")
	for _tick: int in range(179):
		normal.advance_tick()
	if (
		normal.poise_recovery_delay_ticks_remaining != 1
		or not is_equal_approx(normal.current_poise, 24.0)
	):
		errors.append("poise regeneration began before three seconds")
	normal.advance_tick()
	if (
		normal.poise_recovery_delay_ticks_remaining != 0
		or not is_equal_approx(normal.current_poise, 25.0)
	):
		errors.append("poise regeneration did not begin on tick 180")
	for _tick: int in range(11):
		normal.advance_tick()
	if not is_equal_approx(normal.current_poise, normal.maximum_poise):
		errors.append("poise recovery did not clamp at the configured maximum")
	return errors


func _test_combatant_defeat_and_healing() -> PackedStringArray:
	var errors := PackedStringArray()
	var combatant := _make_combatant(_load_reaction_profile(&"normal"), 4007, 88, 24.0, 25.0)
	var defeat_events: Array[int] = []
	combatant.defeated.connect(func() -> void: defeat_events.append(1))
	var packet := _make_damage_packet()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var applied := combatant.apply_damage(packet, resolver.resolve(packet, combatant.defense))
	if (
		not applied.accepted
		or combatant.current_health != 0
		or not combatant.is_defeated
		or combatant.can_receive_hit()
		or applied.reaction_type != CombatantModel.REACTION_DEFEATED
		or not is_zero_approx(applied.poise_damage)
		or applied.broke_poise
	):
		errors.append("lethal damage did not enter the terminal defeated state")
	var rejected := combatant.apply_damage(packet, resolver.resolve(packet, combatant.defense))
	if (
		rejected.accepted
		or rejected.rejection_code != CombatantModel.REJECTION_TARGET_DEFEATED
		or defeat_events.size() != 1
		or combatant.heal(100) != 0
	):
		errors.append("defeated combatant accepted another hit, heal, or duplicate signal")
	if not applied.validation_errors().is_empty() or not rejected.validation_errors().is_empty():
		errors.append("defeat outcomes did not produce valid HitResult objects")

	var heal_target := _make_combatant(_load_reaction_profile(&"normal"), 4008, 100, 24.0, 25.0)
	heal_target.apply_damage(packet, resolver.resolve(packet, heal_target.defense))
	if heal_target.current_health != 12 or heal_target.heal(100) != 88:
		errors.append("healing did not return the exact clamped restored amount")
	if heal_target.current_health != 100 or heal_target.heal(0) != 0:
		errors.append("healing did not clamp at maximum health")
	return errors


func _test_combatant_determinism_and_lifecycle() -> PackedStringArray:
	var errors := PackedStringArray()
	var source_profile := _load_reaction_profile(&"normal").duplicate(true) as CombatReactionProfile
	var combatant := _make_combatant(source_profile, 4009, 500, 24.0, 25.0)
	source_profile.react_on_health_hit = false
	source_profile.hit_reaction_ticks = 0
	var packet := _make_damage_packet()
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var snapshot_outcome := combatant.apply_damage(
		packet,
		resolver.resolve(packet, combatant.defense)
	)
	if snapshot_outcome.reaction_type != CombatantModel.REACTION_HIT_STUN:
		errors.append("combatant reaction profile changed after its source was mutated")

	var previous_instance_id := combatant.instance_id
	var previous_health := combatant.current_health
	var invalid_profile := _load_reaction_profile(&"elite").duplicate(true) as CombatReactionProfile
	invalid_profile.strategy = "invalid"
	var invalid_configuration := combatant.configure(
		0, &"neutral", 0, NAN, INF, invalid_profile
	)
	if invalid_configuration.size() < 6:
		errors.append("invalid combatant configuration did not report its boundaries")
	if combatant.instance_id != previous_instance_id or combatant.current_health != previous_health:
		errors.append("invalid combatant configuration partially changed live state")

	var mismatched := resolver.resolve(packet, combatant.defense).with_application_outcome(
		5.0, false, CombatantModel.REACTION_NONE, Vector2.ZERO
	)
	var mismatched_rejection := combatant.apply_damage(packet, mismatched)
	if (
		mismatched_rejection.accepted
		or mismatched_rejection.rejection_code != CombatantModel.REJECTION_INVALID_RESULT
		or combatant.current_health != previous_health
	):
		errors.append("mismatched packet/result mutated combatant state")

	var model_a := _make_combatant(_load_reaction_profile(&"normal"), 4010, 2000, 24.0, 25.0)
	var model_b := _make_combatant(_load_reaction_profile(&"normal"), 4011, 2000, 24.0, 25.0)
	for _hit: int in range(2):
		model_a.apply_damage(packet, resolver.resolve(packet, model_a.defense))
		model_b.apply_damage(packet, resolver.resolve(packet, model_b.defense))
	for _tick: int in range(240):
		model_a.advance_tick()
		model_b.advance_tick()
		if (
			model_a.current_health != model_b.current_health
			or not is_equal_approx(model_a.current_poise, model_b.current_poise)
			or model_a.reaction_type != model_b.reaction_type
			or model_a.reaction_ticks_remaining != model_b.reaction_ticks_remaining
			or (
				model_a.post_break_protection_ticks_remaining
				!= model_b.post_break_protection_ticks_remaining
			)
		):
			errors.append("identical fixed-tick combatants diverged")
			break
	var weak_a: WeakRef = weakref(model_a)
	var weak_b: WeakRef = weakref(model_b)
	model_a = null
	model_b = null
	if weak_a.get_ref() != null or weak_b.get_ref() != null:
		errors.append("released combatant models remained alive")
	return errors


func _test_normal_juggle_progression() -> PackedStringArray:
	var errors := PackedStringArray()
	var source_profile := _load_reaction_profile(&"normal").duplicate(true) as CombatReactionProfile
	var normal := _make_combatant(source_profile, 5001, 1000, 1000.0, 0.0)
	source_profile.can_be_launched = false
	source_profile.juggle_gravity = 1.0
	var launcher := _load_launch_profile(&"launcher")
	var packet := _make_control_packet(launcher.definition_id)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var launch_events: Array[Vector2] = []
	normal.launched.connect(
		func(upward_velocity: float, resistance: float) -> void:
			launch_events.append(Vector2(upward_velocity, resistance))
	)
	var first := normal.apply_damage(packet, resolver.resolve(packet, normal.defense), launcher)
	if (
		not first.accepted
		or not normal.is_airborne
		or normal.reaction_type != CombatantModel.REACTION_AIRBORNE
		or not is_equal_approx(first.launch_velocity, 720.0)
		or not is_zero_approx(first.juggle_resistance)
		or not is_zero_approx(normal.elevation)
		or not is_equal_approx(normal.vertical_velocity, 720.0)
	):
		errors.append("grounded normal target did not enter its baseline launch")
	normal.advance_tick()
	if (
		not is_equal_approx(normal.vertical_velocity, 690.0)
		or not is_equal_approx(normal.elevation, 11.5)
		or normal.airborne_control_ticks != 1
	):
		errors.append("first airborne fixed tick did not reuse MOV-002 gravity")

	var second := normal.apply_damage(packet, resolver.resolve(packet, normal.defense), launcher)
	if (
		not second.accepted
		or not is_equal_approx(normal.juggle_resistance, 1.0)
		or not is_equal_approx(second.launch_velocity, 612.0)
		or not is_equal_approx(second.juggle_resistance, 1.0)
		or not is_equal_approx(normal.vertical_velocity, 612.0)
	):
		errors.append("air hit did not raise resistance and reduce launch by 15 percent")

	var ordinary_packet := _make_control_packet(&"none")
	var ordinary := normal.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, normal.defense)
	)
	if (
		not ordinary.accepted
		or ordinary.reaction_type != CombatantModel.REACTION_AIRBORNE
		or not is_zero_approx(ordinary.launch_velocity)
		or not is_equal_approx(ordinary.juggle_resistance, 2.0)
	):
		errors.append("non-launching air hit did not increase resistance while preserving airborne state")
	if (
		launch_events != [Vector2(720.0, 0.0), Vector2(612.0, 1.0)]
		or not normal.can_be_launched
	):
		errors.append("launch signals or reaction-profile snapshot changed unexpectedly")
	errors.append_array(first.validation_errors())
	errors.append_array(second.validation_errors())
	errors.append_array(ordinary.validation_errors())
	errors.append_array(normal.validation_errors())
	return errors


func _test_forced_landing_boundary() -> PackedStringArray:
	var errors := PackedStringArray()
	var target := _make_combatant(
		_load_reaction_profile(&"normal"), 5002, 1_000_000, 1_000_000.0, 0.0
	)
	var launcher := _load_launch_profile(&"launcher")
	var packet := _make_control_packet(launcher.definition_id)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	var forced_events: Array[int] = []
	var knockdown_events: PackedStringArray = []
	target.forced_landed.connect(
		func(control_ticks: int) -> void: forced_events.append(control_ticks)
	)
	target.knocked_down.connect(
		func(duration_ticks: int, forced: bool) -> void:
			knockdown_events.append("%d:%s" % [duration_ticks, str(forced)])
	)
	var initial := target.apply_damage(packet, resolver.resolve(packet, 0.0), launcher)
	if not initial.accepted or not target.is_airborne:
		errors.append("forced-landing fixture did not launch")
		return errors
	for _tick: int in range(209):
		var relaunch := target.apply_damage(packet, resolver.resolve(packet, 0.0), launcher)
		if not relaunch.accepted:
			errors.append("continuous airborne fixture rejected a relaunch")
			break
		target.advance_tick()
	if (
		not target.is_airborne
		or target.airborne_control_ticks != 209
		or not forced_events.is_empty()
	):
		errors.append("continuous airborne control ended before tick 210")
	var last_relaunch := target.apply_damage(packet, resolver.resolve(packet, 0.0), launcher)
	if not last_relaunch.accepted:
		errors.append("last relaunch before forced landing was rejected")
	target.advance_tick()
	if (
		not target.is_knocked_down
		or target.reaction_type != CombatantModel.REACTION_KNOCKDOWN
		or target.airborne_control_ticks != 210
		or target.knockdown_ticks_remaining != 30
		or not is_zero_approx(target.elevation)
		or not is_zero_approx(target.vertical_velocity)
		or forced_events != [210]
		or knockdown_events != PackedStringArray(["30:true"])
	):
		errors.append("tick 210 did not force exactly one deterministic knockdown")
	errors.append_array(target.validation_errors())
	return errors


func _test_knockdown_ground_pursuit() -> PackedStringArray:
	var errors := PackedStringArray()
	var target := _make_combatant(
		_load_reaction_profile(&"normal"), 5003, 1000, 1000.0, 0.0
	)
	var launcher := _load_launch_profile(&"launcher").duplicate(true) as CombatLaunchProfile
	launcher.upward_velocity = 60.0
	var launch_packet := _make_control_packet(launcher.definition_id)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	target.apply_damage(launch_packet, resolver.resolve(launch_packet, 0.0), launcher)
	var landing_tick := 0
	for tick: int in range(1, 11):
		target.advance_tick()
		if target.is_knocked_down:
			landing_tick = tick
			break
	if landing_tick != 3 or target.knockdown_ticks_remaining != 30:
		errors.append("low launch did not enter a 30-tick knockdown on its natural landing")

	var ordinary_packet := _make_control_packet(&"none")
	var health_before_block := target.current_health
	var blocked := target.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, 0.0)
	)
	if (
		blocked.accepted
		or blocked.rejection_code != CombatantModel.REJECTION_TARGET_KNOCKDOWN_PROTECTED
		or target.current_health != health_before_block
	):
		errors.append("ordinary attack bypassed knockdown protection or partially damaged")

	var pursuit := _load_launch_profile(&"ground_pursuit")
	var pursuit_packet := _make_control_packet(pursuit.definition_id)
	var first := target.apply_damage(
		pursuit_packet,
		resolver.resolve(pursuit_packet, 0.0),
		pursuit
	)
	var health_after_first := target.current_health
	var second := target.apply_damage(
		pursuit_packet,
		resolver.resolve(pursuit_packet, 0.0),
		pursuit
	)
	if (
		not first.accepted
		or not first.ground_pursuit_consumed
		or first.reaction_type != CombatantModel.REACTION_KNOCKDOWN
		or target.ground_pursuit_hits_used != 1
		or second.accepted
		or second.rejection_code != CombatantModel.REJECTION_GROUND_PURSUIT_LIMIT
		or target.current_health != health_after_first
	):
		errors.append("knockdown window did not enforce exactly one ground pursuit")
	for _tick: int in range(29):
		target.advance_tick()
	if not target.is_knocked_down or target.knockdown_ticks_remaining != 1:
		errors.append("knockdown recovered before its final tick")
	target.advance_tick()
	if (
		target.is_knocked_down
		or target.reaction_type != CombatantModel.REACTION_NONE
		or target.knockdown_ticks_remaining != 0
		or target.ground_pursuit_hits_used != 0
		or not is_zero_approx(target.juggle_resistance)
	):
		errors.append("knockdown did not recover and reset control state on tick 30")
	var recovered_hit := target.apply_damage(
		ordinary_packet,
		resolver.resolve(ordinary_packet, 0.0)
	)
	if not recovered_hit.accepted:
		errors.append("recovered target remained protected after tick 30")

	var late_target := _make_combatant(
		_load_reaction_profile(&"normal"), 5004, 1000, 1000.0, 0.0
	)
	late_target.apply_damage(launch_packet, resolver.resolve(launch_packet, 0.0), launcher)
	for _tick: int in range(3 + 29):
		late_target.advance_tick()
	var late_pursuit := late_target.apply_damage(
		pursuit_packet,
		resolver.resolve(pursuit_packet, 0.0),
		pursuit
	)
	if (
		not late_target.is_knocked_down
		or late_target.knockdown_ticks_remaining != 1
		or not late_pursuit.accepted
		or not late_pursuit.ground_pursuit_consumed
	):
		errors.append("first ground pursuit was not accepted on the last inclusive tick")
	errors.append_array(first.validation_errors())
	errors.append_array(second.validation_errors())
	return errors


func _test_juggle_immunity_and_interrupts() -> PackedStringArray:
	var errors := PackedStringArray()
	var launcher := _load_launch_profile(&"launcher")
	var launch_packet := _make_control_packet(launcher.definition_id)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	for fixture: Dictionary in [
		{"name": "elite", "target": _make_combatant(_load_reaction_profile(&"elite"), 5005, 1000, 1000.0, 0.0)},
		{"name": "boss", "target": _make_combatant(_load_reaction_profile(&"boss"), 5006, 1000, 1000.0, 0.0)},
	]:
		var target: CombatantModel = fixture["target"]
		var applied := target.apply_damage(
			launch_packet,
			resolver.resolve(launch_packet, 0.0),
			launcher
		)
		if (
			not applied.accepted
			or target.is_airborne
			or target.can_be_launched
			or not is_zero_approx(applied.launch_velocity)
			or not is_zero_approx(target.elevation)
		):
			errors.append("%s target ignored its configured launch immunity" % fixture["name"])

	var break_target := _make_combatant(
		_load_reaction_profile(&"normal"), 5007, 1000, 12.0, 0.0
	)
	break_target.apply_damage(
		launch_packet,
		resolver.resolve(launch_packet, 0.0),
		launcher
	)
	var break_packet := _make_control_packet(&"none", 12.0)
	var broke := break_target.apply_damage(
		break_packet,
		resolver.resolve(break_packet, 0.0)
	)
	if (
		not broke.broke_poise
		or not break_target.is_broken
		or break_target.is_airborne
		or not is_zero_approx(break_target.elevation)
	):
		errors.append("poise break did not interrupt airborne control")

	var defeat_target := _make_combatant(
		_load_reaction_profile(&"normal"), 5008, 2, 1000.0, 0.0
	)
	defeat_target.apply_damage(
		launch_packet,
		resolver.resolve(launch_packet, 0.0),
		launcher
	)
	var lethal_packet := _make_control_packet(&"none", 0.0, 1000.0)
	var lethal := defeat_target.apply_damage(
		lethal_packet,
		resolver.resolve(lethal_packet, 0.0)
	)
	if (
		not lethal.accepted
		or not defeat_target.is_defeated
		or defeat_target.is_airborne
		or defeat_target.is_knocked_down
		or not is_zero_approx(defeat_target.elevation)
	):
		errors.append("defeat did not terminate and clear airborne control")

	var transaction_target := _make_combatant(
		_load_reaction_profile(&"normal"), 5009, 1000, 1000.0, 0.0
	)
	var health_before := transaction_target.current_health
	var mismatched := transaction_target.apply_damage(
		launch_packet,
		resolver.resolve(launch_packet, 0.0),
		_load_launch_profile(&"ground_pursuit")
	)
	if (
		mismatched.accepted
		or mismatched.rejection_code != CombatantModel.REJECTION_INVALID_LAUNCH_PROFILE
		or transaction_target.current_health != health_before
		or transaction_target.is_airborne
	):
		errors.append("mismatched launch profile partially changed combatant state")
	return errors


func _test_juggle_determinism_and_lifecycle() -> PackedStringArray:
	var errors := PackedStringArray()
	var source_profile := _load_reaction_profile(&"normal").duplicate(true) as CombatReactionProfile
	var model_a := _make_combatant(source_profile, 5010, 100_000, 100_000.0, 0.0)
	source_profile.can_be_launched = false
	source_profile.juggle_gravity = 9999.0
	var model_b := _make_combatant(
		_load_reaction_profile(&"normal"), 5011, 100_000, 100_000.0, 0.0
	)
	var launcher := _load_launch_profile(&"launcher")
	var packet := _make_control_packet(launcher.definition_id)
	var resolver: DamageResolverModel = DamageResolverModelScript.new()
	model_a.apply_damage(packet, resolver.resolve(packet, 0.0), launcher)
	model_b.apply_damage(packet, resolver.resolve(packet, 0.0), launcher)
	for simulated_frame: int in range(240):
		var ignored_delta := 1.0 / 30.0 if simulated_frame % 2 == 0 else 1.0 / 144.0
		if ignored_delta <= 0.0:
			errors.append("juggle pause fixture produced an invalid delta")
	if (
		model_a.airborne_control_ticks != 0
		or not is_zero_approx(model_a.elevation)
		or not model_a.can_be_launched
	):
		errors.append("render frames or source mutation changed the fixed-tick snapshot")

	for tick: int in range(240):
		if tick % 12 == 0:
			var outcome_a := model_a.apply_damage(
				packet,
				resolver.resolve(packet, 0.0),
				launcher
			)
			var outcome_b := model_b.apply_damage(
				packet,
				resolver.resolve(packet, 0.0),
				launcher
			)
			if (
				outcome_a.accepted != outcome_b.accepted
				or outcome_a.rejection_code != outcome_b.rejection_code
				or not is_equal_approx(outcome_a.launch_velocity, outcome_b.launch_velocity)
			):
				errors.append("identical juggle hits produced different outcomes")
				break
		model_a.advance_tick()
		model_b.advance_tick()
		if (
			model_a.reaction_type != model_b.reaction_type
			or model_a.current_health != model_b.current_health
			or not is_equal_approx(model_a.elevation, model_b.elevation)
			or not is_equal_approx(model_a.vertical_velocity, model_b.vertical_velocity)
			or not is_equal_approx(model_a.juggle_resistance, model_b.juggle_resistance)
			or model_a.airborne_control_ticks != model_b.airborne_control_ticks
			or model_a.knockdown_ticks_remaining != model_b.knockdown_ticks_remaining
			or model_a.ground_pursuit_hits_used != model_b.ground_pursuit_hits_used
		):
			errors.append("identical fixed-tick juggle models diverged")
			break
	if not model_a.validation_errors().is_empty() or not model_b.validation_errors().is_empty():
		errors.append("deterministic juggle fixtures ended with invalid state")
	var weak_a: WeakRef = weakref(model_a)
	var weak_b: WeakRef = weakref(model_b)
	model_a = null
	model_b = null
	if weak_a.get_ref() != null or weak_b.get_ref() != null:
		errors.append("released juggle combatants remained alive")
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
	var boot_source_file := FileAccess.open(
		"res://scenes/boot/boot.gd",
		FileAccess.READ
	)
	if boot_source_file == null:
		errors.append("boot.gd could not be read")
		return errors
	var boot_source := boot_source_file.get_as_text()
	if not boot_source.contains("debug_panel.visible = OS.is_debug_build()"):
		errors.append("boot debug panel is not guarded by OS.is_debug_build()")

	var sandbox_source_file := FileAccess.open(
		"res://scripts/actors/movement_sandbox.gd",
		FileAccess.READ
	)
	if sandbox_source_file == null:
		errors.append("movement_sandbox.gd could not be read")
		return errors
	var sandbox_source := sandbox_source_file.get_as_text()
	var required_guards := PackedStringArray([
		"debug_panel.visible = OS.is_debug_build()",
		"attack_timeline_panel.visible = OS.is_debug_build()",
		"feedback_status_label.visible = OS.is_debug_build()",
	])
	for required_guard: String in required_guards:
		if not sandbox_source.contains(required_guard):
			errors.append(
				"movement sandbox debug UI is missing Release guard: %s"
				% required_guard
			)
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
