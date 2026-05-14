#!/usr/bin/env python3
"""
generate_icons.py
Generates all required Flutter platform icons from appicon.png
Requires: pip install Pillow
"""

import os
import sys
import struct
import zlib
from pathlib import Path

# ── Try to import Pillow ─────────────────────────────────────────────────────
try:
    from PIL import Image
except ImportError:
    print("Pillow not found. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

# ── Paths ────────────────────────────────────────────────────────────────────
ROOT = Path(__file__).parent
SRC  = ROOT / "appicon.png"

assert SRC.exists(), f"Source icon not found: {SRC}"

img = Image.open(SRC).convert("RGBA")
print(f"[OK] Loaded source icon: {SRC} ({img.size[0]}x{img.size[1]})")


def pad_to_square(src_img: Image.Image) -> Image.Image:
    """Center src_img on a transparent square canvas (no stretching)."""
    w, h = src_img.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    offset = ((side - w) // 2, (side - h) // 2)
    canvas.paste(src_img, offset, src_img)
    return canvas


# Pre-compute the square version of the source once
img_square = pad_to_square(img)


def save(dest: Path, size: int, src_img: Image.Image = None):
    """Resize src_img to size x size and save to dest (aspect-ratio safe)."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    src = pad_to_square(src_img) if src_img else img_square
    resized = src.resize((size, size), Image.LANCZOS)
    resized.save(dest, "PNG")
    print(f"  -> {dest.relative_to(ROOT)}  ({size}x{size})")


# ── Windows ICO ──────────────────────────────────────────────────────────────
def make_ico(dest: Path, sizes=(16, 32, 48, 64, 128, 256)):
    dest.parent.mkdir(parents=True, exist_ok=True)
    frames = []
    for s in sizes:
        # Use the pre-squared image so no stretching occurs
        frame = img_square.resize((s, s), Image.LANCZOS)
        frames.append(frame)
    frames[0].save(
        dest, format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=frames[1:],
    )
    print(f"  -> {dest.relative_to(ROOT)}  (multi-size ICO: {list(sizes)})")


# ══════════════════════════════════════════════════════════════════════════════
# 1. WINDOWS
# ══════════════════════════════════════════════════════════════════════════════
print("\n[Windows]")
make_ico(ROOT / "windows/runner/resources/app_icon.ico")


# ══════════════════════════════════════════════════════════════════════════════
# 2. ANDROID — mipmap folders
# ══════════════════════════════════════════════════════════════════════════════
print("\n[Android]")
android_base = ROOT / "android/app/src/main/res"
android_sizes = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in android_sizes.items():
    save(android_base / folder / "ic_launcher.png", size)


# ══════════════════════════════════════════════════════════════════════════════
# 3. iOS — AppIcon.appiconset
# ══════════════════════════════════════════════════════════════════════════════
print("\n[iOS]")
ios_base = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
ios_sizes = {
    "Icon-App-20x20@1x.png":       20,
    "Icon-App-20x20@2x.png":       40,
    "Icon-App-20x20@3x.png":       60,
    "Icon-App-29x29@1x.png":       29,
    "Icon-App-29x29@2x.png":       58,
    "Icon-App-29x29@3x.png":       87,
    "Icon-App-40x40@1x.png":       40,
    "Icon-App-40x40@2x.png":       80,
    "Icon-App-40x40@3x.png":       120,
    "Icon-App-60x60@2x.png":       120,
    "Icon-App-60x60@3x.png":       180,
    "Icon-App-76x76@1x.png":       76,
    "Icon-App-76x76@2x.png":       152,
    "Icon-App-83.5x83.5@2x.png":   167,
    "Icon-App-1024x1024@1x.png":   1024,
}
for filename, size in ios_sizes.items():
    save(ios_base / filename, size)


# ══════════════════════════════════════════════════════════════════════════════
# 4. macOS — AppIcon.appiconset
# ══════════════════════════════════════════════════════════════════════════════
print("\n[macOS]")
macos_base = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
macos_sizes = {
    "app_icon_16.png":   16,
    "app_icon_32.png":   32,
    "app_icon_64.png":   64,
    "app_icon_128.png":  128,
    "app_icon_256.png":  256,
    "app_icon_512.png":  512,
    "app_icon_1024.png": 1024,
}
for filename, size in macos_sizes.items():
    save(macos_base / filename, size)


# ══════════════════════════════════════════════════════════════════════════════
# 5. Web — favicon + icons
# ══════════════════════════════════════════════════════════════════════════════
print("\n[Web]")
save(ROOT / "web/favicon.png", 32)
save(ROOT / "web/icons/Icon-192.png",          192)
save(ROOT / "web/icons/Icon-512.png",          512)
save(ROOT / "web/icons/Icon-maskable-192.png", 192)
save(ROOT / "web/icons/Icon-maskable-512.png", 512)


# ══════════════════════════════════════════════════════════════════════════════
# 6. Linux — desktop icon
# ══════════════════════════════════════════════════════════════════════════════
print("\n[Linux]")
save(ROOT / "linux/my_application.png", 256)


print("\n[DONE] All icons generated successfully!")
