import os
import glob
import json
import time
import torch
import librosa
import numpy as np
import soundfile as sf
from scipy.signal import butter, filtfilt
from transformers import pipeline
from voxcpm import VoxCPM

def butter_highpass_filter(data, cutoff, fs, order=4):
    """Apply high-pass Butterworth filter to remove DC bias and low rumble."""
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='high', analog=False)
    y = filtfilt(b, a, data)
    return y

def create_heldout_clean_reference(sound_dir, out_dir):
    """
    Build reference audio strictly from held-out lines to prevent validation leakage.
    Applies high-pass filtering and peak normalization to eliminate 8-bit rumble.
    """
    heldout_files = [
        "13 - Tonight's Matchup (11k).wav",
        "70 - Win The Game (11k).wav",
        "69 - Overtime (11k).wav",
        "15 - Warriors (11k).wav",
        "17 - Lakers (11k).wav",
        "19 - Bulls (11k).wav",
        "33 - Supersonics (11k).wav",
        "91 Cavaliers (slightly slow).wav",
    ]
    target_sr = 16000
    segments = []
    silence = np.zeros(int(target_sr * 0.2))

    for h in heldout_files:
        p = os.path.join(sound_dir, h)
        if os.path.exists(p):
            y, sr = librosa.load(p, sr=target_sr, mono=True)
            # High-pass filter at 80Hz to strip rumble/DC offset
            y = butter_highpass_filter(y, cutoff=80, fs=target_sr)
            # Trim silence
            y, _ = librosa.effects.trim(y, top_db=25)
            # Peak normalize
            peak = np.max(np.abs(y))
            if peak > 0:
                y = y / peak * 0.95
            segments.append(y)
            segments.append(silence)

    composite = np.concatenate(segments[:-1])
    ref_path = os.path.join(out_dir, "heldout_clean_announcer_ref.wav")
    sf.write(ref_path, composite, target_sr)
    print(f"Created clean held-out reference audio: {ref_path} ({len(composite)/target_sr:.2f}s)")
    return ref_path

def compute_pitch_and_metrics(audio, sr):
    """Extract fundamental frequency (F0) and spectral metrics."""
    if len(audio.shape) > 1:
        audio = np.mean(audio, axis=1)
    
    duration = len(audio) / sr
    rms = np.sqrt(np.mean(audio**2))
    rms_db = 20 * np.log10(rms + 1e-9)

    # Pitch tracking using YIN
    try:
        f0 = librosa.yin(audio, fmin=70, fmax=420, sr=sr)
        # Filter unvoiced frames (YIN returns ~fmin or ~fmax when unvoiced)
        voiced = f0[(f0 > 75) & (f0 < 400)]
        if len(voiced) > 0:
            mean_f0 = float(np.mean(voiced))
            median_f0 = float(np.median(voiced))
            min_f0 = float(np.min(voiced))
            max_f0 = float(np.max(voiced))
            std_f0 = float(np.std(voiced))
        else:
            mean_f0 = median_f0 = min_f0 = max_f0 = std_f0 = 0.0
    except Exception as e:
        print(f"Pitch extraction error: {e}")
        mean_f0 = median_f0 = min_f0 = max_f0 = std_f0 = 0.0

    # Spectral features
    centroid = librosa.feature.spectral_centroid(y=audio, sr=sr)
    mean_centroid = float(np.mean(centroid))
    
    rolloff = librosa.feature.spectral_rolloff(y=audio, sr=sr, roll_percent=0.85)
    mean_rolloff = float(np.mean(rolloff))
    
    return {
        "duration_sec": round(duration, 3),
        "sample_rate": sr,
        "rms_db": round(float(rms_db), 2),
        "mean_f0_hz": round(mean_f0, 1),
        "median_f0_hz": round(median_f0, 1),
        "min_f0_hz": round(min_f0, 1),
        "max_f0_hz": round(max_f0, 1),
        "std_f0_hz": round(std_f0, 1),
        "spectral_centroid_hz": round(mean_centroid, 1),
        "spectral_rolloff_hz": round(mean_rolloff, 1)
    }

