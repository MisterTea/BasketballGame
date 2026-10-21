import os
import sys
import json
import time
import shutil
import torch
import librosa
import numpy as np
import soundfile as sf
from voxcpm import VoxCPM

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
OUT_DIR = os.path.join(BASE_DIR, "announcer")
CLONED_DATA_DIR = os.path.join(BASE_DIR, "cloned_announcer_voxcpm")
REF_PATH = os.path.join(CLONED_DATA_DIR, "announcer_composite_ref.wav")

ANNOUNCEMENTS = [
    # Tipoff & Start
    {"id": "tip_off", "banner": "TIP OFF!", "phrase": "Tip off!"},
    {"id": "center_court", "banner": "CENTER COURT — SHOOT TO JUMP", "phrase": "Center court! Shoot to jump!"},
    {"id": "ball_up", "banner": "BALL UP! SHOOT TO JUMP", "phrase": "Ball up! Shoot to jump!"},
    {"id": "wins_the_tip", "banner": "WINS THE TIP!", "phrase": "Wins the tip!"},

    # Fire & Streaks
    {"id": "hes_on_fire", "banner": "HE'S ON FIRE!", "phrase": "He's on fire!", "existing": "voxcpm_hes_on_fire.wav"},
    {"id": "heating_up", "banner": "HE'S HEATING UP!", "phrase": "Heating up!", "existing": "voxcpm_heating_up.wav"},
    {"id": "hes_cooled_off", "banner": "HE'S COOLED OFF!", "phrase": "He's cooled off!"},
    {"id": "team_in_the_zone", "banner": "TEAM IN THE ZONE! 25 SECONDS!", "phrase": "Team in the zone! 25 seconds!"},
    {"id": "team_zone_expired", "banner": "TEAM ZONE EXPIRED!", "phrase": "Team zone expired!"},

    # Dunks & Special Dunks
    {"id": "boomshakalaka", "banner": "BOOMSHAKALAKA!", "phrase": "Boomshakalaka!"},
    {"id": "slam_dunk", "banner": "SLAM DUNK!", "phrase": "Slam dunk!", "existing": "voxcpm_slams_it.wav"},
    {"id": "double_dunk", "banner": "DOUBLE DUNK!", "phrase": "Double dunk!"},
    {"id": "somersault_jam", "banner": "SOMERSAULT JAM!", "phrase": "Somersault jam!"},
    {"id": "backflip_dunk", "banner": "BACKFLIP DUNK!", "phrase": "Backflip dunk!"},
    {"id": "windmill_360", "banner": "360 WINDMILL!", "phrase": "360 windmill!"},
    {"id": "between_legs", "banner": "BETWEEN THE LEGS!", "phrase": "Between the legs!"},
    {"id": "behind_back_slam", "banner": "BEHIND THE BACK SLAM!", "phrase": "Behind the back slam!"},
    {"id": "shattered", "banner": "BOOM! BACKBOARD SHATTERED!", "phrase": "Boom! Backboard shattered!"},

    # Shots & Scoring
    {"id": "from_downtown", "banner": "FROM DOWNTOWN!", "phrase": "From downtown!", "existing": "voxcpm_from_downtown.wav"},
    {"id": "nothing_but_net", "banner": "NOTHING BUT NET!", "phrase": "Nothing but net!"},
    {"id": "perfect_release", "banner": "PERFECT RELEASE!", "phrase": "Perfect release!"},
    {"id": "fadeaway", "banner": "FADEAWAY JUMPER!", "phrase": "Fadeaway jumper!"},
    {"id": "hook_shot", "banner": "HOOK SHOT!", "phrase": "Hook shot!"},
    {"id": "lay_it_up", "banner": "LAY IT UP!", "phrase": "Lay it up!"},
    {"id": "pull_up_jumper", "banner": "PULL-UP JUMPER!", "phrase": "Pull-up jumper!"},
    {"id": "finger_roll", "banner": "SWITCHES HANDS! FINGER ROLL!", "phrase": "Switches hands! Finger roll!"},
    {"id": "up_it_goes", "banner": "UP IT GOES", "phrase": "Up it goes!"},
    {"id": "take_the_shot", "banner": "TAKE THE SHOT!", "phrase": "Take the shot!"},

    # Passes & Alley-oops
    {"id": "alley_oop", "banner": "ALLEY-OOP!", "phrase": "Alley-oop!"},
    {"id": "lob_it_up", "banner": "LOB IT UP!", "phrase": "Lob it up!"},
    {"id": "airborne_dish", "banner": "AIRBORNE DISH!", "phrase": "Airborne dish!"},
    {"id": "behind_back_pass", "banner": "BEHIND THE BACK PASS!", "phrase": "Behind the back pass!"},
    {"id": "nice_pass", "banner": "NICE PASS", "phrase": "Nice pass!"},
    {"id": "call_for_pass", "banner": "CALL FOR PASS!", "phrase": "Call for pass!"},
    {"id": "spin_move", "banner": "SPIN MOVE!", "phrase": "Spin move!"},

    # Steals, Loose Ball, Turnovers
    {"id": "picked_pocket", "banner": "PICKED THEIR POCKET!", "phrase": "Picked their pocket!"},
    {"id": "stolen", "banner": "STOLEN!", "phrase": "Stolen!", "existing": "voxcpm_stolen.wav"},
    {"id": "pass_picked_off", "banner": "PASS PICKED OFF!", "phrase": "Pass picked off!"},
    {"id": "tipped_pass", "banner": "TIPPED PASS! LOOSE BALL", "phrase": "Tipped pass! Loose ball!"},
    {"id": "lost_the_handle", "banner": "LOST THE HANDLE! LOOSE BALL", "phrase": "Lost the handle! Loose ball!"},
    {"id": "loose_ball", "banner": "LOOSE BALL!", "phrase": "Loose ball!"},
    {"id": "lob_missed", "banner": "LOB MISSED! LOOSE BALL", "phrase": "Lob missed! Loose ball!"},
    {"id": "double_knockdown_turnover", "banner": "DOUBLE KNOCKDOWN! TURNOVER!", "phrase": "Double knockdown! Turnover!"},
    {"id": "stumbled_lost_ball", "banner": "STUMBLED! LOST THE BALL!", "phrase": "Stumbled! Lost the ball!"},

    # Defense, Blocks, Shoves
    {"id": "rejected", "banner": "REJECTED!", "phrase": "Rejected!", "existing": "voxcpm_rejected.wav"},
    {"id": "stuffed_at_rim", "banner": "STUFFED AT THE RIM!", "phrase": "Stuffed at the rim!"},
    {"id": "denied_at_rim", "banner": "DENIED AT THE RIM!", "phrase": "Denied at the rim!"},
    {"id": "rejected_at_rim", "banner": "NO CALL! REJECTED AT THE RIM!", "phrase": "No call! Rejected at the rim!"},
    {"id": "fire_block", "banner": "FIRE BLOCK! NO GOALTENDING!", "phrase": "Fire block! No goaltending!"},
    {"id": "clear_out", "banner": "CLEAR OUT!", "phrase": "Clear out!"},
    {"id": "double_shove", "banner": "DOUBLE SHOVE! KEEPS THE BALL!", "phrase": "Double shove! Keeps the ball!"},
    {"id": "double_knockdown", "banner": "DOUBLE KNOCKDOWN! NO FOULS!", "phrase": "Double knockdown! No fouls!"},
    {"id": "shoved_no_fouls", "banner": "SHOVED! NO FOULS!", "phrase": "Shoved! No fouls!"},
    {"id": "shoved_keeps_ball", "banner": "SHOVED! KEEPS THE BALL!", "phrase": "Shoved! Keeps the ball!"},
    {"id": "stumbled_keeps_ball", "banner": "STUMBLED! KEEPS THE BALL!", "phrase": "Stumbled! Keeps the ball!"},
    {"id": "staggered", "banner": "STAGGERED!", "phrase": "Staggered!"},

    # Rebounds, Misses
    {"id": "rebound", "banner": "REBOUND!", "phrase": "Rebound!"},
    {"id": "off_the_glass", "banner": "OFF THE GLASS!", "phrase": "Off the glass!"},
    {"id": "airball", "banner": "AIRBALL!", "phrase": "Airball!"},
    {"id": "off_the_back_iron", "banner": "OFF THE BACK IRON!", "phrase": "Off the back iron!"},
    {"id": "off_the_rim", "banner": "OFF THE RIM!", "phrase": "Off the rim!"},

    # Rules & Violations
    {"id": "goaltending", "banner": "GOALTENDING!", "phrase": "Goaltending!"},
    {"id": "no_pushing", "banner": "NO PUSHING!", "phrase": "No pushing!"},
    {"id": "shot_clock_violation", "banner": "SHOT CLOCK VIOLATION", "phrase": "Shot clock violation!"},
    {"id": "need_turbo", "banner": "NEED TURBO!", "phrase": "Need turbo!"},
    {"id": "head_fake", "banner": "HEAD FAKE!", "phrase": "Head fake!"},

    # Periods & Final
    {"id": "quarter_1", "banner": "QUARTER 1", "phrase": "Quarter 1!"},
    {"id": "quarter_2", "banner": "QUARTER 2", "phrase": "Quarter 2!"},
    {"id": "quarter_3", "banner": "QUARTER 3", "phrase": "Quarter 3!"},
    {"id": "quarter_4", "banner": "QUARTER 4", "phrase": "Quarter 4!"},
    {"id": "halftime", "banner": "HALFTIME • SWITCH ENDS", "phrase": "Halftime! Switch ends!"},
    {"id": "overtime", "banner": "OVERTIME", "phrase": "Overtime!"},
    {"id": "double_overtime", "banner": "DOUBLE OVERTIME", "phrase": "Double overtime!"},
    {"id": "triple_overtime", "banner": "TRIPLE OVERTIME", "phrase": "Triple overtime!"},
    {"id": "final", "banner": "FINAL", "phrase": "Final!", "existing": "voxcpm_at_the_buzzer.wav"},
]

