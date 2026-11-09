# Bundled voice guidance

Easy Hof includes 16 synthesized speech clips: eight in German and eight in English. These are app-specific recordings of the scripts in `phrases.json`, generated locally with **Piper 1.8.0**. The Android app plays the committed MP3 files directly; it does not contain Piper, the voice models, an Android TTS dependency or a speech API key. No voice download is needed at runtime.

## Sources and attribution

- **German:** `de_DE-thorsten-medium`, based on [Thorsten-Voice](https://github.com/thorstenMueller/Thorsten-Voice). The [voice model card](https://huggingface.co/rhasspy/piper-voices/blob/main/de/de_DE/thorsten/medium/MODEL_CARD) identifies the dataset as **CC0**.
- **English:** `en_US-ljspeech-high`, based on the [LJ Speech dataset](https://keithito.com/LJ-Speech-Dataset/). The [voice model card](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/ljspeech/high/MODEL_CARD) identifies the dataset as **public domain**; model training is credited there to Bryce Beattie.
- Synthesis tool: [OHF-Voice/Piper](https://github.com/OHF-Voice/piper1-gpl). Used during asset creation only, not distributed in the Android app.
- Voice model files are obtained from [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices). Exact ONNX hashes are recorded in `manifest.json`; no model weights are checked into this repository.

## Audio preparation

Mono MP3, 22,050 Hz, 96 kbit/s. Leading/trailing silence trimmed, soft onset, two-pass loudness normalization targeting −18 LUFS and a −1.5 dBTP ceiling. `manifest.json` records the measured final MP3 loudness, true peak, duration, size and checksum for every clip. No decoded clip exceeds 0 dBTP. Inhale/exhale clips are shorter than 1.8 seconds, so they fit into the minimum two-second half-breath. Countdown clips fit within the three-second countdown.

During playback, the previous cue stops before the next one starts. Pausing, leaving the app or losing audio focus stops playback. A playback failure disables speech for the current session and shows a message while the visual guide remains usable.

## Rebuild

Only needed to change the recordings; normal app builds use the committed files.

```sh
python3 -m venv .venv
.venv/bin/pip install piper-tts==1.8.0
# Download .onnx and .onnx.json for both voices into /path/to/models.
# Install ffmpeg, then:
.venv/bin/python tools/generate_voice_assets.py --models /path/to/models
python3 tools/check_voice_assets.py
```

Generation can vary slightly because neural synthesis uses noise. Review regenerated speech and update the committed files/manifest together. CI checks asset integrity and Flutter bundle inclusion; testing on actual phone/watch speakers is still useful.

## Non-verbal breath sounds

`breath/inhale-{2,3,4}.mp3` and `breath/exhale-{2,3,4}.mp3` are original,
deterministically synthesized air-noise cues. `tools/generate_breath_sounds.py`
creates distinct filtered noise and smooth envelopes for inhalation/exhalation.
No third-party recordings, cloned voice or speech model is involved. Each phase
uses its matching duration at normal playback speed; no pitch shifting. Existing
spoken inhale/exhale clips are retained for provenance but are not played during
training. Disable voice guidance to mute both breath sounds and spoken cues.
