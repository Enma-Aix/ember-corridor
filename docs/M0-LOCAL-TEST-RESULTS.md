# M0 local test results

Test date: 2026-08-06  
Engine: Godot 4.7.1.stable.official.a13da4feb  
Environment: Linux x86_64, headless, Compatibility renderer

| Check | Result |
| --- | --- |
| Repository static validation | PASS |
| Godot headless import | PASS |
| Resource data validation | PASS, 1 definition |
| Headless test suite | PASS, 8 tests |
| Boot scene smoke test | PASS |
| Windows export preset validation | PASS up to template availability |

The local environment intentionally did not download the 1.28 GB full export-template bundle. GitHub Actions performs the official template download, Windows Debug export, executable size check, and artifact upload.

The complete local suite was rerun after CI hardening and remained green.

Commands:

    python3 tools/validate_project.py
    godot --headless --path . --import --quit
    godot --headless --path . --script res://scripts/tools/validate_data.gd
    godot --headless --path . --script res://tests/test_runner.gd
    godot --headless --path . --quit-after 3