def normalize_and_save(wav, sr, out_path):
    """Trim silence, peak normalize, and save as 16-bit WAV."""
    if len(wav.shape) > 1:
        wav = np.mean(wav, axis=1)
    # Trim leading/trailing silence
    trimmed, _ = librosa.effects.trim(wav, top_db=28)
    if len(trimmed) > 0:
        peak = np.max(np.abs(trimmed))
        if peak > 0:
            trimmed = (trimmed / peak) * 0.95
        sf.write(out_path, trimmed, sr, subtype='PCM_16')
    else:
        sf.write(out_path, wav, sr, subtype='PCM_16')

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest = {}

    # Seed any existing audio files first
    print("=== Step 1: Checking Existing Cloned Voices ===")
    for item in ANNOUNCEMENTS:
        item_id = item["id"]
        out_wav = os.path.join(OUT_DIR, f"{item_id}.wav")
        existing_name = item.get("existing")
        if existing_name and not os.path.exists(out_wav):
            existing_path = os.path.join(CLONED_DATA_DIR, existing_name)
            if os.path.exists(existing_path):
                y, sr = sf.read(existing_path)
                normalize_and_save(y, sr, out_wav)
                print(f"Seeded {item_id}.wav from {existing_name}")

    # Determine which items still need synthesis
    to_synthesize = []
    for item in ANNOUNCEMENTS:
        item_id = item["id"]
        out_wav = os.path.join(OUT_DIR, f"{item_id}.wav")
        manifest[item["banner"]] = f"res://voices/announcer/{item_id}.wav"
        manifest[item_id] = f"res://voices/announcer/{item_id}.wav"
        if not os.path.exists(out_wav) or os.path.getsize(out_wav) < 1000:
            to_synthesize.append(item)

    manifest_path = os.path.join(OUT_DIR, "announcements_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Saved manifest to {manifest_path}")

    print(f"\nTotal phrases: {len(ANNOUNCEMENTS)}")
    print(f"Already available: {len(ANNOUNCEMENTS) - len(to_synthesize)}")
    print(f"Pending synthesis: {len(to_synthesize)}")

    if not to_synthesize:
        print("All announcement voices already synthesized!")
        return

    print("\n=== Step 2: Initializing VoxCPM2 ===")
    model = VoxCPM.from_pretrained("openbmb/VoxCPM2", optimize=False, load_denoiser=False)
    tts_sample_rate = model.tts_model.sample_rate

    print(f"\n=== Step 3: Synthesizing {len(to_synthesize)} Announcement Voices ===")
    start_total = time.time()
    for idx, item in enumerate(to_synthesize, 1):
        item_id = item["id"]
        phrase = item["phrase"]
        out_wav = os.path.join(OUT_DIR, f"{item_id}.wav")
        print(f"[{idx}/{len(to_synthesize)}] Synthesizing: \"{phrase}\" (id: {item_id})...", flush=True)
        t0 = time.time()
        wav = model.generate(
            text=phrase,
            reference_wav_path=REF_PATH,
            inference_timesteps=10,
            cfg_value=2.5
        )
        gen_time = time.time() - t0
        normalize_and_save(wav, tts_sample_rate, out_wav)
        file_size = os.path.getsize(out_wav)
        print(f"   -> Done in {gen_time:.2f}s ({file_size} bytes)", flush=True)

    elapsed_total = time.time() - start_total
    print(f"\nAll synthesis complete in {elapsed_total:.2f}s ({elapsed_total/60:.2f} min)!")

if __name__ == "__main__":
    main()
