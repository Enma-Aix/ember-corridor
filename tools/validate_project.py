#!/usr/bin/env python3
"""Fast, dependency-free validation for the project repository contract."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_ACTIONS = (
    "move_left",
    "move_right",
    "move_up",
    "move_down",
    "attack",
    "jump",
    "dodge",
    "skill_1",
    "skill_2",
    "skill_3",
    "skill_4",
    "ultimate",
    "interact",
    "pause",
)

EXPECTED_LAYERS = (
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
)

EXPECTED_AUTOLOADS = (
    "App",
    "SceneRouter",
    "EventBus",
    "DataRegistry",
    "SettingsService",
    "AudioService",
)

REQUIRED_FILES = (
    "project.godot",
    "export_presets.cfg",
    "README.md",
    "DEVELOPMENT.md",
    ".github/workflows/m0-ci.yml",
    ".github/workflows/windows-release.yml",
    "installer/windows/EmberCorridor.iss",
    "release/VERSION",
    "scenes/boot/boot.tscn",
    "scenes/boot/boot.gd",
    "scripts/core/app.gd",
    "scripts/core/scene_router.gd",
    "scripts/core/event_bus.gd",
    "scripts/core/data_registry.gd",
    "scripts/core/settings_service.gd",
    "scripts/core/audio_service.gd",
    "scripts/core/game_log.gd",
    "scripts/core/error_boundary.gd",
    "scripts/core/version_info.gd",
    "scripts/data/base_definition.gd",
    "scripts/tools/validate_data.gd",
    "tests/test_runner.gd",
    "scripts/actors/ground_movement_model.gd",
    "scripts/actors/ground_movement_controller.gd",
    "scripts/actors/movement_sandbox.gd",
    "scripts/actors/elevation_model.gd",
    "scripts/actors/elevation_component.gd",
    "scripts/actors/dodge_model.gd",
    "scripts/combat/state_machine_model.gd",
    "scripts/data/attack_definition.gd",
    "scripts/data/attack_cancel_window.gd",
    "scripts/data/skill_movement_profile.gd",
    "scripts/data/skill_definition.gd",
    "scripts/data/hit_feedback_profile.gd",
    "scripts/combat/attack_timeline_model.gd",
    "scripts/combat/input_buffer_model.gd",
    "scripts/combat/normal_attack_combo_model.gd",
    "scripts/combat/linebreaker_skill_model.gd",
    "scripts/combat/hit_feedback_request.gd",
    "scripts/combat/hit_feedback_service.gd",
    "scripts/presentation/hit_feedback_presenter.gd",
    "scripts/combat/hit_contact.gd",
    "scripts/combat/hit_resolver_model.gd",
    "scripts/combat/hitbox_component.gd",
    "scripts/combat/hurtbox_component.gd",
    "scripts/combat/damage_packet.gd",
    "scripts/combat/hit_result.gd",
    "scripts/combat/damage_resolver_model.gd",
    "scripts/data/combat_reaction_profile.gd",
    "scripts/data/combat_launch_profile.gd",
    "scripts/combat/combatant_model.gd",
    "scripts/combat/juggle_model.gd",
    "data/attacks/dev_a1.tres",
    "data/attacks/dev_a2.tres",
    "data/attacks/dev_a3.tres",
    "data/attacks/dev_launcher.tres",
    "data/skills/bladebound_linebreaker.tres",
    "data/combat/feedback_profiles/light.tres",
    "data/combat/feedback_profiles/medium.tres",
    "data/combat/feedback_profiles/heavy.tres",
    "data/combat/feedback_profiles/finisher.tres",
    "data/combat/reaction_profiles/normal.tres",
    "data/combat/reaction_profiles/elite.tres",
    "data/combat/reaction_profiles/boss.tres",
    "data/combat/launch_profiles/dev_launcher.tres",
    "data/combat/launch_profiles/dev_ground_pursuit.tres",
    "scenes/actors/player.tscn",
    "scenes/tests/movement_sandbox.tscn",
    "docs/M1-MOV-001-TEST-PLAN.md",
    "docs/M1-MOV-002-TEST-PLAN.md",
    "docs/M1-MOV-003-TEST-PLAN.md",
    "docs/M1-CMB-001-TEST-PLAN.md",
    "docs/M1-CMB-002-TEST-PLAN.md",
    "docs/M1-CMB-003-TEST-PLAN.md",
    "docs/M1-CMB-004-TEST-PLAN.md",
    "docs/M1-CMB-005-TEST-PLAN.md",
    "docs/M1-CMB-006-TEST-PLAN.md",
    "docs/M1-CMB-007-TEST-PLAN.md",
    "docs/M1-CMB-008-TEST-PLAN.md",
    "docs/M1-CMB-009-TEST-PLAN.md",
    "docs/M1-CMB-010-TEST-PLAN.md",
    "docs/ASSET-LICENSE-REGISTER.csv",
    "licenses/GODOT-ENGINE-LICENSE.md",
    "build/.gdignore",
    "docs/.gdignore",
)

EXPECTED_ASSET_HEADERS = (
    "asset_id",
    "asset_name",
    "category",
    "status",
    "source_url",
    "author",
    "license",
    "attribution_required",
    "project_path",
    "notes",
)


def main() -> int:
    errors: list[str] = []
    validate_required_files(errors)
    validate_project_settings(errors)
    validate_movement_contract(errors)
    validate_elevation_contract(errors)
    validate_dodge_contract(errors)
    validate_state_machine_contract(errors)
    validate_attack_timeline_contract(errors)
    validate_input_buffer_contract(errors)
    validate_normal_combo_contract(errors)
    validate_linebreaker_contract(errors)
    validate_hit_feedback_contract(errors)
    validate_hit_detection_contract(errors)
    validate_damage_formula_contract(errors)
    validate_combatant_contract(errors)
    validate_juggle_contract(errors)
    validate_workflow(errors)
    validate_release_contract(errors)
    validate_export_boundary(errors)
    validate_asset_registry(errors)
    validate_script_uids(errors)
    validate_offline_boundary(errors)

    if errors:
        print(f"PROJECT STATIC VALIDATION: FAIL ({len(errors)} issue(s))")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("PROJECT STATIC VALIDATION: PASS")
    print(f"  - {len(REQUIRED_FILES)} required files")
    print(f"  - {len(REQUIRED_ACTIONS)} Input actions")
    print(f"  - {len(EXPECTED_LAYERS)} named collision layers")
    print(f"  - {len(EXPECTED_AUTOLOADS)} approved Autoload services")
    print("  - stable script UIDs, asset license register, and offline boundary")
    return 0


def validate_required_files(errors: list[str]) -> None:
    for relative_path in REQUIRED_FILES:
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing required file: {relative_path}")
        elif path.stat().st_size == 0:
            errors.append(f"required file is empty: {relative_path}")


def validate_project_settings(errors: list[str]) -> None:
    project_path = ROOT / "project.godot"
    if not project_path.is_file():
        return
    text = project_path.read_text(encoding="utf-8")
    required_markers = (
        'config/features=PackedStringArray("4.7", "GL Compatibility")',
        'renderer/rendering_method="gl_compatibility"',
        "common/physics_ticks_per_second=60",
        'run/main_scene="res://scenes/game/vertical_slice.tscn"',
    )
    for marker in required_markers:
        if marker not in text:
            errors.append(f"project.godot missing marker: {marker}")

    for action in REQUIRED_ACTIONS:
        if not re.search(rf"(?m)^{re.escape(action)}=\{{\s*$", text):
            errors.append(f"project.godot missing Input action: {action}")

    for index, expected_name in enumerate(EXPECTED_LAYERS, start=1):
        marker = f'2d_physics/layer_{index}="{expected_name}"'
        if marker not in text:
            errors.append(f"collision layer {index} must be {expected_name}")

    for autoload in EXPECTED_AUTOLOADS:
        if not re.search(rf'(?m)^{autoload}="\*res://.+\.gd"$', text):
            errors.append(f"missing approved Autoload: {autoload}")

    autoload_section = re.search(
        r"(?ms)^\[autoload\]\s*(.*?)(?=^\[[^\]]+\])", text
    )
    if autoload_section:
        discovered = set(
            re.findall(r'(?m)^([A-Za-z0-9_]+)="\*res://', autoload_section.group(1))
        )
        unexpected = sorted(discovered.difference(EXPECTED_AUTOLOADS))
        if unexpected:
            errors.append(f"unapproved Autoload services: {', '.join(unexpected)}")


def validate_movement_contract(errors: list[str]) -> None:
    model_path = ROOT / "scripts/actors/ground_movement_model.gd"
    controller_path = ROOT / "scripts/actors/ground_movement_controller.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    if not model_path.is_file() or not controller_path.is_file():
        return

    model_text = model_path.read_text(encoding="utf-8")
    for marker in (
        "horizontal_speed := 320.0",
        "depth_speed_ratio := 0.9",
        "raw_input.limit_length(1.0)",
        "FACING_INPUT_THRESHOLD := 0.01",
    ):
        if marker not in model_text:
            errors.append(f"MOV-001 movement model missing marker: {marker}")

    controller_text = controller_path.read_text(encoding="utf-8")
    for action in ("move_left", "move_right", "move_up", "move_down"):
        if f'&"{action}"' not in controller_text:
            errors.append(f"MOV-001 controller does not read Input action: {action}")
    forbidden_input_access = re.search(
        r"\bKEY_[A-Z0-9_]+\b|physical_keycode|Input\.is_key_pressed",
        controller_text,
    )
    if forbidden_input_access:
        errors.append(
            "MOV-001 controller bypasses Input actions: "
            f"{forbidden_input_access.group(0)}"
        )

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if 'GameLog.info(&"MovementSandbox", "MOV-001 sandbox ready")' not in sandbox_text:
            errors.append("MOV-001 sandbox does not emit its readiness marker")


def validate_elevation_contract(errors: list[str]) -> None:
    model_path = ROOT / "scripts/actors/elevation_model.gd"
    component_path = ROOT / "scripts/actors/elevation_component.gd"
    player_scene_path = ROOT / "scenes/actors/player.tscn"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    if not model_path.is_file() or not component_path.is_file():
        return

    model_text = model_path.read_text(encoding="utf-8")
    for marker in (
        "jump_speed := 720.0",
        "gravity := 1800.0",
        "min_hit_height := 0.0",
        "max_hit_height := 56.0",
        "func overlaps_height_range",
        "_snap_to_ground()",
    ):
        if marker not in model_text:
            errors.append(f"MOV-002 elevation model missing marker: {marker}")

    component_text = component_path.read_text(encoding="utf-8")
    for marker in (
        'Input.is_action_just_pressed(&"jump")',
        "_base_visual_position.y - _elevation_model.elevation",
        "signal jump_started",
        "signal landed",
    ):
        if marker not in component_text:
            errors.append(f"MOV-002 elevation component missing marker: {marker}")
    forbidden_input_access = re.search(
        r"\bKEY_[A-Z0-9_]+\b|physical_keycode|Input\.is_key_pressed",
        component_text,
    )
    if forbidden_input_access:
        errors.append(
            "MOV-002 elevation component bypasses Input actions: "
            f"{forbidden_input_access.group(0)}"
        )
    if "global_position" in model_text or "global_position" in component_text:
        errors.append("MOV-002 elevation logic must not mutate ground coordinates")

    if player_scene_path.is_file():
        player_scene = player_scene_path.read_text(encoding="utf-8")
        for marker in (
            '[node name="Elevation" type="Node" parent="."]',
            '[node name="Shadow" type="Polygon2D" parent="."]',
            '[node name="VisualRoot" type="Node2D" parent="."]',
        ):
            if marker not in player_scene:
                errors.append(f"MOV-002 player scene missing marker: {marker}")

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if 'GameLog.info(&"ElevationSandbox", "MOV-002 sandbox ready")' not in sandbox_text:
            errors.append("MOV-002 sandbox does not emit its readiness marker")


def validate_dodge_contract(errors: list[str]) -> None:
    model_path = ROOT / "scripts/actors/dodge_model.gd"
    controller_path = ROOT / "scripts/actors/ground_movement_controller.gd"
    player_scene_path = ROOT / "scenes/actors/player.tscn"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    if not model_path.is_file() or not controller_path.is_file():
        return

    model_text = model_path.read_text(encoding="utf-8")
    for marker in (
        "const TOTAL_TICKS := 24",
        "const TRAVEL_TICKS := 10",
        "const INVULNERABLE_START_TICK := 4",
        "const INVULNERABLE_END_TICK := 13",
        "const COOLDOWN_TICKS := 45",
        "const DODGE_DISTANCE := 70.4",
        "raw_input.limit_length(1.0)",
    ):
        if marker not in model_text:
            errors.append(f"MOV-003 dodge model missing marker: {marker}")

    controller_text = controller_path.read_text(encoding="utf-8")
    for marker in (
        'Input.is_action_just_pressed(&"dodge")',
        "move_and_slide()",
        "signal dodge_started",
        "signal dodge_finished",
        "signal dodge_invulnerability_changed",
    ):
        if marker not in controller_text:
            errors.append(f"MOV-003 controller missing marker: {marker}")
    forbidden_input_access = re.search(
        r"\bKEY_[A-Z0-9_]+\b|physical_keycode|Input\.is_key_pressed",
        controller_text,
    )
    if forbidden_input_access:
        errors.append(
            "MOV-003 controller bypasses Input actions: "
            f"{forbidden_input_access.group(0)}"
        )

    if player_scene_path.is_file():
        player_scene = player_scene_path.read_text(encoding="utf-8")
        if "collision_mask = 1" not in player_scene:
            errors.append(
                "MOV-003 PlayerBody must collide with WorldStatic only so enemy "
                "soft collision does not block dodge"
            )

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if 'GameLog.info(&"DodgeSandbox", "MOV-003 sandbox ready")' not in sandbox_text:
            errors.append("MOV-003 sandbox does not emit its readiness marker")


def validate_state_machine_contract(errors: list[str]) -> None:
    model_path = ROOT / "scripts/combat/state_machine_model.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    if not model_path.is_file():
        return

    model_text = model_path.read_text(encoding="utf-8")
    for marker in (
        "class_name StateMachineModel",
        "extends RefCounted",
        "signal state_changed",
        "signal transition_rejected",
        "func configure",
        "func can_transition_to",
        "func request_transition",
        "func reset",
        "REJECTION_NOT_CONFIGURED",
        "REJECTION_UNKNOWN_TARGET",
        "REJECTION_NOT_ALLOWED",
    ):
        if marker not in model_text:
            errors.append(f"CMB-001 state machine missing marker: {marker}")

    forbidden_dependencies = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
        r"get_node\s*\(",
        model_text,
    )
    if forbidden_dependencies:
        errors.append(
            "CMB-001 state machine core depends on scene or presentation code: "
            f"{forbidden_dependencies.group(0)}"
        )

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if (
            'GameLog.info(&"StateMachineSandbox", "CMB-001 core ready")'
            not in sandbox_text
        ):
            errors.append("CMB-001 sandbox does not emit its readiness marker")


def validate_attack_timeline_contract(errors: list[str]) -> None:
    definition_path = ROOT / "scripts/data/attack_definition.gd"
    cancel_window_path = ROOT / "scripts/data/attack_cancel_window.gd"
    timeline_path = ROOT / "scripts/combat/attack_timeline_model.gd"
    resource_path = ROOT / "data/attacks/dev_a1.tres"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    if not all(
        path.is_file()
        for path in (definition_path, cancel_window_path, timeline_path, resource_path)
    ):
        return

    definition_text = definition_path.read_text(encoding="utf-8")
    for marker in (
        "class_name AttackDefinition",
        "var startup_ticks",
        "var active_ticks",
        "var recovery_ticks",
        "var cancel_windows: Array[AttackCancelWindow]",
        "var hit_stop_ticks",
        "func total_ticks",
        "func phase_at_tick",
        "func is_active_tick",
        "func cancel_targets_at_tick",
        "func phase_tick_range",
    ):
        if marker not in definition_text:
            errors.append(f"CMB-002 AttackDefinition missing marker: {marker}")

    cancel_window_text = cancel_window_path.read_text(encoding="utf-8")
    for marker in (
        "class_name AttackCancelWindow",
        "var start_tick",
        "var end_tick",
        "var target_tags: Array[StringName]",
        "func validation_errors",
        "func contains_tick",
    ):
        if marker not in cancel_window_text:
            errors.append(f"CMB-002 cancel window missing marker: {marker}")

    timeline_text = timeline_path.read_text(encoding="utf-8")
    for marker in (
        "class_name AttackTimelineModel",
        "extends RefCounted",
        "signal timeline_started",
        "signal tick_advanced",
        "signal phase_changed",
        "signal timeline_completed",
        "func start",
        "duplicate(true)",
        "func advance_tick",
        "func available_cancel_targets",
        "func reset",
    ):
        if marker not in timeline_text:
            errors.append(f"CMB-002 timeline model missing marker: {marker}")
    forbidden_dependencies = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
        r"get_node\s*\(",
        timeline_text,
    )
    if forbidden_dependencies:
        errors.append(
            "CMB-002 timeline core depends on scene or presentation code: "
            f"{forbidden_dependencies.group(0)}"
        )

    resource_text = resource_path.read_text(encoding="utf-8")
    for marker in (
        'definition_id = &"attack.dev.a1_placeholder"',
        "startup_ticks = 6",
        "active_ticks = 3",
        "recovery_ticks = 11",
        "start_tick = 15",
        "end_tick = 20",
        '&"action.dodge"',
        "hit_stop_ticks = 3",
    ):
        if marker not in resource_text:
            errors.append(f"CMB-002 placeholder attack missing marker: {marker}")

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if 'Input.is_action_just_pressed(&"attack")' not in sandbox_text:
            errors.append("CMB-002 sandbox does not read the attack Input action")
        if (
            'GameLog.info(&"AttackTimelineSandbox", "CMB-002 timeline ready")'
            not in sandbox_text
        ):
            errors.append("CMB-002 sandbox does not emit its readiness marker")


def validate_input_buffer_contract(errors: list[str]) -> None:
    model_path = ROOT / "scripts/combat/input_buffer_model.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    test_path = ROOT / "tests/test_runner.gd"
    if not model_path.is_file():
        return
    model_text = model_path.read_text(encoding="utf-8")
    for marker in (
        "class_name InputBufferModel",
        "extends RefCounted",
        "const DEFAULT_BUFFER_TICKS := 8",
        "var current_tick",
        "var buffer_ticks",
        "func configure",
        "func advance_tick",
        "func record_pressed",
        "func record_released",
        '"pressed_tick"',
        '"released_tick"',
        '"consumed_tick"',
        "func has_buffered_press",
        "func consume",
        "func clear",
        "input_age_ticks(action) >= _buffer_ticks",
    ):
        if marker not in model_text:
            errors.append(f"CMB-007 InputBufferModel missing marker: {marker}")
    forbidden = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
        r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
        model_text,
    )
    if forbidden:
        errors.append(
            "CMB-007 input buffer depends on scene or presentation code: "
            f"{forbidden.group(0)}"
        )
    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        for marker in (
            'Input.is_action_just_pressed(&"attack")',
            'Input.is_action_just_released(&"attack")',
            "input_buffer.advance_tick()",
            "input_buffer.record_pressed",
            "input_buffer.record_released",
            "NOTIFICATION_APPLICATION_FOCUS_OUT",
            'GameLog.info(&"InputBufferSandbox", "CMB-007 input buffer ready")',
        ):
            if marker not in sandbox_text:
                errors.append(f"CMB-007 sandbox missing marker: {marker}")
    if test_path.is_file():
        test_text = test_path.read_text(encoding="utf-8")
        for marker in (
            "_test_input_buffer_expiration_boundary()",
            "_test_input_buffer_release_and_consumption()",
            "_test_input_buffer_isolation_pause_and_clear()",
        ):
            if marker not in test_text:
                errors.append(f"CMB-007 tests missing marker: {marker}")


def validate_normal_combo_contract(errors: list[str]) -> None:
    combo_path = ROOT / "scripts/combat/normal_attack_combo_model.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    player_scene_path = ROOT / "scenes/actors/player.tscn"
    test_path = ROOT / "tests/test_runner.gd"
    resource_contracts = {
        ROOT / "data/attacks/dev_a1.tres": (
            "startup_ticks = 6",
            "active_ticks = 3",
            "recovery_ticks = 11",
            "start_tick = 9",
            '&"action.attack"',
        ),
        ROOT / "data/attacks/dev_a2.tres": (
            'definition_id = &"attack.bladebound.a2_return_slash"',
            "startup_ticks = 7",
            "active_ticks = 3",
            "recovery_ticks = 13",
            "start_tick = 10",
            "hitbox_size = Vector2(96, 60)",
        ),
        ROOT / "data/attacks/dev_a3.tres": (
            'definition_id = &"attack.bladebound.a3_rising_slash"',
            "startup_ticks = 9",
            "active_ticks = 4",
            "recovery_ticks = 18",
            "hit_stop_ticks = 5",
            'launch_profile = &"combat.launch.dev_launcher"',
        ),
    }
    if combo_path.is_file():
        combo_text = combo_path.read_text(encoding="utf-8")
        for marker in (
            "class_name NormalAttackComboModel",
            "extends RefCounted",
            "signal attack_started",
            "signal attack_finished",
            'const ATTACK_INPUT_ACTION := &"attack"',
            'const ATTACK_CANCEL_TAG := &"action.attack"',
            "func configure",
            "duplicate(true)",
            "func advance_tick",
            "available_cancel_targets()",
            "input_buffer.consume(ATTACK_INPUT_ACTION)",
            "func reset",
        ):
            if marker not in combo_text:
                errors.append(f"CMB-008 combo model missing marker: {marker}")
        forbidden = re.search(
            r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
            r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
            combo_text,
        )
        if forbidden:
            errors.append(
                "CMB-008 combo core depends on scene or presentation code: "
                f"{forbidden.group(0)}"
            )
    for path, markers in resource_contracts.items():
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"CMB-008 Resource {path.name} missing marker: {marker}")
    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        for marker in (
            'preload("res://data/attacks/dev_a1.tres")',
            'preload("res://data/attacks/dev_a2.tres")',
            'preload("res://data/attacks/dev_a3.tres")',
            "normal_attack_combo.advance_tick(input_buffer",
            "player.set_facing_locked(true)",
            'GameLog.info(&"NormalComboSandbox", "CMB-008 three-hit combo ready")',
        ):
            if marker not in sandbox_text:
                errors.append(f"CMB-008 sandbox missing marker: {marker}")
    if player_scene_path.is_file():
        player_scene = player_scene_path.read_text(encoding="utf-8")
        if '[node name="AttackTrail" type="Polygon2D" parent="VisualRoot"]' not in player_scene:
            errors.append("CMB-008 player presentation is missing AttackTrail")
    if test_path.is_file():
        test_text = test_path.read_text(encoding="utf-8")
        for marker in (
            "_test_normal_combo_resource_contract()",
            "_test_normal_combo_buffered_chain()",
            "_test_normal_combo_cancel_boundaries()",
            "_test_normal_combo_recovery_and_validation()",
            "_test_normal_combo_hitbox_mirroring()",
            "_test_project_normal_combo_sandbox()",
        ):
            if marker not in test_text:
                errors.append(f"CMB-008 tests missing marker: {marker}")


def validate_linebreaker_contract(errors: list[str]) -> None:
    movement_path = ROOT / "scripts/data/skill_movement_profile.gd"
    definition_path = ROOT / "scripts/data/skill_definition.gd"
    model_path = ROOT / "scripts/combat/linebreaker_skill_model.gd"
    controller_path = ROOT / "scripts/actors/ground_movement_controller.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    sandbox_scene_path = ROOT / "scenes/tests/movement_sandbox.tscn"
    resource_path = ROOT / "data/skills/bladebound_linebreaker.tres"
    test_path = ROOT / "tests/test_runner.gd"

    contracts = {
        movement_path: (
            "class_name SkillMovementProfile",
            "travel_start_tick",
            "travel_end_tick",
            "distance_pixels",
            "blocking_collision_mask",
            "pass_through_collision_mask",
            "pass_through_target_tags",
            "func displacement_at_tick",
        ),
        definition_path: (
            "class_name SkillDefinition",
            "extends BaseDefinition",
            "cooldown_seconds",
            "attack_sequence",
            "movement_profile",
            "cancel_rules",
            "ai_value_tags",
            "upgrade_nodes",
            'return &"skill"',
        ),
        model_path: (
            "class_name LinebreakerSkillModel",
            "extends RefCounted",
            "signal skill_started",
            "signal skill_finished",
            "func configure",
            "duplicate(true)",
            "func try_start",
            "func advance_tick",
            "movement_profile.displacement_at_tick",
            "_timeline.available_cancel_targets()",
            "input_buffer.consume(input_action)",
        ),
        controller_path: (
            "func begin_action_motion",
            "func queue_action_displacement",
            "func end_action_motion",
            "collision_mask = blocking_collision_mask",
            "move_and_slide()",
        ),
        sandbox_path: (
            '"res://data/skills/bladebound_linebreaker.tres"',
            'Input.is_action_just_pressed(&"skill_1")',
            "linebreaker_skill.advance_tick(input_buffer)",
            "normal_attack_combo.can_cancel_to(&\"action.skill_1\")",
            "_current_normal_attack_hit",
            'GameLog.info(&"LinebreakerSandbox", "CMB-009 linebreaker ready")',
        ),
        sandbox_scene_path: (
            '[node name="DummyA" type="CharacterBody2D"',
            '[node name="DummyB" type="CharacterBody2D"',
            "collision_layer = 4",
        ),
        resource_path: (
            'definition_id = &"skill.bladebound.linebreaker"',
            "cooldown_seconds = 5.0",
            "startup_ticks = 2",
            "active_ticks = 8",
            "recovery_ticks = 10",
            "distance_pixels = 176.0",
            "blocking_collision_mask = 1",
            "pass_through_collision_mask = 4",
            '&"action.attack"',
            '&"action.dodge"',
        ),
    }
    for path, markers in contracts.items():
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"CMB-009 {path.name} missing marker: {marker}")

    for attack_name in ("dev_a1.tres", "dev_a2.tres", "dev_a3.tres"):
        attack_path = ROOT / "data/attacks" / attack_name
        if attack_path.is_file() and '&"action.skill_1"' not in attack_path.read_text(
            encoding="utf-8"
        ):
            errors.append(f"CMB-009 {attack_name} has no declared skill cancel window")

    if model_path.is_file():
        model_text = model_path.read_text(encoding="utf-8")
        forbidden = re.search(
            r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
            r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
            model_text,
        )
        if forbidden:
            errors.append(
                "CMB-009 linebreaker core depends on scene or presentation code: "
                f"{forbidden.group(0)}"
            )

    if test_path.is_file():
        test_text = test_path.read_text(encoding="utf-8")
        for marker in (
            "_test_linebreaker_resource_contract()",
            "_test_linebreaker_movement_boundaries()",
            "_test_linebreaker_progression()",
            "_test_linebreaker_cancel_boundaries()",
            "_test_normal_to_skill_cancel_rules()",
            "_test_linebreaker_collision_sandbox()",
            "_test_linebreaker_cancel_sandbox()",
        ):
            if marker not in test_text:
                errors.append(f"CMB-009 tests missing marker: {marker}")


def validate_hit_feedback_contract(errors: list[str]) -> None:
    profile_path = ROOT / "scripts/data/hit_feedback_profile.gd"
    request_path = ROOT / "scripts/combat/hit_feedback_request.gd"
    service_path = ROOT / "scripts/combat/hit_feedback_service.gd"
    presenter_path = ROOT / "scripts/presentation/hit_feedback_presenter.gd"
    definition_path = ROOT / "scripts/data/attack_definition.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    scene_path = ROOT / "scenes/tests/movement_sandbox.tscn"
    test_path = ROOT / "tests/test_runner.gd"

    contracts = {
        profile_path: (
            "class_name HitFeedbackProfile",
            "extends BaseDefinition",
            '&"light": Vector2i(2, 3)',
            '&"medium": Vector2i(4, 5)',
            '&"heavy": Vector2i(6, 8)',
            '&"finisher": Vector2i(1, 10)',
            "camera_zoom_pulse",
            "camera_extension_ticks",
            "vfx_style",
            "sfx_layer_count",
            "func resolve_hit_stop_ticks",
        ),
        request_path: (
            "class_name HitFeedbackRequest",
            "extends RefCounted",
            "static func from_outcome",
            "result.accepted",
            "var world_position: Vector2",
            "var final_damage: int",
            "var hit_stop_ticks: int",
            "var feedback_strength: StringName",
            "func validation_errors",
        ),
        service_path: (
            "class_name HitFeedbackService",
            "signal hit_stop_requested",
            "signal camera_feedback_requested",
            "signal vfx_feedback_requested",
            "signal sfx_feedback_requested",
            "MAX_CAMERA_FEEDBACK_TICKS := 30",
            "duplicate(true)",
            "func request_feedback",
            "_hit_stop_ticks_remaining = maxi(",
            "_camera_shake_pixels = maxf(",
            "tree.paused = true",
            "func _release_tree_pause",
            "tree.paused = false",
        ),
        presenter_path: (
            "class_name HitFeedbackPresenter",
            "extends Node2D",
            "func bind_service",
            "camera_state_changed.connect",
            "vfx_feedback_requested.connect",
            "sfx_feedback_requested.connect",
            "draw_arc",
            "func _unbind_service",
        ),
        definition_path: (
            "const HIT_STOP_BUDGETS :=",
            "hit_stop_ticks must stay inside the %s budget",
        ),
        sandbox_path: (
            '"res://data/combat/feedback_profiles/light.tres"',
            "hit_feedback_service.configure(profiles)",
            "hit_feedback_presenter.bind_service(hit_feedback_service)",
            "HitFeedbackRequestScript.from_outcome",
            "hit_feedback_service.request_feedback(request)",
            'GameLog.info(&"HitFeedbackSandbox", "CMB-010 feedback service ready")',
        ),
        scene_path: (
            '[node name="CombatCamera" type="Camera2D"',
            '[node name="HitFeedbackService" type="Node"',
            '[node name="HitFeedbackPresenter" type="Node2D"',
            '[node name="FeedbackStatusLabel" type="Label"',
        ),
    }
    for path, markers in contracts.items():
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"CMB-010 {path.name} missing marker: {marker}")

    profile_contracts = {
        "light.tres": (
            'definition_id = &"feedback.hit.light"',
            "minimum_hit_stop_ticks = 2",
            "maximum_hit_stop_ticks = 3",
            "sfx_layer_count = 1",
        ),
        "medium.tres": (
            'definition_id = &"feedback.hit.medium"',
            "minimum_hit_stop_ticks = 4",
            "maximum_hit_stop_ticks = 5",
            "sfx_layer_count = 2",
        ),
        "heavy.tres": (
            'definition_id = &"feedback.hit.heavy"',
            "minimum_hit_stop_ticks = 6",
            "maximum_hit_stop_ticks = 8",
            "sfx_layer_count = 3",
        ),
        "finisher.tres": (
            'definition_id = &"feedback.hit.finisher"',
            "minimum_hit_stop_ticks = 8",
            "maximum_hit_stop_ticks = 10",
            "camera_zoom_pulse = 0.03",
            "sfx_layer_count = 3",
        ),
    }
    for file_name, markers in profile_contracts.items():
        path = ROOT / "data/combat/feedback_profiles" / file_name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"CMB-010 {file_name} missing marker: {marker}")

    if service_path.is_file():
        service_text = service_path.read_text(encoding="utf-8")
        forbidden = re.search(
            r"\b(Camera2D|AudioStreamPlayer|GPUParticles2D|CPUParticles2D|"
            r"HitFeedbackPresenter|Polygon2D|Control)\b|get_node\s*\(",
            service_text,
        )
        if forbidden:
            errors.append(
                "CMB-010 feedback service depends on a concrete presenter: "
                f"{forbidden.group(0)}"
            )

    if test_path.is_file():
        test_text = test_path.read_text(encoding="utf-8")
        for marker in (
            "_test_hit_feedback_profiles()",
            "_test_hit_feedback_request_snapshot()",
            "_test_hit_feedback_channel_routing()",
            "_test_hit_feedback_hit_stop_boundaries()",
            "_test_hit_feedback_camera_merging()",
            "_test_hit_feedback_determinism_and_lifecycle()",
            "_test_hit_feedback_sandbox()",
        ):
            if marker not in test_text:
                errors.append(f"CMB-010 tests missing marker: {marker}")


def validate_hit_detection_contract(errors: list[str]) -> None:
    contact_path = ROOT / "scripts/combat/hit_contact.gd"
    resolver_path = ROOT / "scripts/combat/hit_resolver_model.gd"
    hitbox_path = ROOT / "scripts/combat/hitbox_component.gd"
    hurtbox_path = ROOT / "scripts/combat/hurtbox_component.gd"
    definition_path = ROOT / "scripts/data/attack_definition.gd"
    resource_path = ROOT / "data/attacks/dev_a1.tres"
    player_scene_path = ROOT / "scenes/actors/player.tscn"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    core_paths = (contact_path, resolver_path, hitbox_path, hurtbox_path)
    if not all(path.is_file() for path in core_paths):
        return

    contact_text = contact_path.read_text(encoding="utf-8")
    for marker in (
        "class_name HitContact",
        "extends RefCounted",
        "var source_instance_id: int",
        "var target_instance_id: int",
        "var hit_id: StringName",
        "var rehit_interval_ticks: int",
        "func height_ranges_overlap",
        "func dedupe_key",
    ):
        if marker not in contact_text:
            errors.append(f"CMB-003 HitContact missing marker: {marker}")

    resolver_text = resolver_path.read_text(encoding="utf-8")
    for marker in (
        "class_name HitResolverModel",
        "extends RefCounted",
        "signal hit_accepted",
        "signal hit_rejected",
        "REJECTION_FRIENDLY_FACTION",
        "REJECTION_INVULNERABLE",
        "REJECTION_HEIGHT_MISS",
        "REJECTION_DUPLICATE_HIT",
        "func try_accept",
        "func accept_batch",
        "func clear",
    ):
        if marker not in resolver_text:
            errors.append(f"CMB-003 HitResolver missing marker: {marker}")
    forbidden_resolver_dependency = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|Control|App|GameLog)\b|"
        r"get_node\s*\(|extends\s+(Node|Area2D)",
        resolver_text,
    )
    if forbidden_resolver_dependency:
        errors.append(
            "CMB-003 resolver depends on scene or presentation code: "
            f"{forbidden_resolver_dependency.group(0)}"
        )

    hitbox_text = hitbox_path.read_text(encoding="utf-8")
    for marker in (
        "class_name HitboxComponent",
        "extends Area2D",
        "func activate",
        "duplicate(true)",
        "func set_action_tick",
        "func set_contact_enabled",
        "func set_facing_sign",
        "func build_contact",
        "collision_layer = 1 << 3",
        "collision_mask = 1 << 6",
        "collision_layer = 1 << 4",
        "collision_mask = 1 << 5",
    ):
        if marker not in hitbox_text:
            errors.append(f"CMB-003 HitboxComponent missing marker: {marker}")

    hurtbox_text = hurtbox_path.read_text(encoding="utf-8")
    for marker in (
        "class_name HurtboxComponent",
        "extends Area2D",
        "signal contact_forwarded",
        "func bind_resolver",
        "func set_invulnerable",
        "func set_hit_height_range",
        "func forward_contact",
        "collision_layer = 1 << 5",
        "collision_mask = 1 << 4",
        "collision_layer = 1 << 6",
        "collision_mask = 1 << 3",
    ):
        if marker not in hurtbox_text:
            errors.append(f"CMB-003 HurtboxComponent missing marker: {marker}")

    forbidden_damage_logic = re.search(
        r"\b(DamagePacket|HitResult|apply_damage|health|poise)\b",
        "\n".join((contact_text, resolver_text, hitbox_text, hurtbox_text)),
        re.IGNORECASE,
    )
    if forbidden_damage_logic:
        errors.append(
            "CMB-003 contact layer implements out-of-scope damage logic: "
            f"{forbidden_damage_logic.group(0)}"
        )

    if definition_path.is_file():
        definition_text = definition_path.read_text(encoding="utf-8")
        for marker in (
            "var hitbox_size",
            "var hitbox_offset",
            "var min_hit_height",
            "var max_hit_height",
            "var rehit_interval_ticks",
        ):
            if marker not in definition_text:
                errors.append(f"CMB-003 AttackDefinition missing marker: {marker}")

    if resource_path.is_file():
        resource_text = resource_path.read_text(encoding="utf-8")
        for marker in (
            "hitbox_size = Vector2(88, 44)",
            "hitbox_offset = Vector2(48, -22)",
            "min_hit_height = 0.0",
            "max_hit_height = 56.0",
            "rehit_interval_ticks = 0",
        ):
            if marker not in resource_text:
                errors.append(f"CMB-003 placeholder attack missing marker: {marker}")

    if player_scene_path.is_file():
        player_scene = player_scene_path.read_text(encoding="utf-8")
        for marker in (
            '[node name="Hurtbox" type="Area2D" parent="."]',
            '[node name="HitboxContainer" type="Node2D" parent="."]',
            '[node name="DevA1Hitbox" type="Area2D" parent="HitboxContainer"]',
            "collision_layer = 32",
            "collision_layer = 8",
        ):
            if marker not in player_scene:
                errors.append(f"CMB-003 player scene missing marker: {marker}")

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        if (
            'GameLog.info(&"HitboxSandbox", "CMB-003 hit detection ready")'
            not in sandbox_text
        ):
            errors.append("CMB-003 sandbox does not emit its readiness marker")


def validate_damage_formula_contract(errors: list[str]) -> None:
    packet_path = ROOT / "scripts/combat/damage_packet.gd"
    result_path = ROOT / "scripts/combat/hit_result.gd"
    resolver_path = ROOT / "scripts/combat/damage_resolver_model.gd"
    definition_path = ROOT / "scripts/data/attack_definition.gd"
    resource_path = ROOT / "data/attacks/dev_a1.tres"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    core_paths = (packet_path, result_path, resolver_path)
    if not all(path.is_file() for path in core_paths):
        return

    packet_text = packet_path.read_text(encoding="utf-8")
    for marker in (
        "class_name DamagePacket",
        "extends RefCounted",
        "var source_instance_id: int",
        "var attack_id: StringName",
        "var base_attack: float",
        "var coefficient: float",
        "var flat_damage: float",
        "var poise_damage: float",
        "var hit_tags: PackedStringArray",
        "var direction: Vector2",
        "var launch_profile: StringName",
        "var crit_chance: float",
        "var crit_damage_multiplier: float",
        "var critical_roll: float",
        "static func from_attack",
        "func validation_errors",
    ):
        if marker not in packet_text:
            errors.append(f"CMB-004 DamagePacket missing marker: {marker}")

    result_text = result_path.read_text(encoding="utf-8")
    for marker in (
        "class_name HitResult",
        "extends RefCounted",
        "var accepted: bool",
        "var rejection_code: StringName",
        "var final_damage: int",
        "var critical: bool",
        "var broke_poise: bool",
        "var reaction_type: StringName",
        "var knockback: Vector2",
        "var hit_stop_ticks: int",
        "var feedback_strength: StringName",
        "static func rejected",
        "func validation_errors",
    ):
        if marker not in result_text:
            errors.append(f"CMB-004 HitResult missing marker: {marker}")

    resolver_text = resolver_path.read_text(encoding="utf-8")
    for marker in (
        "class_name DamageResolverModel",
        "extends RefCounted",
        "const DEFAULT_CRIT_CHANCE := 0.05",
        "const MAX_CRIT_CHANCE := 0.60",
        "const DEFAULT_CRIT_DAMAGE_MULTIPLIER := 1.5",
        "REJECTION_INVALID_PACKET",
        "REJECTION_INVALID_DEFENSE",
        "REJECTION_INVALID_MODIFIER",
        "func resolve",
        "packet.base_attack * packet.coefficient + packet.flat_damage",
        "100.0 / (100.0 + maxf(0.0, target_defense))",
        "packet.critical_roll < effective_crit_chance",
        "roundi(maxf(1.0, resolved_damage))",
    ):
        if marker not in resolver_text:
            errors.append(f"CMB-004 DamageResolver missing marker: {marker}")

    core_text = "\n".join((packet_text, result_text, resolver_text))
    forbidden_dependencies = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|App|"
        r"GameLog|RandomNumberGenerator)\b|\brand[fi]_range\b|\brand[fi]\b|"
        r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
        core_text,
    )
    if forbidden_dependencies:
        errors.append(
            "CMB-004 formula core depends on scene, presentation, or global RNG: "
            f"{forbidden_dependencies.group(0)}"
        )
    forbidden_application = re.search(
        r"\b(apply_damage|apply_status|current_health|current_poise|Combatant)\b",
        core_text,
        re.IGNORECASE,
    )
    if forbidden_application:
        errors.append(
            "CMB-004 formula core applies out-of-scope combat state: "
            f"{forbidden_application.group(0)}"
        )

    if definition_path.is_file():
        definition_text = definition_path.read_text(encoding="utf-8")
        for marker in (
            "var damage_coefficient",
            "var flat_damage",
            "var poise_damage",
            "var hit_tags: Array[StringName]",
            "var launch_profile: StringName",
            "var feedback_strength",
        ):
            if marker not in definition_text:
                errors.append(f"CMB-004 AttackDefinition missing marker: {marker}")

    if resource_path.is_file():
        resource_text = resource_path.read_text(encoding="utf-8")
        for marker in (
            "damage_coefficient = 1.0",
            "flat_damage = 10.0",
            "poise_damage = 12.0",
            '&"damage.physical"',
            '&"attack.normal"',
            'launch_profile = &"none"',
            'feedback_strength = "light"',
        ):
            if marker not in resource_text:
                errors.append(f"CMB-004 placeholder attack missing marker: {marker}")

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        for marker in (
            'GameLog.info(&"DamageSandbox", "CMB-004 formula ready")',
            "DamagePacketScript.from_attack",
            "damage_resolver.resolve",
            "_total_preview_damage",
            "_minimum_preview_damage",
            "_maximum_preview_damage",
        ):
            if marker not in sandbox_text:
                errors.append(f"CMB-004 sandbox missing marker: {marker}")


def validate_combatant_contract(errors: list[str]) -> None:
    profile_path = ROOT / "scripts/data/combat_reaction_profile.gd"
    combatant_path = ROOT / "scripts/combat/combatant_model.gd"
    result_path = ROOT / "scripts/combat/hit_result.gd"
    hurtbox_path = ROOT / "scripts/combat/hurtbox_component.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    profile_resources = {
        "normal": ROOT / "data/combat/reaction_profiles/normal.tres",
        "elite": ROOT / "data/combat/reaction_profiles/elite.tres",
        "boss": ROOT / "data/combat/reaction_profiles/boss.tres",
    }
    if not profile_path.is_file() or not combatant_path.is_file():
        return

    profile_text = profile_path.read_text(encoding="utf-8")
    for marker in (
        "class_name CombatReactionProfile",
        "extends BaseDefinition",
        'SUPPORTED_STRATEGIES := [&"normal", &"elite", &"boss"]',
        "var strategy",
        "var react_on_health_hit",
        "var hit_reaction_ticks",
        "var break_duration_ticks",
        "var poise_recovery_per_tick",
        "var post_break_poise_damage_multiplier",
        "var forced_break_tags: Array[StringName]",
        "func has_forced_break_tag",
        "func validation_errors",
    ):
        if marker not in profile_text:
            errors.append(f"CMB-005 reaction profile missing marker: {marker}")

    combatant_text = combatant_path.read_text(encoding="utf-8")
    for marker in (
        "class_name CombatantModel",
        "extends RefCounted",
        "signal health_changed",
        "signal poise_changed",
        "signal reaction_changed",
        "signal poise_broken",
        "signal defeated",
        "const POISE_RECOVERY_DELAY_TICKS := 3 * TICKS_PER_SECOND",
        "const POST_BREAK_PROTECTION_TICKS := 1 * TICKS_PER_SECOND",
        'const REACTION_HIT_STUN := &"hit_stun"',
        'const REACTION_POISE_BREAK := &"poise_break"',
        'const REACTION_DEFEATED := &"defeated"',
        "func configure",
        "duplicate(true)",
        "func can_receive_hit",
        "func apply_damage",
        "func heal",
        "func advance_tick",
        "func validation_errors",
        "with_application_outcome",
    ):
        if marker not in combatant_text:
            errors.append(f"CMB-005 CombatantModel missing marker: {marker}")

    forbidden_dependencies = re.search(
        r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|App|"
        r"GameLog|RandomNumberGenerator)\b|\brand[fi]_range\b|\brand[fi]\b|"
        r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
        "\n".join((profile_text, combatant_text)),
    )
    if forbidden_dependencies:
        errors.append(
            "CMB-005 combatant core depends on scene, presentation, or RNG: "
            f"{forbidden_dependencies.group(0)}"
        )

    if result_path.is_file():
        result_text = result_path.read_text(encoding="utf-8")
        if "func with_application_outcome" not in result_text:
            errors.append("CMB-005 HitResult cannot create an immutable applied outcome")

    if hurtbox_path.is_file():
        hurtbox_text = hurtbox_path.read_text(encoding="utf-8")
        for marker in (
            'set_deferred("monitoring", enabled)',
            'set_deferred("monitorable", enabled)',
            'collision_shape.set_deferred("disabled", not enabled)',
        ):
            if marker not in hurtbox_text:
                errors.append(
                    "CMB-005 defeated Hurtbox must defer physics-state changes: "
                    f"{marker}"
                )

    expected_resources = {
        "normal": (
            'definition_id = &"combat.reaction.normal"',
            'strategy = "normal"',
            "react_on_health_hit = true",
            "hit_reaction_ticks = 12",
            "break_duration_ticks = 45",
        ),
        "elite": (
            'definition_id = &"combat.reaction.elite"',
            'strategy = "elite"',
            "react_on_health_hit = false",
            "hit_reaction_ticks = 0",
            "break_duration_ticks = 90",
        ),
        "boss": (
            'definition_id = &"combat.reaction.boss"',
            'strategy = "boss"',
            "react_on_health_hit = false",
            "break_duration_ticks = 60",
            '&"reaction.boss_break"',
        ),
    }
    for strategy, resource_path in profile_resources.items():
        if not resource_path.is_file():
            continue
        resource_text = resource_path.read_text(encoding="utf-8")
        for marker in expected_resources[strategy]:
            if marker not in resource_text:
                errors.append(
                    f"CMB-005 {strategy} reaction Resource missing marker: {marker}"
                )

    if sandbox_path.is_file():
        sandbox_text = sandbox_path.read_text(encoding="utf-8")
        for marker in (
            'GameLog.info(&"CombatantSandbox", "CMB-005 combatant reactions ready")',
            "CombatantModelScript.new",
            "target.apply_damage(packet, result, launch_profile)",
            "combatant.advance_tick()",
            "target_hurtbox.set_accepting_hits(false)",
            "Normal HP %d/%d",
            "Elite HP %d/%d",
        ):
            if marker not in sandbox_text:
                errors.append(f"CMB-005 sandbox missing marker: {marker}")


def validate_juggle_contract(errors: list[str]) -> None:
    launch_profile_path = ROOT / "scripts/data/combat_launch_profile.gd"
    reaction_profile_path = ROOT / "scripts/data/combat_reaction_profile.gd"
    elevation_path = ROOT / "scripts/actors/elevation_model.gd"
    juggle_path = ROOT / "scripts/combat/juggle_model.gd"
    combatant_path = ROOT / "scripts/combat/combatant_model.gd"
    result_path = ROOT / "scripts/combat/hit_result.gd"
    sandbox_path = ROOT / "scripts/actors/movement_sandbox.gd"
    attack_path = ROOT / "data/attacks/dev_a3.tres"
    test_path = ROOT / "tests/test_runner.gd"

    if launch_profile_path.is_file():
        text = launch_profile_path.read_text(encoding="utf-8")
        for marker in (
            "class_name CombatLaunchProfile",
            "extends BaseDefinition",
            "var upward_velocity",
            "var can_hit_downed",
            'return &"combat_launch_profile"',
            "func validation_errors",
        ):
            if marker not in text:
                errors.append(f"CMB-006 launch profile missing marker: {marker}")

    if reaction_profile_path.is_file():
        text = reaction_profile_path.read_text(encoding="utf-8")
        for marker in (
            "var can_be_launched",
            "var juggle_gravity",
            "var juggle_resistance_per_air_hit",
            "var juggle_gravity_multiplier_per_resistance",
            "var juggle_maximum_gravity_multiplier",
            "var juggle_launch_reduction_per_resistance",
            "var juggle_minimum_launch_multiplier",
        ):
            if marker not in text:
                errors.append(f"CMB-006 reaction profile missing marker: {marker}")

    if elevation_path.is_file():
        text = elevation_path.read_text(encoding="utf-8")
        for marker in (
            "func launch(upward_velocity: float) -> bool",
            "func force_land() -> bool",
            "func advance(delta: float, gravity_multiplier: float = 1.0) -> bool",
            "vertical_velocity -= gravity * gravity_multiplier * delta",
        ):
            if marker not in text:
                errors.append(f"CMB-006 ElevationModel missing marker: {marker}")

    if juggle_path.is_file():
        text = juggle_path.read_text(encoding="utf-8")
        for marker in (
            "class_name JuggleModel",
            "extends RefCounted",
            'preload("res://scripts/actors/elevation_model.gd")',
            "const MAX_AIRBORNE_CONTROL_TICKS := 210",
            "const KNOCKDOWN_DURATION_TICKS := 30",
            "const MAX_GROUND_PURSUIT_HITS := 1",
            'const STATE_AIRBORNE := &"airborne"',
            'const STATE_KNOCKDOWN := &"knockdown"',
            "func register_airborne_hit() -> bool",
            "func effective_launch_multiplier() -> float",
            "func effective_gravity_multiplier() -> float",
            "func consume_ground_pursuit() -> bool",
            "func advance_tick() -> StringName",
            "func interrupt_to_ground() -> void",
            "_airborne_control_ticks >= MAX_AIRBORNE_CONTROL_TICKS",
            "_knockdown_ticks_remaining = KNOCKDOWN_DURATION_TICKS",
        ):
            if marker not in text:
                errors.append(f"CMB-006 JuggleModel missing marker: {marker}")
        forbidden = re.search(
            r"\b(Input|AnimationPlayer|AudioStreamPlayer|CanvasItem|App|"
            r"GameLog|RandomNumberGenerator)\b|\brand[fi]_range\b|\brand[fi]\b|"
            r"get_node\s*\(|extends\s+(Node|Area2D|Control)",
            text,
        )
        if forbidden:
            errors.append(
                "CMB-006 juggle core depends on scene, presentation, or RNG: "
                f"{forbidden.group(0)}"
            )

    if combatant_path.is_file():
        text = combatant_path.read_text(encoding="utf-8")
        for marker in (
            'preload("res://scripts/combat/juggle_model.gd")',
            "signal launched",
            "signal forced_landed",
            "signal knocked_down",
            "signal knockdown_recovered",
            'const REACTION_AIRBORNE := &"airborne"',
            'const REACTION_KNOCKDOWN := &"knockdown"',
            'const REJECTION_INVALID_LAUNCH_PROFILE := &"invalid_launch_profile"',
            'const REJECTION_TARGET_KNOCKDOWN_PROTECTED := &"target_knockdown_protected"',
            'const REJECTION_GROUND_PURSUIT_LIMIT := &"ground_pursuit_limit_reached"',
            "launch_profile: CombatLaunchProfile = null",
            "func hit_height_range",
            "func _launch_profile_matches_packet",
            "_juggle_model.register_airborne_hit()",
            "_juggle_model.launch(launch_profile.upward_velocity)",
            "_juggle_model.interrupt_to_ground()",
        ):
            if marker not in text:
                errors.append(f"CMB-006 CombatantModel missing marker: {marker}")

    if result_path.is_file():
        text = result_path.read_text(encoding="utf-8")
        for marker in (
            "var launch_velocity: float",
            "var juggle_resistance: float",
            "var ground_pursuit_consumed: bool",
            "new_launch_velocity: float = 0.0",
            "new_juggle_resistance: float = 0.0",
            "new_ground_pursuit_consumed: bool = false",
        ):
            if marker not in text:
                errors.append(f"CMB-006 HitResult missing marker: {marker}")

    resource_contracts = {
        ROOT / "data/combat/launch_profiles/dev_launcher.tres": (
            'definition_id = &"combat.launch.dev_launcher"',
            "upward_velocity = 720.0",
            "can_hit_downed = false",
        ),
        ROOT / "data/combat/launch_profiles/dev_ground_pursuit.tres": (
            'definition_id = &"combat.launch.dev_ground_pursuit"',
            "upward_velocity = 0.0",
            "can_hit_downed = true",
        ),
        ROOT / "data/combat/reaction_profiles/normal.tres": (
            "can_be_launched = true",
            "juggle_gravity = 1800.0",
            "juggle_resistance_per_air_hit = 1.0",
            "juggle_gravity_multiplier_per_resistance = 0.25",
            "juggle_maximum_gravity_multiplier = 2.5",
            "juggle_launch_reduction_per_resistance = 0.15",
            "juggle_minimum_launch_multiplier = 0.35",
        ),
        ROOT / "data/combat/reaction_profiles/elite.tres": (
            "can_be_launched = false",
            "juggle_gravity = 1800.0",
        ),
        ROOT / "data/combat/reaction_profiles/boss.tres": (
            "can_be_launched = false",
            "juggle_gravity = 1800.0",
        ),
    }
    for path, markers in resource_contracts.items():
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                errors.append(f"CMB-006 Resource {path.name} missing marker: {marker}")

    if attack_path.is_file():
        text = attack_path.read_text(encoding="utf-8")
        for marker in (
            'definition_id = &"attack.bladebound.a3_rising_slash"',
            'launch_profile = &"combat.launch.dev_launcher"',
            "max_hit_height = 160.0",
        ):
            if marker not in text:
                errors.append(f"CMB-006 launcher attack missing marker: {marker}")

    if sandbox_path.is_file():
        text = sandbox_path.read_text(encoding="utf-8")
        for marker in (
            'GameLog.info(&"JuggleSandbox", "CMB-006 airborne control ready")',
            'preload("res://data/attacks/dev_a3.tres")',
            "func _configure_launch_profiles() -> bool",
            "target.apply_damage(packet, result, launch_profile)",
            "combatant.hit_height_range(",
            "body.position.y = (",
            "normal.juggle_resistance",
        ):
            if marker not in text:
                errors.append(f"CMB-006 sandbox missing marker: {marker}")

    if test_path.is_file():
        text = test_path.read_text(encoding="utf-8")
        for marker in (
            "_test_elevation_combat_launch()",
            "_test_combat_launch_profiles()",
            "_test_normal_juggle_progression()",
            "_test_forced_landing_boundary()",
            "_test_knockdown_ground_pursuit()",
            "_test_juggle_immunity_and_interrupts()",
            "_test_juggle_determinism_and_lifecycle()",
        ):
            if marker not in text:
                errors.append(f"CMB-006 tests missing marker: {marker}")


def validate_workflow(errors: list[str]) -> None:
    workflow_path = ROOT / ".github/workflows/m0-ci.yml"
    if not workflow_path.is_file():
        return
    text = workflow_path.read_text(encoding="utf-8")
    for marker in (
        "version=4.7.1",
        "tools/validate_project.py",
        "res://scripts/tools/validate_data.gd",
        "res://tests/test_runner.gd",
        "build/test-results/game-tests.txt",
        '--export-debug "Windows Desktop"',
        "mkdir -p build/windows",
        "cp licenses/GODOT-ENGINE-LICENSE.md",
        "cp docs/ASSET-LICENSE-REGISTER.csv",
        '--main-pack "$RUNNER_TEMP/ember-corridor-m0.pck"',
        'grep -Fq "[DataRegistry] Loaded 15 definition(s)"',
        "actions/upload-artifact@v4",
        "runs-on: windows-latest",
        "Godot_v4.7.1-stable_win64.exe",
        "actions/download-artifact@v4",
        "PROJECT TEST SUMMARY: 87 passed, 0 failed",
        "Run exported game natively",
        'grep -Fq "[MovementSandbox] MOV-001 sandbox ready"',
        'grep -Fq "[ElevationSandbox] MOV-002 sandbox ready"',
        'grep -Fq "[DodgeSandbox] MOV-003 sandbox ready"',
        'grep -Fq "[StateMachineSandbox] CMB-001 core ready"',
        'grep -Fq "[AttackTimelineSandbox] CMB-002 timeline ready"',
        'grep -Fq "[HitboxSandbox] CMB-003 hit detection ready"',
        'grep -Fq "[DamageSandbox] CMB-004 formula ready"',
        'grep -Fq "[CombatantSandbox] CMB-005 combatant reactions ready"',
        'grep -Fq "[JuggleSandbox] CMB-006 airborne control ready"',
        'grep -Fq "[InputBufferSandbox] CMB-007 input buffer ready"',
        'grep -Fq "[NormalComboSandbox] CMB-008 three-hit combo ready"',
        'grep -Fq "[LinebreakerSandbox] CMB-009 linebreaker ready"',
        'grep -Fq "[HitFeedbackSandbox] CMB-010 feedback service ready"',
        'grep -Eq "^(SCRIPT )?ERROR:"',
    ):
        if marker not in text:
            errors.append(f"CI workflow missing step marker: {marker}")


def validate_release_contract(errors: list[str]) -> None:
    workflow_path = ROOT / ".github/workflows/windows-release.yml"
    installer_path = ROOT / "installer/windows/EmberCorridor.iss"
    version_path = ROOT / "release/VERSION"
    readme_path = ROOT / "README.md"
    version_info_path = ROOT / "scripts/core/version_info.gd"
    export_preset_path = ROOT / "export_presets.cfg"
    if not all(
        path.is_file()
        for path in (
            workflow_path,
            installer_path,
            version_path,
            readme_path,
            version_info_path,
            export_preset_path,
        )
    ):
        return

    workflow_text = workflow_path.read_text(encoding="utf-8")
    workflow_markers = (
        "name: Publish Windows Visual Slice Release",
        "workflow_dispatch:",
        "push:",
        "branches:",
        "- main",
        '"release/VERSION"',
        "contents: write",
        "runs-on: windows-latest",
        "Godot_v4.7.1-stable_win64.exe",
        "Godot_v4.7.1-stable_win64_console.exe",
        "Record visual acceptance boundary",
        "Publishing as a prerelease",
        "windowed visuals and input feel remain user-acceptance items",
        'Join-Path $env:RUNNER_TEMP "godot_console.exe"',
        "& $godotConsole --version",
        '$null -ne $versionExitCode -and $versionExitCode -ne 0',
        'versionOutput -match "^4\\.7\\.1\\.stable"',
        "& godot_console.exe --headless --path . --import --quit",
        "& godot_console.exe --headless --path . --script res://tests/test_runner.gd",
        "windows_release_x86_64.exe",
        'PROJECT TEST SUMMARY: 88 passed, 0 failed',
        "PASS: loaded and validated 15 definition(s)",
        '--export-release "Windows Desktop"',
        "Exported game is not a Windows PE executable",
        "PE machine 0x{0:X4}",
        "choco install innosetup",
        "ISCC.exe",
        '"/VERYSILENT"',
        "Installer did not place EmberCorridor.exe",
        "Installed game does not match the tested exported executable",
        r"\[DataRegistry\] Loaded 15 definition\(s\)",
        r"\[JuggleSandbox\] CMB-006 airborne control ready",
        r"\[InputBufferSandbox\] CMB-007 input buffer ready",
        r"\[NormalComboSandbox\] CMB-008 three-hit combo ready",
        r"\[LinebreakerSandbox\] CMB-009 linebreaker ready",
        r"\[HitFeedbackSandbox\] CMB-010 feedback service ready",
        "SHA256SUMS.txt",
        "actions/upload-artifact@v4",
        "GH_TOKEN: ${{ github.token }}",
        "gh release create",
        "--prerelease",
        "EmberCorridor-0.1.2-Visual-Slice-Setup-x64.exe",
        "EmberCorridor-0.1.2-Visual-Slice-Windows-x64.zip",
    )
    for marker in workflow_markers:
        if marker not in workflow_text:
            errors.append(f"Windows release workflow missing marker: {marker}")

    if re.search(r"(?m)^\s*pull_request\s*:", workflow_text):
        errors.append("Windows release workflow must not publish from pull requests")
    if not re.search(r"(?m)^\s*push\s*:", workflow_text):
        errors.append("Windows release workflow must publish from a push to main")

    installer_text = installer_path.read_text(encoding="utf-8")
    installer_markers = (
        "AppId={{5E08DCE9-20B5-4F60-8C7D-66E2469C1E87}",
        "PrivilegesRequired=lowest",
        "ArchitecturesAllowed=x64",
        "ArchitecturesInstallIn64BitMode=x64",
        'Source: "..\\..\\build\\windows\\EmberCorridor.exe"',
        "OutputBaseFilename=EmberCorridor-0.1.2-Visual-Slice-Setup-x64",
        'Name: "{autoprograms}\\Ember Corridor"',
        'Name: "{autodesktop}\\Ember Corridor"',
    )
    for marker in installer_markers:
        if marker not in installer_text:
            errors.append(f"Windows installer definition missing marker: {marker}")

    version = version_path.read_text(encoding="utf-8").strip()
    if version != "0.1.2-visual-slice":
        errors.append(
            "release/VERSION must be 0.1.2-visual-slice for the visual slice"
        )

    version_info_text = version_info_path.read_text(encoding="utf-8")
    if f'const GAME_VERSION := "{version}"' not in version_info_text:
        errors.append("VersionInfo.GAME_VERSION must match release/VERSION")
    if 'const BUILD_CHANNEL := "legacy visual slice"' not in version_info_text:
        errors.append("VersionInfo.BUILD_CHANNEL must identify the legacy visual slice")

    export_preset_text = export_preset_path.read_text(encoding="utf-8")
    for marker in (
        'application/file_version="0.1.2.0"',
        'application/product_version="0.1.2.0"',
        'application/file_description="Ember Corridor legacy-direction playable visual slice"',
    ):
        if marker not in export_preset_text:
            errors.append(f"Windows export metadata missing marker: {marker}")

    readme_text = readme_path.read_text(encoding="utf-8")
    for marker in (
        "v0.1.0-m1-preview",
        "已标记为不合格的历史灰盒",
        "不建议作为玩家版本下载",
        "真实窗口截图",
        "人工验收",
        "v0.1.2-visual-slice",
        "v0.1.1-m1-tech-preview",
        "已撤回",
        "旧方向",
    ):
        if marker not in readme_text:
            errors.append(f"README missing deprecated preview warning: {marker}")


def validate_export_boundary(errors: list[str]) -> None:
    preset_path = ROOT / "export_presets.cfg"
    if not preset_path.is_file():
        return
    text = preset_path.read_text(encoding="utf-8")
    match = re.search(r'(?m)^exclude_filter="([^"]*)"$', text)
    if not match:
        errors.append("Windows export preset must define an exclude_filter")
        return
    filters = {value.strip() for value in match.group(1).split(",")}
    required_filters = {
        "addons/*",
        "build/*",
        "design/*",
        "docs/*",
        "export_templates/*",
        "feature_profiles/*",
        "installer/*",
        "licenses/*",
        "release/*",
        "script_templates/*",
        "scripts/tools/*",
        "tests/*",
        "text_editor_themes/*",
        "tools/*",
    }
    missing = sorted(required_filters.difference(filters))
    if missing:
        errors.append(f"Windows export boundary missing filters: {', '.join(missing)}")


def validate_asset_registry(errors: list[str]) -> None:
    registry_path = ROOT / "docs/ASSET-LICENSE-REGISTER.csv"
    if not registry_path.is_file():
        return
    with registry_path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if tuple(reader.fieldnames or ()) != EXPECTED_ASSET_HEADERS:
            errors.append("asset register headers do not match the M0 schema")
            return
        rows = list(reader)
    if not rows:
        errors.append("asset register must contain at least the Godot Engine entry")
        return
    for row_index, row in enumerate(rows, start=2):
        for field in ("asset_id", "source_url", "author", "license", "project_path"):
            if not (row.get(field) or "").strip():
                errors.append(f"asset register row {row_index} has empty {field}")


def validate_script_uids(errors: list[str]) -> None:
    discovered: dict[str, Path] = {}
    for script_path in sorted(ROOT.rglob("*.gd")):
        relative_path = script_path.relative_to(ROOT)
        if ".godot" in relative_path.parts or "build" in relative_path.parts:
            continue
        uid_path = Path(f"{script_path}.uid")
        if not uid_path.is_file():
            errors.append(f"Godot script UID is not tracked: {relative_path}.uid")
            continue
        uid = uid_path.read_text(encoding="utf-8").strip()
        if not re.fullmatch(r"uid://[a-z0-9]+", uid):
            errors.append(f"invalid Godot script UID in {uid_path.relative_to(ROOT)}")
            continue
        if uid in discovered:
            errors.append(
                "duplicate Godot script UID in "
                f"{uid_path.relative_to(ROOT)} and {discovered[uid]}"
            )
            continue
        discovered[uid] = uid_path.relative_to(ROOT)


def validate_offline_boundary(errors: list[str]) -> None:
    forbidden = re.compile(
        r"\b("
        r"HTTPRequest|HTTPClient|WebSocketPeer|WebRTCPeerConnection|"
        r"ENetMultiplayerPeer|MultiplayerAPI|PacketPeerUDP|StreamPeerTCP|"
        r"TCPServer|UDPServer"
        r")\b|https?://"
    )
    source_suffixes = {".gd", ".tscn", ".tres"}
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in source_suffixes:
            continue
        relative_path = path.relative_to(ROOT)
        if ".godot" in relative_path.parts or "build" in relative_path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        match = forbidden.search(text)
        if match:
            errors.append(
                f"offline boundary violation in {relative_path}: {match.group(0)}"
            )


if __name__ == "__main__":
    sys.exit(main())
