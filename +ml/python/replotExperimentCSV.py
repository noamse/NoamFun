#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan  9 12:14:16 2026

@author: noamse
"""

from pathlib import Path
import pandas as pd
import subprocess
import sys

# --- CONFIGURATION (Adjust these to match your setup) ---

# 1. Experiment Details
ExpName = "ogleAprior"
Experiment_Root = Path("/data4/KMT/data/Experiments") / ExpName
CSV_PATH = Path("/home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv")

bin_days=5
# 2. Path to the replotting script (Created in the previous step)
#    Assumes it is in the same folder as this script.
PLOT_SCRIPT = Path(__file__).parent / "replot_WIS_res_bins_opt.py"
#PLOT_SCRIPT = Path(__file__).parent / "replot_WIS_flipped.py"

# 3. Output Directory Base
#    Plots will be saved to: {SaveFigDir_Base}/{EventName}/
SaveFigDir_Base = Path("/home/noamse/astro/KMT_ML/data/KMTNet/Experiments") / ExpName / "plots_summary"

# 4. Data Roots
OGLE_ROOT = Path("/home/noamse/KMT/OGLELC")
USE_OGLE = True

# --------------------------------------------------------

def get_event_name(event_num, field):
    return f"kmt{int(event_num):06d}_{int(field):02d}"

def get_config_path(event_num, field):
    """Returns path to config_WIS-2.yaml for existence check."""
    event_name = get_event_name(event_num, field)
    base_folder = Path(Experiment_Root) / event_name
    return base_folder / "config_WIS-2.yaml"

def main():
    # 1. Validate inputs
    if not CSV_PATH.is_file():
        raise FileNotFoundError(f"CSV not found: {CSV_PATH}")
    
    if not PLOT_SCRIPT.is_file():
        raise FileNotFoundError(f"Plotting script not found at: {PLOT_SCRIPT}\nPlease save the previous code as 'replot_WIS_final.py'.")

    # 2. Load and Filter CSV
    df = pd.read_csv(CSV_PATH)
    if "Accepted" in df.columns:
        df_ok = df[df["Accepted"] == 1].copy()
    else:
        print("Warning: 'Accepted' column not found. Running on ALL rows.")
        df_ok = df.copy()

    print(f"Found {len(df_ok)} accepted targets to process.")
    print(f"Experiment Root: {Experiment_Root}")
    print(f"Output Base:     {SaveFigDir_Base}")

    # 3. Loop over events
    for _, row in df_ok.iterrows():
        try:
            event_num = int(row["NumID"])
            field = int(row["FieldID"])
            eventind = int(row["EventInd"])
        except ValueError:
            print(f"Skipping row with invalid IDs: {row}")
            continue

        event_name = get_event_name(event_num, field)
        
        # Check if the experiment exists (via config check)
        cfg_ast = get_config_path(event_num, field)
        if not cfg_ast.is_file():
            print(f"⚠️  Missing main config for {event_name}. Skipping.")
            continue

        # Construct specific output directory for this event
        # (replot_WIS_final.py uses the passed --out_dir as the final destination)
        event_out_dir = SaveFigDir_Base / event_name

        # Build Command
        cmd = [
            sys.executable, str(PLOT_SCRIPT),
            "--event_num", str(event_num),
            "--field", str(field),
            "--EventInd", str(eventind),
            "--exp_root", str(Experiment_Root),
            "--out_dir", str(event_out_dir),
            "--ogle_root", str(OGLE_ROOT),
            "--bin_days" , str(bin_days)
        ]

        if USE_OGLE:
            cmd.append("--use_ogle")
        else:
            cmd.append("--no_ogle")

        print(f"\n--- Processing: {event_name} E{eventind} ---")
        
        # Execute
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed on {event_name} E{eventind}. Exit code: {e.returncode}")
            continue

    print("\nAll done.")

if __name__ == "__main__":
    main()