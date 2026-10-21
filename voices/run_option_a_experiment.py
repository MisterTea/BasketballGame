import os
import json
import time
import torch
import librosa
import numpy as np
import soundfile as sf
from scipy.signal import butter, filtfilt
from transformers import pipeline
from voxcpm import VoxCPM

def butter_highpass_filter(data, cutoff=80, fs=16000, order=4):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='high', analog=False)
    return filtfilt(b, a, data)

def build_profile(files, sound_dir, out_path, target_sr=16000):
    segments = []
    silence = np.zeros(int(target_sr * 0.15))
    for f in files:
        p = os.path.join(sound_dir, f)
        if os.path.exists(p):
            y, sr = librosa.load(p, sr=target_sr, mono=True)
            y = butter_highpass_filter(y, cutoff=80, fs=target_sr)
            y, _ = librosa.effects.trim(y, top_db=25)
            peak = np.max(np.abs(y))
            if peak > 0:
                y = y / peak * 0.95
            segments.append(y)
            segments.append(silence)
    composite = np.concatenate(segments[:-1])
    sf.write(out_path, composite, target_sr)
    
    # measure reference pitch
    f0 = librosa.yin(composite, fmin=70, fmax=420, sr=target_sr)
    voiced = f0[(f0 > 75) & (f0 < 400)]
    mean_f0 = float(np.mean(voiced)) if len(voiced) > 0 else 0.0
    med_f0 = float(np.median(voiced)) if len(voiced) > 0 else 0.0
    print(f"Built {os.path.basename(out_path)} ({len(composite)/target_sr:.2f}s) -> Reference Pitch: Med {med_f0:.1f} Hz, Mean {mean_f0:.1f} Hz")
    return out_path, med_f0

def extract_pitch(audio, sr):
    if len(audio.shape) > 1:
        audio = np.mean(audio, axis=1)
    f0 = librosa.yin(audio, fmin=70, fmax=420, sr=sr)
    voiced = f0[(f0 > 75) & (f0 < 400)]
    if len(voiced) > 0:
        return float(np.mean(voiced)), float(np.median(voiced)), float(np.std(voiced))
    return 0.0, 0.0, 0.0

