"""Deterministic, original breath cues. Requires numpy, scipy and ffmpeg.
Filtered air noise with smooth respiratory envelopes; no voice or samples.
Run from repository root. All six clips are embedded and available offline.
"""
from pathlib import Path
import subprocess
import tempfile
import numpy as np
from scipy.signal import butter, sosfilt
from scipy.io.wavfile import write

rate = 44100
root = Path('assets/audio/breath')
root.mkdir(parents=True, exist_ok=True)
for phase in ('inhale', 'exhale'):
    for seconds in (2, 3, 4):
        rng = np.random.default_rng(180 if phase == 'inhale' else 260)
        t = np.arange(rate * seconds) / rate / seconds
        noise = rng.normal(size=t.size)
        band = (450, 3500) if phase == 'inhale' else (180, 2100)
        air = sosfilt(butter(3, band, btype='bandpass', fs=rate, output='sos'), noise)
        envelope = np.sin(np.pi * t) ** (0.85 if phase == 'inhale' else 1.25)
        envelope *= (0.65 + 0.35 * t) if phase == 'inhale' else (1 - 0.35 * t)
        signal = air * envelope
        signal *= 0.55 / max(abs(signal))
        with tempfile.TemporaryDirectory() as temp:
            wav = Path(temp) / 'breath.wav'
            write(wav, rate, np.int16(signal * 32767))
            subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(wav), '-codec:a',
                            'libmp3lame', '-b:a', '96k', str(root / f'{phase}-{seconds}.mp3')], check=True)
