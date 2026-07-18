#!/usr/bin/env python3
"""Generate static PopugVPocket console layout previews.

This mirrors the high-level geometry in app/ui/console_frame.gd closely enough
to catch empty zones and overlapping controls without launching Godot.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "artifacts" / "ui-preview"

SCREEN_ASPECT = 1.25
MIN_SIDE_MARGIN = 8.0
SAFE_FALLBACK_MARGIN = 10.0
MAX_CONSOLE_WIDTH = 720.0
MIN_TOUCH_TARGET = 56.0
HEADER_RATIO = 0.055
SCREEN_WIDTH_RATIO = 0.92
SCREEN_MAX_HEIGHT_RATIO = 0.46
SCREEN_GAP_RATIO = 0.038
SYSTEM_BUTTON_RATIO = 0.052
BOTTOM_MARGIN_RATIO = 0.045
ACTION_TOUCH_PAD = 16.0

PALETTE = {
    "dark": (15, 56, 15),
    "mid": (48, 98, 48),
    "light": (139, 172, 15),
    "hi": (155, 188, 15),
    "case_dark": (67, 68, 65),
    "case_mid": (91, 99, 70),
    "case_light": (156, 174, 91),
}


@dataclass
class Rect:
    x: float
    y: float
    w: float
    h: float

    @property
    def end_x(self) -> float:
        return self.x + self.w

    @property
    def end_y(self) -> float:
        return self.y + self.h

    def inset(self, amount: float) -> "Rect":
        return Rect(self.x + amount, self.y + amount, self.w - amount * 2.0, self.h - amount * 2.0)

    def as_int(self) -> tuple[int, int, int, int]:
        return (round(self.x), round(self.y), round(self.end_x), round(self.end_y))

    def overlaps(self, other: "Rect") -> bool:
        return self.x < other.end_x and self.end_x > other.x and self.y < other.end_y and self.end_y > other.y

    def text(self) -> str:
        return f"{int(self.x)},{int(self.y)} {int(self.w)}x{int(self.h)}"


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def layout(width: int, height: int) -> dict[str, Rect]:
    safe = Rect(0, 0, width, height)
    outer_margin = clamp(safe.w * 0.018, 4.0, SAFE_FALLBACK_MARGIN)
    content = safe.inset(outer_margin)
    console_w = min(MAX_CONSOLE_WIDTH, content.w - MIN_SIDE_MARGIN * 2.0)
    if console_w < 320.0:
        console_w = content.w
    width_t = clamp((console_w - 360.0) / 360.0, 0.0, 1.0)
    max_console_ratio = 1.85 + (1.55 - 1.85) * width_t
    console_h = min(content.h, max(640.0, console_w * max_console_ratio))
    console = Rect(content.x + (content.w - console_w) * 0.5, content.y + (content.h - console_h) * 0.5, console_w, console_h)

    header_h = clamp(console.h * HEADER_RATIO, 36.0, 56.0)
    screen_margin = clamp(console.w * (1.0 - SCREEN_WIDTH_RATIO) * 0.5, 10.0, 22.0)
    desired_screen_w = console.w - screen_margin * 2.0
    desired_screen_h = min(desired_screen_w / SCREEN_ASPECT, console.h * SCREEN_MAX_HEIGHT_RATIO)
    screen_w = desired_screen_h * SCREEN_ASPECT
    screen = Rect(console.x + (console.w - screen_w) * 0.5, console.y + header_h + clamp(console.h * 0.01, 6.0, 12.0), screen_w, desired_screen_h)

    adaptive_gap = clamp(console.h * SCREEN_GAP_RATIO, 20.0, 36.0)
    system_h = clamp(console.h * SYSTEM_BUTTON_RATIO, 40.0, 52.0)
    bottom_margin = clamp(console.h * BOTTOM_MARGIN_RATIO, 24.0, 44.0)
    system_y = console.end_y - bottom_margin - system_h
    controls_top = screen.end_y + adaptive_gap
    controls_bottom = system_y - clamp(console.h * 0.024, 14.0, 24.0)
    controls = Rect(console.x, controls_top, console.w, max(MIN_TOUCH_TARGET * 2.6, controls_bottom - controls_top))

    side_pad = clamp(console.w * 0.028, 10.0, 22.0)
    center_gap = clamp(console.w * 0.035, 12.0, 26.0)
    dpad_size = clamp(console.w * 0.52, 168.0, min(250.0, controls.h * 0.9))
    primary = clamp(dpad_size * 0.42, 72.0, 96.0)
    secondary = primary * 0.86
    spacing = primary * 0.82
    primary_touch_size = max(MIN_TOUCH_TARGET, primary + ACTION_TOUCH_PAD)
    action_size = spacing * 2.0 + primary_touch_size
    total_controls_w = dpad_size + center_gap + action_size
    if total_controls_w > console.w - side_pad * 2.0:
        shrink = (console.w - side_pad * 2.0) / total_controls_w
        dpad_size *= shrink
        primary *= shrink
        secondary *= shrink
        spacing *= shrink
        primary_touch_size = max(MIN_TOUCH_TARGET, primary + ACTION_TOUCH_PAD)
        action_size = spacing * 2.0 + primary_touch_size
        total_controls_w = dpad_size + center_gap + action_size

    controls_x = console.x + (console.w - total_controls_w) * 0.5
    controls_y = controls.y + min((controls.h - max(dpad_size, action_size)) * 0.48, 64.0)
    dpad = Rect(controls_x, controls_y + max(0.0, (action_size - dpad_size) * 0.5), dpad_size, dpad_size)
    cluster_center_x = controls_x + dpad_size + center_gap + action_size * 0.5
    cluster_center_y = controls_y + max(dpad_size, action_size) * 0.5
    actions = Rect(cluster_center_x - action_size * 0.5, cluster_center_y - action_size * 0.5, action_size, action_size)

    sys_w = clamp(console.w * 0.19, 82.0, 112.0)
    sys_gap = clamp(console.w * 0.075, 28.0, 48.0)
    sys_x = console.x + (console.w - (sys_w * 2.0 + sys_gap)) * 0.5
    menu = Rect(sys_x, system_y, sys_w, system_h)
    back = Rect(sys_x + sys_w + sys_gap, system_y, sys_w, system_h)

    return {
        "window": safe,
        "safe_rect": safe,
        "console_rect": console,
        "screen_rect": screen,
        "controls_rect": controls,
        "dpad_rect": dpad,
        "action_cluster_rect": actions,
        "menu_rect": menu,
        "back_rect": back,
    }


def has_overlap(rects: Iterable[Rect]) -> bool:
    items = list(rects)
    for index, rect in enumerate(items):
        for other in items[index + 1 :]:
            if rect.overlaps(other):
                return True
    return False


def draw_preview(width: int, height: int, rects: dict[str, Rect]) -> None:
    image = Image.new("RGB", (width, height), PALETTE["dark"])
    draw = ImageDraw.Draw(image)
    for y in range(0, height, 10):
        for x in range((y // 10) % 2 * 10, width, 20):
            draw.rectangle((x, y, x + 9, y + 9), fill=PALETTE["mid"])
    draw.rectangle(rects["console_rect"].as_int(), fill=PALETTE["case_dark"], outline=PALETTE["case_light"], width=3)
    inner = rects["console_rect"].inset(6)
    draw.rectangle(inner.as_int(), outline=PALETTE["case_mid"], width=1)
    draw.rectangle(rects["screen_rect"].as_int(), fill=PALETTE["dark"], outline=PALETTE["case_light"], width=4)
    draw.rectangle(rects["dpad_rect"].as_int(), outline=PALETTE["hi"], width=3)
    draw.rectangle(rects["action_cluster_rect"].as_int(), outline=PALETTE["hi"], width=3)
    draw.rectangle(rects["menu_rect"].as_int(), outline=PALETTE["case_light"], width=2)
    draw.rectangle(rects["back_rect"].as_int(), outline=PALETTE["case_light"], width=2)
    image.save(OUT / f"preview-{width}x{height}.png")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = [(360, 640), (360, 720), (393, 852), (412, 915), (540, 960), (1080, 2400)]
    lines = []
    for width, height in sizes:
        rects = layout(width, height)
        overlap = has_overlap([rects["screen_rect"], rects["dpad_rect"], rects["action_cluster_rect"], rects["menu_rect"], rects["back_rect"]])
        gap = rects["controls_rect"].y - rects["screen_rect"].end_y
        bottom_gap = rects["console_rect"].end_y - rects["back_rect"].end_y
        status = "PASS" if not overlap and gap <= 40 and bottom_gap <= 48 else "FAIL"
        lines.append(f"{width}x{height}: {status}")
        for key in ["safe_rect", "screen_rect", "controls_rect", "dpad_rect", "action_cluster_rect", "menu_rect", "back_rect"]:
            lines.append(f"  {key}: {rects[key].text()}")
        lines.append(f"  overlap detected: {'yes' if overlap else 'no'}")
        lines.append(f"  screen-controls gap: {int(gap)}")
        lines.append(f"  bottom gap: {int(bottom_gap)}")
        draw_preview(width, height, rects)
    (OUT / "layout-report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
