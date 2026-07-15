#!/usr/bin/env python3
"""Create standalone OpenPocket app and game cartridge template repositories."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SDK_VERSION = "0.3.2"
PLACEHOLDER_PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
    "1f15c4890000000a49444154789c6360000002000100ffff030000060005"
    "57bfab0000000049454e44ae426082"
)


def write(path: Path, content: str | bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, bytes):
        path.write_bytes(content)
    else:
        path.write_text(content.strip() + "\n", encoding="utf-8")


def manifest(package_id: str, name: str, kind: str) -> str:
    return json.dumps(
        {
            "id": package_id,
            "name": name,
            "version": "0.1.0",
            "type": kind,
            "entry_scene": "main.tscn",
            "sdk_version": SDK_VERSION,
            "author": "Your Name",
            "description": f"{name} OpenPocket cartridge.",
            "category": "arcade" if kind == "game" else "utility",
            "capabilities": ["storage", "audio", "theme", "system_menu"],
        },
        indent=2,
    )


def cartridge_manifest(package_id: str, name: str, kind: str) -> str:
    return json.dumps(
        {
            "format_version": 1,
            "id": package_id,
            "name": name,
            "version": "0.1.0",
            "type": kind,
            "entry_scene": f"res://cartridges/{package_id}/main.tscn",
            "sdk_version": SDK_VERSION,
            "runtime": {"min_version": SDK_VERSION, "max_version": None},
            "author": {"name": "Your Name", "url": ""},
            "description": f"{name} OpenPocket cartridge.",
            "category": "arcade" if kind == "game" else "utility",
            "icon": "icon.png",
            "license": "MIT",
            "capabilities": ["storage", "audio", "theme", "system_menu"],
            "permissions": [],
            "content": {"file": "content.pck", "sha256": "0" * 64},
            "signature": None,
            "store": {"featured": False, "tags": ["template"]},
        },
        indent=2,
    )


APP_SCRIPT = r'''
extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.example.pockethello"
const ITEMS := ["HELLO", "SETTINGS", "ABOUT"]
var selected := 0
var friendly := true


func _ready() -> void:
	friendly = bool(PocketStorage.get_package_setting(PACKAGE_ID, "friendly", true))


func _process(_delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.UP): selected = wrapi(selected - 1, 0, ITEMS.size())
	if PocketInput.just_pressed(PocketInput.DOWN): selected = wrapi(selected + 1, 0, ITEMS.size())
	if PocketInput.just_pressed(PocketInput.A) and selected == 1:
		friendly = not friendly
		PocketStorage.set_package_setting(PACKAGE_ID, "friendly", friendly)
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.MENU): request_system_menu.emit()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT): exit_to_library.emit()
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(20, 18), "POCKET HELLO", p["hi"], 2)
	for index in range(ITEMS.size()):
		var prefix := "> " if index == selected else "  "
		PixelFont.draw_text(self, Vector2(28, 72 + index * 30), prefix + ITEMS[index], p["light"], 2)
	var greeting := "WELCOME FRIEND" if friendly else "HELLO WORLD"
	PixelFont.draw_text(self, Vector2(28, 190), greeting, p["hi"], 2)
	PixelFont.draw_text(self, Vector2(16, 286), "DPAD MOVE  A SELECT  B BACK", p["light"], 1)


func set_paused_by_system(paused: bool) -> void: set_process(not paused)
'''


GAME_SCRIPT = r'''
extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.example.pocketdodge"
var player := Vector2(200, 270)
var obstacle := Vector2(200, -20)
var score := 0
var high_score := 0
var speed := 120.0
var playing := false
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	high_score = int(PocketStorage.get_package_data(PACKAGE_ID, "high_score", 0))
	speed = float(PocketStorage.get_package_setting(PACKAGE_ID, "speed", 120))


func _process(delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.A) and not playing: _restart()
	if PocketInput.just_pressed(PocketInput.X) and not playing:
		speed = 170.0 if speed < 150.0 else 120.0
		PocketStorage.set_package_setting(PACKAGE_ID, "speed", int(speed))
	if PocketInput.just_pressed(PocketInput.MENU): request_system_menu.emit()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT): exit_to_library.emit()
	if playing:
		player.x = clampf(player.x + PocketInput.axis().x * 190.0 * delta, 12.0, 388.0)
		obstacle.y += speed * delta
		if obstacle.y > 330:
			score += 1
			_spawn_obstacle()
		if Rect2(player - Vector2(10, 8), Vector2(20, 16)).has_point(obstacle): _game_over()
	queue_redraw()


func _restart() -> void:
	playing = true
	score = 0
	player = Vector2(200, 270)
	_spawn_obstacle()


func _spawn_obstacle() -> void:
	obstacle = Vector2(random.randi_range(16, 384), -10)


func _game_over() -> void:
	playing = false
	high_score = maxi(high_score, score)
	PocketStorage.set_package_data(PACKAGE_ID, "high_score", high_score)
	CartridgeAudio.play_ui("error")


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(14, 14), "POCKET DODGE  " + str(score) + "  HI " + str(high_score), p["hi"], 1)
	draw_rect(Rect2(player - Vector2(10, 8), Vector2(20, 16)), p["light"], true)
	draw_rect(Rect2(obstacle - Vector2(7, 7), Vector2(14, 14)), p["hi"], true)
	if not playing: PixelFont.draw_text(self, Vector2(96, 140), "A START  X SPEED", p["light"], 2)


func set_paused_by_system(paused: bool) -> void: set_process(not paused)
'''


def readme(kind: str, name: str, package_id: str) -> str:
    return f'''# OpenPocket {kind.title()} Cartridge Template

Standalone Godot template for humans and AI agents. The sample is **{name}** and targets experimental OpenPocket SDK `{SDK_VERSION}`.

## Preview

Open `project.godot` to run a 400x320 controller-first pixel sample.

## Prerequisites

- Godot 4.7 available as `godot`/`godot4` or under `.tools/godot`.
- Python 3.10+.
- Git.

## Use This Template

Use GitHub's `Use this template` button, or clone the repository. Rename `{package_id}` in both manifests, `cartridge/main.gd`, and the unique entry path. Do not change `res://cartridges/<id>/` to an arbitrary root.

## Run And Controls

Open `project.godot` and run. Arrow keys/WASD are D-pad; Z=A, X=B, A=X, S=Y, Enter=MENU, Escape=BACK.

## Validate And Build

```powershell
python tools/validate.py
python tools/build.py
```

The `.pctrg` is written to `dist/cartridges/`. Install it through OpenPocket's `Install Cartridge` picker with Developer Mode enabled.

## Manifest And Release

Update version, author, description, capabilities, license, and changelog before every release. Publish source, `.pctrg`, and SHA-256. SDK code is pinned in `tools/openpocket_sdk`; replace that folder from a newer official template to update it.

## Creating Your Cartridge Without AI

Start with `cartridge/main.gd`, keep each screen operable with console buttons, save only through `PocketStorage`, and iterate in Godot. Read `docs/API.md` and `docs/BUILDING.md` before adding features.

## Creating With Codex

Use the prompt in `docs/AI_AGENT_GUIDE.md`. Codex must read `AGENTS.md`, stay inside the cartridge root, validate, and build before reporting completion.

## Troubleshooting

- `Godot executable not found`: add Godot to PATH or `.tools/godot`.
- `entry scene root`: update every package id occurrence consistently.
- `direct Input/FileAccess`: use Pocket APIs.
- Installation blocked: enable Developer Mode only for code you trust.

## License

MIT for template code. Replace author metadata for your cartridge and document third-party assets.
'''


def create_repository(destination: Path, kind: str) -> None:
    if destination.exists() and any(destination.iterdir()):
        raise SystemExit(f"Refusing to overwrite non-empty directory: {destination}")
    name = "Pocket Hello" if kind == "app" else "Pocket Dodge"
    package_id = "org.example.pockethello" if kind == "app" else "org.example.pocketdodge"
    destination.mkdir(parents=True, exist_ok=True)
    write(destination / "README.md", readme(kind, name, package_id))
    write(destination / "AGENTS.md", AGENTS)
    write(destination / "CONTRIBUTING.md", CONTRIBUTING)
    write(destination / "SECURITY.md", SECURITY)
    write(destination / "THIRD_PARTY.md", "# Third-Party Notices\n\nNo third-party runtime assets are included.")
    write(destination / "LICENSE", (ROOT / "LICENSE").read_text(encoding="utf-8"))
    write(destination / ".gitignore", ".godot/\nbuild/\ndist/\n.tools/\n__pycache__/\n*.pyc")
    write(destination / "project.godot", PROJECT)
    write(destination / "cartridge" / "manifest.json", manifest(package_id, name, kind))
    write(destination / "cartridge" / "cartridge.json", cartridge_manifest(package_id, name, kind))
    write(destination / "cartridge" / "main.gd", APP_SCRIPT if kind == "app" else GAME_SCRIPT)
    write(destination / "cartridge" / "main.tscn", SCENE.replace("SampleRoot", name.replace(" ", "")))
    write(destination / "cartridge" / "icon.png", PLACEHOLDER_PNG)
    write(destination / "cartridge" / "README.md", f"# {name}\n\nStarter OpenPocket {kind} cartridge.")
    write(destination / "cartridge" / "LICENSE", (ROOT / "LICENSE").read_text(encoding="utf-8"))
    write(destination / "docs" / "API.md", API_DOC)
    write(destination / "docs" / "BUILDING.md", BUILD_DOC)
    write(destination / "docs" / "AI_AGENT_GUIDE.md", AI_DOC)
    write(destination / "docs" / "PUBLISHING.md", PUBLISH_DOC)
    write(destination / ".codex" / "skills" / ("create-app.md" if kind == "app" else "create-game.md"), SKILL.replace("{kind}", kind))
    write(destination / ".github" / "workflows" / "validate.yml", WORKFLOW)
    write(destination / ".github" / "ISSUE_TEMPLATE" / "bug_report.md", ISSUE)
    write(destination / ".github" / "pull_request_template.md", PR)
    write(destination / "tools" / "validate.py", VALIDATOR)
    write(destination / "tools" / "build.py", BUILD_WRAPPER)
    write(destination / "tools" / "setup.py", SETUP)
    builder = (ROOT / "tools" / "cartridge_builder.py").read_text(encoding="utf-8")
    builder = builder.replace("Path(__file__).resolve().parents[1]", "Path(__file__).resolve().parents[2]", 1)
    write(destination / "tools" / "openpocket_sdk" / "cartridge_builder.py", builder)
    write(destination / "tools" / "openpocket_sdk" / "VERSION", SDK_VERSION)
    runtime = destination / "tools" / "openpocket_sdk" / "runtime"
    write(runtime / "pocket_input.gd", INPUT_STUB)
    write(runtime / "pocket_storage.gd", STORAGE_STUB)
    write(runtime / "cartridge_audio.gd", AUDIO_STUB)
    write(runtime / "pocket_theme.gd", THEME_STUB)
    write(runtime / "pocket_system.gd", SYSTEM_STUB)
    shutil.copy2(ROOT / "app" / "ui" / "components" / "pixel_font.gd", runtime / "pixel_font.gd")


AGENTS = '''# AGENTS.md

- Do not modify the OpenPocket runtime.
- Use PocketInput, never direct Input in cartridge code.
- Use package-scoped PocketStorage, never direct FileAccess.
- Preserve the unique cartridge resource root.
- Do not add network access without a declared future capability.
- Use PixelFont and pixel-art UI; no default fonts.
- Every screen must support controller-only navigation; no mouse-only UI.
- Avoid unrelated refactors.
- Run `python tools/validate.py` and `python tools/build.py`.
'''
CONTRIBUTING = '''# Contributing

Keep changes focused, update both manifests, preserve controller navigation, document assets, and run validation plus build before opening a pull request.
'''
SECURITY = '''# Security

OpenPocket SDK 0.3.2 does not sandbox or digitally sign external Godot code. Do not install cartridges from untrusted sources. Report vulnerabilities privately through GitHub when enabled.
'''
PROJECT = '''config_version=5

[application]
config/name="OpenPocket Cartridge Template"
run/main_scene="res://cartridge/main.tscn"

[autoload]
PocketInput="*res://tools/openpocket_sdk/runtime/pocket_input.gd"
PocketStorage="*res://tools/openpocket_sdk/runtime/pocket_storage.gd"
CartridgeAudio="*res://tools/openpocket_sdk/runtime/cartridge_audio.gd"
PocketTheme="*res://tools/openpocket_sdk/runtime/pocket_theme.gd"
PocketSystem="*res://tools/openpocket_sdk/runtime/pocket_system.gd"

[display]
window/size/viewport_width=400
window/size/viewport_height=320
window/size/window_width_override=800
window/size/window_height_override=640
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
'''
SCENE = '''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://cartridge/main.gd" id="1"]
[node name="SampleRoot" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
'''
API_DOC = '''# Pocket API

Experimental 0.3.2 services: PocketInput for controls, PocketStorage for package settings/data, CartridgeAudio for scoped feedback, PocketTheme for palette, and PocketSystem for read-only context. Emit `request_system_menu` and `exit_to_library` for lifecycle actions.
'''
BUILD_DOC = '''# Building

Run `python tools/validate.py`, then `python tools/build.py`. The standalone builder calls Godot `--export-pack`, verifies a real PCK header and SHA-256, and writes `dist/cartridges/<id>-<version>.pctrg`.
'''
AI_DOC = '''# AI Agent Guide

Read `AGENTS.md`. Work only in this repository and use public Pocket APIs. Preserve the package id/resource root relationship, PixelFont, controller navigation, pause/resume, and exit flow. Direct Input, FileAccess, shell internals, arbitrary roots, undeclared network, mouse-only UI, and unrelated refactors are forbidden.

Prompt:

```text
Read AGENTS.md and docs/AI_AGENT_GUIDE.md.
Create an OpenPocket cartridge based on this template.
Concept: [describe cartridge]
Use PocketInput and package-scoped storage, preserve pixel/controller UI, update manifests, validate, build, and report output.
```
'''
PUBLISH_DOC = '''# Publishing

Publish source, license, `.pctrg`, SHA-256, package id/version, SDK compatibility, controls, capabilities, storage migration notes, and third-party notices. Do not claim signing or sandboxing.
'''
SKILL = '''# Create OpenPocket {kind}

Read AGENTS.md, choose a unique reverse-DNS id, update both manifests and script constants, use only Pocket APIs, preserve controller/pixel UI, validate, build, and report the `.pctrg` path.
'''
WORKFLOW = '''name: Validate
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.12"}
      - run: python tools/validate.py
'''
ISSUE = '''---
name: Bug report
about: Report a cartridge template problem
---
Describe the issue, Godot/Python versions, controls used, and reproduction steps.
'''
PR = '''## Summary

## Checks

- [ ] `python tools/validate.py`
- [ ] `python tools/build.py`
- [ ] Controller-only navigation tested
'''
VALIDATOR = r'''#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
package = json.loads((ROOT / "cartridge/manifest.json").read_text(encoding="utf-8"))
cartridge = json.loads((ROOT / "cartridge/cartridge.json").read_text(encoding="utf-8"))
assert package["id"] == cartridge["id"]
assert package["version"] == cartridge["version"]
assert package["type"] in {"app", "game"}
assert (ROOT / "cartridge" / package["entry_scene"]).exists()
assert cartridge["entry_scene"].startswith(f"res://cartridges/{package['id']}/")
for script in (ROOT / "cartridge").glob("**/*.gd"):
    text = script.read_text(encoding="utf-8")
    assert not re.search(r"\bInput\.", text), f"direct Input in {script}"
    assert "FileAccess" not in text, f"direct FileAccess in {script}"
assert "PixelFont" in (ROOT / "cartridge/main.gd").read_text(encoding="utf-8")
print("OpenPocket template validation passed.")
'''
BUILD_WRAPPER = r'''#!/usr/bin/env python3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/openpocket_sdk"))
import cartridge_builder

output = cartridge_builder.build(ROOT / "cartridge", ROOT / "dist/cartridges")
result = cartridge_builder.inspect(output)
print(f"[OK] {result.manifest['id']} {result.manifest['version']}")
print(output)
'''
SETUP = '''#!/usr/bin/env python3
from pathlib import Path
print("OpenPocket SDK", (Path(__file__).parent / "openpocket_sdk/VERSION").read_text().strip())
print("Setup complete. Open project.godot in Godot 4.7.")
'''
INPUT_STUB = '''extends Node
const UP="pocket_up"; const DOWN="pocket_down"; const LEFT="pocket_left"; const RIGHT="pocket_right"
const A="pocket_a"; const B="pocket_b"; const X="pocket_x"; const Y="pocket_y"; const MENU="pocket_menu"; const EXIT="pocket_exit"
func just_pressed(action: String) -> bool: return Input.is_action_just_pressed(action)
func axis() -> Vector2: return Input.get_vector(LEFT, RIGHT, UP, DOWN)
'''
STORAGE_STUB = '''extends Node
var values := {}
func get_package_setting(id: String, key: String, fallback=null): return values.get(id+":s:"+key, fallback)
func set_package_setting(id: String, key: String, value) -> bool: values[id+":s:"+key]=value; return true
func get_package_data(id: String, key: String, fallback=null): return values.get(id+":d:"+key, fallback)
func set_package_data(id: String, key: String, value) -> bool: values[id+":d:"+key]=value; return true
'''
AUDIO_STUB = '''extends Node
func play_ui(_event_name: String) -> bool: return true
func play_sfx(_stream_id: String) -> bool: return true
func stop_own_sounds() -> void: pass
func set_local_volume(_value: float) -> void: pass
'''
THEME_STUB = '''extends Node
func palette() -> Dictionary: return {"dark":Color("101d14"),"mid":Color("31502f"),"light":Color("91ad55"),"hi":Color("c5df58")}
func theme_label() -> String: return "MONO"
'''
SYSTEM_STUB = '''extends Node
func get_cartridge_context() -> Dictionary: return {"id":"template.preview","version":"0.1.0","trust":"development"}
'''


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", type=Path, default=ROOT.parent)
    parser.add_argument("--refresh-sdk", action="store_true")
    args = parser.parse_args()
    if args.refresh_sdk:
        builder = (ROOT / "tools" / "cartridge_builder.py").read_text(encoding="utf-8")
        builder = builder.replace("Path(__file__).resolve().parents[1]", "Path(__file__).resolve().parents[2]", 1)
        for repository in ["openpocket-app-template", "openpocket-game-template"]:
            destination = args.output_root / repository / "tools" / "openpocket_sdk" / "cartridge_builder.py"
            if not destination.parent.exists():
                raise SystemExit(f"Template repository missing: {destination.parent}")
            write(destination, builder)
        return 0
    create_repository(args.output_root / "openpocket-app-template", "app")
    create_repository(args.output_root / "openpocket-game-template", "game")
    print(args.output_root / "openpocket-app-template")
    print(args.output_root / "openpocket-game-template")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
