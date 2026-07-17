#!/usr/bin/env python3
"""
HEAL — App icon verification.

Verifies that all required iOS, Android, and web app icon sizes exist
and have the right pixel dimensions. Run before every release.

Usage: python3 tools/verify-app-icons.py
"""
import os
import sys
import struct
from pathlib import Path

# Required iOS icons (filename → expected pixel size)
IOS_ICONS = {
    "Icon-App-20x20@2x.png":       40,
    "Icon-App-20x20@3x.png":       60,
    "Icon-App-29x29@2x.png":       58,
    "Icon-App-29x29@3x.png":       87,
    "Icon-App-40x40@2x.png":       80,
    "Icon-App-40x40@3x.png":      120,
    "Icon-App-60x60@2x.png":      120,
    "Icon-App-60x60@3x.png":      180,
    "Icon-App-76x76@1x.png":       76,
    "Icon-App-76x76@2x.png":      152,
    "Icon-App-83.5x83.5@2x.png":  167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# Required Android mipmap densities
ANDROID_DENSITIES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi":192,
}

def png_dimensions(path):
    """Return (width, height) of a PNG without external deps."""
    with open(path, 'rb') as f:
        sig = f.read(8)
        if sig != b'\x89PNG\r\n\x1a\n':
            return None
        # IHDR chunk: 4 bytes length, 4 bytes type, 4 bytes width, 4 bytes height
        length = struct.unpack('>I', f.read(4))[0]
        chunk_type = f.read(4)
        if chunk_type != b'IHDR' or length != 13:
            return None
        width, height = struct.unpack('>II', f.read(8))
        return (width, height)

def main():
    repo = Path(__file__).resolve().parent.parent
    ios_dir = repo / "media" / "app-icon" / "ios"
    android_dir = repo / "media" / "app-icon" / "android"
    android_res = repo / "mobile" / "android" / "app" / "src" / "main" / "res"

    failed = False

    # iOS
    print(f"── iOS ({len(IOS_ICONS)} sizes) ──")
    for name, expected_px in sorted(IOS_ICONS.items()):
        path = ios_dir / name
        if not path.exists():
            print(f"  MISSING  {name}  (expected {expected_px}x{expected_px})")
            failed = True
            continue
        dims = png_dimensions(path)
        if dims is None:
            print(f"  INVALID  {name}  (not a valid PNG)")
            failed = True
        elif dims != (expected_px, expected_px):
            print(f"  WRONG    {name}  expected {expected_px}x{expected_px}, got {dims[0]}x{dims[1]}")
            failed = True
        else:
            print(f"  OK       {name}  ({expected_px}x{expected_px})")

    # Android legacy mipmap (pre-adaptive)
    print()
    print(f"── Android mipmap density buckets ──")
    for density, expected_px in sorted(ANDROID_DENSITIES.items()):
        for variant in ('ic_launcher.png', 'ic_launcher_round.png',
                        'ic_launcher_background.png', 'ic_launcher_foreground.png'):
            path = android_res / density / variant
            if not path.exists():
                # Round / foreground / background are optional
                if variant in ('ic_launcher_round.png',
                               'ic_launcher_background.png',
                               'ic_launcher_foreground.png'):
                    continue
                print(f"  MISSING  {density}/{variant}  (expected {expected_px}x{expected_px})")
                failed = True
                continue
            dims = png_dimensions(path)
            if variant == 'ic_launcher_foreground.png':
                # Android adaptive icon foregrounds are conventionally
                # 108x108 dp (regardless of density bucket) — the inner
                # 72dp is the "safe zone" and the rest is masked by the
                # launcher. Just check it's a square >= 108px.
                if dims[0] != dims[1] or dims[0] < 108:
                    print(f"  WRONG    {density}/{variant}  expected square >= 108x108, got {dims[0]}x{dims[1]}")
                    failed = True
                else:
                    print(f"  OK       {density}/{variant}  ({dims[0]}x{dims[1]} adaptive-foreground)")
                continue
            if dims != (expected_px, expected_px):
                print(f"  WRONG    {density}/{variant}  expected {expected_px}x{expected_px}, got {dims[0]}x{dims[1]}")
                failed = True
            else:
                print(f"  OK       {density}/{variant}  ({expected_px}x{expected_px})")

    # Android adaptive icon
    print()
    print("── Android adaptive icon ──")
    adaptive = android_res / "mipmap-anydpi-v26" / "ic_launcher.xml"
    if adaptive.exists():
        print(f"  OK       mipmap-anydpi-v26/ic_launcher.xml")
    else:
        print(f"  MISSING  mipmap-anydpi-v26/ic_launcher.xml")
        failed = True

    # Web
    web_dir = repo / "web" / "public"
    web_favicons = [
        "favicon.ico",
        "favicon-16x16.png",
        "favicon-32x32.png",
        "apple-touch-icon.png",
        "android-chrome-192x192.png",
        "android-chrome-512x512.png",
    ]
    print()
    print(f"── Web favicons ──")
    for name in web_favicons:
        path = web_dir / name
        if not path.exists():
            print(f"  MISSING  web/public/{name}")
            failed = True
        else:
            print(f"  OK       web/public/{name}")

    if failed:
        print()
        print("FAIL — see above")
        sys.exit(1)
    else:
        print()
        print("OK — all required icons present and correct dimensions")

if __name__ == '__main__':
    main()
