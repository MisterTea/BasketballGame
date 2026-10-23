"""Record roster name chunks in the cloned announcer voice.

NBA Jam keeps each last name as its own sample (SPEECH.ASM name_speech) and
plays that chunk ahead of a phrase. This uses the same VoxCPM2 reference clone
as voices/synthesize_all_announcements.py.
"""
import os
import re
import json
import time
import numpy as np
import soundfile as sf
import librosa
from voxcpm import VoxCPM

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
OUT_DIR = os.path.join(BASE_DIR, "announcer", "names")
REF_PATH = os.path.join(BASE_DIR, "cloned_announcer_voxcpm", "announcer_composite_ref.wav")
TEAMS_PATH = os.path.join(PROJECT_ROOT, "scripts", "teams.gd")

# Spoken form when the roster spelling is not how the name is said.
SPOKEN = {
    "GAUCI": "Gowchee!",
    "WATERS": "Waters!",
    # The style tag made these two ramble. A bare shout stays a name chunk.
    "FLASH": "Flash!",
    "VICE": "Vice!",
}


def roster_names():
    text = open(TEAMS_PATH, encoding="utf-8").read()
    found = []
    for group in re.findall(r'"players"\s*:\s*\[([^\]]+)\]', text):
        found.extend(re.findall(r'"([^"]+)"', group))
    if not found:
        raise SystemExit(f"No player names found in {TEAMS_PATH}")
    return found


def spoken_phrase(name: str) -> str:
    if name in SPOKEN:
        return SPOKEN[name]
    # Short excited shout, matching name_speech ("last name only, excited").
    return f"(excited sports announcer, short shout) {name.title()}!"


def normalize_and_save(wav, sr, out_path):
    if len(wav.shape) > 1:
        wav = np.mean(wav, axis=1)
    trimmed, _ = librosa.effects.trim(wav, top_db=28)
    if len(trimmed) == 0:
        trimmed = wav
    peak = np.max(np.abs(trimmed))
    if peak > 0:
        trimmed = (trimmed / peak) * 0.95
    sf.write(out_path, trimmed, sr, subtype="PCM_16")
    return len(trimmed) / float(sr)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    names = roster_names()
    manifest = {}
    pending = []
    for name in names:
        item_id = name.lower()
        out_wav = os.path.join(OUT_DIR, f"{item_id}.wav")
        manifest[name] = f"res://voices/announcer/names/{item_id}.wav"
        if not os.path.exists(out_wav) or os.path.getsize(out_wav) < 1000:
            pending.append((name, out_wav))

    manifest_path = os.path.join(OUT_DIR, "names_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Roster names: {', '.join(names)}")
    print(f"Pending synthesis: {len(pending)}")
    if not pending:
        print("All player-name voices already recorded.")
        return

    print("Initializing VoxCPM2")
    model = VoxCPM.from_pretrained("openbmb/VoxCPM2", optimize=False, load_denoiser=False)
    sample_rate = model.tts_model.sample_rate
    if sample_rate != 48000:
        raise SystemExit(f"Expected 48000 Hz announcer audio, got {sample_rate}")

    for idx, (name, out_wav) in enumerate(pending, 1):
        phrase = spoken_phrase(name)
        print(f"[{idx}/{len(pending)}] {name}: {phrase}", flush=True)
        t0 = time.time()
        wav = model.generate(
            text=phrase,
            reference_wav_path=REF_PATH,
            inference_timesteps=10,
            cfg_value=2.5,
        )
        duration = normalize_and_save(wav, sample_rate, out_wav)
        print(f"   -> {duration:.2f}s in {time.time() - t0:.1f}s", flush=True)


if __name__ == "__main__":
    main()
