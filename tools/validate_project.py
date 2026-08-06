#!/usr/bin/env python3
"""Fast, dependency-free validation for the M0 repository contract."""

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
    "docs/ASSET-LICENSE-REGISTER.csv",
    "licenses/GODOT-ENGINE-LICENSE.md",
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
    validate_workflow(errors)
    validate_asset_registry(errors)
    validate_offline_boundary(errors)

    if errors:
        print(f"M0 STATIC VALIDATION: FAIL ({len(errors)} issue(s))")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("M0 STATIC VALIDATION: PASS")
    print(f"  - {len(REQUIRED_FILES)} required files")
    print(f"  - {len(REQUIRED_ACTIONS)} Input actions")
    print(f"  - {len(EXPECTED_LAYERS)} named collision layers")
    print(f"  - {len(EXPECTED_AUTOLOADS)} approved Autoload services")
    print("  - asset license register and offline boundary")
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
        "actions/upload-artifact@v4",
    ):
        if marker not in text:
            errors.append(f"CI workflow missing step marker: {marker}")


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


def validate_offline_boundary(errors: list[str]) -> None:
    forbidden = re.compile(
        r"\b(HTTPRequest|WebSocketPeer|ENetMultiplayerPeer|MultiplayerAPI)\b"
    )
    for path in sorted((ROOT / "scripts").rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        match = forbidden.search(text)
        if match:
            errors.append(
                f"offline boundary violation in {path.relative_to(ROOT)}: {match.group(1)}"
            )


if __name__ == "__main__":
    sys.exit(main())