def main():
    sound_dir = r"E:\github\jam_game\base\NBA Jam - Tournament Edition Sounds"
    out_dir = r"E:\github\jam_game\voices\cloned_announcer_voxcpm\option_a_split"
    os.makedirs(out_dir, exist_ok=True)

    print("=== Step 1: Building Separate Held-Out Reference Profiles ===")
    
    # 1. SHOUT reference pool (held-out from shout test set)
    shout_heldout_files = [
        "85 - Scream.wav",
        "71 - Intercepted (7.3k).wav",
        "25 - Wide Open (7.3k).wav",
        "56 - No Good.wav",
        "9 -  Wild Shot.wav"
    ]
    shout_ref_path = os.path.join(out_dir, "ref_shout_heldout.wav")
    _, shout_ref_f0 = build_profile(shout_heldout_files, sound_dir, shout_ref_path)

    # 2. PLAY-BY-PLAY reference pool (held-out from play-by-play test set)
    pbp_heldout_files = [
        "13 - Tonight's Matchup (11k).wav",
        "15 - Warriors (11k).wav",
        "17 - Lakers (11k).wav",
        "22 - Scores.wav",
        "69 - Overtime (slow).wav",
        "70 -  Win the game (slow).wav"
    ]
    pbp_ref_path = os.path.join(out_dir, "ref_pbp_heldout.wav")
    _, pbp_ref_f0 = build_profile(pbp_heldout_files, sound_dir, pbp_ref_path)

    # Load baseline CFG 2.7 results for direct comparison
    baseline_json_p = r"E:\github\jam_game\voices\cloned_announcer_voxcpm\cfg27\cfg27_pitch_results.json"
    baseline_lookup = {}
    if os.path.exists(baseline_json_p):
        with open(baseline_json_p, "r", encoding="utf-8") as f:
            for item in json.load(f):
                baseline_lookup[item["id"]] = item

    print("\n=== Step 2: Defining Test Lines for Shout & Play-by-Play ===")
    test_lines = [
        # --- SHOUT CATEGORY ---
        {
            "id": "hes_on_fire",
            "category": "shout",
            "phrase": "He's on fire!",
            "orig_file": "50 - He's On Fire (7.3k).wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "kaboom",
            "category": "shout",
            "phrase": "Kaboom!",
            "orig_file": "58 - Kaboom (slightly slow).wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "rejected",
            "category": "shout",
            "phrase": "Rejected!",
            "orig_file": "77 - Rejected (7.3k).wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "monster_jam",
            "category": "shout",
            "phrase": "Monster jam!",
            "orig_file": "23 - Monster Jam (6k).wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "from_downtown",
            "category": "shout",
            "phrase": "From downtown!",
            "orig_file": "21 - From Downtown (6k).wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "slams_it",
            "category": "shout",
            "phrase": "Slams it!",
            "orig_file": "4 -  Slams It.wav",
            "ref_path": shout_ref_path
        },
        {
            "id": "razzle_dazzle",
            "category": "shout",
            "phrase": "Razzle Dazzle!",
            "orig_file": "3 - Razzle Dazzle.wav",
            "ref_path": shout_ref_path
        },
        # --- PLAY-BY-PLAY CATEGORY ---
        {
            "id": "welcome_to_nba_jam",
            "category": "play_by_play",
            "phrase": "Welcome to NBA Jam!",
            "orig_file": "28 - Welcome to NBA JAM (slightly slow).wav",
            "ref_path": pbp_ref_path
        },
        {
            "id": "showtime",
            "category": "play_by_play",
            "phrase": "Showtime!",
            "orig_file": "68 - Showtime.wav",
            "ref_path": pbp_ref_path
        },
        {
            "id": "at_the_buzzer",
            "category": "play_by_play",
            "phrase": "At the buzzer!",
            "orig_file": "49 - At the Buzzer (7.3k).wav",
            "ref_path": pbp_ref_path
        },
        {
            "id": "heating_up",
            "category": "play_by_play",
            "phrase": "Heating up!",
            "orig_file": "51 Heating Up (slow).wav",
            "ref_path": pbp_ref_path
        },
        {
            "id": "two_points",
            "category": "play_by_play",
            "phrase": "Two points!",
            "orig_file": "57 - Two Points (7.3k).wav",
            "ref_path": pbp_ref_path
        },
        {
            "id": "count_it",
            "category": "play_by_play",
            "phrase": "Count it!",
            "orig_file": "20 - Count It.wav",
            "ref_path": pbp_ref_path
        }
    ]

    print(f"Total test phrases: {len(test_lines)} (7 Shouts, 6 Play-by-Play)")

    print("\n=== Step 3: Loading VoxCPM2 (bf16, CUDA) ===")
    model = VoxCPM.from_pretrained("openbmb/VoxCPM2", optimize=False, load_denoiser=False)
    tts_sample_rate = model.tts_model.sample_rate

    print("\n=== Step 4: Loading Whisper Pipeline ===")
    transcriber = pipeline("automatic-speech-recognition", model="openai/whisper-tiny", device="cuda")

    results = []

    print("\n=== Step 5: Synthesizing with Option A & Measuring Pitch ===")
    for idx, item in enumerate(test_lines, 1):
        phrase = item["phrase"]
        item_id = item["id"]
        cat = item["category"]
        ref_path = item["ref_path"]
        orig_p = os.path.join(sound_dir, item["orig_file"])
        out_p = os.path.join(out_dir, f"optA_{cat}_{item_id}.wav")

        print(f"\n[{idx}/{len(test_lines)}] [{cat.upper()}] Synthesizing: \"{phrase}\" (CFG=2.7, 30 steps)...")
        t0 = time.time()
        wav = model.generate(
            text=phrase,
            reference_wav_path=ref_path,
            inference_timesteps=30,
            cfg_value=2.7
        )
        gen_time = time.time() - t0
        sf.write(out_p, wav, tts_sample_rate)

        # Ground truth pitch & ASR
        orig_audio, orig_sr = sf.read(orig_p)
        orig_mean_f0, orig_med_f0, orig_std_f0 = extract_pitch(orig_audio, orig_sr)
        orig_asr = transcriber({"raw": orig_audio, "sampling_rate": orig_sr})["text"].strip()

        # Option A cloned pitch & ASR
        cloned_audio, cloned_sr = sf.read(out_p)
        optA_mean_f0, optA_med_f0, optA_std_f0 = extract_pitch(cloned_audio, cloned_sr)
        optA_asr = transcriber({"raw": cloned_audio, "sampling_rate": cloned_sr})["text"].strip()

        # Semitone error vs ground truth
        st_err_optA = 0.0
        if orig_med_f0 > 0 and optA_med_f0 > 0:
            st_err_optA = round(12 * np.log2(optA_med_f0 / orig_med_f0), 2)

        # Baseline error comparison if available
        base_med_f0 = None
        base_st_err = None
        if item_id in baseline_lookup:
            base_med_f0 = baseline_lookup[item_id]["cloned_cfg27"]["metrics"]["median_f0_hz"]
            base_st_err = baseline_lookup[item_id]["pitch_comparison"]["semitone_diff"]

        comp = {
            "id": item_id,
            "category": cat,
            "target_phrase": phrase,
            "original": {
                "file": item["orig_file"],
                "median_f0_hz": round(orig_med_f0, 1),
                "mean_f0_hz": round(orig_mean_f0, 1),
                "asr": orig_asr
            },
            "option_a": {
                "file": os.path.basename(out_p),
                "median_f0_hz": round(optA_med_f0, 1),
                "mean_f0_hz": round(optA_mean_f0, 1),
                "semitone_diff": st_err_optA,
                "asr": optA_asr
            },
            "baseline_single_ref": {
                "median_f0_hz": base_med_f0,
                "semitone_diff": base_st_err
            }
        }
        results.append(comp)

        print(f"   [Ground Truth] Median F0: {orig_med_f0:5.1f} Hz")
        print(f"   [Option A    ] Median F0: {optA_med_f0:5.1f} Hz (Err: {st_err_optA:+4.2f} st) | ASR: \"{optA_asr}\"")
        if base_med_f0:
            print(f"   [Single Ref  ] Median F0: {base_med_f0:5.1f} Hz (Err: {base_st_err:+4.2f} st)")

    res_json_p = os.path.join(out_dir, "option_a_pitch_comparison.json")
    with open(res_json_p, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\nExperiment complete! Saved results to {res_json_p}")

if __name__ == "__main__":
    main()
