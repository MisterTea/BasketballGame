import os
import glob
import json
import time
import torch
import librosa
import numpy as np
import soundfile as sf
from transformers import pipeline
from voxcpm import VoxCPM

def create_reference_audio(sound_dir, out_dir):
    """Create a composite reference audio of iconic announcer calls for optimal voice cloning."""
    ref_clips = [
        "50 - He's On Fire (7.3k).wav",
        "58 - Kaboom (slightly slow).wav",
        "21 - From Downtown (6k).wav",
        "23 - Monster Jam (6k).wav",
        "3 - Razzle Dazzle.wav",
    ]
    target_sr = 16000
    segments = []
    silence = np.zeros(int(target_sr * 0.2))

    for clip in ref_clips:
        p = os.path.join(sound_dir, clip)
        if os.path.exists(p):
            y, sr = librosa.load(p, sr=target_sr)
            y, _ = librosa.effects.trim(y, top_db=25)
            # Normalize peak
            if np.max(np.abs(y)) > 0:
                y = y / np.max(np.abs(y)) * 0.95
            segments.append(y)
            segments.append(silence)

    composite = np.concatenate(segments[:-1])
    composite_path = os.path.join(out_dir, "announcer_composite_ref.wav")
    sf.write(composite_path, composite, target_sr)
    print(f"Created composite reference audio: {composite_path} ({len(composite)/target_sr:.2f}s)")
    return composite_path

def compute_audio_metrics(audio, sr):
    """Calculate key acoustic and spectral metrics."""
    if len(audio.shape) > 1:
        audio = np.mean(audio, axis=1)
    
    duration = len(audio) / sr
    rms = np.sqrt(np.mean(audio**2))
    rms_db = 20 * np.log10(rms + 1e-9)
    peak = np.max(np.abs(audio))
    peak_db = 20 * np.log10(peak + 1e-9)
    
    # Spectral features
    centroid = librosa.feature.spectral_centroid(y=audio, sr=sr)
    mean_centroid = float(np.mean(centroid))
    
    rolloff = librosa.feature.spectral_rolloff(y=audio, sr=sr, roll_percent=0.85)
    mean_rolloff = float(np.mean(rolloff))
    
    zcr = librosa.feature.zero_crossing_rate(y=audio)
    mean_zcr = float(np.mean(zcr))
    
    return {
        "duration_sec": round(duration, 3),
        "sample_rate": sr,
        "rms_db": round(float(rms_db), 2),
        "peak_db": round(float(peak_db), 2),
        "spectral_centroid_hz": round(mean_centroid, 1),
        "spectral_rolloff_hz": round(mean_rolloff, 1),
        "zero_crossing_rate": round(mean_zcr, 4)
    }