def main():
    sound_dir = r"E:\github\jam_game\base\NBA Jam - Tournament Edition Sounds"
    out_dir = r"E:\github\jam_game\voices\cloned_announcer_voxcpm\cfg27"
    os.makedirs(out_dir, exist_ok=True)

    print("=== Step 1: Building Clean Held-Out Reference Audio (Zero Validation Leakage) ===")
    ref_audio_path = create_heldout_clean_reference(sound_dir, out_dir)

    print("\n=== Step 2: Defining Validation Target Phrases ===")
    test_lines = [
        {"id": "hes_on_fire", "phrase": "He's on fire!", "orig_file": "50 - He's On Fire (7.3k).wav"},
        {"id": "kaboom", "phrase": "Kaboom!", "orig_file": "58 - Kaboom (slightly slow).wav"},
        {"id": "from_downtown", "phrase": "From downtown!", "orig_file": "21 - From Downtown (6k).wav"},
        {"id": "monster_jam", "phrase": "Monster jam!", "orig_file": "23 - Monster Jam (6k).wav"},
        {"id": "razzle_dazzle", "phrase": "Razzle Dazzle!", "orig_file": "3 - Razzle Dazzle.wav"},
        {"id": "rejected", "phrase": "Rejected!", "orig_file": "77 - Rejected (7.3k).wav"},
        {"id": "stolen", "phrase": "Stolen!", "orig_file": "2 - Stolen.wav"},
        {"id": "slams_it", "phrase": "Slams it!", "orig_file": "4 -  Slams It.wav"},
        {"id": "heating_up", "phrase": "Heating up!", "orig_file": "51 Heating Up (slow).wav"},
        {"id": "showtime", "phrase": "Showtime!", "orig_file": "68 - Showtime.wav"},
        {"id": "terrible_shot", "phrase": "Terrible shot!", "orig_file": "8 - Terrible Shot.wav"},
        {"id": "at_the_buzzer", "phrase": "At the buzzer!", "orig_file": "49 - At the Buzzer (7.3k).wav"},
        {"id": "welcome_to_nba_jam", "phrase": "Welcome to NBA Jam!", "orig_file": "28 - Welcome to NBA JAM (slightly slow).wav"}
    ]

    print(f"Total phrases: {len(test_lines)}")

    print("\n=== Step 3: Loading VoxCPM2 (bf16, CUDA) ===")
    model = VoxCPM.from_pretrained("openbmb/VoxCPM2", optimize=False, load_denoiser=False)
    tts_sample_rate = model.tts_model.sample_rate

    print("\n=== Step 4: Loading Whisper Pipeline ===")
    transcriber = pipeline("automatic-speech-recognition", model="openai/whisper-tiny", device="cuda")

    results = []

    print("\n=== Step 5: Synthesizing with CFG = 2.7 & 30 Diffusion Steps ===")
    for idx, item in enumerate(test_lines, 1):
        phrase = item["phrase"]
        item_id = item["id"]
        orig_filename = item["orig_file"]
        orig_path = os.path.join(sound_dir, orig_filename)
        out_filename = f"voxcpm_cfg27_{item_id}.wav"
        cloned_path = os.path.join(out_dir, out_filename)

        print(f"\n[{idx}/{len(test_lines)}] Synthesizing: \"{phrase}\" (CFG=2.7, 30 steps)...")
        t0 = time.time()
        wav = model.generate(
            text=phrase,
            reference_wav_path=ref_audio_path,
            inference_timesteps=30,
            cfg_value=2.7
        )
        gen_time = time.time() - t0
        sf.write(cloned_path, wav, tts_sample_rate)

        # Analyze Ground Truth Audio
        orig_audio, orig_sr = sf.read(orig_path)
        orig_metrics = compute_pitch_and_metrics(orig_audio, orig_sr)
        orig_asr = transcriber({"raw": orig_audio, "sampling_rate": orig_sr})["text"].strip()

        # Analyze Generated Audio
        cloned_audio, cloned_sr = sf.read(cloned_path)
        cloned_metrics = compute_pitch_and_metrics(cloned_audio, cloned_sr)
        cloned_asr = transcriber({"raw": cloned_audio, "sampling_rate": cloned_sr})["text"].strip()

        # Pitch difference
        delta_f0 = round(cloned_metrics["mean_f0_hz"] - orig_metrics["mean_f0_hz"], 1)
        semitone_diff = 0.0
        if orig_metrics["mean_f0_hz"] > 0 and cloned_metrics["mean_f0_hz"] > 0:
            semitone_diff = round(12 * np.log2(cloned_metrics["mean_f0_hz"] / orig_metrics["mean_f0_hz"]), 2)

        comparison = {
            "id": item_id,
            "target_phrase": phrase,
            "generation_time_sec": round(gen_time, 2),
            "original": {
                "file": orig_filename,
                "metrics": orig_metrics,
                "asr_transcript": orig_asr
            },
            "cloned_cfg27": {
                "file": out_filename,
                "metrics": cloned_metrics,
                "asr_transcript": cloned_asr
            },
            "pitch_comparison": {
                "delta_mean_f0_hz": delta_f0,
                "semitone_diff": semitone_diff
            }
        }
        results.append(comparison)

        print(f"   [Original] Pitch: {orig_metrics['mean_f0_hz']} Hz (med: {orig_metrics['median_f0_hz']} Hz) | ASR: \"{orig_asr}\"")
        print(f"   [CFG 2.7 ] Pitch: {cloned_metrics['mean_f0_hz']} Hz (med: {cloned_metrics['median_f0_hz']} Hz) | ASR: \"{cloned_asr}\" | ΔF0: {delta_f0:+5.1f} Hz ({semitone_diff:+4.2f} st)")

    res_file = os.path.join(out_dir, "cfg27_pitch_results.json")
    with open(res_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"\nRegeneration complete! Saved results to {res_file}")

if __name__ == "__main__":
    main()
