#!/usr/bin/env python3
"""Verify the committed, measured speech assets without any TTS dependency."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'assets/audio'
phrases = json.loads((root / 'phrases.json').read_text())
manifest = json.loads((root / 'manifest.json').read_text())
expected = {(language, cue) for language, items in phrases.items() for cue in items}
actual = {(clip['language'], clip['cue']) for clip in manifest['clips']}
assert expected == actual and len(manifest['clips']) == 16
size = 0
for clip in manifest['clips']:
    language, cue = clip['language'], clip['cue']
    content = (root / language / f'{cue}.mp3').read_bytes()
    assert hashlib.sha256(content).hexdigest() == clip['sha256'], (language, cue, 'hash')
    assert len(content) == clip['bytes'] and len(content) > 4000
    assert clip['text'] == phrases[language][cue]
    assert 0 < clip['durationSeconds'] < 10
    assert clip['truePeakDb'] < 0
    assert -21 <= clip['loudnessLufs'] <= -16
    if cue in ('inhale', 'exhale'):
        assert clip['durationSeconds'] < 1.8
    if cue == 'countdown':
        assert clip['durationSeconds'] < 2.8
    size += len(content)
assert size < 1_000_000
print(f'16 bundled speech clips verified; {size:,} bytes total.')