def main():
    sound_dir = r"E:\github\jam_game\base\NBA Jam - Tournament Edition Sounds"
    out_dir = r"E:\github\jam_game\voices\cloned_announcer_voxcpm"
    os.makedirs(out_dir, exist_ok=True)

    print("=== Step 1: Preparing Reference Audio ===")
    ref_audio_path = create_reference_audio(sound_dir, out_dir)

    print("\n=== Step 2: Defining Target Announcer Test Lines ===")
    test_lines = [
        {
            "id": "hes_on_fire",
            "phrase": "He's on fire!",
            "orig_file": "50 - He's On Fire (7.3k).wav"
        },
        {
            "id": "kaboom",
            "phrase": "Kaboom!",
            "orig_file": "58 - Kaboom (slightly slow).wav"
        },
        {
            "id": "from_downtown",
            "phrase": "From downtown!",
            "orig_file": "21 - From Downtown (6k).wav"
        },
        {
            "id": "monster_jam",
            "phrase": "Monster jam!",
            "orig_file": "23 - Monster Jam (6k).wav"
        },
        {
            "id": "razzle_dazzle",
            "phrase": "Razzle Dazzle!",
            "orig_file": "3 - Razzle Dazzle.wav"
        },
        {
            "id": "rejected",
            "phrase": "Rejected!",
            "orig_file": "77 - Rejected (7.3k).wav"
        },
        {
            "id": "stolen",
            "phrase": "Stolen!",
            "orig_file": "2 - Stolen.wav"
        },
        {
            "id": "slams_it",
            "phrase": "Slams it!",
            "orig_file": "4 -  Slams It.wav"
        },
        {
            "id": "heating_up",
            "phrase": "Heating up!",
            "orig_file": "51 Heating Up (slow).wav"
        },
        {
            "id": "showtime",
            "phrase": "Showtime!",
            "orig_file": "68 - Showtime.wav"
        },
        {
            "id": "terrible_shot",
            "phrase": "Terrible shot!",
            "orig_file": "8 - Terrible Shot.wav"
        },
        {
            "id": "at_the_buzzer",
            "phrase": "At the buzzer!",
            "orig_file": "49 - At the Buzzer (7.3k).wav"
        }
    ]

    print(f"Total phrases to synthesize and compare: {len(test_lines)}")

    print("\n=== Step 3: Loading VoxCPM (bf16, CUDA) ===")
    model = VoxCPM.from_pretrained("openbmb/VoxCPM2", optimize=False, load_denoiser=False)
    tts_sample_rate = model.tts_model.sample_rate
    print(f"VoxCPM loaded. Sample rate: {tts_sample_rate}Hz, Model device: {model.tts_model.device}")

    # Check parameter precision
    first_p = next(model.tts_model.parameters())
    print(f"Model weights dtype: {first_p.dtype}")

    print("\n=== Step 4: Initializing Whisper for Intelligibility Verification ===")
    transcriber = pipeline("automatic-speech-recognition", model="openai/whisper-tiny", device="cuda")

    results = []

    print("\n=== Step 5: Synthesizing with 30 Diffusion Steps & Comparing ===")
    for idx, item in enumerate(test_lines, 1):
        phrase = item["phrase"]
        item_id = item["id"]
        orig_filename = item["orig_file"]
        orig_path = os.path.join(sound_dir, orig_filename)
        out_filename = f"voxcpm_{item_id}.wav"
        cloned_path = os.path.join(out_dir, out_filename)

        print(f"\n[{idx}/{len(test_lines)}] Generating: \"{phrase}\" (30 diffusion steps)...")
        t0 = time.time()
        
        # Synthesize with 30 diffusion steps
        wav = model.generate(
            text=phrase,
            reference_wav_path=ref_audio_path,
            inference_timesteps=30,
            cfg_value=2.0
        )
        gen_time = time.time() - t0
        print(f"   -> Generated in {gen_time:.2f}s, saving to {out_filename}")
        sf.write(cloned_path, wav, tts_sample_rate)

        # Analyze Original Audio
        orig_audio, orig_sr = sf.read(orig_path)
        orig_metrics = compute_audio_metrics(orig_audio, orig_sr)
        orig_asr = transcriber({"raw": orig_audio, "sampling_rate": orig_sr})["text"].strip()

        # Analyze Cloned Audio
        cloned_audio, cloned_sr = sf.read(cloned_path)
        cloned_metrics = compute_audio_metrics(cloned_audio, cloned_sr)
        cloned_asr = transcriber({"raw": cloned_audio, "sampling_rate": cloned_sr})["text"].strip()

        comparison = {
            "id": item_id,
            "target_phrase": phrase,
            "generation_time_sec": round(gen_time, 2),
            "original": {
                "file": orig_filename,
                "path": orig_path,
                "metrics": orig_metrics,
                "asr_transcript": orig_asr
            },
            "cloned": {
                "file": out_filename,
                "path": cloned_path,
                "metrics": cloned_metrics,
                "asr_transcript": cloned_asr
            }
        }
        results.append(comparison)

        print(f"   [Original] Dur: {orig_metrics['duration_sec']}s | SR: {orig_sr}Hz | Rolloff: {orig_metrics['spectral_rolloff_hz']}Hz | ASR: \"{orig_asr}\"")
        print(f"   [Cloned]   Dur: {cloned_metrics['duration_sec']}s | SR: {cloned_sr}Hz | Rolloff: {cloned_metrics['spectral_rolloff_hz']}Hz | ASR: \"{cloned_asr}\"")

    results_file = os.path.join(out_dir, "comparison_results.json")
    with open(results_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"\nAll generations and comparisons complete! Saved results to {results_file}")

if __name__ == "__main__":
    main()
