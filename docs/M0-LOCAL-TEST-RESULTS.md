# M0 local test results

Test date: 2026-08-06  
Engine: Godot 4.7.1.stable.official.a13da4feb  
Environment: Linux x86_64, headless, Compatibility renderer

| Check | Result |
| --- | --- |
| Repository static validation | PASS |
| Godot headless import | PASS |
| Resource data validation | PASS, 1 definition |
| Headless test suite | PASS, 9 tests |
| Boot scene smoke test | PASS |
| Official export-template archive integrity | PASS |
| Windows x86-64 Debug export | PASS |
| Exported resource-pack smoke test | PASS, 1 definition loaded |
| Export content boundary | PASS, tests/docs/build reports excluded |

The official Godot 4.7.1 export-template archive was downloaded and checked with
`unzip -t`. Its SHA-256 is
`86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.

The final Windows artifact is a PE32+ GUI executable for x86-64:

- File: `build/windows/EmberCorridor.exe`
- Size: 103,014,176 bytes
- SHA-256: `5c5988f9045ec445d049985ba4727c21875a5227ac7f9589416c191ec7d19d46`
- Sidecars: Godot Engine license and asset-license register

The Linux sandbox cannot natively execute a Windows PE file and has no Wine
installation. To test the packaged game payload rather than only its source
project, the same Windows preset was exported as a PCK and started with Godot
4.7.1 headlessly. The packaged boot completed with exit code 0 and
`DataRegistry` loaded exactly 1 definition. A native Windows launch remains a
manual/Windows-runner acceptance check.

## Iteration findings

1. The first export included generated test reports and CSV translation caches.
   Export filters plus `.gdignore` boundaries now keep build output and
   documentation outside the game pack.
2. The first packaged boot loaded 0 definitions because exported resources are
   enumerated as `.tres.remap`. `DataRegistry` now canonicalizes remapped paths,
   has a dedicated regression test, and the CI workflow boots the packaged PCK.

The complete local suite was rerun after both fixes and remained green.

Commands:

    python3 tools/validate_project.py
    godot --headless --path . --import --quit
    godot --headless --path . --script res://scripts/tools/validate_data.gd
    godot --headless --path . --script res://tests/test_runner.gd
    godot --headless --path . --quit-after 3
    mkdir -p build/windows
    godot --headless --path . --export-debug "Windows Desktop" build/windows/EmberCorridor.exe
    godot --headless --path . --export-pack "Windows Desktop" /tmp/ember-corridor-m0.pck
    godot --headless --main-pack /tmp/ember-corridor-m0.pck --quit-after 3
