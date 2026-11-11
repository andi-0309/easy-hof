#!/usr/bin/env python3
"""Build bundled speech clips with Piper 1.8.0 and FFmpeg; not app dependencies.

Usage: python tools/generate_voice_assets.py --models /path/to/piper-models
See assets/audio/README.md for model sources and attribution.
"""
import argparse
import os

# Documented ONNX switch: prevent uploader/events/device IDs before runtime import.
os.environ["ORT_DISABLE_TELEMETRY"] = "1"
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import wave
import onnxruntime

# Synthesis is local: disable ONNX runtime telemetry before creating any session.
onnxruntime.disable_telemetry_events()
from piper import PiperVoice, SynthesisConfig

ROOT = Path(__file__).resolve().parents[1]
MODELS = {'de': 'de_DE-thorsten-medium', 'en': 'en_US-ljspeech-high'}


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--models', required=True, type=Path)
    parser.add_argument('--only', help='Regenerate one cue and preserve other clips')
    parser.add_argument('--base64', action='store_true', help='Store MP3 bytes in a text asset for API-based source updates')
    args = parser.parse_args()
    phrases = json.loads((ROOT / 'assets/audio/phrases.json').read_text())
    manifest = {'generator': 'piper-tts 1.8.0', 'format': 'MP3 mono 22050 Hz, 96 kbit/s', 'voices': {}, 'clips': []}
    if args.only:
        manifest = json.loads((ROOT / 'assets/audio/manifest.json').read_text())
        manifest['clips'] = [c for c in manifest['clips'] if c['cue'] != args.only]
    with tempfile.TemporaryDirectory() as temp:
        for language, model in MODELS.items():
            model_path = args.models / f'{model}.onnx'
            manifest['voices'][language] = {'model': model, 'sha256': hashlib.sha256(model_path.read_bytes()).hexdigest()}
            voice = PiperVoice.load(str(model_path))
            for cue, text in phrases[language].items():
                if args.only and cue != args.only:
                    continue
                raw = Path(temp) / f'{language}-{cue}.wav'
                with wave.open(str(raw), 'wb') as wav:
                    voice.synthesize_wav(text, wav, syn_config=SynthesisConfig(length_scale=1.05, noise_scale=0.5, noise_w_scale=0.7))
                cleaned = Path(temp) / f'{language}-{cue}-clean.wav'
                run(['ffmpeg', '-y', '-i', str(raw), '-af', 'silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,afade=t=in:d=0.012,apad=pad_dur=0.08', str(cleaned)])
                report = run(['ffmpeg', '-i', str(cleaned), '-af', 'loudnorm=I=-18:TP=-1.5:LRA=7:print_format=json', '-f', 'null', '-']).stderr
                stats = json.JSONDecoder().raw_decode(report[report.rfind('{'):])[0]
                normalization = ('loudnorm=I=-18:TP=-1.5:LRA=7:linear=true:'
                    f"measured_I={stats['input_i']}:measured_TP={stats['input_tp']}:"
                    f"measured_LRA={stats['input_lra']}:measured_thresh={stats['input_thresh']}:offset={stats['target_offset']}")
                output = ROOT / 'assets/audio' / language / f'{cue}.mp3'
                run(['ffmpeg', '-y', '-i', str(cleaned), '-af', normalization, '-ar', '22050', '-ac', '1', '-c:a', 'libmp3lame', '-b:a', '96k', str(output)])
                duration = float(run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=nw=1:nk=1', str(output)]).stdout.strip())
                if cue in ('inhale', 'exhale') and duration > 1.8:
                    raise RuntimeError(f'{language}/{cue} too long for 4-second breath cycle: {duration:.2f}s')
                if cue == 'countdown' and duration > 2.8:
                    raise RuntimeError(f'{language}/{cue} too long for countdown: {duration:.2f}s')
                check = run(['ffmpeg', '-i', str(output), '-af', 'loudnorm=I=-18:TP=-1.5:LRA=7:print_format=json', '-f', 'null', '-']).stderr
                actual = json.JSONDecoder().raw_decode(check[check.rfind('{'):])[0]
                if float(actual['input_tp']) > 0:
                    raise RuntimeError(f'Clipping in {output}')
                if cue == 'final_exhale' and duration >= 5.7:
                    raise RuntimeError('Final exhale must fit within the six-second transition')
                manifest['clips'].append({'language': language, 'cue': cue, 'text': text, 'durationSeconds': round(duration, 3), 'loudnessLufs': float(actual['input_i']), 'truePeakDb': float(actual['input_tp']), 'bytes': output.stat().st_size, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest()})
                if args.base64:
                    output.with_suffix('.b64').write_text(base64.b64encode(output.read_bytes()).decode('ascii') + '\n')
                    manifest['clips'][-1]['encoding'] = 'base64'
                    output.unlink()
                print(f'{language}/{cue}: {duration:.2f}s, {actual["input_i"]} LUFS, {manifest['clips'][-1]['bytes']} bytes', flush=True)
    (ROOT / 'assets/audio/manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
