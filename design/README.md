# Design source assets

This directory contains visual-development material for **Ember Corridor**.

## Status rules

- `concepts/` contains exploration only. These files may guide composition, palette, silhouettes, and Figma layouts.
- Concept files are not shippable game assets unless their source, rights, authorship, and production treatment are reviewed and the asset register status is changed to `approved`.
- Runtime UI must follow the frozen Figma frame and component versions recorded in the handoff documents.

## Current Figma file

- File: `余烬回廊 · 单机游戏视觉设计 v0.1`
- URL: https://www.figma.com/design/hD242j8y6JUddZ9sdjsNh0
- Current state: foundations in progress; not frozen.

Figma is currently not the active blocking source because Starter MCP write limits prevent continuous iteration. The versioned executable prototype in `prototype/` is the current UI design source until the Figma workflow resumes. See `docs/ADR-UI-001-EXECUTABLE-DESIGN-SOURCE.md`.

## Executable UI prototype

- Entry point: `prototype/index.html`
- Windows launcher: `prototype/OPEN-PROTOTYPE.bat`
- Coverage: 15 screens, primary keyboard/gamepad flows, component states, loading, errors, confirmations, normal/elite/boss HUDs, 1080p and 720p validation.
- Status: interactive design and handoff source; not the final Godot runtime UI.

## Visual-development package v0.1

The package establishes one coherent, original industrial-fantasy direction: ember-orange human/physical action versus cyan anomaly energy, readable side-scrolling lanes, strong silhouettes, and non-graphic fantasy combat.

| File | Design purpose |
| --- | --- |
| `concepts/title_keyart_v01.png` | Title-screen composition and menu-safe negative space |
| `concepts/grey_harbor_hub_v01.png` | Grey Harbor hub navigation, NPC zones, forge, route board, and corridor gate |
| `concepts/combat_corridor_keyframe_v01.png` | Core combat HUD composition and base corridor mood |
| `concepts/combat_transit_gallery_v01.png` | Multi-target and elite-combat readability, attack telegraphs, and alternate room layout |
| `concepts/boss_kiln_warden_v01.png` | Boss HUD, phase readability, arena scale, and hazard telegraphs |
| `concepts/player_corridor_ranger_sheet_v01.png` | Player silhouette, costume, materials, poses, and animation direction |
| `concepts/enemy_roster_v01.png` | Enemy-family silhouettes, scale contrast, roles, and material language |
| `concepts/skill_icons_sheet_v01.png` | Eight active-skill icon concepts and shared frame language |
| `concepts/equipment_icons_sheet_v01.png` | Twelve inventory/equipment icon concepts and item-rarity presentation |

These images are concept references for Figma and production planning. They are not gameplay captures, finished sprites, cut UI assets, final environment textures, or approved release assets. Runtime use requires deliberate asset extraction/redrawing, animation preparation, rights review, and an `approved` entry in the asset register.

See `concepts/MANIFEST.md` for the intended Figma placement and production follow-up for every image.
