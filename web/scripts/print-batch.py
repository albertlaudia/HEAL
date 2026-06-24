#!/usr/bin/env python3
"""
Print batch_prompts (instr + vocal) for next N ungenerated songs.
Usage: python3 print-batch.py [N] [start_idx]
"""
import sys
import json
from pathlib import Path

WORK = Path('/workspace/.mavis-cache/heal-song-gen')
N = int(sys.argv[1]) if len(sys.argv) > 1 else 4
START = int(sys.argv[2]) if len(sys.argv) > 2 else 0

done = set(p.stem.replace('-instr', '') for p in WORK.glob('*-instr.mp3'))
all_songs = sorted([p.stem.replace('-instr-prompt', '') for p in WORK.glob('*-instr-prompt.txt')])
todo = [s for s in all_songs if s not in done]
todo = todo[START:START + N]

print(f'=== Batch starting at {START}, {len(todo)} songs ===')
print()
for slug in todo:
    info = json.loads((WORK / f'{slug}-info.json').read_text())
    print(f'INSTR_PROMPT: {slug} | {info["voice"]} | {info["speed"]}')
    print(f'  (text) {(WORK / f"{slug}-instr-prompt.txt").read_text().strip()[:120]}')
    print(f'  (vocal) {info["vocal_text"]}')
    print()