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
    "scenes/actors/player.tscn",
    "scenes/tests/movement_sandbox.tscn",
    "docs/M1-MOV-001-TEST-PLAN.md",
    "docs/M1-MOV-002-TEST-PLAN.md",
    "docs/M1-MOV-003-TEST-PLAN.md",
    "docs/M1-CMB-001-TEST-PLAN.md",
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
    validate_workflow(errors)
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
        'run/main_scene="res://scenes/tests/movement_sandbox.tscn"',
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
        '--export-debug "Windows Desktop"',
        "mkdir -p build/windows",
        "cp licenses/GODOT-ENGINE-LICENSE.md",
        "cp docs/ASSET-LICENSE-REGISTER.csv",
        '--main-pack "$RUNNER_TEMP/ember-corridor-m0.pck"',
        'grep -Fq "[DataRegistry] Loaded 1 definition(s)"',
        "actions/upload-artifact@v4",
        "runs-on: windows-latest",
        "Godot_v4.7.1-stable_win64.exe",
        "actions/download-artifact@v4",
        "PROJECT TEST SUMMARY: 29 passed, 0 failed",
        "Run exported game natively",
        'grep -Fq "[MovementSandbox] MOV-001 sandbox ready"',
        'grep -Fq "[ElevationSandbox] MOV-002 sandbox ready"',
        'grep -Fq "[DodgeSandbox] MOV-003 sandbox ready"',
        'grep -Fq "[StateMachineSandbox] CMB-001 core ready"',
        'grep -Eq "^(SCRIPT )?ERROR:"',
    ):
        if marker not in text:
            errors.append(f"CI workflow missing step marker: {marker}")


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
        "build/*",
        "docs/*",
        "licenses/*",
        "scripts/tools/*",
        "tests/*",
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
