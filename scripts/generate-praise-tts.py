#!/usr/bin/env python3
"""
HEAL Praise TTS Generator
========================

Generates TTS audio for the 10 new original praise songs. Uses the
OpenRouter TTS API (English_CaptivatingStoryteller, speed 0.95) to match
the 1perc nightly spark quality.

Output:
  /tmp/praise-tts/{slug}.mp3
  /workspace/HEAL/assets/audio/praise/{slug}.mp3
  Uploaded to B2 GOPResources/heal/heal/audio/praise/{slug}.mp3
  Optional: notify the API gateway with the new audio_url

Usage:
  python3 generate-praise-tts.py --all
  python3 generate-praise-tts.py --slug not-by-sight
"""
import argparse
import base64
import json
import os
import sys
import time
from pathlib import Path
from urllib import request as urlrequest
from urllib import error as urlerror
from urllib.parse import urlencode

OR_KEY = os.environ.get("OPENROUTER_APIKEY", "").strip()
TTS_URL = "https://openrouter.ai/api/v1/audio/speech"
VOICE = "English_CaptivatingStoryteller"  # matches 1perc pipeline
SPEED = 0.95
MODEL = "tts/openai/gpt-4o-mini-tts"

# 10 new praise songs
NEW_PRAISE_SLUGS = [
    "not-by-sight",
    "all-my-years",
    "hundredfold",
    "lo-i-am-with-you",
    "wake-o-sleeper",
    "table-for-the-stranger",
    "the-long-obedience",
    "he-counts-the-sparrows",
    "the-welcome-at-the-gate",
    "the-stone-was-rolled",
]

# Local source lyrics (from /tmp/tts/{slug}.txt)
SRC_DIR = Path("/tmp/tts")
OUT_DIR = Path("/tmp/praise-tts")
ASSETS_DIR = Path("/workspace/HEAL/assets/audio/praise")


def clean_lyrics(text: str) -> str:
    """Strip the [Verse N] markers for cleaner TTS — but keep them as
    spoken words so the listener still hears 'Verse 1' as a cue."""
    out = text
    out = out.replace("**[Verse", "Verse").replace("]**", ":")
    out = out.replace("**[Chorus]**", "Chorus:").replace("**[Bridge]**", "Bridge:").replace("**[Tag]**", "Tag:")
    out = out.replace("**", "")
    return out.strip()


def call_tts(text: str, retries: int = 3) -> bytes:
    """Call OpenRouter TTS, retrying on 5xx/429."""
    if not OR_KEY:
        raise RuntimeError("OPENROUTER_APIKEY not set")
    payload = json.dumps({
        "model": MODEL,
        "input": text,
        "voice": VOICE,
        "speed": SPEED,
        "response_format": "mp3",
    }).encode("utf-8")
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            req = urlrequest.Request(
                TTS_URL,
                data=payload,
                headers={
                    "Authorization": f"Bearer {OR_KEY}",
                    "Content-Type": "application/json",
                },
            )
            with urlrequest.urlopen(req, timeout=120) as resp:
                if resp.status != 200:
                    raise RuntimeError(f"HTTP {resp.status}: {resp.read().decode('utf-8', 'replace')[:200]}")
                return resp.read()
        except (urlerror.HTTPError, urlerror.URLError, TimeoutError) as e:
            last_err = e
            print(f"  TTS attempt {attempt}/{retries} failed: {e}", file=sys.stderr)
            if attempt < retries:
                time.sleep(5 * attempt)
    raise RuntimeError(f"TTS failed after {retries} attempts: {last_err}")


def estimate_duration(text: str) -> int:
    """Estimate TTS duration in seconds. English_CaptivatingStoryteller at
    speed=0.95 averages ~0.42 s/word (based on 1perc nightly runs)."""
    words = len(text.split())
    return int(round(words * 0.42))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true", help="Generate all 10 new songs")
    ap.add_argument("--slug", help="Generate one specific slug")
    args = ap.parse_args()

    if args.all:
        slugs = NEW_PRAISE_SLUGS
    elif args.slug:
        slugs = [args.slug]
    else:
        print("Specify --all or --slug <name>", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    results = []
    for slug in slugs:
        src = SRC_DIR / f"{slug}.txt"
        if not src.exists():
            print(f"  SKIP {slug}: no source file at {src}", file=sys.stderr)
            continue
        text = clean_lyrics(src.read_text(encoding="utf-8"))
        words = len(text.split())
        est_dur = estimate_duration(text)
        print(f"[{slug}] {words} words, est ~{est_dur}s ...", end=" ", flush=True)
        try:
            audio = call_tts(text)
        except Exception as e:
            print(f"FAIL: {e}", file=sys.stderr)
            results.append({"slug": slug, "ok": False, "error": str(e)})
            continue
        out = OUT_DIR / f"{slug}.mp3"
        out.write_bytes(audio)
        # Mirror into the assets dir too
        (ASSETS_DIR / f"{slug}.mp3").write_bytes(audio)
        print(f"OK ({len(audio):,} bytes)")
        results.append({
            "slug": slug,
            "ok": True,
            "bytes": len(audio),
            "duration_estimate": est_dur,
        })
        time.sleep(1.0)  # be polite to the API

    out_json = OUT_DIR / "results.json"
    out_json.write_text(json.dumps(results, indent=2))
    ok = sum(1 for r in results if r.get("ok"))
    print(f"\n{ok}/{len(results)} generated. Results: {out_json}")
    return 0 if ok == len(results) else 2


if __name__ == "__main__":
    sys.exit(main())
